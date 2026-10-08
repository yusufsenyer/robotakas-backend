module Api
  module V1
    module Admin
      class PartsController < BaseController
        def index
          parts = Part.includes(:category, :suggested_by)

          parts = parts.where(status: params[:status]) if params[:status].present?

          if params[:q].present?
            q = params[:q].to_s.strip.downcase
            parts = parts.where(
              "LOWER(parts.code) LIKE :q OR LOWER(parts.name) LIKE :q",
              q: "%#{q}%",
            )
          end

          parts = parts.where(category_id: params[:category]) if params[:category].present?
          parts = parts.order(:code)

          data, meta = paginate(parts)

          listing_counts = Listing.where(part_id: data.map(&:id)).group(:part_id).count

          pending_ids = data.select { |p| p.status == "pending" }.map(&:id)
          pending_by_part =
            if pending_ids.any?
              Listing.where(part_id: pending_ids, status: "pending_part")
                .includes(:user)
                .group_by(&:part_id)
            else
              {}
            end

          render json: {
            parts: data.map do |part|
              pending_listings = (pending_by_part[part.id] || []).map do |listing|
                {
                  id: listing.id,
                  title: listing.title,
                  user: { id: listing.user_id, full_name: listing.user&.full_name }
                }
              end
              AdminSerializer.part(
                part,
                listing_count: listing_counts[part.id] || 0,
                pending_listings: pending_listings,
              )
            end,
            meta: meta
          }
        end

        def create
          part = Part.new(part_params.merge(status: "approved"))

          if part.save
            render json: { part: AdminSerializer.part(part, listing_count: 0) }, status: :created
          else
            render_validation_error(part)
          end
        end

        def update
          part = Part.find(params[:id])
          part.assign_attributes(part_attributes)

          if part.save
            render json: { part: AdminSerializer.part(part) }
          else
            render_validation_error(part)
          end
        end

        def approve
          part = Part.find(params[:id])
          part.assign_attributes(part_attributes)

          pending_count = part.listings.where(status: "pending_part").count

          if part.invalid?
            render_validation_error(part)
            return
          end

          part.approve!

          render json: {
            part: AdminSerializer.part(part),
            activated_listing_count: pending_count
          }
        end

        def reject
          part = Part.find(params[:id])
          reason = params[:reason].to_s.strip

          if reason.length < 5 || reason.length > 200
            render_error(
              code: "validation_failed",
              message: "Gerekçe 5–200 karakter arasında olmalı.",
              status: :unprocessable_entity,
              fields: { reason: [ "5–200 karakter arasında olmalı" ] },
            )
            return
          end

          affected = part.listings.where(status: "pending_part").count
          part.reject!(reason)

          render json: {
            part: AdminSerializer.part(part),
            affected_listing_count: affected
          }
        end

        def destroy
          part = Part.find(params[:id])
          count = part.listings.count

          if count > 0
            render_error(
              code: "part_has_listings",
              message: "Bu parçaya bağlı #{count} ilan var. Önce ilanları kaldır ya da başka parçaya taşı.",
              status: :unprocessable_entity,
            )
            return
          end

          part.destroy!
          head :no_content
        end

        private

        def part_params
          params.permit(:code, :name, :brand, :category_id, :description, specs: [ :label, :value ])
        end

        def part_attributes
          attrs = {}
          attrs[:code] = params[:code] if params.key?(:code)
          attrs[:name] = params[:name] if params.key?(:name)
          attrs[:brand] = params[:brand] if params.key?(:brand)
          attrs[:category_id] = params[:category_id] if params.key?(:category_id)
          attrs[:description] = params[:description] if params.key?(:description)
          attrs[:specs] = params[:specs] if params.key?(:specs)
          attrs
        end
      end
    end
  end
end
