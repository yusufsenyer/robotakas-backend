class Listing < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :part, optional: true

  has_many :favorites, dependent: :destroy
  has_many :listing_compatible_categories, dependent: :destroy
  has_many :compatible_categories,
    through: :listing_compatible_categories,
    source: :category
  has_many :conversations, dependent: :destroy
  has_many :reports, dependent: :destroy

  has_many_attached :photos, dependent: :purge
  has_one_attached :video, dependent: :purge

  before_validation :assign_status, if: -> { new_record? || part_id_changed? }

  validates :title, presence: true, length: { minimum: 5, maximum: 80 }
  validates :description, presence: true, length: { maximum: 2000 }
  validates :condition, inclusion: { in: %w[new used] }
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :quantity,
    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 999 }
  validates :city, presence: true
  validates :status, inclusion: {
    in: %w[pending_part part_rejected active removed],
  }
  validate :seasons_used_only_for_used
  validate :category_must_be_leaf
  validate :photos_within_limits
  validate :video_within_limits

  scope :active, -> { where(status: "active") }

  def active?
    status == "active"
  end

  def remove!(reason:)
    raise ArgumentError, "reason sold ya da withdrawn olmalı" unless %w[sold withdrawn].include?(reason)

    SiteStat.add!("sold_total") if reason == "sold"

    update!(
      status: "removed",
      removal_reason: reason,
      removed_at: Time.current,
    )
  end

  def favorited_by?(user)
    return false if user.nil?

    favorites.exists?(user_id: user.id)
  end

  def owner?(user)
    return false if user.nil?

    user_id == user.id
  end

  private

  def assign_status
    self.status =
      if part.nil?
        "active"
      else
        case part.status
        when "approved" then "active"
        when "pending" then "pending_part"
        when "rejected" then "part_rejected"
        else "active"
        end
      end

    self.published_at = Time.current if status == "active" && published_at.nil?
  end

  def seasons_used_only_for_used
    if condition == "new" && seasons_used.present?
      errors.add(:seasons_used, "sadece ikinci el ilanlarda kullanılabilir")
    end
  end

  def category_must_be_leaf
    if category.present? && !category.leaf?
      errors.add(:category_id, "yaprak (parça türü) kategori olmalı")
    end
  end

  def photos_within_limits
    if photos.count > 10
      errors.add(:photos, "en fazla 10 fotoğraf yüklenebilir")
    end

    photos.each do |photo|
      if photo.byte_size > 8.megabytes
        errors.add(:photos, "her fotoğraf en fazla 8 MB olabilir")
      end
      unless photo.content_type.in?(%w[image/jpeg image/png image/webp])
        errors.add(:photos, "yalnızca jpeg, png ya da webp yüklenebilir")
      end
    end
  end

  def video_within_limits
    return unless video.attached?

    if video.byte_size > 45.megabytes
      errors.add(:video, "video en fazla 45 MB olabilir")
    end

    unless video.content_type.to_s.in?(%w[video/mp4 video/webm video/quicktime])
      errors.add(:video, "yalnızca mp4, webm ya da mov yüklenebilir")
    end
  end
end
