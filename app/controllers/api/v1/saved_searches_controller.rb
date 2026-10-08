module Api
  module V1
    class SavedSearchesController < ApplicationController
      before_action :require_user!

      def index
        render json: current_user.saved_searches
          .order(created_at: :desc)
          .map { |search| serialize(search) }
      end

      def create
        clean = clean_params

        if clean.blank?
          render_error(
            code: "validation_failed",
            message: "En az bir filtre gerekli.",
            status: :unprocessable_entity,
            fields: { params: ["en az bir filtre"] },
          )
          return
        end

        existing = current_user.saved_searches.to_a.find { |s| s.params == clean }
        if existing
          render json: serialize(existing)
          return
        end

        search = current_user.saved_searches.new(
          params: clean,
          name: params[:name].to_s.strip.presence || SavedSearch.generate_name(clean),
        )

        if search.save
          render json: serialize(search), status: :created
        else
          render_validation_error(search)
        end
      end

      def destroy
        search = current_user.saved_searches.find(params[:id])
        search.destroy!
        head :no_content
      end

      private

      def clean_params
        raw = params[:params]
        return {} unless raw.respond_to?(:permit)

        raw.permit(*SavedSearch::ALLOWED_KEYS).to_h.compact_blank
      end

      def serialize(search)
        {
          id: search.id,
          name: search.name,
          params: search.params,
          created_at: search.created_at.iso8601,
        }
      end
    end
  end
end
