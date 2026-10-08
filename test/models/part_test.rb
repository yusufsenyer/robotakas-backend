require "test_helper"

class PartTest < ActiveSupport::TestCase
  setup do
    @category = Category.create!(name: "Motor Sürücü", slug: "motor-surucu")
  end

  test "normalizes code to uppercase and trims" do
    part = Part.create!(code: "  tb6612fng ", name: "TB6612FNG", category: @category, status: "approved")
    assert_equal "TB6612FNG", part.code
  end

  test "generates slug from downcased code" do
    part = Part.create!(code: "TB6612FNG", name: "TB6612FNG", category: @category, status: "approved")
    assert_equal "tb6612fng", part.slug
  end

  test "slug replaces non-alphanumerics with dashes and trims edges" do
    part = Part.create!(code: "QTR-8A+", name: "QTR-8A", category: @category, status: "approved")
    assert_equal "QTR-8A+", part.code
    assert_equal "qtr-8a", part.slug
  end

  test "approve! activates pending_part listings" do
    part = Part.create!(code: "X1", name: "X", category: @category, status: "pending")
    user = User.create!(full_name: "A B", email: "a@example.com", password: "password1", city: "Ankara")
    listing = Listing.create!(
      user: user, category: @category, part: part,
      title: "X parçası", description: "açıklama", condition: "new", price: 100, city: "Ankara",
    )
    assert_equal "pending_part", listing.status

    part.approve!
    assert_equal "approved", part.reload.status
    assert_equal "active", listing.reload.status
    assert listing.published_at
  end

  test "reject! sets pending_part listings to part_rejected" do
    part = Part.create!(code: "X2", name: "X", category: @category, status: "pending")
    user = User.create!(full_name: "A B", email: "b@example.com", password: "password1", city: "Ankara")
    listing = Listing.create!(
      user: user, category: @category, part: part,
      title: "X parçası", description: "açıklama", condition: "new", price: 100, city: "Ankara",
    )

    part.reject!("geçersiz model")
    assert_equal "rejected", part.reload.status
    assert_equal "geçersiz model", part.reject_reason
    assert_equal "part_rejected", listing.reload.status
  end
end
