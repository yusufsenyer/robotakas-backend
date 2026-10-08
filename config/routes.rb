Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      get "public_stats", to: "public_stats#show"

      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"

      get "me", to: "me#show"
      patch "me", to: "me#update"
      delete "me", to: "me#destroy"
      get "me/listings", to: "me#listings"
      get "me/favorites", to: "me#favorites"
      get "me/unread_counts", to: "me#unread_counts"

      get "saved_searches", to: "saved_searches#index"
      post "saved_searches", to: "saved_searches#create"
      delete "saved_searches/:id", to: "saved_searches#destroy"

      get "categories", to: "categories#index"

      get "conversations", to: "conversations#index"
      post "conversations", to: "conversations#create"
      get "conversations/:id", to: "conversations#show"
      get "conversations/:id/messages", to: "conversations#messages"
      post "conversations/:id/messages", to: "conversations#create_message"

      get "announcements", to: "announcements#index"
      post "announcements/read", to: "announcements#read"

      get "notifications", to: "notifications#index"
      post "notifications/read", to: "notifications#read"

      post "link_previews", to: "link_previews#create"

      get "parts", to: "parts#index"
      get "parts/popular", to: "parts#popular"
      post "parts", to: "parts#create"
      get "parts/:slug", to: "parts#show"

      get "search/suggestions", to: "search#suggestions"

      get "listings", to: "listings#index"
      post "listings", to: "listings#create"
      get "listings/:id", to: "listings#show"
      patch "listings/:id", to: "listings#update"
      delete "listings/:id", to: "listings#destroy"
      post "listings/:id/remove", to: "listings#remove"
      post "listings/:id/favorite", to: "listings#favorite"
      delete "listings/:id/favorite", to: "listings#unfavorite"
      post "listings/:id/reports", to: "reports#create"

      namespace :forum do
        get "boards", to: "boards#index"
        get "boards/:slug", to: "boards#show"

        get "topics", to: "topics#index"
        post "topics", to: "topics#create"
        get "topics/solved_recent", to: "topics#solved_recent"
        get "topics/:id", to: "topics#show"
        patch "topics/:id", to: "topics#update"
        delete "topics/:id", to: "topics#destroy"
        get "topics/:id/posts", to: "topics#posts"
        post "topics/:id/posts", to: "posts#create"
        post "topics/:id/like", to: "topics#like"
        delete "topics/:id/like", to: "topics#unlike"
        post "topics/:id/solution", to: "topics#solution"
        delete "topics/:id/solution", to: "topics#destroy_solution"

        patch "posts/:id", to: "posts#update"
        delete "posts/:id", to: "posts#destroy"
        post "posts/:id/like", to: "posts#like"
        delete "posts/:id/like", to: "posts#unlike"
      end

      namespace :admin do
        get "stats", to: "stats#show"

        get "parts", to: "parts#index"
        post "parts", to: "parts#create"
        patch "parts/:id", to: "parts#update"
        post "parts/:id/approve", to: "parts#approve"
        post "parts/:id/reject", to: "parts#reject"
        delete "parts/:id", to: "parts#destroy"

        get "listings", to: "listings#index"
        delete "listings/:id", to: "listings#destroy"
        post "listings/bulk_destroy", to: "listings#bulk_destroy"

        get "reports", to: "reports#index"
        post "reports/:id/resolve", to: "reports#resolve"
        post "reports/:id/dismiss", to: "reports#dismiss"

        get "announcements", to: "announcements#index"
        post "announcements", to: "announcements#create"
        delete "announcements/:id", to: "announcements#destroy"

        get "categories", to: "categories#index"
        post "categories", to: "categories#create"
        patch "categories/:id", to: "categories#update"
        delete "categories/:id", to: "categories#destroy"
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
