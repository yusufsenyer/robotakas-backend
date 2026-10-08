require "test_helper"

class ForumMediaTest < ActionDispatch::IntegrationTest
  setup do
    @board = ForumBoard.create!(name: "Mini Sumo", slug: "mini-sumo", kind: "competition", position: 0)
    @owner = User.create!(full_name: "Efe Kaya", email: "efe@example.com", password: "password1", city: "Ankara")
  end

  def login_as(user)
    post "/api/v1/auth/login", params: { email: user.email, password: "password1" }, as: :json
    assert_response :success
  end

  def image(type = "image/png")
    fixture_file_upload("test.png", type)
  end

  def create_topic(params = {})
    post "/api/v1/forum/topics", params: {
      board: "mini-sumo", kind: "question",
      title: "Görsel yüklenen konu başlığı",
      body: "Gövde metni buraya yazıyorum, görsel ekledim."
    }.merge(params)
  end

  test "creating a topic with images returns them" do
    login_as(@owner)
    create_topic(images: [ image, image ])
    assert_response :created

    body = JSON.parse(response.body)
    assert_equal 2, body["images"].size
    assert body["images"].first["id"]
    assert body["images"].first["url"].start_with?("/rails/active_storage")
  end

  test "topic rejects more than 6 images" do
    login_as(@owner)
    create_topic(images: Array.new(7) { image })
    assert_response :unprocessable_entity
  end

  test "showcase allows up to 10 images" do
    login_as(@owner)
    create_topic(kind: "showcase", images: Array.new(7) { image })
    assert_response :created
  end

  test "rejects unsupported content types" do
    login_as(@owner)
    create_topic(images: [ image("image/gif") ])
    assert_response :unprocessable_entity
  end

  test "removing an image on update purges the stored file" do
    login_as(@owner)
    create_topic(images: [ image ])
    topic = ForumTopic.last
    attachment = topic.images.first
    blob = attachment.blob
    key = blob.key
    service = blob.service

    patch "/api/v1/forum/topics/#{topic.id}",
      params: { title: topic.title, images_to_remove: [ attachment.id ] }
    assert_response :success
    assert_equal 0, topic.reload.images.size
    assert_nil ActiveStorage::Blob.find_by(id: blob.id)
    refute service.exist?(key)
  end

  test "destroying a topic purges its images from disk" do
    login_as(@owner)
    create_topic(images: [ image ])
    topic = ForumTopic.last
    blob = topic.images.first.blob
    key = blob.key
    service = blob.service

    delete "/api/v1/forum/topics/#{topic.id}"
    assert_response :no_content
    assert_nil ActiveStorage::Blob.find_by(id: blob.id)
    refute service.exist?(key)
  end

  test "posts reject more than 4 images" do
    topic = ForumTopic.create!(forum_board: @board, user: @owner, kind: "question",
      title: "Sensör seçimi nasıl olmalı", body: "Uzun bir gövde metni yazıyorum buraya.")
    login_as(@owner)

    post "/api/v1/forum/topics/#{topic.id}/posts",
      params: { body: "Cevap metni", images: Array.new(5) { image } }
    assert_response :unprocessable_entity
  end
end
