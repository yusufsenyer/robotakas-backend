class ForumPost < ApplicationRecord
  IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze
  IMAGE_MAX_BYTES = 8.megabytes
  IMAGE_LIMIT = 4

  belongs_to :forum_topic
  belongs_to :user
  belongs_to :reply_to_post, class_name: "ForumPost", optional: true
  has_many :forum_likes, dependent: :destroy
  has_many_attached :images, dependent: :purge

  before_validation :sanitize_text

  after_create :refresh_counters
  after_create :notify_creation
  before_destroy :handle_deletion
  after_destroy :refresh_counters

  validates :body, presence: true, length: { minimum: 2, maximum: 10000 }
  validate :reply_target_in_topic
  validate :images_within_limits

  attr_reader :masked

  def owner?(user)
    user.present? && user_id == user.id
  end

  def editable_by?(user)
    owner?(user) || user&.admin?
  end

  def reply_target
    return nil if reply_to_post_id.blank?

    forum_topic.forum_posts.find_by(id: reply_to_post_id)
  end

  private

  def sanitize_text
    masked_body, changed = PersonalInfoMasker.call(ForumText.clean(body))
    self.body = masked_body
    @masked = changed
  end

  def reply_target_in_topic
    return if reply_to_post_id.blank?

    target = ForumPost.find_by(id: reply_to_post_id)
    if target.nil? || target.forum_topic_id != forum_topic_id
      errors.add(:reply_to_post_id, "aynı konudaki bir yazıya yanıt verilmeli")
    end
  end

  def images_within_limits
    errors.add(:images, "en fazla #{IMAGE_LIMIT} görsel yüklenebilir") if images.count > IMAGE_LIMIT

    images.each do |image|
      errors.add(:images, "her görsel en fazla 8 MB olabilir") if image.byte_size > IMAGE_MAX_BYTES
      unless image.content_type.in?(IMAGE_TYPES)
        errors.add(:images, "yalnızca JPG, PNG ya da WEBP yüklenebilir")
      end
    end
  end

  def notify_creation
    Notification.push!(
      user: forum_topic.user, actor: user,
      kind: "topic_reply", forum_topic: forum_topic,
    )

    return if reply_to_post_id.blank?

    target = ForumPost.find_by(id: reply_to_post_id)
    return if target.nil?

    Notification.push!(
      user: target.user, actor: user,
      kind: "post_reply", forum_topic: forum_topic, forum_post: self,
    )
  end

  def handle_deletion
    ForumTopic.where(id: forum_topic_id, solved_post_id: id)
      .update_all(solved_post_id: nil, solved_at: nil)
    ForumPost.where(reply_to_post_id: id)
      .update_all(reply_to_post_id: nil, reply_to_deleted: true)
    Notification.where(forum_post_id: id).delete_all
  end

  def refresh_counters
    topic = ForumTopic.find_by(id: forum_topic_id)
    return unless topic

    topic.recalculate_counters!
    topic.forum_board.recalculate_counters!
  end
end
