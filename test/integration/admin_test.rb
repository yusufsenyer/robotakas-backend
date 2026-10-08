require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  setup do
    @root = Category.create!(name: "Mini Sumo", slug: "mini-sumo")
    @leaf = Category.create!(name: "Motor Sürücü", slug: "mini-sumo-motor-surucu", parent: @root)
    @leaf2 = Category.create!(name: "Sensör", slug: "mini-sumo-sensor", parent: @root)

    @admin = User.create!(
      full_name: "Admin Kişi", email: "admin@example.com", password: "password1",
      city: "Ankara", role: "admin",
    )
    @user = User.create!(
      full_name: "Normal Kişi", email: "user@example.com", password: "password1",
      city: "İzmir",
    )
    @seller = User.create!(
      full_name: "Satıcı Kişi", email: "seller@example.com", password: "password1",
      city: "Ankara",
    )

    @part = Part.create!(code: "TB6612FNG", name: "TB6612FNG", category: @leaf, status: "approved")

    @listing = Listing.create!(
      user: @seller, category: @leaf, part: @part,
      title: "TB6612FNG sürücü", description: "çalışır", condition: "used",
      price: 100, city: "Ankara", published_at: 1.day.ago,
    )
  end

  def login_as(user)
    post "/api/v1/auth/login", params: { email: user.email, password: "password1" }, as: :json
    assert_response :success
  end

  # --- Yetkilendirme ---

  test "admin endpoints reject anonymous with 401" do
    get "/api/v1/admin/stats"
    assert_response :unauthorized
    get "/api/v1/admin/parts"
    assert_response :unauthorized
    get "/api/v1/admin/listings"
    assert_response :unauthorized
    get "/api/v1/admin/reports"
    assert_response :unauthorized
    get "/api/v1/admin/announcements"
    assert_response :unauthorized
    get "/api/v1/admin/categories"
    assert_response :unauthorized
  end

  test "admin endpoints reject non-admin with 403" do
    login_as(@user)
    get "/api/v1/admin/stats"
    assert_response :forbidden
    assert_equal "Bu işlem için yetkin yok.", JSON.parse(response.body)["error"]["message"]
    get "/api/v1/admin/parts"
    assert_response :forbidden
    get "/api/v1/admin/categories"
    assert_response :forbidden
  end

  test "admin can access stats" do
    login_as(@admin)
    get "/api/v1/admin/stats"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["active_listings"]
    assert_equal 1, body["total_listings"]
    assert_equal 0, body["sold_total"]
    assert_equal 3, body["total_users"]
  end

  # --- Parçalar ---

  test "parts index filters by status and includes pending listings" do
    pending = Part.create!(code: "NEWPART", name: "Yeni Parça", category: @leaf, status: "pending", suggested_by: @user)
    Listing.create!(
      user: @user, category: @leaf, part: pending,
      title: "Yeni parça ilanı", description: "açıklama", condition: "new",
      price: 200, city: "İzmir", status: "pending_part",
    )

    login_as(@admin)
    get "/api/v1/admin/parts", params: { status: "pending" }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["parts"].size
    part = body["parts"].first
    assert_equal "NEWPART", part["code"]
    assert_equal "pending", part["status"]
    assert_equal 1, part["pending_listings"].size
    assert_equal "Yeni parça ilanı", part["pending_listings"].first["title"]
    assert_equal @user.id, part["suggested_by"]["id"]
  end

  test "creates part directly as approved" do
    login_as(@admin)
    assert_difference -> { Part.count }, 1 do
      post "/api/v1/admin/parts", params: {
        code: "L293D", name: "L293D Motor Sürücü", brand: "ST", category_id: @leaf.id,
        description: "açıklama", specs: [ { label: "Kanal", value: "2" } ]
      }, as: :json
    end
    assert_response :created
    part = JSON.parse(response.body)["part"]
    assert_equal "approved", part["status"]
    assert_equal "l293d", part["slug"]
    assert_equal "ST", part["brand"]
  end

  test "updates part and refreshes slug when code changes" do
    login_as(@admin)
    patch "/api/v1/admin/parts/#{@part.id}", params: { code: "TB6612FNG-X", name: "Yeni ad" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)["part"]
    assert_equal "TB6612FNG-X", body["code"]
    assert_equal "tb6612fng-x", body["slug"]
    assert_equal "Yeni ad", body["name"]
  end

  test "update rejects duplicate code" do
    login_as(@admin)
    Part.create!(code: "DUP", name: "Dup", category: @leaf, status: "approved")
    patch "/api/v1/admin/parts/#{@part.id}", params: { code: "DUP" }, as: :json
    assert_response :unprocessable_entity
  end

  test "approve activates pending listings and fills published_at" do
    pending = Part.create!(code: "X9", name: "X9", category: @leaf, status: "pending", suggested_by: @user)
    plist = Listing.create!(
      user: @user, category: @leaf, part: pending,
      title: "X9 ilanı", description: "açıklama", condition: "new", price: 50, city: "İzmir",
    )
    assert_equal "pending_part", plist.status

    login_as(@admin)
    post "/api/v1/admin/parts/#{pending.id}/approve"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["activated_listing_count"]
    assert_equal "approved", body["part"]["status"]
    assert_equal "active", plist.reload.status
    assert plist.published_at
  end

  test "approve applies edits" do
    pending = Part.create!(code: "X10", name: "X10", category: @leaf, status: "pending")
    login_as(@admin)

    post "/api/v1/admin/parts/#{pending.id}/approve", params: {
      name: "Düzenlenmiş ad", brand: "Marka", category_id: @leaf2.id,
      description: "yeni açıklama", specs: [ { label: "A", value: "B" } ]
    }, as: :json

    assert_response :success
    part = JSON.parse(response.body)["part"]
    assert_equal "Düzenlenmiş ad", part["name"]
    assert_equal "Marka", part["brand"]
    assert_equal @leaf2.id, part["category"]["id"]
    assert_equal [ { "label" => "A", "value" => "B" } ], part["specs"]
  end

  test "reject requires reason and marks listings part_rejected" do
    pending = Part.create!(code: "X11", name: "X11", category: @leaf, status: "pending")
    plist = Listing.create!(
      user: @user, category: @leaf, part: pending,
      title: "X11 ilanı", description: "açıklama", condition: "new", price: 50, city: "İzmir",
    )

    login_as(@admin)
    post "/api/v1/admin/parts/#{pending.id}/reject", params: { reason: "kısa" }, as: :json
    assert_response :unprocessable_entity

    post "/api/v1/admin/parts/#{pending.id}/reject", params: { reason: "Model numarası hatalı" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["affected_listing_count"]
    assert_equal "rejected", body["part"]["status"]
    assert_equal "Model numarası hatalı", body["part"]["reject_reason"]
    assert_equal "part_rejected", plist.reload.status
  end

  test "part with listings cannot be deleted" do
    login_as(@admin)
    delete "/api/v1/admin/parts/#{@part.id}"
    assert_response :unprocessable_entity
    assert_equal "part_has_listings", JSON.parse(response.body)["error"]["code"]
    assert Part.find_by(id: @part.id)
  end

  test "empty part can be deleted" do
    empty = Part.create!(code: "EMPTY1", name: "Boş parça", category: @leaf, status: "approved")
    login_as(@admin)
    delete "/api/v1/admin/parts/#{empty.id}"
    assert_response :no_content
    assert_nil Part.find_by(id: empty.id)
  end

  # --- İlanlar ---

  test "listings index searches and filters" do
    login_as(@admin)
    get "/api/v1/admin/listings", params: { q: "tb6612fng" }
    ids = JSON.parse(response.body)["listings"].map { |l| l["id"] }
    assert_includes ids, @listing.id

    get "/api/v1/admin/listings", params: { q: "seller@example.com" }
    ids = JSON.parse(response.body)["listings"].map { |l| l["id"] }
    assert_includes ids, @listing.id

    get "/api/v1/admin/listings", params: { status: "removed" }
    assert_empty JSON.parse(response.body)["listings"]
  end

  test "destroy listing cascades conversations, messages, reports and favorites" do
    @listing.photos.attach(
      io: StringIO.new("foto"), filename: "t.png", content_type: "image/png",
    )
    buyer = @user
    conversation = @listing.conversations.create!(buyer: buyer)
    conversation.messages.create!(sender: buyer, body: "merhaba")
    @listing.reports.create!(reporter: buyer, reason: "spam")
    @listing.favorites.create!(user: buyer)
    @listing.compatible_categories << @root

    attachment = @listing.photos_attachments.first

    login_as(@admin)
    assert_difference -> { Listing.count }, -1 do
      delete "/api/v1/admin/listings/#{@listing.id}"
    end

    assert_response :no_content
    assert_equal 0, Conversation.where(listing_id: @listing.id).count
    assert_equal 0, Message.count
    assert_equal 0, Report.where(listing_id: @listing.id).count
    assert_equal 0, Favorite.where(listing_id: @listing.id).count
    assert_equal 0, ListingCompatibleCategory.where(listing_id: @listing.id).count
    assert_nil ActiveStorage::Attachment.find_by(id: attachment.id)
  end

  test "bulk destroy deletes listings in one transaction" do
    l2 = Listing.create!(
      user: @seller, category: @leaf, part: @part,
      title: "İkinci ilan", description: "açıklama", condition: "new", price: 150, city: "Ankara",
    )

    login_as(@admin)
    assert_difference -> { Listing.count }, -2 do
      post "/api/v1/admin/listings/bulk_destroy", params: { ids: [ @listing.id, l2.id ] }, as: :json
    end
    assert_response :success
    assert_equal 2, JSON.parse(response.body)["deleted_count"]
  end

  test "bulk destroy rejects more than 50 ids" do
    login_as(@admin)
    post "/api/v1/admin/listings/bulk_destroy", params: { ids: (1..51).to_a }, as: :json
    assert_response :unprocessable_entity
  end

  # --- Şikayetler ---

  test "reports index, resolve and dismiss" do
    report = @listing.reports.create!(reporter: @user, reason: "spam")

    login_as(@admin)
    get "/api/v1/admin/reports", params: { status: "open" }
    assert_response :success
    assert_equal 1, JSON.parse(response.body)["reports"].size

    post "/api/v1/admin/reports/#{report.id}/resolve"
    assert_response :success
    assert_equal "resolved", report.reload.status
    assert_equal @admin.id, report.resolved_by_id
    assert report.resolved_at

    post "/api/v1/admin/reports/#{report.id}/resolve"
    assert_response :unprocessable_entity
    assert_equal "report_closed", JSON.parse(response.body)["error"]["code"]
  end

  test "dismiss closes report" do
    report = @listing.reports.create!(reporter: @user, reason: "other")
    login_as(@admin)

    post "/api/v1/admin/reports/#{report.id}/dismiss"
    assert_response :success
    assert_equal "dismissed", report.reload.status
  end

  # --- Duyurular ---

  test "create and destroy announcement with read cascade" do
    login_as(@admin)

    assert_difference -> { Announcement.count }, 1 do
      post "/api/v1/admin/announcements", params: { title: "Duyuru", body: "İçerik" }, as: :json
    end
    assert_response :created
    announcement = Announcement.last
    assert_equal @admin.id, announcement.admin_id
    assert announcement.published_at

    announcement.announcement_reads.create!(user: @user)

    delete "/api/v1/admin/announcements/#{announcement.id}"
    assert_response :no_content
    assert_nil Announcement.find_by(id: announcement.id)
    assert_equal 0, AnnouncementRead.where(announcement_id: announcement.id).count
  end

  # --- Kategoriler ---

  test "categories index includes counts" do
    login_as(@admin)
    get "/api/v1/admin/categories"
    assert_response :success
    body = JSON.parse(response.body)
    leaf = body.find { |c| c["id"] == @leaf.id }
    assert_equal 1, leaf["listing_count"]
    assert_equal 1, leaf["part_count"]
    assert_equal 0, leaf["children_count"]
    assert_equal 0, leaf["compatible_count"]
  end

  test "creates root and leaf categories with prefixed slug" do
    login_as(@admin)

    post "/api/v1/admin/categories", params: { name: "Yeni Yarışma", icon_key: "Bot" }, as: :json
    assert_response :created
    root = JSON.parse(response.body)["category"]
    assert_equal "yeni-yarisma", root["slug"]

    post "/api/v1/admin/categories", params: { name: "Motor", parent_id: root["id"] }, as: :json
    assert_response :created
    leaf = JSON.parse(response.body)["category"]
    assert_equal "yeni-yarisma-motor", leaf["slug"]
  end

  test "update name does not change slug" do
    login_as(@admin)
    patch "/api/v1/admin/categories/#{@leaf.id}", params: { name: "Sürücü Kartı" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)["category"]
    assert_equal "Sürücü Kartı", body["name"]
    assert_equal "mini-sumo-motor-surucu", body["slug"]
  end

  test "category with listings and parts cannot be deleted" do
    login_as(@admin)

    delete "/api/v1/admin/categories/#{@leaf.id}"
    assert_response :unprocessable_entity
    message = JSON.parse(response.body)["error"]["message"]
    assert_includes message, "1 ilan"
    assert_includes message, "1 parça"
  end

  test "category with children cannot be deleted" do
    login_as(@admin)

    delete "/api/v1/admin/categories/#{@root.id}"
    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["error"]["message"], "alt kategori"
  end

  test "empty category can be deleted" do
    empty = Category.create!(name: "Boş", slug: "bos")
    login_as(@admin)
    delete "/api/v1/admin/categories/#{empty.id}"
    assert_response :no_content
    assert_nil Category.find_by(id: empty.id)
  end

  test "new category appears in public categories tree" do
    login_as(@admin)
    post "/api/v1/admin/categories", params: { name: "Görünür Yarışma" }, as: :json
    assert_response :created

    get "/api/v1/categories"
    slugs = JSON.parse(response.body).map { |c| c["slug"] }
    assert_includes slugs, "gorunur-yarisma"
  end
end
