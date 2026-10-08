require "test_helper"

class ForumBoardTest < ActiveSupport::TestCase
  test "slug is generated from name with Turkish characters" do
    board = ForumBoard.create!(name: "Çizgi İzleyen (Temel Seviye)", kind: "competition", position: 0)
    assert_equal "cizgi-izleyen-temel-seviye", board.slug
  end

  test "slug must be unique" do
    ForumBoard.create!(name: "Mini Sumo", slug: "mini-sumo", kind: "competition", position: 0)
    duplicate = ForumBoard.new(name: "Başka", slug: "mini-sumo", kind: "general", position: 1)
    assert duplicate.invalid?
  end

  test "description is limited to 160 characters" do
    board = ForumBoard.new(name: "Uzun", kind: "general", position: 0, description: "a" * 161)
    assert board.invalid?
  end

  test "kind must be competition or general" do
    board = ForumBoard.new(name: "Geçersiz", kind: "random", position: 0)
    assert board.invalid?
  end

  test "ordered puts competition boards before general ones" do
    general = ForumBoard.create!(name: "Genel", kind: "general", position: 0)
    competition = ForumBoard.create!(name: "Yarışma", kind: "competition", position: 5)

    assert_equal [ competition.id, general.id ], ForumBoard.ordered.map(&:id)
  end

  test "recalculate_counters reflects topics and replies" do
    board = ForumBoard.create!(name: "Mini Sumo", kind: "competition", position: 0)
    user = User.create!(full_name: "Test", email: "t@example.com", password: "password1", city: "Ankara")
    topic = ForumTopic.create!(forum_board: board, user: user, kind: "question",
      title: "Sensör seçimi nasıl olmalı", body: "Uzun bir gövde metni yazıyorum buraya.")
    topic.forum_posts.create!(user: user, body: "Şu sensörü dene")

    board.recalculate_counters!
    board.reload
    assert_equal 1, board.topics_count
    assert_equal 1, board.posts_count
    assert_equal topic.reload.last_activity_at.to_i, board.last_activity_at.to_i

    topic.forum_posts.first.destroy!
    board.reload
    assert_equal 0, board.posts_count
  end
end
