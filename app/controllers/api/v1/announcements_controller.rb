module Api
  module V1
    class AnnouncementsController < ApplicationController
      before_action :require_user!

      def index
        announcements = Announcement.published.limit(20)
        read_ids = current_user.announcement_reads
          .where(announcement_id: announcements.map(&:id))
          .pluck(:announcement_id)

        render json: announcements.map { |a| AnnouncementSerializer.render(a, read_ids) }
      end

      def read
        ids = Announcement.published.pluck(:id)
        existing = current_user.announcement_reads
          .where(announcement_id: ids)
          .pluck(:announcement_id)

        (ids - existing).each do |id|
          current_user.announcement_reads.find_or_create_by!(announcement_id: id)
        end

        head :no_content
      end
    end
  end
end
