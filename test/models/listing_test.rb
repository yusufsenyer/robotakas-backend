require "test_helper"

class ListingTest < ActiveSupport::TestCase
  setup do
    @leaf = Category.create!(name: "Motor Sürücü", slug: "motor-surucu")
    @user = User.create!(full_name: "Test Kullanıcı", email: "listing@example.com", password: "password1", city: "Ankara")
  end

  def build_listing(part: nil, **overrides)
    Listing.new(
      {
        user: @user,
        category: @leaf,
        part: part,
        title: "Motor sürücü ilanı",
        description: "Çalışır durumda.",
        condition: "used",
        price: 120,
        city: "Ankara",
      }.merge(overrides)
    )
  end

  test "generic listing becomes active" do
    listing = build_listing(part: nil)
    listing.save!
    assert_equal "active", listing.status
    assert listing.published_at
  end

  test "approved part listing becomes active" do
    part = Part.create!(code: "TB6612FNG", name: "TB6612FNG", category: @leaf, status: "approved")
    listing = build_listing(part: part)
    listing.save!
    assert_equal "active", listing.status
  end

  test "pending part listing becomes pending_part" do
    part = Part.create!(code: "P1", name: "P1", category: @leaf, status: "pending")
    listing = build_listing(part: part)
    listing.save!
    assert_equal "pending_part", listing.status
    assert_nil listing.published_at
  end

  test "rejected part listing becomes part_rejected" do
    part = Part.create!(code: "R1", name: "R1", category: @leaf, status: "rejected")
    listing = build_listing(part: part)
    listing.save!
    assert_equal "part_rejected", listing.status
  end

  test "recomputes status when part changes" do
    approved = Part.create!(code: "P2", name: "P2", category: @leaf, status: "approved")
    pending = Part.create!(code: "P3", name: "P3", category: @leaf, status: "pending")
    listing = build_listing(part: approved)
    listing.save!
    assert_equal "active", listing.status

    listing.update!(part: pending)
    assert_equal "pending_part", listing.status
  end

  test "title must be between 5 and 80 characters" do
    assert build_listing(title: "kısa").invalid?
    assert build_listing(title: "a" * 81).invalid?
    assert build_listing(title: "Beş harf").valid?
  end

  test "price must be positive integer" do
    assert build_listing(price: 0).invalid?
    assert build_listing(price: -5).invalid?
  end

  test "seasons_used only allowed for used condition" do
    assert build_listing(condition: "new", seasons_used: 1).invalid?
    assert build_listing(condition: "used", seasons_used: 1).valid?
  end

  test "category must be a leaf" do
    root = Category.create!(name: "Mini Sumo", slug: "mini-sumo")
    Category.create!(name: "Motor", slug: "mini-sumo-motor", parent: root)
    assert build_listing(category: root).invalid?
  end

  test "remove! with sold increments counter" do
    listing = build_listing
    listing.save!

    assert_difference -> { SiteStat.value("sold_total") }, 1 do
      listing.remove!(reason: "sold")
    end

    assert_equal "removed", listing.status
    assert_equal "sold", listing.removal_reason
    assert listing.removed_at
  end

  test "remove! with withdrawn does not increment counter" do
    listing = build_listing
    listing.save!

    assert_no_difference -> { SiteStat.value("sold_total") } do
      listing.remove!(reason: "withdrawn")
    end

    assert_equal "withdrawn", listing.removal_reason
  end

  test "destroy purges attachments from db and disk" do
    listing = build_listing
    listing.save!
    listing.photos.attach(
      io: StringIO.new("fakephoto"),
      filename: "test.png",
      content_type: "image/png",
    )
    listing.compatible_categories << Category.create!(name: "Mini Sumo", slug: "mini-sumo-t")
    listing.favorites.create!(user: @user)

    blob = listing.photos.first
    key = blob.key
    service = ActiveStorage::Blob.service
    assert File.exist?(service.path_for(key))

    assert_difference -> { ListingCompatibleCategory.count }, -1 do
      assert_difference -> { Favorite.count }, -1 do
        listing.destroy!
      end
    end

    assert_nil ActiveStorage::Blob.find_by(id: blob.id)
    assert_not File.exist?(service.path_for(key))
  end
end
