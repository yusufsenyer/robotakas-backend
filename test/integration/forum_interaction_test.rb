require "test_helper"

class ForumInteractionTest < ActionDispatch::IntegrationTest
  setup do
    @board = ForumBoard.create!(name: "Mini Sumo", slug: "mini-sumo", kind: "competition", position: 0)
    @other_board = ForumBoard.create!(name: "Genel sohbet", slug: "genel-sohbet", kind: "general", position: 0)

    @owner = User.create!(full_name: "Efe Kaya", email: "efe@example.com", password: "password1", city: "Ankara")
    @other = User.create!(full_name: "Zeynep Demir", email: "zeynep@example.com", password: "password1", city: "İzmir")
    @third = User.create!(full_name: "Mert Yılmaz", email: "mert@example.com", password: "password1", city: "Bursa")
    @admin = User.create!(full_name: "Admin", email: "admin@example.com", password: "password1", city: "Ankara", role: "admin")
  end

  def login_as(user)
    post "/api/v1/auth/login", params: { email: user.email, password: "password1" }, as: :json
    assert_response :success
  end

  def create_topic(user: @owner, board: @board, kind: "question", title: "Sensör seçimi nasıl olmalı",
                   body: "Uzun bir gövde metni yazıyorum buraya, fikir almak istiyorum.", created_at: nil)
    topic = ForumTopic.create!(forum_board: board, user: user, kind: kind, title: title, body: body)
    topic.update_column(:created_at, created_at) if created_at
    topic
  end

  test "liking a topic updates counters and is not idempotent" do
    topic = create_topic
    login_as(@other)

    assert_difference -> { topic.reload.likes_count }, 1 do
      post "/api/v1/forum/topics/#{topic.id}/like"
    end
    assert_response :success
    assert_equal true, JSON.parse(response.body)["liked_by_me"]

    post "/api/v1/forum/topics/#{topic.id}/like"
    assert_response :unprocessable_entity
    assert_equal "already_liked", JSON.parse(response.body)["error"]["code"]

    assert_difference -> { topic.reload.likes_count }, -1 do
      delete "/api/v1/forum/topics/#{topic.id}/like"
    end
    assert_response :success
  end

  test "cannot like own content" do
    topic = create_topic
    login_as(@owner)
    post "/api/v1/forum/topics/#{topic.id}/like"
    assert_response :unprocessable_entity
    assert_equal "own_content", JSON.parse(response.body)["error"]["code"]
  end

  test "liking a post updates its counter" do
    topic = create_topic
    post_record = topic.forum_posts.create!(user: @owner, body: "Bir cevap yazıyorum")
    login_as(@other)

    post "/api/v1/forum/posts/#{post_record.id}/like"
    assert_response :success
    assert_equal 1, post_record.reload.likes_count
  end

  test "owner marks a solution and it notifies the answer author" do
    topic = create_topic
    answer = topic.forum_posts.create!(user: @other, body: "Şu sensörü dene")
    login_as(@owner)

    assert_difference -> { @other.notifications.count }, 1 do
      post "/api/v1/forum/topics/#{topic.id}/solution", params: { post_id: answer.id }, as: :json
    end
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal answer.id, body["solved_post_id"]
    assert topic.reload.solved?

    delete "/api/v1/forum/topics/#{topic.id}/solution"
    assert_response :success
    refute topic.reload.solved?
  end

  test "solution requires question kind and permission" do
    discussion = create_topic(kind: "discussion", title: "Genel bir tartışma konusu")
    answer = discussion.forum_posts.create!(user: @other, body: "Bir cevap yazıyorum")

    login_as(@other)
    post "/api/v1/forum/topics/#{discussion.id}/solution", params: { post_id: answer.id }, as: :json
    assert_response :forbidden

    login_as(@owner)
    post "/api/v1/forum/topics/#{discussion.id}/solution", params: { post_id: answer.id }, as: :json
    assert_response :unprocessable_entity
    assert_equal "not_question", JSON.parse(response.body)["error"]["code"]
  end

  test "changing kind away from question clears the solution" do
    topic = create_topic
    answer = topic.forum_posts.create!(user: @other, body: "Şu sensörü dene")
    topic.solve!(answer, actor: @owner)

    login_as(@owner)
    patch "/api/v1/forum/topics/#{topic.id}", params: { kind: "discussion" }, as: :json
    assert_response :success
    refute topic.reload.solved?
  end

  test "reply citation must point to a post in the same topic" do
    topic = create_topic
    other_topic = create_topic(title: "Başka bir konu başlığı burada")
    target = topic.forum_posts.create!(user: @owner, body: "Hedef cevap")
    foreign = other_topic.forum_posts.create!(user: @owner, body: "Başka konunun cevabı")

    login_as(@other)
    post "/api/v1/forum/topics/#{topic.id}/posts",
      params: { body: "Yanıt veriyorum", reply_to_post_id: target.id }, as: :json
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal target.id, body["reply_to"]["id"]
    assert_equal "Efe Kaya", body["reply_to"]["user"]["full_name"]

    post "/api/v1/forum/topics/#{topic.id}/posts",
      params: { body: "Yanlış hedef", reply_to_post_id: foreign.id }, as: :json
    assert_response :unprocessable_entity
  end

  test "deleting a cited post marks replies as reply_to_deleted" do
    topic = create_topic
    target = topic.forum_posts.create!(user: @owner, body: "Hedef cevap")
    reply = topic.forum_posts.create!(user: @other, body: "Yanıt veriyorum", reply_to_post_id: target.id)

    target.destroy!

    reply.reload
    assert_nil reply.reply_to_post_id
    assert_equal true, reply.reply_to_deleted
  end

  test "notifications merge repeated replies and skip self actions" do
    topic = create_topic
    topic.forum_posts.create!(user: @other, body: "Birinci cevap")
    topic.forum_posts.create!(user: @third, body: "İkinci cevap")
    topic.forum_posts.create!(user: @owner, body: "Kendi cevabım")

    notes = @owner.notifications.where(kind: "topic_reply")
    assert_equal 1, notes.count
    assert_equal 2, notes.first.count
  end

  test "liking merges into one notification and unlike removes it" do
    topic = create_topic
    like = ForumLike.create!(user: @other, forum_topic: topic)
    ForumLike.create!(user: @third, forum_topic: topic)

    note = @owner.notifications.find_by(kind: "topic_liked")
    assert_equal 2, note.count

    like.destroy!
    assert_equal 1, @owner.notifications.find_by(kind: "topic_liked").count

    ForumLike.where(forum_topic: topic).destroy_all
    assert_nil @owner.notifications.find_by(kind: "topic_liked")
  end

  test "notifications endpoints return items and mark them read" do
    topic = create_topic
    topic.forum_posts.create!(user: @other, body: "Bir cevap yazıyorum")
    login_as(@owner)

    get "/api/v1/notifications"
    assert_response :success
    items = JSON.parse(response.body)["notifications"]
    assert_equal 1, items.size
    assert_equal "topic_reply", items.first["kind"]
    assert_equal false, items.first["read"]
    assert_equal topic.id, items.first["topic"]["id"]

    get "/api/v1/me/unread_counts"
    assert_equal 1, JSON.parse(response.body)["notifications"]

    post "/api/v1/notifications/read"
    assert_response :no_content
    get "/api/v1/me/unread_counts"
    assert_equal 0, JSON.parse(response.body)["notifications"]
  end

  test "deleting a topic removes its notifications" do
    topic = create_topic
    topic.forum_posts.create!(user: @other, body: "Bir cevap yazıyorum")
    assert_operator @owner.notifications.count, :>, 0

    topic.destroy!
    assert_equal 0, @owner.notifications.count
  end

  test "search matches title and body, tur filter combines" do
    create_topic(title: "TB6612FNG motor sürücü sorunu", body: "Sürücü ısınıyor ve duman çıkıyor.")
    create_topic(title: "Genel bir tartışma başlığı", kind: "discussion", body: "Sohbet edelim biraz.")

    get "/api/v1/forum/topics", params: { q: "tb6612fng" }
    assert_response :success
    assert_equal 1, JSON.parse(response.body)["topics"].size

    get "/api/v1/forum/topics", params: { q: "ısınıyor" }
    assert_equal 1, JSON.parse(response.body)["topics"].size

    get "/api/v1/forum/topics", params: { tur: "tartisma" }
    assert_equal 1, JSON.parse(response.body)["topics"].size
  end

  test "tabs sort and filter topics" do
    base = 5.hours.ago
    first = create_topic(title: "Birinci konu başlığı", created_at: base)
    second = create_topic(title: "İkinci konu başlığı", created_at: base + 1.hour)
    ForumLike.create!(user: @other, forum_topic: first)

    get "/api/v1/forum/topics", params: { sekme: "yeni" }
    assert_equal second.id, JSON.parse(response.body)["topics"].first["id"]

    get "/api/v1/forum/topics", params: { sekme: "en-faydali" }
    assert_equal first.id, JSON.parse(response.body)["topics"].first["id"]

    get "/api/v1/forum/topics", params: { sekme: "cevapsiz" }
    assert JSON.parse(response.body)["topics"].all? { |t| t["posts_count"].zero? }

    answer = first.forum_posts.create!(user: @other, body: "Bir cevap yazıyorum")
    first.solve!(answer, actor: @owner)
    get "/api/v1/forum/topics", params: { sekme: "cozuldu" }
    ids = JSON.parse(response.body)["topics"].map { |t| t["id"] }
    assert_equal [ first.id ], ids
  end

  test "link previews resolve active listings, approved parts and hide others" do
    category = Category.create!(name: "Motor Sürücü", slug: "motor-surucu")
    part = Part.create!(code: "TB6612FNG", name: "TB6612FNG", slug: "tb6612fng", category: category, status: "approved")
    listing = Listing.create!(user: @owner, category: category, part: part,
      title: "TB6612FNG sürücü", description: "çalışır durumda", condition: "used", price: 120, city: "Ankara")

    post "/api/v1/link_previews", params: {
      urls: [ "/ilan/#{listing.id}", "/parca/#{part.slug}",
              "https://example.com/ilan/#{listing.id}", "/ilan/999999" ]
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "listing", body["/ilan/#{listing.id}"]["type"]
    assert_equal listing.id, body["/ilan/#{listing.id}"]["id"]
    assert_equal "part", body["/parca/tb6612fng"]["type"]
    assert_nil body["https://example.com/ilan/#{listing.id}"]
    assert_equal "missing", body["/ilan/999999"]["type"]
  end

  test "link previews hide non-active listings without leaking titles" do
    category = Category.create!(name: "Motor Sürücü", slug: "motor-surucu")
    listing = Listing.create!(user: @owner, category: category,
      title: "Gizli ilan başlığı", description: "açıklama", condition: "used", price: 100, city: "Ankara")
    listing.remove!(reason: "withdrawn")

    post "/api/v1/link_previews", params: { urls: [ "/ilan/#{listing.id}" ] }, as: :json
    body = JSON.parse(response.body)
    assert_equal "missing", body["/ilan/#{listing.id}"]["type"]
  end
end
