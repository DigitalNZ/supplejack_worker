HarvesterWorker::Application.routes.draw do

  devise_for :users, skip: :sessions

  resources :harvest_jobs, only: [:index, :create, :update, :show]
  resources :harvest_schedules, only: [:index, :create, :update, :show, :destroy]
  
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end