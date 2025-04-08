class Admin::DashboardController < Admin::BaseController
  def index
    render json: {
      message: "Admin Dashboard Access Granted",
      admin_email: @current_admin_user.email, # Example usage
      data_fetched_at: Time.current
    }
  end
end