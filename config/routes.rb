HarvesterWorker::Application.routes.draw do

  resources :harvest_jobs, only: [:create, :update, :show]
  
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
