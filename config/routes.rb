Rails.application.routes.draw do
  devise_for :users
  root to: "beers#home"
  resources :users
  resources :beers, only: [:index, :show] do
    resources :reviews, only: [:new, :edit, :update]
    resources :favorites, only: [:new, :create]
  end

  namespace :api do
    namespace :v1 do
       resources :beers
       resources :reviews
       resources :users
     end
  end


  resources :favorites, only: [:destroy]
  resources :reviews, only: [:show, :destroy] do
    resources :votes
  end
end
