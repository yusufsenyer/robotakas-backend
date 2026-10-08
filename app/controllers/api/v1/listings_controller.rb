module Api
  module V1
    class ListingsController < ApplicationController
      before_action :require_user!,
        only: [:create, :update, :destroy, :remove, :favorite, :unfavorite]

      def index
        listings = Listing.active

        listings = apply_filters(listings)
        listings = apply_sort(listings)

        listings = listings
          .includes(:user, :part, category: :parent)
          .with_attached_photos

        data, meta = paginate(listings)

        favorite_ids =
          if current_user
            current_user.favorites.where(listing_id: data.map(&:id)).pluck(:listing_id)
          end

        render json: {
          listings: data.map { |l| ListingSerializer.list_item(l, favorite_ids: favorite_ids) },
          meta: meta,
        }
      end

      def show
        listing = Listing
          .includes(:user, :part, :compatible_categories, category: :parent)
          .with_attached_photos
          .with_attached_video
          .find(params[:id])

        unless listing.active? || listing.owner?(current_user) || current_user&.admin?
          render_not_found
          return
        end

        listing.increment!(:view_count) unless listing.owner?(current_user)

        render json: ListingSerializer.detail(listing, current_user: current_user)
      end

      def create
        if show_phone_requested? && current_user.phone.blank?
          render_error(
            code: "phone_required",
            message: "İlanda telefonu göstermek için profiline telefon ekle.",
            status: :unprocessable_entity,
            fields: { phone: ["profilinde telefon yok"] },
          )
          return
        end

        if Array(params[:photos]).size > 10
          render_error(
            code: "validation_failed",
            message: "En fazla 10 fotoğraf yüklenebilir.",
            status: :unprocessable_entity,
            fields: { photos: ["en fazla 10 fotoğraf yüklenebilir"] },
          )
          return
        end

        listing = current_user.listings.new(listing_params)
        listing.show_phone = show_phone_requested?
        apply_part(listing, force: true)
        attach_files(listing)

        if listing.save
          listing.compatible_category_ids = compatible_category_ids
          render json: ListingSerializer.detail(listing, current_user: current_user), status: :created
        else
          render_validation_error(listing)
        end
      end

      def update
        listing = load_owned_listing
        return if listing.nil?

        if listing.status == "removed"
          render_error(
            code: "listing_removed",
            message: "Kaldırılmış bir ilan düzenlenemez.",
            status: :unprocessable_entity,
          )
          return
        end

        if show_phone_requested? && current_user.phone.blank?
          render_error(
            code: "phone_required",
            message: "İlanda telefonu göstermek için profiline telefon ekle.",
            status: :unprocessable_entity,
            fields: { phone: ["profilinde telefon yok"] },
          )
          return
        end

        listing.assign_attributes(listing_params)
        listing.show_phone = show_phone_requested?
        apply_part(listing, force: false)
        remove_photos(listing)
        remove_video(listing)
        attach_files(listing)

        if listing.save
          listing.compatible_category_ids = compatible_category_ids if params.key?(:compatible_category_ids)
          render json: ListingSerializer.detail(listing, current_user: current_user)
        else
          render_validation_error(listing)
        end
      end

      def destroy
        listing = load_owned_listing
        return if listing.nil?

        listing.destroy!
        head :no_content
      end

      def remove
        listing = Listing.find(params[:id])

        unless listing.owner?(current_user)
          render_error(code: "forbidden", message: "Bu işlemi yapamazsın.", status: :forbidden)
          return
        end

        reason = params[:reason].to_s
        unless %w[sold withdrawn].include?(reason)
          render_error(code: "bad_request", message: "reason sold ya da withdrawn olmalı.", status: :bad_request)
          return
        end

        if params[:delete].to_s == "true"
          SiteStat.add!("sold_total") if reason == "sold"
          listing.destroy!
          head :no_content
        else
          listing.remove!(reason: reason)
          render json: ListingSerializer.detail(listing, current_user: current_user)
        end
      end

      def favorite
        listing = Listing.active.find(params[:id])
        listing.favorites.find_or_create_by!(user: current_user)
        render json: { favorited: true }
      end

      def unfavorite
        listing = Listing.find(params[:id])
        listing.favorites.where(user: current_user).destroy_all
        render json: { favorited: false }
      end

      private

      def apply_sort(listings)
        case params[:sort]
        when "price_asc"
          listings.order(price: :asc, published_at: :desc)
        when "price_desc"
          listings.order(price: :desc, published_at: :desc)
        when "newest"
          listings.order(published_at: :desc)
        else
          smart_sort(listings)
        end
      end

      def smart_sort(listings)
        q = params[:q].to_s.strip.downcase
        return listings.order(published_at: :desc) if q.blank?

        rank_sql = ActiveRecord::Base.sanitize_sql_array(
          [
            "CASE WHEN LOWER(parts.code) = ? THEN 0 " \
            "WHEN LOWER(parts.code) LIKE ? THEN 1 " \
            "WHEN LOWER(listings.title) LIKE ? THEN 2 ELSE 3 END",
            q,
            "#{q}%",
            "%#{q}%",
          ],
        )

        listings.order(Arel.sql(rank_sql)).order(published_at: :desc)
      end

      def apply_filters(listings)
        listings = listings.left_joins(:part)

        if params[:q].present?
          q = "%#{params[:q].to_s.strip.downcase}%"
          listings = listings.where(
            "LOWER(listings.title) LIKE :q OR LOWER(listings.description) LIKE :q " \
            "OR LOWER(parts.code) LIKE :q OR LOWER(parts.name) LIKE :q",
            q: q,
          )
        end

        if params[:category_id].present? || params[:category].present?
          category =
            if params[:category_id].present?
              Category.find_by(id: params[:category_id])
            else
              Category.find_by(slug: params[:category])
            end

          if category
            ids = category.descendant_ids
            listings = listings.where(
              "listings.category_id IN (:ids) OR listings.id IN " \
              "(SELECT listing_id FROM listing_compatible_categories WHERE category_id = :category_id)",
              ids: ids,
              category_id: category.id,
            )
          else
            listings = listings.none
          end
        end

        if params[:compatible_category_id].present? || params[:compatible_category].present?
          category =
            if params[:compatible_category_id].present?
              Category.find_by(id: params[:compatible_category_id])
            else
              Category.find_by(slug: params[:compatible_category])
            end

          if category
            listings = listings.where(
              "listings.id IN (SELECT listing_id FROM listing_compatible_categories WHERE category_id = ?)",
              category.id,
            )
          else
            listings = listings.none
          end
        end

        if params[:part].present?
          part = Part.find_by(slug: params[:part])
          listings = listings.where(part_id: part ? part.id : -1)
        end

        if %w[new used].include?(params[:condition])
          listings = listings.where(condition: params[:condition])
        end

        listings = listings.where("price >= ?", params[:min_price].to_i) if params[:min_price].present?
        listings = listings.where("price <= ?", params[:max_price].to_i) if params[:max_price].present?
        listings = listings.where("LOWER(city) = ?", params[:city].to_s.strip.downcase) if params[:city].present?

        listings
      end

      def listing_params
        params.permit(
          :title,
          :description,
          :condition,
          :price,
          :quantity,
          :seasons_used,
          :category_id,
          :city,
          :district,
        )
      end

      def show_phone_requested?
        ["true", "1", "on"].include?(params[:show_phone].to_s)
      end

      def apply_part(listing, force:)
        return unless force || params.key?(:part_id) || params.key?(:generic)

        if params[:generic].to_s == "true" || params[:part_id].blank?
          listing.part = nil
        else
          listing.part = Part.find_by(id: params[:part_id])
        end
      end

      def attach_files(listing)
        Array(params[:photos]).each do |photo|
          listing.photos.attach(photo)
        end

        listing.video.attach(params[:video]) if params[:video].present?
      end

      def remove_photos(listing)
        ids = Array(params[:photos_to_remove]).map(&:to_i).reject(&:zero?)
        return if ids.empty?

        listing.photos_attachments.where(id: ids).each(&:purge)
      end

      def remove_video(listing)
        return unless ["true", "1", "on"].include?(params[:video_to_remove].to_s)

        listing.video.purge
      end

      def compatible_category_ids
        ids = Array(params[:compatible_category_ids]).map(&:to_i).reject(&:zero?).uniq
        Category.where(id: ids).pluck(:id)
      end

      def load_owned_listing
        listing = Listing.find(params[:id])
        return listing if listing.owner?(current_user) || current_user&.admin?

        render_error(code: "forbidden", message: "Bu işlemi yapamazsın.", status: :forbidden)
        nil
      end
    end
  end
end
