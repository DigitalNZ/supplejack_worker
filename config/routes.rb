HarvesterWorker::Application.routes.draw do

  devise_for :users, skip: :sessions

  resources :harvest_jobs, only: [:create, :update, :show]
  
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end