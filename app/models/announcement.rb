class Announcement < ApplicationRecord
  belongs_to :admin, class_name: "User"
  has_many :announcement_reads, dependent: :destroy

  validates :title, presence: true, length: { maximum: 80 }
  validates :body, presence: true, length: { maximum: 1000 }

  scope :published, -> { where.not(published_at: nil).order(published_at: :desc) }
end
