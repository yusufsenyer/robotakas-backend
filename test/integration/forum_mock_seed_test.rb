require "test_helper"

class ForumMockSeedTest < ActiveSupport::TestCase
  setup do
    User.create!(
      full_name: "RoboTakas Admin", email: "admin@robotakas.test",
      password: "Admin1234!", city: "Ankara", role: "admin",
    )
  end

  test "seed! beklenen yapıyı oluşturur" do
    notification_floor = Notification.maximum(:id).to_i
    summary = ForumMockSeeder.seed!

    assert_equal [], summary[:topics_skipped]
    assert_equal 15, summary[:topics_created].size
    assert_equal 15, ForumTopic.count
    assert_equal 33, ForumPost.count
    assert_equal 4, ForumTopic.where.not(solved_post_id: nil).count

    ForumTopic.where.not(solved_post_id: nil).find_each do |topic|
      answer = ForumPost.find(topic.solved_post_id)
      assert_equal "question", topic.kind
      assert answer.created_at < topic.solved_at, "solved_at çözüm cevabından sonra olmalı"
      assert topic.solved_at <= Time.current
    end

    unanswered = ForumTopic.where(posts_count: 0)
    assert_equal 3, unanswered.count
    assert unanswered.all? { |topic| topic.kind == "question" }

    assert_equal 2, ForumTopic.where(pinned: true).count
    assert_equal 1, ForumTopic.where(locked: true).count

    ForumBoard.find_each do |board|
      assert_equal board.forum_topics.count, board.topics_count
      expected_posts = ForumPost.joins(:forum_topic)
        .where(forum_topics: { forum_board_id: board.id }).count
      assert_equal expected_posts, board.posts_count
    end

    ForumTopic.find_each do |topic|
      expected = [ topic.created_at, topic.forum_posts.maximum(:created_at) ].compact.max
      assert_equal expected.to_i, topic.last_activity_at.to_i
      assert_equal topic.forum_posts.count, topic.posts_count
      assert topic.created_at <= Time.current, "created_at gelecekte olamaz"
    end

    likes = ForumLike.count
    assert_operator likes, :>=, 25
    assert_operator likes, :<=, 30

    ForumLike.find_each do |like|
      target_author = if like.forum_post_id
        ForumPost.find(like.forum_post_id).user_id
      else
        ForumTopic.find(like.forum_topic_id).user_id
      end
      refute_equal target_author, like.user_id, "kendi içeriğine beğeni olmamalı"
    end

    duplicates = ForumLike.group(:user_id, :forum_post_id, :forum_topic_id)
      .having("COUNT(*) > 1").count
    assert_empty duplicates

    assert_equal 0, Notification.where("id > ?", notification_floor).where(read_at: nil).count
  end

  test "seed! idempotenttir" do
    ForumMockSeeder.seed!
    counts = [ User.count, ForumTopic.count, ForumPost.count, ForumLike.count, Notification.count ]

    second = ForumMockSeeder.seed!

    assert_equal [], second[:topics_created]
    assert_equal 15, second[:topics_skipped].size
    assert_equal counts, [ User.count, ForumTopic.count, ForumPost.count, ForumLike.count, Notification.count ]
  end
end
