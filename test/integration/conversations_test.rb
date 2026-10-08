require "test_helper"

class ConversationsTest < ActionDispatch::IntegrationTest
  setup do
    @leaf = Category.create!(name: "Motor Sürücü", slug: "motor-surucu")
    @part = Part.create!(code: "TB6612FNG", name: "TB6612FNG", category: @leaf, status: "approved")

    @seller = User.create!(full_name: "Satıcı Kişi", email: "seller@example.com", password: "password1", city: "Ankara")
    @buyer = User.create!(full_name: "Alıcı Kişi", email: "buyer@example.com", password: "password1", city: "İzmir")
    @stranger = User.create!(full_name: "Yabancı Kişi", email: "stranger@example.com", password: "password1", city: "Bursa")

    @listing = Listing.create!(
      user: @seller, category: @leaf, part: @part,
      title: "TB6612FNG sürücü", description: "çalışır durumda", condition: "used",
      price: 100, city: "Ankara",
    )
  end

  def login_as(user)
    post "/api/v1/auth/login", params: { email: user.email, password: "password1" }, as: :json
    assert_response :success
  end

  test "requires login" do
    get "/api/v1/conversations"
    assert_response :unauthorized
  end

  test "creates conversation without message" do
    login_as(@buyer)

    assert_difference -> { Conversation.count }, 1 do
      post "/api/v1/conversations", params: { listing_id: @listing.id }, as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "buyer", body["role"]
    assert_equal @listing.id, body["listing"]["id"]
    assert_equal @seller.id, body["other_user"]["id"]
  end

  test "find or create returns existing conversation" do
    login_as(@buyer)
    post "/api/v1/conversations", params: { listing_id: @listing.id, body: "Merhaba" }, as: :json
    assert_response :created

    assert_no_difference -> { Conversation.count } do
      post "/api/v1/conversations", params: { listing_id: @listing.id }, as: :json
    end
    assert_response :success
  end

  test "cannot message own listing" do
    login_as(@seller)

    post "/api/v1/conversations", params: { listing_id: @listing.id }, as: :json
    assert_response :unprocessable_entity
    assert_equal "own_listing", JSON.parse(response.body)["error"]["code"]
  end

  test "cannot message non-active listing" do
    login_as(@buyer)
    @listing.remove!(reason: "withdrawn")

    post "/api/v1/conversations", params: { listing_id: @listing.id }, as: :json
    assert_response :unprocessable_entity
    assert_equal "listing_not_active", JSON.parse(response.body)["error"]["code"]
  end

  test "index lists conversations with last_message and unread_count" do
    login_as(@buyer)
    conversation = Conversation.create!(listing: @listing, buyer: @buyer)
    conversation.messages.create!(sender: @seller, body: "Merhaba", read_at: nil)
    conversation.messages.create!(sender: @buyer, body: "Selam", read_at: nil)
    conversation.update!(last_message_at: conversation.messages.order(:id).last.created_at)

    get "/api/v1/conversations"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal "buyer", body.first["role"]
    assert_equal 1, body.first["unread_count"]
    assert_equal "Selam", body.first["last_message"]["body"]
  end

  test "show returns last messages and marks counterpart read" do
    conversation = Conversation.create!(listing: @listing, buyer: @buyer)
    m1 = conversation.messages.create!(sender: @seller, body: "Merhaba")
    conversation.messages.create!(sender: @buyer, body: "Selam")

    login_as(@buyer)
    get "/api/v1/conversations/#{conversation.id}"
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 2, body["messages"].size
    assert m1.reload.read_at
  end

  test "stranger cannot access conversation" do
    conversation = Conversation.create!(listing: @listing, buyer: @buyer)
    login_as(@stranger)

    get "/api/v1/conversations/#{conversation.id}"
    assert_response :not_found
  end

  test "messages after returns only newer messages" do
    conversation = Conversation.create!(listing: @listing, buyer: @buyer)
    m1 = conversation.messages.create!(sender: @buyer, body: "ilk")
    m2 = conversation.messages.create!(sender: @seller, body: "ikinci")
    m3 = conversation.messages.create!(sender: @seller, body: "üçüncü")

    login_as(@buyer)
    get "/api/v1/conversations/#{conversation.id}/messages", params: { after: m1.id }
    assert_response :success
    ids = JSON.parse(response.body)["messages"].map { |m| m["id"] }
    assert_equal [m2.id, m3.id], ids
    assert m2.reload.read_at
    assert m3.reload.read_at
  end

  test "create message updates last_message_at" do
    conversation = Conversation.create!(listing: @listing, buyer: @buyer)
    login_as(@buyer)

    post "/api/v1/conversations/#{conversation.id}/messages", params: { body: "Yeni mesaj" }, as: :json
    assert_response :created

    conversation.reload
    assert conversation.last_message_at
    assert_equal "Yeni mesaj", conversation.messages.last.body
  end

  test "blank message is rejected" do
    conversation = Conversation.create!(listing: @listing, buyer: @buyer)
    login_as(@buyer)

    post "/api/v1/conversations/#{conversation.id}/messages", params: { body: "   " }, as: :json
    assert_response :unprocessable_entity
  end

  test "unread_counts returns message and announcement counts" do
    conversation = Conversation.create!(listing: @listing, buyer: @buyer)
    conversation.messages.create!(sender: @seller, body: "Merhaba", read_at: nil)

    login_as(@buyer)
    get "/api/v1/me/unread_counts"
    assert_response :success
    assert_equal 1, JSON.parse(response.body)["messages"]
    assert_equal 0, JSON.parse(response.body)["announcements"]
  end

  test "deleting listing deletes conversations, messages and reports" do
    conversation = Conversation.create!(listing: @listing, buyer: @buyer)
    conversation.messages.create!(sender: @seller, body: "Merhaba")
    @listing.reports.create!(reporter: @buyer, reason: "spam")

    assert_difference -> { Conversation.count }, -1 do
      assert_difference -> { Message.count }, -1 do
        assert_difference -> { Report.count }, -1 do
          @listing.destroy!
        end
      end
    end
  end

  test "deleting user deletes buyer conversations, reports and announcement_reads" do
    conversation = Conversation.create!(listing: @listing, buyer: @buyer)
    conversation.messages.create!(sender: @buyer, body: "Merhaba")

    other_listing = Listing.create!(
      user: @buyer, category: @leaf,
      title: "Başka ilan", description: "açıklama", condition: "new", price: 50, city: "İzmir",
    )
    other_listing.reports.create!(reporter: @seller, reason: "spam")

    announcement = Announcement.create!(
      admin: @seller, title: "Duyuru", body: "İçerik", published_at: Time.current,
    )
    @buyer.announcement_reads.create!(announcement: announcement)

    @buyer.destroy!

    assert_equal 0, Conversation.count
    assert_equal 0, Message.count
    assert_equal 0, @seller.reports.count
    assert_equal 0, AnnouncementRead.count
  end
end
