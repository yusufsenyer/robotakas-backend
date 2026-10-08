module Api
  module V1
    class PublicStatsController < ApplicationController
      def show
        render json: {
          active_listings: Listing.active.count,
          approved_parts: Part.approved.count,
          competitions: Category.roots.count,
          sold_total: SiteStat.value("sold_total").to_i,
        }
      end
    end
  end
end
