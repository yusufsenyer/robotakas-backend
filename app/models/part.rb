class Part < ApplicationRecord
  belongs_to :category
  belongs_to :suggested_by, class_name: "User", optional: true
  has_many :listings, dependent: :nullify

  before_validation :normalize_code
  before_validation :set_slug

  validates :code, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
  validates :status, inclusion: { in: %w[approved pending rejected] }

  scope :approved, -> { where(status: "approved") }

  def approve!
    update!(status: "approved", reject_reason: nil)
    listings.where(status: "pending_part").find_each do |listing|
      listing.update!(status: "active", published_at: Time.current)
    end
  end

  def reject!(reason)
    update!(status: "rejected", reject_reason: reason)
    listings.where(status: "pending_part").find_each do |listing|
      listing.update!(status: "part_rejected")
    end
  end

  def approved?
    status == "approved"
  end

  private

  def normalize_code
    self.code = code.to_s.strip.upcase
  end

  def set_slug
    self.slug = code.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
  end
end
