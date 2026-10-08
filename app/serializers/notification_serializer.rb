module NotificationSerializer
  def self.render(note)
    {
      id: note.id,
      kind: note.kind,
      count: note.count,
      read: note.read_at.present?,
      created_at: note.created_at.iso8601,
      updated_at: note.updated_at.iso8601,
      actor: { full_name: note.actor.full_name },
      topic: note.forum_topic ? {
        id: note.forum_topic.id,
        slug: note.forum_topic.slug,
        title: note.forum_topic.title
      } : nil,
      post_id: note.forum_post_id
    }
  end
end
