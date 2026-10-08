module ListingSerializer
  def self.list_item(listing, favorite_ids: nil)
    {
      id: listing.id,
      title: listing.title,
      price: listing.price,
      condition: listing.condition,
      city: listing.city,
      district: listing.district,
      published_at: listing.published_at&.iso8601,
      part: listing.part ? part_summary(listing.part) : nil,
      category_path: listing.category.path,
      category_icon_key: listing.category.icon_key,
      cover_photo_url: cover_photo_url(listing),
      photo_count: listing.photos.size,
      seller: seller_summary(listing.user),
      favorited_by_me: favorite_ids ? favorite_ids.include?(listing.id) : false,
    }
  end

  def self.detail(listing, current_user: nil)
    {
      id: listing.id,
      title: listing.title,
      description: listing.description,
      condition: listing.condition,
      price: listing.price,
      quantity: listing.quantity,
      seasons_used: listing.seasons_used,
      status: listing.status,
      category: {
        id: listing.category_id,
        path: listing.category.path,
        icon_key: listing.category.icon_key,
      },
      city: listing.city,
      district: listing.district,
      published_at: listing.published_at&.iso8601,
      view_count: listing.view_count,
      part: listing.part ? part_detail(listing.part) : nil,
      compatible_categories: listing.compatible_categories.map do |category|
        { id: category.id, name: category.name, slug: category.slug }
      end,
      photos: listing.photos.filter_map do |photo|
        url = attachment_url(photo)
        url ? { id: photo.id, url: url } : nil
      end,
      video: listing.video.attached? ? { url: attachment_url(listing.video) } : nil,
      seller: seller_detail(listing.user),
      phone: listing.show_phone ? listing.user.phone : nil,
      favorited_by_me: listing.favorited_by?(current_user),
      is_owner: listing.owner?(current_user),
    }
  end

  def self.part_summary(part)
    { code: part.code, slug: part.slug, name: part.name }
  end

  def self.part_detail(part)
    {
      id: part.id,
      code: part.code,
      slug: part.slug,
      name: part.name,
      brand: part.brand,
      specs: part.specs || [],
      status: part.status,
      reject_reason: part.reject_reason,
    }
  end

  def self.seller_summary(user)
    { id: user.id, full_name: user.full_name, team_name: user.team_name }
  end

  def self.seller_detail(user)
    seller_summary(user).merge(
      city: user.city,
      member_since: user.created_at.iso8601,
      active_listing_count: user.listings.active.count,
    )
  end

  def self.cover_photo_url(listing)
    cover = listing.photos.first
    cover ? attachment_url(cover) : nil
  end

  def self.attachment_url(attachment)
    blob = attachment.blob
    return nil unless blob && blob_exists?(blob)

    Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
  end

  def self.blob_exists?(blob)
    blob.service.exist?(blob.key)
  rescue StandardError
    false
  end
end
