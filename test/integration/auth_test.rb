require "test_helper"

class AuthTest < ActionDispatch::IntegrationTest
  test "register creates user, opens session, and hides password_digest" do
    assert_difference -> { User.count }, 1 do
      post "/api/v1/auth/register", params: {
        full_name: "Test Kullanıcı",
        email: "test@example.com",
        password: "password123",
        city: "Ankara"
      }, as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_nil body["password_digest"]
    assert_equal "test@example.com", body["email"]

    get "/api/v1/me"
    assert_response :success
    assert_equal "test@example.com", JSON.parse(response.body)["email"]
  end

  test "login with wrong password returns 401" do
    user = User.create!(
      full_name: "Test Kullanıcı",
      email: "login@example.com",
      password: "password123",
      city: "Ankara",
    )

    post "/api/v1/auth/login", params: { email: user.email, password: "yanlis" }, as: :json
    assert_response :unauthorized
    assert_equal(
      "E-posta ya da şifre tutmadı. Bir daha dene.",
      JSON.parse(response.body)["error"]["message"],
    )
  end

  test "login succeeds and me returns user" do
    user = User.create!(
      full_name: "Test Kullanıcı",
      email: "login2@example.com",
      password: "password123",
      city: "Ankara",
      phone: "0555 000 00 01",
    )

    post "/api/v1/auth/login", params: { email: "LOGIN2@EXAMPLE.COM", password: "password123" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal user.email, body["email"]
    assert_equal "05550000001", body["phone"]

    get "/api/v1/me"
    assert_response :success
  end

  test "logout clears session" do
    post "/api/v1/auth/register", params: {
      full_name: "Test Kullanıcı",
      email: "logout@example.com",
      password: "password123",
      city: "Ankara"
    }, as: :json

    delete "/api/v1/auth/logout"
    assert_response :no_content

    get "/api/v1/me"
    assert_response :unauthorized
  end

  test "me without login returns 401" do
    get "/api/v1/me"
    assert_response :unauthorized
  end

  test "me update normalizes phone" do
    post "/api/v1/auth/register", params: {
      full_name: "Test Kullanıcı",
      email: "update@example.com",
      password: "password123",
      city: "Ankara"
    }, as: :json

    patch "/api/v1/me", params: {
      full_name: "Yeni Ad",
      city: "İzmir",
      team_name: "Ege Robotics",
      phone: "0555 000-00-02"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Yeni Ad", body["full_name"]
    assert_equal "İzmir", body["city"]
    assert_equal "Ege Robotics", body["team_name"]
    assert_equal "05550000002", body["phone"]
  end
end
