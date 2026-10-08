require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and trims email" do
    user = User.create!(
      full_name: "Test Kullanıcı",
      email: "  TEST@Example.COM ",
      password: "password1",
      city: "Ankara",
    )
    assert_equal "test@example.com", user.email
  end

  test "normalizes phone by stripping spaces and dashes" do
    user = User.create!(
      full_name: "Test Kullanıcı",
      email: "phone@example.com",
      password: "password1",
      city: "Ankara",
      phone: "0555 000-00-01",
    )
    assert_equal "05550000001", user.phone
  end

  test "rejects invalid phone" do
    user = User.new(
      full_name: "Test Kullanıcı",
      email: "badphone@example.com",
      password: "password1",
      city: "Ankara",
      phone: "0123456789",
    )
    assert user.invalid?
    assert user.errors[:phone].present?
  end

  test "password must be at least 8 characters" do
    user = User.new(
      full_name: "Test Kullanıcı",
      email: "short@example.com",
      password: "kısa",
      city: "Ankara",
    )
    assert user.invalid?
  end
end
