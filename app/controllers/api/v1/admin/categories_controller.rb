module Api
  module V1
    module Admin
      class CategoriesController < BaseController
        def index
          categories = Category.order(:position, :id)
          render json: categories.map { |category| AdminSerializer.category(category) }
        end

        def create
          parent = params[:parent_id].present? ? Category.find(params[:parent_id]) : nil

          if parent && !parent.root?
            render_error(
              code: "validation_failed",
              message: "Alt kategori yalnızca bir yarışma kategorisinin altına eklenebilir.",
              status: :unprocessable_entity,
              fields: { parent_id: [ "yalnızca yarışma kategorisi altına eklenebilir" ] },
            )
            return
          end

          siblings = parent ? parent.children : Category.roots
          position =
            if params[:position].present?
              params[:position].to_i
            else
              (siblings.maximum(:position) || -1) + 1
            end

          category = Category.new(
            name: params[:name].to_s.strip,
            parent: parent,
            icon_key: params[:icon_key].presence,
            position: position,
          )

          if category.save
            render json: { category: AdminSerializer.category(category) }, status: :created
          else
            render_validation_error(category)
          end
        end

        def update
          category = Category.find(params[:id])
          category.name = params[:name] if params.key?(:name)
          category.icon_key = params[:icon_key].presence if params.key?(:icon_key)
          category.position = params[:position].to_i if params.key?(:position)

          if category.save
            render json: { category: AdminSerializer.category(category) }
          else
            render_validation_error(category)
          end
        end

        def destroy
          category = Category.find(params[:id])
          listing_count = category.listings.count
          compatible_count = ListingCompatibleCategory.where(category_id: category.id).count
          part_count = category.parts.count
          children_count = category.children.count
          total_listings = listing_count + compatible_count

          if total_listings > 0 || part_count > 0 || children_count > 0
            render_error(
              code: "category_in_use",
              message: category_in_use_message(total_listings, part_count, children_count),
              status: :unprocessable_entity,
            )
            return
          end

          category.destroy!
          head :no_content
        end

        private

        def category_in_use_message(listings, parts, children)
          items = []
          items << "#{listings} ilan" if listings > 0
          items << "#{parts} parça" if parts > 0
          items << "#{children} alt kategori" if children > 0
          "Bu kategoride #{join_tr(items)} var."
        end

        def join_tr(items)
          return items.first if items.size <= 1

          "#{items[0...-1].join(', ')} ve #{items.last}"
        end
      end
    end
  end
end
