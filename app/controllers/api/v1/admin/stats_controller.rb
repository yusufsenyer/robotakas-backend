module Api
  module V1
    module Admin
      class StatsController < BaseController
        def show
          render json: {
            active_listings: Listing.active.count,
            pending_parts: Part.where(status: "pending").count,
            open_reports: Report.open.count,
            sold_total: SiteStat.value("sold_total").to_i,
            total_users: User.count,
            total_listings: Listing.count
          }
        end
      end
    end
  end
end
