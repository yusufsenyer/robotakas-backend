class Conversation < ApplicationRecord
  belongs_to :listing
  belongs_to :buyer, class_name: "User"
  has_many :messages, dependent: :destroy

  validates :listing_id, uniqueness: { scope: :buyer_id }

  scope :ordered, -> { order(last_message_at: :desc, id: :desc) }

  def seller
    listing.user
  end

  def participant?(user)
    return false if user.nil?

    buyer_id == user.id || listing.user_id == user.id
  end

  def other_user(user)
    buyer_id == user.id ? seller : buyer
  end

  def role_for(user)
    buyer_id == user.id ? "buyer" : "seller"
  end

  def unread_count_for(user)
    messages.where.not(sender_id: user.id).where(read_at: nil).count
  end

  def mark_read_for(user)
    messages.where.not(sender_id: user.id).where(read_at: nil)
      .update_all(read_at: Time.current)
  end
end
