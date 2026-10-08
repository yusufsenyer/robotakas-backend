module AdminSerializer
  def self.part(part, listing_count: nil, pending_listings: [])
    data = {
      id: part.id,
      code: part.code,
      slug: part.slug,
      name: part.name,
      brand: part.brand,
      status: part.status,
      reject_reason: part.reject_reason,
      category: { id: part.category_id, path: part.category&.path },
      description: part.description,
      specs: part.specs || [],
      suggested_by: part.suggested_by ? {
        id: part.suggested_by.id,
        full_name: part.suggested_by.full_name,
        email: part.suggested_by.email,
      } : nil,
      created_at: part.created_at.iso8601,
      listing_count: listing_count.nil? ? part.listings.count : listing_count,
    }
    data[:pending_listings] = pending_listings if part.status == "pending"
    data
  end

  def self.listing(listing, open_report_count: 0)
    {
      id: listing.id,
      title: listing.title,
      price: listing.price,
      status: listing.status,
      removal_reason: listing.removal_reason,
      part: listing.part ? { code: listing.part.code, slug: listing.part.slug } : nil,
      category_path: listing.category&.path,
      user: {
        id: listing.user_id,
        full_name: listing.user&.full_name,
        email: listing.user&.email,
      },
      created_at: listing.created_at.iso8601,
      published_at: listing.published_at&.iso8601,
      open_report_count: open_report_count,
    }
  end

  def self.report(report, listing_open_report_count: 0)
    {
      id: report.id,
      reason: report.reason,
      details: report.details,
      status: report.status,
      created_at: report.created_at.iso8601,
      resolved_at: report.resolved_at&.iso8601,
      reporter: { id: report.reporter_id, full_name: report.reporter&.full_name },
      listing: {
        id: report.listing_id,
        title: report.listing&.title,
        status: report.listing&.status,
        user: report.listing&.user ? {
          id: report.listing.user_id,
          full_name: report.listing.user.full_name,
        } : nil,
      },
      listing_open_report_count: listing_open_report_count,
    }
  end

  def self.announcement(announcement)
    {
      id: announcement.id,
      title: announcement.title,
      body: announcement.body,
      published_at: announcement.published_at&.iso8601,
      created_at: announcement.created_at.iso8601,
    }
  end

  def self.category(category)
    {
      id: category.id,
      name: category.name,
      slug: category.slug,
      parent_id: category.parent_id,
      icon_key: category.icon_key,
      position: category.position,
      listing_count: category.listings.count,
      compatible_count: ListingCompatibleCategory.where(category_id: category.id).count,
      part_count: category.parts.count,
      children_count: category.children.count,
    }
  end
end
