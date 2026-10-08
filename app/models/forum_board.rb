class ForumBoard < ApplicationRecord
  KINDS = %w[competition general].freeze

  has_many :forum_topics, dependent: :restrict_with_error

  before_validation :set_slug, if: -> { slug.blank? }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :description, length: { maximum: 160 }
  validates :kind, inclusion: { in: KINDS }
  validates :position, numericality: { only_integer: true }

  scope :ordered, -> {
    order(Arel.sql("CASE kind WHEN 'competition' THEN 0 ELSE 1 END"), :position, :id)
  }

  def recalculate_counters!
    update_columns(
      topics_count: forum_topics.count,
      posts_count: ForumPost
        .joins(:forum_topic)
        .where(forum_topics: { forum_board_id: id })
        .count,
      last_activity_at: forum_topics.maximum(:last_activity_at),
    )
  end

  private

  def set_slug
    self.slug = Category.normalize_slug(name)
  end
end
