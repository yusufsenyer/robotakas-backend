require "test_helper"

class MeTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      full_name: "Sil Kişi",
      email: "sil@example.com",
      password: "password1",
      city: "Ankara",
    )
  end

  def login(user)
    post "/api/v1/auth/login", params: { email: user.email, password: "password1" }, as: :json
    assert_response :success
  end

  test "destroy deletes user, listings, favorites and attachments" do
    login(@user)

    leaf = Category.create!(name: "Motor", slug: "me-test-motor")
    listing = @user.listings.create!(
      category: leaf,
      title: "Test ilanı",
      description: "açıklama",
      condition: "new",
      price: 100,
      city: "Ankara",
    )
    listing.photos.attach(io: StringIO.new("foto"), filename: "t.png", content_type: "image/png")
    listing.favorites.create!(user: @user)

    blob = listing.photos.first
    key = blob.key
    service = ActiveStorage::Blob.service
    assert File.exist?(service.path_for(key))

    delete "/api/v1/me", params: { password: "password1" }, as: :json

    assert_response :no_content
    assert_nil User.find_by(id: @user.id)
    assert_nil Listing.find_by(id: listing.id)
    assert_nil ActiveStorage::Blob.find_by(id: blob.id)
    assert_not File.exist?(service.path_for(key))

    get "/api/v1/me"
    assert_response :unauthorized
  end

  test "destroy with wrong password returns 422" do
    login(@user)

    delete "/api/v1/me", params: { password: "yanlis" }, as: :json

    assert_response :unprocessable_entity
    assert_equal "invalid_password", JSON.parse(response.body)["error"]["code"]
    assert User.find_by(id: @user.id)
  end

  test "last admin cannot be deleted" do
    admin = User.create!(
      full_name: "Admin",
      email: "admin@example.com",
      password: "password1",
      city: "Ankara",
      role: "admin",
    )
    login(admin)

    delete "/api/v1/me", params: { password: "password1" }, as: :json

    assert_response :unprocessable_entity
    assert_equal "last_admin", JSON.parse(response.body)["error"]["code"]
    assert User.find_by(id: admin.id)
  end
end
