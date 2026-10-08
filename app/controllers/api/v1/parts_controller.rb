module Api
  module V1
    class PartsController < ApplicationController
      before_action :require_user!, only: [ :create ]

      def index
        parts = Part.approved.includes(:category)

        if params[:q].present?
          q = params[:q].to_s.strip
          parts = parts.where("LOWER(code) LIKE :q OR LOWER(name) LIKE :q", q: "%#{q.downcase}%")
        end

        if params[:category_id].present?
          parts = parts.where(category_id: params[:category_id])
        elsif params[:category].present?
          category = Category.find_by(slug: params[:category])
          parts = category ? parts.where(category_id: category.descendant_ids) : parts.none
        end

        parts, meta = paginate(parts.order(:code))
        counts = Listing.active.where(part_id: parts.map(&:id)).group(:part_id).count

        render json: {
          parts: parts.map { |part| PartSerializer.summary(part, listing_count: counts[part.id] || 0) },
          meta: meta
        }
      end

      def popular
        parts = Part.approved
          .includes(:category)
          .left_joins(:listings)
          .where(listings: { status: "active" })
          .group("parts.id")
          .order("COUNT(listings.id) DESC", "parts.code ASC")
          .limit(8)

        min_prices = Listing.active
          .where(part_id: parts.map(&:id))
          .group(:part_id)
          .minimum(:price)

        render json: {
          parts: parts.map do |part|
            PartSerializer.summary(part, min_price: min_prices[part.id])
          end
        }
      end

      def show
        part = Part.approved.find_by!(slug: params[:slug])
        render json: PartSerializer.detail(part)
      end

      def create
        code = params[:code].to_s.strip.upcase
        slug = code.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")

        existing = Part.find_by(code: code)

        if existing&.approved?
          render_error(
            code: "part_exists",
            message: "Bu parça zaten katalogda.",
            status: :unprocessable_entity,
            fields: { slug: [ existing.slug ] },
          )
          return
        end

        if existing&.pending?
          render json: PartSerializer.summary(existing)
          return
        end

        part = Part.new(part_params.merge(code: code, slug: slug))
        part.suggested_by = current_user
        part.status = "pending"

        if part.save
          render json: PartSerializer.summary(part), status: :created
        else
          render_validation_error(part)
        end
      end

      private

      def part_params
        params.permit(:name, :brand, :category_id)
      end
    end
  end
end
