module Api
  module V1
    class MeController < ApplicationController
      before_action :require_user!

      def show
        render json: UserSerializer.render(current_user, include_phone: true)
      end

      def update
        if current_user.update(me_params)
          render json: UserSerializer.render(current_user, include_phone: true)
        else
          render_validation_error(current_user)
        end
      end

      def listings
        listings = current_user.listings
          .includes(:category, :part, :user)
          .with_attached_photos
          .order(created_at: :desc)

        render json: listings.map { |listing| listing_json(listing) }
      end

      def favorites
        listings = current_user.favorite_listings
          .active
          .includes(:category, :part, :user)
          .with_attached_photos
          .order(created_at: :desc)

        favorite_ids = listings.map(&:id)

        render json: listings.map do |listing|
          ListingSerializer.list_item(listing, favorite_ids: favorite_ids)
        end
      end

      def unread_counts
        messages = Message.joins(:conversation)
          .joins("INNER JOIN listings ON listings.id = conversations.listing_id")
          .where.not(sender_id: current_user.id)
          .where(read_at: nil)
          .where(
            "conversations.buyer_id = :id OR listings.user_id = :id",
            id: current_user.id,
          )
          .count

        announcements = Announcement.published
          .where.not(id: current_user.announcement_reads.select(:announcement_id))
          .count

        notifications = current_user.notifications.unread.count

        render json: { messages: messages, announcements: announcements, notifications: notifications }
      end

      def destroy
        unless current_user.authenticate(params[:password].to_s)
          render_error(
            code: "invalid_password",
            message: "Şifre yanlış.",
            status: :unprocessable_entity,
            fields: { password: [ "yanlış şifre" ] },
          )
          return
        end

        if current_user.admin? && User.where(role: "admin").count <= 1
          render_error(
            code: "last_admin",
            message: "Son admin hesabı silinemez.",
            status: :unprocessable_entity,
          )
          return
        end

        current_user.destroy!
        reset_session
        head :no_content
      end

      private

      def me_params
        params.permit(:full_name, :city, :team_name, :phone)
      end

      def listing_json(listing)
        ListingSerializer.list_item(listing).merge(
          status: listing.status,
          removal_reason: listing.removal_reason,
          removed_at: listing.removed_at&.iso8601,
          part: listing.part ? part_with_status(listing.part) : nil,
        )
      end

      def part_with_status(part)
        ListingSerializer.part_summary(part).merge(
          status: part.status,
          reject_reason: part.reject_reason,
        )
      end
    end
  end
end
