module ForumBoardSerializer
  def self.render(board)
    {
      id: board.id,
      name: board.name,
      slug: board.slug,
      description: board.description,
      icon_key: board.icon_key,
      kind: board.kind,
      topics_count: board.topics_count,
      posts_count: board.posts_count,
      last_activity_at: board.last_activity_at&.iso8601
    }
  end
end
