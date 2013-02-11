HarvesterWorker::Application.routes.draw do

  devise_for :users, skip: :sessions

  resources :harvest_jobs, only: [:index, :create, :update, :show]
  
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end