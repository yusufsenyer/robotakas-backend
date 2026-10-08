require "test_helper"

class ForumMockTasksTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("forum:seed_mock")
    User.create!(
      full_name: "RoboTakas Admin", email: "admin@robotakas.test",
      password: "Admin1234!", city: "Ankara", role: "admin",
    )
  end

  teardown do
    ENV.delete("CONFIRM")
  end

  test "seed_mock production'da abort eder" do
    with_production_env do
      assert_raises(SystemExit) do
        Rake::Task["forum:seed_mock"].reenable
        Rake::Task["forum:seed_mock"].invoke
      end
    end
  end

  test "purge_test_topics production'da abort eder" do
    with_production_env do
      assert_raises(SystemExit) do
        Rake::Task["forum:purge_test_topics"].reenable
        Rake::Task["forum:purge_test_topics"].invoke
      end
    end
  end

  test "purge dry-run hiçbir şey silmez" do
    create_test_user_with_topic

    assert_no_difference -> { ForumTopic.count } do
      Rake::Task["forum:purge_test_topics"].reenable
      Rake::Task["forum:purge_test_topics"].invoke
    end
  end

  test "purge CONFIRM=yes yalnızca Test User 1 konularını siler, sayaçları düzeltir" do
    board = ForumBoard.create!(name: "Mini Sumo", slug: "mini-sumo", kind: "competition", position: 0)
    test_user = User.create!(full_name: "Test User 1", email: "tu1@robotakas.test", password: "password1", city: "Ankara")
    other = User.create!(full_name: "Başka Kişi", email: "other@robotakas.test", password: "password1", city: "İzmir")

    test_topic = ForumTopic.create!(forum_board: board, user: test_user, kind: "question",
      title: "Test konusu bir başlık", body: "Test gövdesi buraya yazıyorum.")
    test_topic.forum_posts.create!(user: other, body: "Bir cevap")
    other_topic = ForumTopic.create!(forum_board: board, user: other, kind: "question",
      title: "Başka bir konu başlığı", body: "Gövde metni buraya yazıyorum.")
    other_topic.forum_posts.create!(user: test_user, body: "Test kullanıcının cevabı")

    ENV["CONFIRM"] = "yes"

    assert_difference -> { ForumTopic.count }, -1 do
      Rake::Task["forum:purge_test_topics"].reenable
      Rake::Task["forum:purge_test_topics"].invoke
    end

    assert_nil ForumTopic.find_by(id: test_topic.id)
    assert ForumTopic.exists?(other_topic.id)
    assert ForumPost.where(user: test_user, forum_topic_id: other_topic.id).exists?,
      "başka konudaki cevap silinmemeli"

    board.reload
    assert_equal board.forum_topics.count, board.topics_count
    expected_posts = ForumPost.joins(:forum_topic)
      .where(forum_topics: { forum_board_id: board.id }).count
    assert_equal expected_posts, board.posts_count
  end

  private

  def with_production_env
    env = Rails.env
    env.define_singleton_method(:production?) { true }
    yield
  ensure
    env.singleton_class.send(:remove_method, :production?)
  end

  def create_test_user_with_topic
    board = ForumBoard.create!(name: "Mini Sumo", slug: "mini-sumo", kind: "competition", position: 0)
    user = User.create!(full_name: "Test User 1", email: "tu1@robotakas.test", password: "password1", city: "Ankara")
    ForumTopic.create!(forum_board: board, user: user, kind: "question",
      title: "Test konusu bir başlık", body: "Test gövdesi buraya yazıyorum.")
  end
end
