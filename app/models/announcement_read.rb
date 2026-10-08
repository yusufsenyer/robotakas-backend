class AnnouncementRead < ApplicationRecord
  belongs_to :user
  belongs_to :announcement

  validates :announcement_id, uniqueness: { scope: :user_id }
end
