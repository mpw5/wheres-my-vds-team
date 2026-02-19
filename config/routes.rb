Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # API for GitHub Action scraper
  namespace :api do
    get 'startlists', to: 'startlists#index'
    put 'startlists', to: 'startlists#update'
  end

  # Defines the root path route ("/")
  root 'teams#index'
end
