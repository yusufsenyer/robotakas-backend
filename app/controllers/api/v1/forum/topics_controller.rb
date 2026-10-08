module Api
  module V1
    module Forum
      class TopicsController < BaseController
        TUR_KINDS = {
          "soru" => "question",
          "tartisma" => "discussion",
          "proje" => "showcase",
          "parca" => "seeking"
        }.freeze

        before_action :require_user!,
          only: %i[create update destroy like unlike solution destroy_solution]
        before_action :set_topic,
          only: %i[show update destroy posts like unlike solution destroy_solution]

        def index
          scope = ForumTopic.includes(:forum_board, :user).with_attached_images

          if params[:board].present?
            board = ForumBoard.find_by(slug: params[:board])
            scope = board ? scope.where(forum_board_id: board.id) : scope.none
          end

          kind = TUR_KINDS[params[:tur]] || params[:kind]
          scope = scope.where(kind: kind) if ForumTopic::KINDS.include?(kind)
          scope = scope.where(kind: "question", posts_count: 0) if truthy?(params[:unanswered])
          scope = apply_search(scope)

          data, meta = paginate_with_limit(order_topics(scope))
          render json: { topics: serialize_list(data), meta: meta }
        end

        def solved_recent
          limit = params[:limit].present? ? [ [ params[:limit].to_i, 1 ].max, 20 ].min : 5
          topics = ForumTopic
            .includes(:forum_board, :user)
            .with_attached_images
            .where.not(solved_post_id: nil)
            .order(solved_at: :desc, id: :desc)
            .limit(limit)

          render json: { topics: serialize_list(topics) }
        end

        def show
          unless count_view_disabled? || @topic.owner?(current_user)
            @topic.increment!(:views_count)
          end

          render json: ForumTopicSerializer.detail(@topic, current_user)
        end

        def create
          return render_rate_limited if topic_rate_limited?

          board = ForumBoard.find_by(slug: params[:board].to_s)
          unless board
            render_error(code: "not_found", message: "Bölüm bulunamadı.", status: :not_found)
            return
          end

          topic = ForumTopic.new(
            forum_board: board,
            user: current_user,
            kind: params[:kind],
            title: params[:title],
            body: params[:body],
          )
          attach_images(topic, params[:images])

          if topic.save
            render json: ForumTopicSerializer.detail(topic, current_user), status: :created
          else
            render_validation_error(topic)
          end
        end

        def update
          return render_forbidden unless @topic.editable_by?(current_user)

          attrs = {}
          attrs[:title] = params[:title] if params.key?(:title)
          attrs[:body] = params[:body] if params.key?(:body)
          attrs[:kind] = params[:kind] if params.key?(:kind)
          attrs[:edited_at] = Time.current if attrs.any?

          @topic.assign_attributes(attrs)
          remove_images(@topic, params[:images_to_remove])
          attach_images(@topic, params[:images])

          if @topic.save
            render json: ForumTopicSerializer.detail(@topic, current_user)
          else
            render_validation_error(@topic)
          end
        end

        def destroy
          return render_forbidden unless @topic.editable_by?(current_user)

          @topic.destroy!
          head :no_content
        end

        def posts
          scope = @topic.forum_posts
            .includes(:user, reply_to_post: :user)
            .with_attached_images
            .order(:created_at, :id)
          data, meta = paginate(scope)
          liked_ids = liked_post_ids(data)
          render json: {
            posts: data.map do |post|
              ForumPostSerializer.render(post, current_user, liked_by_me: liked_ids.include?(post.id))
            end,
            meta: meta
          }
        end

        def like
          return render_own_content if @topic.user_id == current_user.id

          if ForumLike.exists?(user_id: current_user.id, forum_topic_id: @topic.id)
            render_error(code: "already_liked", message: "Bu yazıya zaten Faydalı verdin.", status: :unprocessable_entity)
            return
          end

          ForumLike.create!(user: current_user, forum_topic: @topic)
          render json: { likes_count: @topic.reload.likes_count, liked_by_me: true }
        end

        def unlike
          ForumLike.where(user_id: current_user.id, forum_topic_id: @topic.id).destroy_all
          render json: { likes_count: @topic.reload.likes_count, liked_by_me: false }
        end

        def solution
          return render_forbidden unless @topic.owner?(current_user) || current_user.admin?

          unless @topic.kind == "question"
            render_error(code: "not_question", message: "Yalnızca soru konularında çözüm işaretlenebilir.", status: :unprocessable_entity)
            return
          end

          post = @topic.forum_posts.find_by(id: params[:post_id])
          unless post
            render_error(code: "not_found", message: "Cevap bulunamadı.", status: :not_found)
            return
          end

          @topic.solve!(post, actor: current_user)
          render json: ForumTopicSerializer.detail(@topic, current_user)
        end

        def destroy_solution
          return render_forbidden unless @topic.owner?(current_user) || current_user.admin?

          @topic.unsolve!
          render json: ForumTopicSerializer.detail(@topic, current_user)
        end

        private

        def set_topic
          @topic = ForumTopic.find_by(id: params[:id])
          render_not_found unless @topic
        end

        def order_topics(scope)
          case params[:sekme]
          when "yeni"
            scope.order(created_at: :desc, id: :desc)
          when "en-faydali"
            scope.order(likes_count: :desc, last_activity_at: :desc, id: :desc)
          when "cevapsiz"
            scope.where(posts_count: 0).order(last_activity_at: :desc, id: :desc)
          when "cozuldu"
            scope.where.not(solved_post_id: nil).order(solved_at: :desc, id: :desc)
          else
            scope.ordered
          end
        end

        def apply_search(scope)
          q = params[:q].to_s.strip
          return scope if q.length < 2

          pattern = "%#{q.downcase}%"
          scope.where("LOWER(title) LIKE :q OR LOWER(body) LIKE :q", q: pattern)
        end

        def serialize_list(topics)
          liked_ids = liked_topic_ids(topics)
          topics.map do |topic|
            ForumTopicSerializer.list_item(topic, liked_by_me: liked_ids.include?(topic.id))
          end
        end

        def liked_topic_ids(topics)
          return [] if current_user.nil? || topics.empty?

          ForumLike.where(user_id: current_user.id, forum_topic_id: topics.map(&:id)).pluck(:forum_topic_id)
        end

        def liked_post_ids(posts)
          return [] if current_user.nil? || posts.empty?

          ForumLike.where(user_id: current_user.id, forum_post_id: posts.map(&:id)).pluck(:forum_post_id)
        end

        def attach_images(record, files)
          Array(files).each { |file| record.images.attach(file) }
        end

        def remove_images(record, ids)
          ids = Array(ids).map(&:to_i).reject(&:zero?)
          return if ids.empty?

          record.images_attachments.where(id: ids).each(&:purge)
        end

        def truthy?(value)
          value.present? && value.to_s != "false" && value.to_s != "0"
        end

        def count_view_disabled?
          params[:count].to_s == "0" || params[:count].to_s == "false"
        end
      end
    end
  end
end
