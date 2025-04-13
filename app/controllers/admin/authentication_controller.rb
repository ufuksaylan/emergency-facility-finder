class Admin::AuthenticationController < Admin::BaseController
  skip_before_action :authenticate_admin_request!, only: [:login]

  # POST /admin/login
  def login
    email = params[:email] || params.dig(:authentication, :email)
    password = params[:password] || params.dig(:authentication, :password)

    user = User.find_by(email: email)

    if user&.authenticate(password)
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

    exp_time = decoded_token && decoded_token[:exp]

    render json: { token: token, exp: decoded_token[:exp], user: { id: user.id, email: user.email } }, status: :ok
  end
end
