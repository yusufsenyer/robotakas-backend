require "test_helper"

class AnnouncementsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(full_name: "Admin", email: "admin@example.com", password: "password1", city: "Ankara", role: "admin")
    @user = User.create!(full_name: "Kullanıcı", email: "user@example.com", password: "password1", city: "İzmir")

    @a1 = Announcement.create!(admin: @admin, title: "Duyuru bir", body: "İlk duyuru", published_at: 1.day.ago)
    @a2 = Announcement.create!(admin: @admin, title: "Duyuru iki", body: "İkinci duyuru", published_at: Time.current)
    @unpublished = Announcement.create!(admin: @admin, title: "Taslak", body: "Yayında değil")
  end

  def login_as(user)
    post "/api/v1/auth/login", params: { email: user.email, password: "password1" }, as: :json
    assert_response :success
  end

  test "requires login" do
    get "/api/v1/announcements"
    assert_response :unauthorized
  end

  test "lists published announcements with read flag" do
    login_as(@user)

    get "/api/v1/announcements"
    assert_response :success
    body = JSON.parse(response.body)

    assert_equal 2, body.size
    assert_equal @a2.id, body.first["id"]
    assert_equal false, body.first["read"]
  end

  test "mark read clears unread count" do
    login_as(@user)

    post "/api/v1/announcements/read"
    assert_response :no_content

    get "/api/v1/me/unread_counts"
    assert_equal 0, JSON.parse(response.body)["announcements"]

    get "/api/v1/announcements"
    assert JSON.parse(response.body).all? { |a| a["read"] }
  end
end
