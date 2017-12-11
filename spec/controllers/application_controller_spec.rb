# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController do
  controller do

    before_action :authenticate_user!

    def index
      render body: 'success'
    end
  end

  describe '#authenticate_user!' do
    it 'returns a status 200 with a valid token' do
      request.headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"
      get :index
      expect(response.status).to eq 200
      expect(response.body).to eq 'success'
    end

    it 'returns a 401 with an invalid token' do
      request.headers['Authorization'] = 'Token token=somerandomkey'
      get :index
      expect(response.status).to eq 401
      expect(response.body).to eq "HTTP Token: Access denied.\n"
    end
  end
end
