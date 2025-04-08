# --- app/controllers/admin/users_controller.rb ---
class Admin::UsersController < Admin::BaseController
  # Skip authentication for the create (registration) action
  skip_before_action :authenticate_admin_request!, only: [:create]

  # POST /admin/register
  def create
    user = User.new(user_params)

    if user.save
      # Registration successful. We won't log them in automatically here.
      # Return user info (excluding password)
      render json: { id: user.id, email: user.email, created_at: user.created_at }, status: :created
    else
      # Registration failed (e.g., validation errors)
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /admin/me (Kept from previous step)
  def me
    # @current_admin_user is set by the before_action in Admin::BaseController
    render json: { id: @current_admin_user.id, email: @current_admin_user.email }, status: :ok
  end

  private

  def user_params
    # Use strong parameters to allow only permitted attributes
    params.require(:user).permit(:email, :password, :password_confirmation)
    # If you send params without nesting under 'user', adjust accordingly:
    # params.permit(:email, :password, :password_confirmation)
  end
end
