class ForumTopic < ApplicationRecord
  KINDS = %w[question discussion showcase seeking].freeze
  SLUG_MAX_LENGTH = 60
  IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze
  IMAGE_MAX_BYTES = 8.megabytes
  IMAGE_LIMIT = 6
  SHOWCASE_IMAGE_LIMIT = 10

  belongs_to :forum_board
  belongs_to :user
  has_many :forum_posts, dependent: :destroy
  has_many :forum_likes, dependent: :destroy
  has_many_attached :images, dependent: :purge

  before_validation :sanitize_text
  before_validation :set_last_activity_at, on: :create
  before_validation :set_slug, if: -> { slug.blank? }
  before_validation :clear_solution_when_not_question

  after_create :refresh_board_counters
  before_destroy :purge_notifications
  after_destroy :refresh_board_counters

  validates :kind, inclusion: { in: KINDS }
  validates :title, presence: true, length: { minimum: 10, maximum: 120 }
  validates :body, presence: true, length: { minimum: 10, maximum: 10000 }
  validate :images_within_limits

  scope :ordered, -> { order(pinned: :desc, last_activity_at: :desc, id: :desc) }

  attr_reader :masked

  def owner?(user)
    user.present? && user_id == user.id
  end

  def editable_by?(user)
    owner?(user) || user&.admin?
  end

  def solved?
    solved_post_id.present?
  end

  def solution_post
    return nil if solved_post_id.blank?

    forum_posts.find_by(id: solved_post_id)
  end

  def solve!(post, actor:)
    return false unless kind == "question"
    return false if post.nil? || post.forum_topic_id != id

    update!(solved_post_id: post.id, solved_at: Time.current)
    Notification.push!(
      user: post.user, actor: actor,
      kind: "solution_marked", forum_topic: self, forum_post: post, merge: false,
    )
    true
  end

  def unsolve!
    update!(solved_post_id: nil, solved_at: nil)
  end

  def recalculate_counters!
    update_columns(
      posts_count: forum_posts.count,
      last_activity_at: [ created_at, forum_posts.maximum(:created_at) ].compact.max,
    )
  end

  private

  def purge_notifications
    Notification.where(forum_topic_id: id).delete_all
  end

  def refresh_board_counters
    forum_board.recalculate_counters!
  end

  def sanitize_text
    title_text, title_masked = PersonalInfoMasker.call(ForumText.clean(title))
    body_text, body_masked = PersonalInfoMasker.call(ForumText.clean(body))

    self.title = title_text
    self.body = body_text
    @masked = title_masked || body_masked
  end

  def set_last_activity_at
    self.last_activity_at ||= Time.current
  end

  def set_slug
    self.slug = Category.normalize_slug(title)[0, SLUG_MAX_LENGTH].to_s.gsub(/-+\z/, "")
  end

  def clear_solution_when_not_question
    return if kind == "question"

    self.solved_post_id = nil
    self.solved_at = nil
  end

  def images_within_limits
    max = kind == "showcase" ? SHOWCASE_IMAGE_LIMIT : IMAGE_LIMIT
    errors.add(:images, "en fazla #{max} görsel yüklenebilir") if images.count > max

    images.each do |image|
      errors.add(:images, "her görsel en fazla 8 MB olabilir") if image.byte_size > IMAGE_MAX_BYTES
      unless image.content_type.in?(IMAGE_TYPES)
        errors.add(:images, "yalnızca JPG, PNG ya da WEBP yüklenebilir")
      end
    end
  end
end
