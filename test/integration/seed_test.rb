require "test_helper"

class SeedTest < ActiveSupport::TestCase
  test "seed is idempotent" do
    Rails.application.load_seed
    before = [ Category.count, Part.count, User.count, Listing.count ]

    Rails.application.load_seed
    after = [ Category.count, Part.count, User.count, Listing.count ]

    assert_equal before, after
  end
end
