module Api
  module V1
    module Admin
      class ListingsController < BaseController
        def index
          listings = Listing.left_joins(:part, :user)
            .includes(:user, :part, category: :parent)

          if params[:q].present?
            q = "%#{params[:q].to_s.strip.downcase}%"
            listings = listings.where(
              "LOWER(listings.title) LIKE :q OR LOWER(parts.code) LIKE :q " \
              "OR LOWER(users.full_name) LIKE :q OR LOWER(users.email) LIKE :q",
              q: q,
            )
          end

          listings = listings.where(status: params[:status]) if params[:status].present?

          if params[:category].present?
            category = find_category(params[:category])
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

          if params[:user].present?
            q = "%#{params[:user].to_s.strip.downcase}%"
            listings = listings.where(
              "LOWER(users.full_name) LIKE :q OR LOWER(users.email) LIKE :q",
              q: q,
            )
          end

          listings = listings.order(created_at: :desc)
          data, meta = paginate(listings)

          report_counts = Report.open
            .where(listing_id: data.map(&:id))
            .group(:listing_id)
            .count

          render json: {
            listings: data.map do |listing|
              AdminSerializer.listing(listing, open_report_count: report_counts[listing.id] || 0)
            end,
            meta: meta
          }
        end

        def destroy
          Listing.find(params[:id]).destroy!
          head :no_content
        end

        def bulk_destroy
          ids = Array(params[:ids]).map(&:to_i).reject(&:zero?).uniq

          if ids.empty? || ids.size > 50
            render_error(
              code: "validation_failed",
              message: "En az 1, en fazla 50 ilan seç.",
              status: :unprocessable_entity,
              fields: { ids: [ "en fazla 50 ilan" ] },
            )
            return
          end

          deleted = 0
          Listing.transaction do
            Listing.where(id: ids).find_each do |listing|
              listing.destroy!
              deleted += 1
            end
          end

          render json: { deleted_count: deleted }
        end

        private

        def find_category(value)
          if value.to_s.match?(/\A\d+\z/)
            Category.find_by(id: value)
          else
            Category.find_by(slug: value)
          end
        end
      end
    end
  end
end
