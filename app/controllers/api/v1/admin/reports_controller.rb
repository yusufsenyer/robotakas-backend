module Api
  module V1
    module Admin
      class ReportsController < BaseController
        def index
          reports = Report.includes(:reporter, listing: :user)
          reports = reports.where(status: params[:status]) if params[:status].present?
          reports = reports.order(created_at: :desc)

          data, meta = paginate(reports)

          open_counts = Report.open
            .where(listing_id: data.map(&:listing_id).uniq)
            .group(:listing_id)
            .count

          render json: {
            reports: data.map do |report|
              AdminSerializer.report(
                report,
                listing_open_report_count: open_counts[report.listing_id] || 0,
              )
            end,
            meta: meta,
          }
        end

        def resolve
          close_report("resolved")
        end

        def dismiss
          close_report("dismissed")
        end

        private

        def close_report(status)
          report = Report.find(params[:id])

          unless report.status == "open"
            render_error(
              code: "report_closed",
              message: "Bu şikayet zaten kapatılmış.",
              status: :unprocessable_entity,
            )
            return
          end

          report.update!(status: status, resolved_by: current_user, resolved_at: Time.current)
          render json: { report: AdminSerializer.report(report) }
        end
      end
    end
  end
end
