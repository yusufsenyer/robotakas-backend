module MessageSerializer
  def self.render(message)
    {
      id: message.id,
      conversation_id: message.conversation_id,
      sender_id: message.sender_id,
      body: message.body,
      read_at: message.read_at&.iso8601,
      created_at: message.created_at.iso8601,
    }
  end
end
