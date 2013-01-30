class User
  include Mongoid::Document

  devise :token_authenticatable

  ## Token authenticatable
  field :authentication_token, type: String

  before_save :ensure_authentication_token
end