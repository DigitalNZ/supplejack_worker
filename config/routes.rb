# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resources :abstract_jobs, only: [:index] do
    get :jobs_since, on: :collection
  end
  resources :harvest_jobs, only: %i[create update show index]
  resources :enrichment_jobs, only: %i[create update show]
  resources :harvest_schedules, only: %i[index create update show destroy] do
    get :next, on: :collection
  end
  resources :previews, only: %i[create show]

  resources :link_check_jobs, only: %i[create show]
  resources :link_check_rules
  resources :collection_statistics, only: [:index]

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  get :status, to: proc { [200, { 'Cache-Control' => 'no-store, must-revalidate, private, max-age=0' }, ['ok']] }
end
