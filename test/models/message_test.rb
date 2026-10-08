require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @leaf = Category.create!(name: "Motor Sürücü", slug: "motor-surucu")
    @seller = User.create!(full_name: "Satıcı", email: "seller@example.com", password: "password1", city: "Ankara")
    @buyer = User.create!(full_name: "Alıcı", email: "buyer@example.com", password: "password1", city: "İzmir")
    @listing = Listing.create!(
      user: @seller, category: @leaf,
      title: "Test ilanı", description: "açıklama", condition: "new", price: 100, city: "Ankara",
    )
    @conversation = Conversation.create!(listing: @listing, buyer: @buyer)
  end

  test "strips body" do
    message = @conversation.messages.create!(sender: @buyer, body: "  Merhaba  ")
    assert_equal "Merhaba", message.body
  end

  test "rejects body over 1000 characters" do
    message = @conversation.messages.build(sender: @buyer, body: "a" * 1001)
    assert message.invalid?
  end

  test "touches conversation last_message_at on create" do
    message = @conversation.messages.create!(sender: @buyer, body: "Merhaba")
    assert_equal message.created_at.to_i, @conversation.reload.last_message_at.to_i
  end

  test "mark_read_for updates only counterpart messages" do
    from_seller = @conversation.messages.create!(sender: @seller, body: "Satıcıdan")
    from_buyer = @conversation.messages.create!(sender: @buyer, body: "Alıcıdan")

    @conversation.mark_read_for(@buyer)

    assert from_seller.reload.read_at
    assert_nil from_buyer.reload.read_at
  end

  test "unread_count_for counts only counterpart unread" do
    @conversation.messages.create!(sender: @seller, body: "Bir")
    @conversation.messages.create!(sender: @seller, body: "İki")
    @conversation.messages.create!(sender: @buyer, body: "Üç")

    assert_equal 2, @conversation.unread_count_for(@buyer)
  end
end
