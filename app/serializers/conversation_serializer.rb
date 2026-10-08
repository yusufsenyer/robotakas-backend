module ConversationSerializer
  def self.list_items(conversations, user)
    ids = conversations.map(&:id)

    last_messages = Message
      .where(conversation_id: ids)
      .group(:conversation_id)
      .maximum(:id)
      .then { |max_ids| Message.where(id: max_ids.values).index_by(&:conversation_id) }

    unread_counts = Message
      .where(conversation_id: ids)
      .where.not(sender_id: user.id)
      .where(read_at: nil)
      .group(:conversation_id)
      .count

    conversations.map do |conversation|
      list_item(conversation, user,
        last_message: last_messages[conversation.id],
        unread_count: unread_counts[conversation.id] || 0)
    end
  end

  def self.list_item(conversation, user, last_message: nil, unread_count: 0)
    listing = conversation.listing

    {
      id: conversation.id,
      role: conversation.role_for(user),
      listing: listing_summary(listing),
      other_user: other_user_summary(conversation, user),
      last_message: last_message ? MessageSerializer.render(last_message) : nil,
      unread_count: unread_count
    }
  end

  def self.detail(conversation, user)
    {
      id: conversation.id,
      role: conversation.role_for(user),
      listing: listing_summary(conversation.listing),
      other_user: other_user_summary(conversation, user)
    }
  end

  def self.listing_summary(listing)
    {
      id: listing.id,
      title: listing.title,
      price: listing.price,
      status: listing.status,
      cover_photo_url: ListingSerializer.cover_photo_url(listing),
      part_code: listing.part&.code
    }
  end

  def self.other_user_summary(conversation, user)
    other = conversation.other_user(user)
    { id: other.id, full_name: other.full_name, team_name: other.team_name }
  end
end
