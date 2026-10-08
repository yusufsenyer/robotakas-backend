module ForumPostSerializer
  REPLY_EXCERPT_LENGTH = 140

  def self.render(post, current_user = nil, liked_by_me: nil)
    liked =
      if liked_by_me.nil?
        current_user.present? && post.forum_likes.exists?(user_id: current_user.id)
      else
        liked_by_me
      end

    {
      id: post.id,
      body: post.body,
      created_at: post.created_at.iso8601,
      edited_at: post.edited_at&.iso8601,
      is_owner: post.editable_by?(current_user),
      user: ForumUserSerializer.render(post.user),
      likes_count: post.likes_count,
      liked_by_me: liked,
      images: ForumMedia.images(post),
      masked: !!post.masked,
      reply_to: reply_to_summary(post),
      reply_to_deleted: post.reply_to_deleted
    }
  end

  def self.reply_to_summary(post)
    return nil if post.reply_to_post_id.blank?

    target = post.reply_to_post
    return nil if target.nil?

    {
      id: target.id,
      user: { full_name: target.user.full_name },
      excerpt: ForumTopicSerializer.excerpt(target.body, REPLY_EXCERPT_LENGTH),
      page: page_of(target)
    }
  end

  def self.page_of(post)
    position = ForumPost.where(forum_topic_id: post.forum_topic_id).where("id <= ?", post.id).count
    ((position - 1) / 20) + 1
  end
end
