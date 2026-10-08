require "test_helper"

class ForumPostTest < ActiveSupport::TestCase
  setup do
    @board = ForumBoard.create!(name: "Mini Sumo", kind: "competition", position: 0)
    @user = User.create!(full_name: "Efe Kaya", email: "efe@example.com", password: "password1", city: "Ankara")
    @topic = ForumTopic.create!(
      forum_board: @board, user: @user, kind: "question",
      title: "Sensör seçimi nasıl olmalı", body: "Uzun bir gövde metni yazıyorum buraya.",
    )
  end

  test "trims body" do
    post = @topic.forum_posts.create!(user: @user, body: "  Merhaba dünya  ")
    assert_equal "Merhaba dünya", post.body
  end

  test "rejects too short body" do
    post = @topic.forum_posts.new(user: @user, body: "a")
    assert post.invalid?
  end

  test "rejects too long body" do
    post = @topic.forum_posts.new(user: @user, body: "a" * 10001)
    assert post.invalid?
  end
end
