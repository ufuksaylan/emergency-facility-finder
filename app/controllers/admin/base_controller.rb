class Admin::BaseController < ApplicationController
  before_action :authenticate_admin_request!

  attr_reader :current_admin_user # Make current user accessible

  private

  def authenticate_admin_request!
    token = extract_token_from_header
    decoded_token = JsonWebToken.decode(token) if token

    find_current_user(decoded_token) if decoded_token

    render_unauthorized unless @current_admin_user
  end

  def extract_token_from_header
    request.headers["Authorization"]&.split(" ")&.last
  end

  def find_current_user(decoded_token)
    @current_admin_user = User.find_by(id: decoded_token[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_unauthorized # User ID in token doesn't exist
  end

  def render_unauthorized(message = "Not Authorized")
    render json: { error: message }, status: :unauthorized
  end
end
