module AnnouncementSerializer
  def self.render(announcement, read_ids)
    {
      id: announcement.id,
      title: announcement.title,
      body: announcement.body,
      published_at: announcement.published_at&.iso8601,
      read: read_ids.include?(announcement.id),
    }
  end
end
