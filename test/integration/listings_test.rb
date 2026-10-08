require "test_helper"

class ListingsTest < ActionDispatch::IntegrationTest
  setup do
    @root = Category.create!(name: "Mini Sumo", slug: "mini-sumo")
    @leaf_motor = Category.create!(name: "Motor Sürücü", slug: "mini-sumo-motor-surucu", parent: @root)
    @leaf_sensor = Category.create!(name: "Sensör", slug: "mini-sumo-sensor", parent: @root)

    @root2 = Category.create!(name: "Çizgi İzleyen", slug: "cizgi-izleyen")
    @leaf2_sensor = Category.create!(name: "Sensör", slug: "cizgi-izleyen-sensor", parent: @root2)

    @part = Part.create!(code: "TB6612FNG", name: "TB6612FNG", category: @leaf_motor, status: "approved")

    @seller = User.create!(full_name: "Satıcı Kişi", email: "seller@example.com", password: "password1", city: "Ankara", phone: "05550000001")
    @other = User.create!(full_name: "Başka Kişi", email: "other@example.com", password: "password1", city: "İzmir")

    @l1 = Listing.create!(
      user: @seller, category: @leaf_motor, part: @part,
      title: "TB6612FNG sürücü", description: "çalışır durumda", condition: "used",
      price: 100, city: "Ankara", published_at: 1.day.ago,
    )
    @l2 = Listing.create!(
      user: @seller, category: @leaf_motor, part: @part,
      title: "TB6612FNG sıfır", description: "sıfır kutu", condition: "new",
      price: 200, city: "İzmir", published_at: 2.days.ago,
    )
    @l3 = Listing.create!(
      user: @other, category: @leaf_sensor,
      title: "QTR sensör seti", description: "genel ürün", condition: "used",
      price: 50, city: "Ankara", published_at: 3.days.ago,
    )
  end

  def login_as(user)
    post "/api/v1/auth/login", params: { email: user.email, password: "password1" }, as: :json
    assert_response :success
  end

  test "index returns only active listings" do
    get "/api/v1/listings"
    assert_response :success
    ids = JSON.parse(response.body)["listings"].map { |l| l["id"] }
    assert_equal [@l1.id, @l2.id, @l3.id].sort, ids.sort
  end

  test "list item and detail expose the category icon key" do
    @leaf_motor.update!(icon_key: "Cpu")

    get "/api/v1/listings"
    item = JSON.parse(response.body)["listings"].find { |l| l["id"] == @l1.id }
    assert_equal "Cpu", item["category_icon_key"]

    get "/api/v1/listings/#{@l1.id}"
    assert_equal "Cpu", JSON.parse(response.body).dig("category", "icon_key")
  end

  test "filters by price range" do
    get "/api/v1/listings", params: { min_price: 80, max_price: 150 }
    ids = JSON.parse(response.body)["listings"].map { |l| l["id"] }
    assert_includes ids, @l1.id
    assert_not_includes ids, @l2.id
    assert_not_includes ids, @l3.id
  end

  test "sorts by price ascending" do
    get "/api/v1/listings", params: { sort: "price_asc" }
    prices = JSON.parse(response.body)["listings"].map { |l| l["price"] }
    assert_equal prices.sort, prices
  end

  test "smart sort ranks part code match above title match" do
    title_only = Listing.create!(
      user: @seller, category: @leaf_motor, part: nil,
      title: "TB6612FNG benzeri sürücü", description: "açıklama", condition: "used",
      price: 70, city: "Ankara", published_at: 1.hour.ago,
    )

    get "/api/v1/listings", params: { q: "tb66", sort: "smart" }
    ids = JSON.parse(response.body)["listings"].map { |l| l["id"] }

    assert_equal [@l1.id, @l2.id, title_only.id], ids
  end

  test "category_id covers subtree and compatible tags" do
    @l1.compatible_categories << @root2

    get "/api/v1/listings", params: { category_id: @root.id }
    ids = JSON.parse(response.body)["listings"].map { |l| l["id"] }
    assert_includes ids, @l1.id
    assert_includes ids, @l2.id

    get "/api/v1/listings", params: { category_id: @root2.id }
    ids = JSON.parse(response.body)["listings"].map { |l| l["id"] }
    assert_includes ids, @l1.id
    assert_not_includes ids, @l2.id
  end

  test "category slug filters subtree" do
    get "/api/v1/listings", params: { category: @root.slug }
    ids = JSON.parse(response.body)["listings"].map { |l| l["id"] }
    assert_equal [@l1.id, @l2.id, @l3.id].sort, ids.sort
  end

  test "compatible_category slug filters by tag" do
    @l1.compatible_categories << @root2

    get "/api/v1/listings", params: { compatible_category: @root2.slug }
    ids = JSON.parse(response.body)["listings"].map { |l| l["id"] }
    assert_includes ids, @l1.id
    assert_not_includes ids, @l2.id
  end

  test "index marks favorited_by_me for current user" do
    login_as(@other)
    @other.favorites.create!(listing: @l1)

    get "/api/v1/listings"
    by_id = JSON.parse(response.body)["listings"].index_by { |l| l["id"] }
    assert by_id[@l1.id]["favorited_by_me"]
    assert_not by_id[@l2.id]["favorited_by_me"]
  end

  test "paginates" do
    get "/api/v1/listings", params: { per_page: 2, page: 1 }
    meta = JSON.parse(response.body)["meta"]
    assert_equal 3, meta["total"]
    assert_equal 2, meta["total_pages"]
    assert_equal 2, JSON.parse(response.body)["listings"].size
  end

  test "requires login to create" do
    post "/api/v1/listings", params: { title: "Deneme ilan", description: "açıklama", condition: "new", price: 100, category_id: @leaf_motor.id, city: "Ankara" }, as: :json
    assert_response :unauthorized
  end

  test "creates listing with part" do
    login_as(@seller)

    assert_difference -> { Listing.count }, 1 do
      post "/api/v1/listings", params: {
        title: "Yeni sürücü", description: "kısa açıklama", condition: "new", price: 150,
        category_id: @leaf_motor.id, part_id: @part.id, city: "Ankara", district: "Çankaya",
      }, as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "active", body["status"]
    assert_equal "TB6612FNG", body["part"]["code"]
    assert body["is_owner"]
  end

  test "creates listing with photo via multipart" do
    login_as(@seller)

    assert_difference -> { ActiveStorage::Attachment.count }, 1 do
      post "/api/v1/listings", params: {
        title: "Fotoğraflı sürücü",
        description: "fotoğraflı ilan",
        condition: "used",
        price: 130,
        category_id: @leaf_motor.id,
        part_id: @part.id,
        city: "Ankara",
        photos: [fixture_file_upload("test.png", "image/png")],
      }
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal 1, body["photos"].size
    assert body["photos"].first
  end

  test "show_phone requires phone" do
    login_as(@other)

    post "/api/v1/listings", params: {
      title: "Telefonsuz ilan", description: "açıklama", condition: "new", price: 100,
      category_id: @leaf_motor.id, part_id: @part.id, city: "İzmir", show_phone: "true",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "phone_required", JSON.parse(response.body)["error"]["code"]
  end

  test "cannot update another user's listing" do
    login_as(@other)

    patch "/api/v1/listings/#{@l1.id}", params: { title: "Çalındı" }, as: :json
    assert_response :forbidden
  end

  test "cannot delete another user's listing" do
    login_as(@other)

    delete "/api/v1/listings/#{@l1.id}"
    assert_response :forbidden
  end

  test "remove with delete true deletes listing and keeps counter" do
    login_as(@seller)

    post "/api/v1/listings/#{@l1.id}/remove", params: { reason: "sold", delete: "true" }, as: :json
    assert_response :no_content
    assert_nil Listing.find_by(id: @l1.id)
    assert_equal 1, SiteStat.value("sold_total")
  end

  test "favorite and unfavorite" do
    login_as(@other)

    post "/api/v1/listings/#{@l1.id}/favorite"
    assert_response :success

    get "/api/v1/me/favorites"
    ids = JSON.parse(response.body).map { |l| l["id"] }
    assert_includes ids, @l1.id

    delete "/api/v1/listings/#{@l1.id}/favorite"
    assert_response :success

    get "/api/v1/me/favorites"
    assert_empty JSON.parse(response.body)
  end

  test "detail includes photo ids, category object and null video" do
    @l1.photos.attach(
      io: StringIO.new("foto"),
      filename: "t.png",
      content_type: "image/png",
    )

    get "/api/v1/listings/#{@l1.id}"
    body = JSON.parse(response.body)

    assert_equal 1, body["photos"].size
    assert body["photos"].first["id"].positive?
    assert body["photos"].first["url"].present?
    assert_equal @leaf_motor.id, body["category"]["id"]
    assert_equal "Mini Sumo / Motor Sürücü", body["category"]["path"]
    assert_nil body["video"]
  end

  test "removed listing cannot be updated" do
    login_as(@seller)
    @l1.remove!(reason: "withdrawn")

    patch "/api/v1/listings/#{@l1.id}", params: { title: "Yeni başlık" }, as: :json
    assert_response :unprocessable_entity
    assert_equal "listing_removed", JSON.parse(response.body)["error"]["code"]
  end

  test "owner can remove existing video" do
    login_as(@seller)
    @l1.video.attach(
      io: StringIO.new("fakevideo"),
      filename: "v.mp4",
      content_type: "video/mp4",
    )

    patch "/api/v1/listings/#{@l1.id}", params: { video_to_remove: "true" }, as: :json
    assert_response :success
    assert_not @l1.reload.video.attached?
  end
end
