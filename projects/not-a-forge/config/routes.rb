Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Public pages
  root "pages#home"
  get "pages/home"

  # Registration routes
  get "signup", to: "registrations#new", as: :signup
  post "signup", to: "registrations#create"

  # Dashboard
  resources :repositories

  # Settings namespace
  namespace :settings do
    resource :profile, only: [:show, :edit, :update, :destroy]
    resources :tokens
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
