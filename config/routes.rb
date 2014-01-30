HarvesterWorker::Application.routes.draw do

  devise_for :users, skip: :sessions

  resources :abstract_jobs, only: [:index] do
    get :jobs_since, on: :collection
  end
  resources :harvest_jobs, only: [:create, :update, :show, :index]
  resources :enrichment_jobs, only: [:create, :update, :show]
  resources :harvest_schedules, only: [:index, :create, :update, :show, :destroy] do
    get :next, on: :collection
  end
  resources :previews, only: [:create, :show]
  
  resources :link_check_jobs, only: [:create, :show]
  resources :link_check_rules
  resources :collection_statistics, only: [:index]
  
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end