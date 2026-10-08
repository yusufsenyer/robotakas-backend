class ListingCompatibleCategory < ApplicationRecord
  belongs_to :listing
  belongs_to :category

  validates :category_id, uniqueness: { scope: :listing_id }
end
