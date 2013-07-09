HarvesterWorker::Application.routes.draw do

  devise_for :users, skip: :sessions

  resources :abstract_jobs, only: [:index]
  resources :harvest_jobs, only: [:create, :update, :show, :index]
  resources :enrichment_jobs, only: [:create, :update, :show]
  resources :harvest_schedules, only: [:index, :create, :update, :show, :destroy]
  resources :previews, only: [:create]
  
  resources :link_check_jobs, only: [:create, :show]
  resources :collection_rules, only: [:show]
  
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end