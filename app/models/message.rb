class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  before_validation :strip_body

  validates :body, presence: true, length: { maximum: 1000 }

  after_create_commit :touch_conversation_last_message

  private

  def strip_body
    self.body = body.to_s.strip
  end

  def touch_conversation_last_message
    conversation.update_column(:last_message_at, created_at)
  end
end
