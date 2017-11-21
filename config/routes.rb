# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

HarvesterWorker::Application.routes.draw do
  resources :abstract_jobs, only: [:index] do
    get :jobs_since, on: :collection
  end
  resources :harvest_jobs, only: %i[create update show index]
  resources :enrichment_jobs, only: %i[create update show]
  resources :harvest_schedules, only: %i[index create update show destroy] do
    get :next, on: :collection
  end
  resources :previews, only: [:create, :show]

  resources :link_check_jobs, only: [:create, :show]
  resources :link_check_rules
  resources :collection_statistics, only: [:index]

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
