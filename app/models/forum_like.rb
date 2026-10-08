class ForumLike < ApplicationRecord
  belongs_to :user
  belongs_to :forum_topic, optional: true
  belongs_to :forum_post, optional: true

  after_create :increment_likes_count
  after_create :notify_target
  after_destroy :decrement_likes_count
  after_destroy :remove_notification

  validate :exactly_one_target

  private

  def exactly_one_target
    return if forum_topic_id.present? ^ forum_post_id.present?

    errors.add(:base, "Faydalı tam olarak bir konuya ya da cevaba verilmeli.")
  end

  def increment_likes_count
    if forum_topic_id
      ForumTopic.increment_counter(:likes_count, forum_topic_id)
    else
      ForumPost.increment_counter(:likes_count, forum_post_id)
    end
  end

  def decrement_likes_count
    if forum_topic_id
      ForumTopic.decrement_counter(:likes_count, forum_topic_id)
    else
      ForumPost.decrement_counter(:likes_count, forum_post_id)
    end
  end

  def notify_target
    if forum_topic_id
      Notification.push!(
        user: forum_topic.user, actor: user,
        kind: "topic_liked", forum_topic: forum_topic,
      )
    else
      Notification.push!(
        user: forum_post.user, actor: user,
        kind: "post_liked", forum_topic: forum_post.forum_topic, forum_post: forum_post,
      )
    end
  end

  def remove_notification
    if forum_topic_id
      Notification.decrement_like!(kind: "topic_liked", forum_topic_id: forum_topic_id)
    else
      Notification.decrement_like!(kind: "post_liked", forum_post_id: forum_post_id)
    end
  end
end
