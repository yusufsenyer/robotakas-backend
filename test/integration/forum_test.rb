require "test_helper"

class ForumTest < ActionDispatch::IntegrationTest
  setup do
    @board = ForumBoard.create!(name: "Mini Sumo", slug: "mini-sumo", kind: "competition", position: 0)
    @general = ForumBoard.create!(name: "Genel sohbet", slug: "genel-sohbet", kind: "general", position: 0)

    @owner = User.create!(full_name: "Efe Kaya", email: "efe@example.com", password: "password1", city: "Ankara")
    @other = User.create!(full_name: "Zeynep Demir", email: "zeynep@example.com", password: "password1", city: "İzmir")
    @admin = User.create!(full_name: "Admin", email: "admin@example.com", password: "password1", city: "Ankara", role: "admin")
  end

  def login_as(user)
    post "/api/v1/auth/login", params: { email: user.email, password: "password1" }, as: :json
    assert_response :success
  end

  def create_topic(user:, board: @board, kind: "question", title: "Sensör seçimi nasıl olmalı",
                   body: "Uzun bir gövde metni yazıyorum buraya, fikir almak istiyorum.")
    ForumTopic.create!(forum_board: board, user: user, kind: kind, title: title, body: body)
  end

  test "boards index returns competition before general" do
    get "/api/v1/forum/boards"
    assert_response :success
    kinds = JSON.parse(response.body).map { |b| b["kind"] }
    assert_equal %w[competition general], kinds.uniq
    assert_equal "mini-sumo", JSON.parse(response.body).first["slug"]
  end

  test "board show returns 404 for unknown slug" do
    get "/api/v1/forum/boards/yok"
    assert_response :not_found
  end

  test "creating a topic requires login" do
    assert_no_difference -> { ForumTopic.count } do
      post "/api/v1/forum/topics", params: { board: "mini-sumo", kind: "question", title: "Başlık buraya", body: "Gövde metni buraya yazıyorum." }, as: :json
    end
    assert_response :unauthorized
  end

  test "creates a topic and updates board counters" do
    login_as(@owner)

    assert_difference -> { ForumTopic.count }, 1 do
      post "/api/v1/forum/topics", params: { board: "mini-sumo", kind: "question", title: "Motor seçimi nasıl yapılır", body: "İki sezon kullandığım motoru paylaşıyorum." }, as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "question", body["kind"]
    assert_equal true, body["is_owner"]
    assert_equal @owner.id, body["user"]["id"]
    assert_equal "mini-sumo", body["board"]["slug"]

    @board.reload
    assert_equal 1, @board.topics_count
  end

  test "rejects invalid topic with Turkish validation error" do
    login_as(@owner)
    post "/api/v1/forum/topics", params: { board: "mini-sumo", kind: "question", title: "kısa", body: "kısa" }, as: :json
    assert_response :unprocessable_entity
    assert_equal "validation_failed", JSON.parse(response.body)["error"]["code"]
  end

  test "topics index filters by board, kind and unanswered" do
    create_topic(user: @owner, kind: "question")
    answered = create_topic(user: @other, kind: "discussion", title: "Genel bir tartışma konusu")
    answered.forum_posts.create!(user: @owner, body: "Bir cevap yazıyorum")
    create_topic(user: @owner, board: @general, kind: "discussion", title: "Genel sohbet başlığı")

    get "/api/v1/forum/topics", params: { board: "mini-sumo" }
    assert_response :success
    slugs = JSON.parse(response.body)["topics"].map { |t| t["board"]["slug"] }
    assert_equal [ "mini-sumo" ], slugs.uniq

    get "/api/v1/forum/topics", params: { unanswered: "true" }
    body = JSON.parse(response.body)["topics"]
    assert_equal 1, body.size
    assert_equal "question", body.first["kind"]

    get "/api/v1/forum/topics", params: { kind: "discussion" }
    assert_equal 2, JSON.parse(response.body)["topics"].size
  end

  test "pinned topics come first" do
    older = create_topic(user: @owner, title: "Eski konu başlığı burada")
    newer = create_topic(user: @owner, title: "Yeni konu başlığı burada")
    older.update!(pinned: true)

    get "/api/v1/forum/topics"
    ids = JSON.parse(response.body)["topics"].map { |t| t["id"] }
    assert_equal older.id, ids.first
    assert_includes ids, newer.id
  end

  test "show increments views except for owner and when count disabled" do
    topic = create_topic(user: @owner)

    get "/api/v1/forum/topics/#{topic.id}"
    assert_response :success
    assert_equal 1, topic.reload.views_count

    get "/api/v1/forum/topics/#{topic.id}", params: { count: "0" }
    assert_equal 1, topic.reload.views_count

    login_as(@owner)
    get "/api/v1/forum/topics/#{topic.id}"
    assert_equal 1, topic.reload.views_count
  end

  test "replying to a locked topic returns 422" do
    topic = create_topic(user: @owner)
    topic.update!(locked: true)

    login_as(@other)
    post "/api/v1/forum/topics/#{topic.id}/posts", params: { body: "Yeni cevap" }, as: :json
    assert_response :unprocessable_entity
    assert_equal "topic_locked", JSON.parse(response.body)["error"]["code"]
  end

  test "topic creation is rate limited but admin is exempt" do
    5.times { |i| create_topic(user: @owner, title: "Konu başlığı numara #{i}") }

    login_as(@owner)
    post "/api/v1/forum/topics", params: { board: "mini-sumo", kind: "question", title: "Altıncı konu başlığı", body: "Gövde metni buraya yazıyorum." }, as: :json
    assert_response :too_many_requests
    assert_equal "rate_limited", JSON.parse(response.body)["error"]["code"]

    login_as(@admin)
    post "/api/v1/forum/topics", params: { board: "mini-sumo", kind: "question", title: "Admin konusu açıyor", body: "Gövde metni buraya yazıyorum." }, as: :json
    assert_response :created
  end

  test "post creation is rate limited but admin is exempt" do
    topic = create_topic(user: @owner)
    20.times { |i| topic.forum_posts.create!(user: @other, body: "Cevap #{i}") }

    login_as(@other)
    post "/api/v1/forum/topics/#{topic.id}/posts", params: { body: "Yirmi birinci cevap" }, as: :json
    assert_response :too_many_requests

    login_as(@admin)
    post "/api/v1/forum/topics/#{topic.id}/posts", params: { body: "Admin cevabı" }, as: :json
    assert_response :created
  end

  test "only owner and admin can edit or delete a topic" do
    topic = create_topic(user: @owner)

    login_as(@other)
    patch "/api/v1/forum/topics/#{topic.id}", params: { title: "Değiştirilmiş başlık" }, as: :json
    assert_response :forbidden
    delete "/api/v1/forum/topics/#{topic.id}"
    assert_response :forbidden

    login_as(@owner)
    patch "/api/v1/forum/topics/#{topic.id}", params: { title: "Yeni başlık buraya" }, as: :json
    assert_response :success
    assert JSON.parse(response.body)["edited_at"].present?
  end

  test "admin can permanently delete a topic with its posts" do
    topic = create_topic(user: @owner)
    topic.forum_posts.create!(user: @other, body: "Bir cevap yazıyorum")

    login_as(@admin)
    assert_difference -> { ForumTopic.count }, -1 do
      assert_difference -> { ForumPost.count }, -1 do
        delete "/api/v1/forum/topics/#{topic.id}"
      end
    end
    assert_response :no_content
    @board.reload
    assert_equal 0, @board.topics_count
    assert_equal 0, @board.posts_count
  end

  test "posts are listed oldest first with pagination" do
    topic = create_topic(user: @owner)
    25.times { |i| topic.forum_posts.create!(user: @other, body: "Cevap numara #{i}") }

    get "/api/v1/forum/topics/#{topic.id}/posts"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 25, body["meta"]["total"]
    assert_equal 20, body["posts"].size
    assert_equal "Cevap numara 0", body["posts"].first["body"]

    get "/api/v1/forum/topics/#{topic.id}/posts", params: { page: 2 }
    assert_equal 5, JSON.parse(response.body)["posts"].size
  end

  test "creating a post returns it and updates counters" do
    topic = create_topic(user: @owner)
    login_as(@other)

    assert_difference -> { ForumPost.count }, 1 do
      post "/api/v1/forum/topics/#{topic.id}/posts", params: { body: "Yeni bir cevap yazıyorum" }, as: :json
    end

    assert_response :created
    assert_equal true, JSON.parse(response.body)["is_owner"]
    assert_equal 1, topic.reload.posts_count
    assert_equal 1, @board.reload.posts_count
  end

  test "deleting a user removes their forum content and updates board counters" do
    topic = create_topic(user: @owner)
    topic.forum_posts.create!(user: @owner, body: "Kendi cevabım")

    assert_difference -> { ForumTopic.count }, -1 do
      assert_difference -> { ForumPost.count }, -1 do
        @owner.destroy!
      end
    end

    @board.reload
    assert_equal 0, @board.topics_count
    assert_equal 0, @board.posts_count
  end
end
