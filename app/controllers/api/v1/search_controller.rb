module Api
  module V1
    class SearchController < ApplicationController
      def suggestions
        q = params[:q].to_s.strip

        if q.length < 2
          render json: { parts: [], listings: [], categories: [] }
          return
        end

        render json: {
          parts: suggest_parts(q),
          listings: suggest_listings(q),
          categories: suggest_categories(q)
        }
      end

      private

      def suggest_parts(q)
        like = "%#{q.downcase}%"
        prefix = "#{q.downcase}%"

        prefix_order = Part.sanitize_sql_array(
          [ "CASE WHEN LOWER(code) LIKE ? THEN 0 ELSE 1 END", prefix ]
        )

        parts = Part.approved
          .where("LOWER(code) LIKE :like OR LOWER(name) LIKE :like", like: like)
          .order(Arel.sql(prefix_order), :code)
          .limit(5)

        counts = Listing.active.where(part_id: parts.map(&:id)).group(:part_id).count

        parts.map do |part|
          {
            code: part.code,
            slug: part.slug,
            name: part.name,
            brand: part.brand,
            listing_count: counts[part.id] || 0
          }
        end
      end

      def suggest_listings(q)
        like = "%#{q.downcase}%"

        listings = Listing.active
          .left_joins(:part)
          .where(
            "LOWER(listings.title) LIKE :like OR LOWER(listings.description) LIKE :like " \
            "OR LOWER(parts.code) LIKE :like OR LOWER(parts.name) LIKE :like",
            like: like,
          )
          .order(published_at: :desc)
          .limit(5)

        listings.map do |listing|
          {
            id: listing.id,
            title: listing.title,
            price: listing.price,
            part_code: listing.part&.code
          }
        end
      end

      def suggest_categories(q)
        like = "%#{q.downcase}%"

        Category.where("LOWER(name) LIKE :like", like: like)
          .order(:position, :id)
          .limit(5)
          .map do |category|
            {
              id: category.id,
              name: category.name,
              slug: category.slug,
              path: category.path
            }
          end
      end
    end
  end
end
