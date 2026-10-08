require "test_helper"

class SavedSearchesTest < ActionDispatch::IntegrationTest
  setup do
    @root = Category.create!(name: "Mini Sumo", slug: "mini-sumo")
    @user = User.create!(
      full_name: "Kayıt Kullanıcı",
      email: "kayit@example.com",
      password: "password1",
      city: "Ankara",
    )
  end

  def login
    post "/api/v1/auth/login", params: { email: @user.email, password: "password1" }, as: :json
    assert_response :success
  end

  test "requires login" do
    get "/api/v1/saved_searches"
    assert_response :unauthorized
  end

  test "creates and lists saved search" do
    login
    post "/api/v1/saved_searches",
      params: { name: "Sumo ikinci el", params: { kategori: "mini-sumo", durum: "used" } },
      as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Sumo ikinci el", body["name"]
    assert_equal "used", body["params"]["durum"]

    get "/api/v1/saved_searches"
    assert_response :success
    assert_equal 1, JSON.parse(response.body).size
  end

  test "generates name from filters when blank" do
    login
    post "/api/v1/saved_searches",
      params: { params: { kategori: "mini-sumo", durum: "used", min: "100", max: "500" } },
      as: :json

    assert_response :created
    assert_equal "Mini Sumo · İkinci el · 100–500 ₺", JSON.parse(response.body)["name"]
  end

  test "does not duplicate identical params" do
    login
    params = { kategori: "mini-sumo", durum: "used" }

    post "/api/v1/saved_searches", params: { params: params }, as: :json
    assert_response :created
    post "/api/v1/saved_searches", params: { params: params }, as: :json
    assert_response :success

    assert_equal 1, @user.saved_searches.count
  end

  test "rejects unknown param keys" do
    login
    post "/api/v1/saved_searches",
      params: { params: { kategori: "mini-sumo", hack: "x" } },
      as: :json

    assert_response :created
    assert_not JSON.parse(response.body)["params"].key?("hack")
  end

  test "owner can delete" do
    login
    post "/api/v1/saved_searches", params: { params: { q: "tb66" } }, as: :json
    id = JSON.parse(response.body)["id"]

    delete "/api/v1/saved_searches/#{id}"
    assert_response :no_content
    assert_equal 0, @user.saved_searches.count
  end

  test "saved searches are deleted with the user" do
    login
    post "/api/v1/saved_searches", params: { params: { q: "tb66" } }, as: :json
    assert_equal 1, @user.saved_searches.count

    @user.destroy!
    assert_equal 0, SavedSearch.count
  end
end
