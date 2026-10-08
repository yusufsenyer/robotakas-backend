# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.
#
# The frontend normally reaches the API through a same-origin Next.js rewrite,
# so CORS is only needed for direct cross-origin calls. Add production origins
# via CORS_ORIGINS (comma-separated); by default only localhost is allowed.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*[
      "localhost:3000",
      "127.0.0.1:3000",
      *ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)
    ])

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true
  end
end
