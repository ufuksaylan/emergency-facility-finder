require 'jwt'

class JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base.to_s
  DEFAULT_EXPIRATION = 24.hours.from_now

  def self.encode(payload, exp = DEFAULT_EXPIRATION)
    payload[:exp] = exp.to_i
    # Ensure user_id is the primary identifier in the payload
    JWT.encode(payload.reverse_merge(user_id: nil), SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end