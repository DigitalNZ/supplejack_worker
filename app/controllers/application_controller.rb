class ApplicationController < ActionController::API
  def authenticate_user!
    true
  end

  def current_user
    User.first
  end
end
