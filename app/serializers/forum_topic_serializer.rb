module ForumTopicSerializer
  EXCERPT_LENGTH = 160

  def self.list_item(topic, liked_by_me: false)
    {
      id: topic.id,
      slug: topic.slug,
      title: topic.title,
      kind: topic.kind,
      excerpt: excerpt(topic.body),
      pinned: topic.pinned,
      locked: topic.locked,
      solved: topic.solved?,
      posts_count: topic.posts_count,
      views_count: topic.views_count,
      likes_count: topic.likes_count,
      liked_by_me: liked_by_me,
      cover_image_url: ForumMedia.cover_url(topic),
      created_at: topic.created_at.iso8601,
      last_activity_at: topic.last_activity_at&.iso8601,
      board: board_summary(topic.forum_board),
      user: ForumUserSerializer.render(topic.user)
    }
  end

  def self.detail(topic, current_user)
    liked = current_user.present? && topic.forum_likes.exists?(user_id: current_user.id)
    list_item(topic, liked_by_me: liked).merge(
      body: topic.body,
      edited_at: topic.edited_at&.iso8601,
      is_owner: topic.editable_by?(current_user),
      images: ForumMedia.images(topic),
      solved_post_id: topic.solved_post_id,
      solved_at: topic.solved_at&.iso8601,
      masked: !!topic.masked,
    )
  end

  def self.board_summary(board)
    { id: board.id, name: board.name, slug: board.slug }
  end

  def self.excerpt(body, length = EXCERPT_LENGTH)
    text = body.to_s
      .gsub(/```.*?```/m, " ")
      .gsub(/[`*_>#]/, "")
      .gsub(/!?\[([^\]]*)\]\([^)]*\)/, '\1')
      .gsub(/\s+/, " ")
      .strip

    text.length > length ? "#{text[0, length].rstrip}…" : text
  end
end
