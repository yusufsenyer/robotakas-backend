module Api
  module V1
    module Forum
      class BaseController < ApplicationController
        TOPIC_RATE_LIMIT = 5
        POST_RATE_LIMIT = 20
        RATE_WINDOW = 1.hour

        private

        def topic_rate_limited?
          return false if current_user&.admin?

          ForumTopic
            .where(user_id: current_user.id)
            .where(created_at: RATE_WINDOW.ago..)
            .count >= TOPIC_RATE_LIMIT
        end

        def post_rate_limited?
          return false if current_user&.admin?

          ForumPost
            .where(user_id: current_user.id)
            .where(created_at: RATE_WINDOW.ago..)
            .count >= POST_RATE_LIMIT
        end

        def render_rate_limited
          render_error(
            code: "rate_limited",
            message: "Çok hızlı yazıyorsun. Biraz bekleyip tekrar dene.",
            status: :too_many_requests,
          )
        end

        def render_forbidden
          render_error(
            code: "forbidden",
            message: "Bu işlemi yapamazsın.",
            status: :forbidden,
          )
        end

        def render_own_content
          render_error(
            code: "own_content",
            message: "Kendi yazına Faydalı veremezsin.",
            status: :unprocessable_entity,
          )
        end

        def paginate_with_limit(relation)
          return paginate(relation).then { |data, meta| [ data.to_a, meta ] } if params[:limit].blank?

          limit = [ [ params[:limit].to_i, 1 ].max, 50 ].min
          total = relation.count
          [
            relation.limit(limit).to_a,
            { page: 1, per_page: limit, total: total, total_pages: (total.to_f / limit).ceil }
          ]
        end
      end
    end
  end
end
