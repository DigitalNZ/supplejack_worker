Airbrake.configure do |config|
  config.api_key = ENV['AIRBRAKE_API_KEY']

  config.ignore_only = ['ActiveRecord::RecordNotFound',
                      'ActionController::RoutingError',
                      'ActionController::InvalidAuthenticityToken',
                      'CGI::Session::CookieStore::TamperedWithCookie',
                      'ActionController::UnknownHttpMethod',
                      'ActionController::UnknownAction',
                      'AbstractController::ActionNotFound',
                      'Mongoid::Errors::DocumentNotFound',
                      'ThrottleLimitError']
end
