module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :require_user!

      def index
        limit = params[:limit].present? ? [ [ params[:limit].to_i, 1 ].max, 50 ].min : 20
        notes = current_user.notifications
          .includes(:actor, :forum_topic)
          .recent
          .limit(limit)

        render json: { notifications: notes.map { |note| NotificationSerializer.render(note) } }
      end

      def read
        current_user.notifications.unread.update_all(read_at: Time.current)
        head :no_content
      end
    end
  end
end
