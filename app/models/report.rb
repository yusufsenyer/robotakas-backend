class Report < ApplicationRecord
  REASONS = %w[fake_listing wrong_info prohibited_item spam other].freeze

  belongs_to :listing
  belongs_to :reporter, class_name: "User"
  belongs_to :resolved_by, class_name: "User", optional: true

  before_validation :strip_details

  validates :reason, inclusion: { in: REASONS }
  validates :details, length: { maximum: 500 }
  validates :status, inclusion: { in: %w[open resolved dismissed] }

  scope :open, -> { where(status: "open") }

  private

  def strip_details
    self.details = details.to_s.strip.presence
  end
end
