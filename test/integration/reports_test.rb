require "test_helper"

class ReportsTest < ActionDispatch::IntegrationTest
  setup do
    @leaf = Category.create!(name: "Motor Sürücü", slug: "motor-surucu")
    @seller = User.create!(full_name: "Satıcı Kişi", email: "seller@example.com", password: "password1", city: "Ankara")
    @reporter = User.create!(full_name: "Şikayetçi", email: "reporter@example.com", password: "password1", city: "İzmir")

    @listing = Listing.create!(
      user: @seller, category: @leaf,
      title: "Test ilanı", description: "açıklama", condition: "new", price: 100, city: "Ankara",
    )
  end

  def login_as(user)
    post "/api/v1/auth/login", params: { email: user.email, password: "password1" }, as: :json
    assert_response :success
  end

  test "requires login" do
    post "/api/v1/listings/#{@listing.id}/reports", params: { reason: "spam" }, as: :json
    assert_response :unauthorized
  end

  test "creates report" do
    login_as(@reporter)

    assert_difference -> { Report.count }, 1 do
      post "/api/v1/listings/#{@listing.id}/reports",
        params: { reason: "spam", details: "alakasız içerik" }, as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "spam", body["reason"]
    assert_equal "open", body["status"]
  end

  test "cannot report own listing" do
    login_as(@seller)

    post "/api/v1/listings/#{@listing.id}/reports", params: { reason: "spam" }, as: :json
    assert_response :unprocessable_entity
    assert_equal "own_listing", JSON.parse(response.body)["error"]["code"]
  end

  test "cannot report same open report twice" do
    login_as(@reporter)
    @listing.reports.create!(reporter: @reporter, reason: "spam")

    post "/api/v1/listings/#{@listing.id}/reports", params: { reason: "spam" }, as: :json
    assert_response :unprocessable_entity
    assert_equal "already_reported", JSON.parse(response.body)["error"]["code"]
  end

  test "rejects invalid reason" do
    login_as(@reporter)

    post "/api/v1/listings/#{@listing.id}/reports", params: { reason: "hack" }, as: :json
    assert_response :unprocessable_entity
  end

  test "can report non-active listing" do
    login_as(@reporter)
    @listing.remove!(reason: "withdrawn")

    post "/api/v1/listings/#{@listing.id}/reports", params: { reason: "fake_listing" }, as: :json
    assert_response :created
  end
end
