module Api
  module V1
    module Forum
      class PostsController < BaseController
        before_action :require_user!

        def create
          topic = ForumTopic.find_by(id: params[:id])
          return render_not_found unless topic

          if topic.locked?
            render_error(code: "topic_locked", message: "Bu konu kilitli.", status: :unprocessable_entity)
            return
          end

          return render_rate_limited if post_rate_limited?

          post = topic.forum_posts.new(user: current_user, body: params[:body])
          post.reply_to_post_id = params[:reply_to_post_id] if params[:reply_to_post_id].present?
          attach_images(post, params[:images])

          if post.save
            render json: ForumPostSerializer.render(post, current_user), status: :created
          else
            render_validation_error(post)
          end
        end

        def update
          post = ForumPost.find_by(id: params[:id])
          return render_not_found unless post
          return render_forbidden unless post.editable_by?(current_user)

          post.body = params[:body] if params.key?(:body)
          post.edited_at = Time.current
          remove_images(post, params[:images_to_remove])
          attach_images(post, params[:images])

          if post.save
            render json: ForumPostSerializer.render(post, current_user)
          else
            render_validation_error(post)
          end
        end

        def destroy
          post = ForumPost.find_by(id: params[:id])
          return render_not_found unless post
          return render_forbidden unless post.editable_by?(current_user)

          post.destroy!
          head :no_content
        end

        def like
          post = ForumPost.find_by(id: params[:id])
          return render_not_found unless post
          return render_own_content if post.user_id == current_user.id

          if ForumLike.exists?(user_id: current_user.id, forum_post_id: post.id)
            render_error(code: "already_liked", message: "Bu yazıya zaten Faydalı verdin.", status: :unprocessable_entity)
            return
          end

          ForumLike.create!(user: current_user, forum_post: post)
          render json: { likes_count: post.reload.likes_count, liked_by_me: true }
        end

        def unlike
          post = ForumPost.find_by(id: params[:id])
          return render_not_found unless post

          ForumLike.where(user_id: current_user.id, forum_post_id: post.id).destroy_all
          render json: { likes_count: post.reload.likes_count, liked_by_me: false }
        end

        private

        def attach_images(record, files)
          Array(files).each { |file| record.images.attach(file) }
        end

        def remove_images(record, ids)
          ids = Array(ids).map(&:to_i).reject(&:zero?)
          return if ids.empty?

          record.images_attachments.where(id: ids).each(&:purge)
        end
      end
    end
  end
end
