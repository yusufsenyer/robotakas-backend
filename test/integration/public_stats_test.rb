require "test_helper"

class PublicStatsTest < ActionDispatch::IntegrationTest
  setup do
    @root = Category.create!(name: "Mini Sumo", slug: "mini-sumo")
    @leaf = Category.create!(name: "Motor", slug: "mini-sumo-motor", parent: @root)
    Category.create!(name: "Çizgi İzleyen", slug: "cizgi-izleyen")

    Part.create!(code: "TB6612FNG", name: "TB6612FNG", category: @leaf, status: "approved")
    Part.create!(code: "BEKLEYEN-1", name: "Bekleyen parça", category: @leaf, status: "pending")

    @seller = User.create!(
      full_name: "Satıcı Kişi", email: "seller@example.com",
      password: "password1", city: "Ankara",
    )

    Listing.create!(
      user: @seller, category: @leaf,
      title: "Aktif ilan", description: "çalışır", condition: "used",
      price: 100, city: "Ankara", published_at: Time.current,
    )
    removed = Listing.create!(
      user: @seller, category: @leaf,
      title: "Kaldırılmış ilan", description: "yok", condition: "used",
      price: 100, city: "Ankara",
    )
    removed.remove!(reason: "withdrawn")

    SiteStat.find_or_create_by!(key: "sold_total").update!(value: 4)
  end

  test "public stats returns real database counts without auth" do
    get "/api/v1/public_stats"
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 1, body["active_listings"]
    assert_equal 1, body["approved_parts"]
    assert_equal 2, body["competitions"]
    assert_equal 4, body["sold_total"]
  end
end
