module Api
  module V1
    class LinkPreviewsController < ApplicationController
      MAX_URLS = 10
      MAX_LENGTH = 300
      ALLOWED_HOSTS = [ ENV["SITE_HOST"], "localhost", "127.0.0.1" ].compact.freeze

      def create
        urls = Array(params[:urls]).map(&:to_s).first(MAX_URLS)
        result = urls.each_with_object({}) { |url, acc| acc[url] = resolve(url) }
        render json: result
      end

      private

      def resolve(raw)
        url = raw.to_s.strip
        return nil if url.blank? || url.length > MAX_LENGTH

        path = extract_path(url)
        return nil if path.nil?

        if (match = path.match(%r{\A/ilan/(\d+)\z}))
          listing_preview(match[1].to_i)
        elsif (match = path.match(%r{\A/parca/([A-Za-z0-9\-_]+)\z}))
          part_preview(match[1])
        end
      end

      def extract_path(raw)
        if raw.start_with?("/")
          return nil if raw.start_with?("//")

          raw.split("?").first.split("#").first
        else
          uri = URI.parse(raw)
          return nil unless %w[http https].include?(uri.scheme) && ALLOWED_HOSTS.include?(uri.host)

          uri.path
        end
      rescue URI::InvalidURIError
        nil
      end

      def listing_preview(id)
        listing = Listing.active.find_by(id: id)
        return { type: "missing" } unless listing

        {
          type: "listing",
          id: listing.id,
          title: listing.title,
          price: listing.price,
          condition: listing.condition,
          city: listing.city,
          cover_photo_url: ListingSerializer.cover_photo_url(listing),
          category_icon_key: listing.category.icon_key
        }
      end

      def part_preview(slug)
        part = Part.approved.find_by(slug: slug)
        return { type: "missing" } unless part

        active = part.listings.active
        {
          type: "part",
          code: part.code,
          slug: part.slug,
          name: part.name,
          brand: part.brand,
          listing_count: active.count,
          min_price: active.minimum(:price)
        }
      end
    end
  end
end
