require "test_helper"

class SearchTest < ActionDispatch::IntegrationTest
  setup do
    @leaf = Category.create!(name: "Motor Sürücü", slug: "motor-surucu")
    User.create!(full_name: "Ara Satıcı", email: "search@example.com", password: "password1", city: "Ankara")
    Part.create!(code: "TB6612FNG", name: "TB6612FNG Motor Sürücü", category: @leaf, status: "approved")
    Part.create!(code: "L298N", name: "L298N Motor Sürücü", category: @leaf, status: "approved")
  end

  test "returns parts matching code or name" do
    get "/api/v1/search/suggestions", params: { q: "motor" }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal %w[L298N TB6612FNG], body["parts"].map { |part| part["code"] }.sort
  end

  test "orders code prefix matches first" do
    get "/api/v1/search/suggestions", params: { q: "l298" }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal "L298N", body["parts"].first["code"]
  end

  test "short query returns empty result without touching the database" do
    get "/api/v1/search/suggestions", params: { q: "a" }
    assert_response :success
    assert_equal [], JSON.parse(response.body)["parts"]
  end

  test "sql injection payload is treated as a literal string" do
    get "/api/v1/search/suggestions", params: { q: "x')) OR 1=1--" }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal [], body["parts"]
  end
end
