module ForumMedia
  def self.images(record)
    record.images.filter_map do |image|
      url = url_for(image)
      url ? { id: image.id, url: url } : nil
    end
  end

  def self.cover_url(record)
    first = record.images.first
    first ? url_for(first) : nil
  end

  def self.url_for(attachment)
    blob = attachment.blob
    return nil unless blob && blob.service.exist?(blob.key)

    Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
  rescue StandardError
    nil
  end
end
