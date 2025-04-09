# app/controllers/admin/complaints_controller.rb
class Admin::ComplaintsController < Admin::BaseController
  before_action :set_complaint, only: [ :show, :update, :destroy ]

  # GET /admin/complaints
  def index
    # Basic index, consider adding pagination and filtering (e.g., by status)
    @complaints = Complaint.order(created_at: :desc) # Show newest first
    render json: @complaints
  end

  # GET /admin/complaints/:id
  def show
    render json: @complaint, include: { facility: { only: [ :osm_id, :name ] } }
  end

  # PATCH/PUT /admin/complaints/:id
  def update
    original_status = @complaint.status
    new_status = complaint_params[:status]

    if @complaint.update(complaint_params)
      # Automatically set/unset resolved_at based on status change
      update_resolved_at(original_status, new_status)

      render json: @complaint
    else
      render json: { errors: @complaint.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /admin/complaints/:id
  def destroy
    if @complaint.destroy
      head :no_content # Standard successful deletion response for APIs
    else
      # Less common, but handle potential destroy failures (e.g., callbacks)
      render json: { errors: @complaint.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_complaint
    @complaint = Complaint.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Complaint not found" }, status: :not_found
  end

  def complaint_params
    # Permit status and resolution_notes for admin updates
    params.require(:complaint).permit(:status, :resolution_notes)
  end

  def update_resolved_at(original_status, new_status)
    terminal_statuses = %w[resolved rejected]
    was_terminal = terminal_statuses.include?(original_status)
    is_terminal = terminal_statuses.include?(new_status)

    if !was_terminal && is_terminal
      # Complaint is entering a terminal state
      @complaint.update_column(:resolved_at, Time.current) # Use update_column to skip validations/callbacks if needed
    elsif was_terminal && !is_terminal
      @complaint.update_column(:resolved_at, nil)
    end
    # No change needed if moving between terminal states or between non-terminal states
  end
end
