require "test_helper"

class ForumTopicTest < ActiveSupport::TestCase
  setup do
    @board = ForumBoard.create!(name: "Mini Sumo", kind: "competition", position: 0)
    @user = User.create!(full_name: "Efe Kaya", email: "efe@example.com", password: "password1", city: "Ankara")
    @admin = User.create!(full_name: "Admin", email: "admin@example.com", password: "password1", city: "Ankara", role: "admin")
  end

  def build_topic(overrides = {})
    ForumTopic.new({
      forum_board: @board,
      user: @user,
      kind: "question",
      title: "Mini sumo için hangi motor",
      body: "İki sezon kullandığım motoru paylaşıyorum, fikir almak istiyorum."
    }.merge(overrides))
  end

  test "valid topic" do
    assert build_topic.valid?
  end

  test "title length is validated" do
    assert build_topic(title: "kısa").invalid?
    assert build_topic(title: "a" * 121).invalid?
  end

  test "body length is validated" do
    assert build_topic(body: "kısa").invalid?
    assert build_topic(body: "a" * 10001).invalid?
  end

  test "kind is validated" do
    assert build_topic(kind: "random").invalid?
  end

  test "slug is generated from Turkish title" do
    topic = build_topic(title: "Çizgi izleyen için sensör seçimi")
    topic.save!
    assert_equal "cizgi-izleyen-icin-sensor-secimi", topic.slug
  end

  test "control characters and null bytes are stripped" do
    topic = build_topic(title: "Başlık\u0000 deneme", body: "Gövde\u0007 metni burada yazıyorum.")
    assert topic.valid?
    assert_equal "Başlık deneme", topic.title
    assert_equal "Gövde metni burada yazıyorum.", topic.body
  end

  test "creating a topic updates board counters and last activity" do
    topic = build_topic
    topic.save!

    @board.reload
    assert_equal 1, @board.topics_count
    assert_equal 0, @board.posts_count
    assert_equal topic.last_activity_at.to_i, @board.last_activity_at.to_i
  end

  test "creating a post updates topic and board counters" do
    topic = build_topic
    topic.save!
    post = topic.forum_posts.create!(user: @user, body: "Birinci cevap")

    topic.reload
    @board.reload
    assert_equal 1, topic.posts_count
    assert_equal 1, @board.posts_count
    assert_equal post.created_at.to_i, topic.last_activity_at.to_i
  end

  test "deleting the last post reverts topic last activity to its creation" do
    topic = build_topic
    topic.save!
    post = topic.forum_posts.create!(user: @user, body: "Birinci cevap")

    post.destroy!

    topic.reload
    assert_equal 0, topic.posts_count
    assert_equal topic.created_at.to_i, topic.last_activity_at.to_i
  end

  test "destroying a topic removes its posts and updates board counters" do
    topic = build_topic
    topic.save!
    topic.forum_posts.create!(user: @user, body: "Birinci cevap")

    assert_difference -> { ForumPost.count }, -1 do
      topic.destroy!
    end

    @board.reload
    assert_equal 0, @board.topics_count
    assert_equal 0, @board.posts_count
    assert_nil @board.last_activity_at
  end

  test "editable_by owner and admin only" do
    topic = build_topic
    topic.save!
    assert topic.editable_by?(@user)
    assert topic.editable_by?(@admin)
    refute topic.editable_by?(nil)
  end

  test "deleting a user removes their forum topics and posts" do
    topic = build_topic
    topic.save!
    topic.forum_posts.create!(user: @user, body: "Birinci cevap")

    assert_difference -> { ForumTopic.count }, -1 do
      assert_difference -> { ForumPost.count }, -1 do
        @user.destroy!
      end
    end
  end
end
