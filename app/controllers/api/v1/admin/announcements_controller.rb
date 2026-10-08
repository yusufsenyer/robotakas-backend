module Api
  module V1
    module Admin
      class AnnouncementsController < BaseController
        def index
          announcements = Announcement.order(published_at: :desc)
          render json: announcements.map { |a| AdminSerializer.announcement(a) }
        end

        def create
          announcement = Announcement.new(
            title: params[:title].to_s.strip,
            body: params[:body].to_s.strip,
            admin: current_user,
            published_at: Time.current,
          )

          if announcement.save
            render json: { announcement: AdminSerializer.announcement(announcement) }, status: :created
          else
            render_validation_error(announcement)
          end
        end

        def destroy
          Announcement.find(params[:id]).destroy!
          head :no_content
        end
      end
    end
  end
end
