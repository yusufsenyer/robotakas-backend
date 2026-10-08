module Api
  module V1
    class ReportsController < ApplicationController
      before_action :require_user!

      def create
        listing = Listing.find(params[:id])

        if listing.owner?(current_user)
          render_error(
            code: "own_listing",
            message: "Kendi ilanını bildiremezsin.",
            status: :unprocessable_entity,
          )
          return
        end

        unless Report::REASONS.include?(params[:reason].to_s)
          render_error(
            code: "validation_failed",
            message: "Geçerli bir neden seç.",
            status: :unprocessable_entity,
            fields: { reason: ["geçerli bir neden seç"] },
          )
          return
        end

        if params[:details].to_s.length > 500
          render_error(
            code: "validation_failed",
            message: "Açıklama en fazla 500 karakter olabilir.",
            status: :unprocessable_entity,
            fields: { details: ["en fazla 500 karakter"] },
          )
          return
        end

        if listing.reports.open.where(reporter: current_user).exists?
          render_error(
            code: "already_reported",
            message: "Bu ilanı zaten bildirdin.",
            status: :unprocessable_entity,
          )
          return
        end

        report = listing.reports.new(
          reporter: current_user,
          reason: params[:reason].to_s,
          details: params[:details].to_s,
        )

        if report.save
          render json: serialize(report), status: :created
        else
          render_validation_error(report)
        end
      end

      private

      def serialize(report)
        {
          id: report.id,
          listing_id: report.listing_id,
          reason: report.reason,
          details: report.details,
          status: report.status,
          created_at: report.created_at.iso8601,
        }
      end
    end
  end
end
