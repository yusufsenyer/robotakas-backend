class Notification < ApplicationRecord
  KINDS = %w[topic_reply post_reply solution_marked topic_liked post_liked].freeze

  belongs_to :user
  belongs_to :actor, class_name: "User"
  belongs_to :forum_topic, optional: true
  belongs_to :forum_post, optional: true

  validates :kind, inclusion: { in: KINDS }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(updated_at: :desc, id: :desc) }

  def self.push!(user:, actor:, kind:, forum_topic: nil, forum_post: nil, merge: true)
    return nil if user.nil? || actor.nil? || user.id == actor.id

    topic_id = forum_topic&.id
    post_id = forum_post&.id

    if merge
      existing = unread.find_by(
        user_id: user.id, kind: kind,
        forum_topic_id: topic_id, forum_post_id: post_id,
      )
      if existing
        existing.increment!(:count)
        existing.touch
        return existing
      end
    end

    create!(
      user: user, actor: actor, kind: kind,
      forum_topic_id: topic_id, forum_post_id: post_id,
    )
  end

  def self.decrement_like!(kind:, forum_topic_id: nil, forum_post_id: nil)
    note = where(kind: kind, forum_topic_id: forum_topic_id, forum_post_id: forum_post_id)
      .order(updated_at: :desc, id: :desc)
      .first
    return unless note

    if note.count <= 1
      note.destroy
    else
      note.decrement!(:count)
    end
  end
end
