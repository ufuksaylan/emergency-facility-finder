class Admin::AuthenticationController < Admin::BaseController
  skip_before_action :authenticate_admin_request!, only: [:login]

  # POST /admin/login
  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      issue_token(user)
    else
      render_unauthorized("Invalid email or password")
    end
  end

  private

  def issue_token(user)
    payload = { user_id: user.id, email: user.email, issued_at: Time.now.to_i }
    token = JsonWebToken.encode(payload)
    decoded_token = JsonWebToken.decode(token)

    render json: { token: token, exp: decoded_token[:exp], user: { id: user.id, email: user.email } }, status: :ok
  end
end
