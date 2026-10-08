module Api
  module V1
    class CategoriesController < ApplicationController
      def index
        counts = Listing.active.group(:category_id).count
        roots = Category.roots

        render json: roots.map { |root| CategorySerializer.render_node(root, counts) }
      end
    end
  end
end
