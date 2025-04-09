class ComplaintsController < ApplicationController
  before_action :set_facility

  # POST /facilities/:facility_id/complaints
  def create
    @complaint = @facility.complaints.build(complaint_params)

    if @complaint.save
      render json: @complaint, status: :created # Respond with the created complaint object
    else
      render json: { errors: @complaint.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_facility
    @facility = Facility.find(params[:facility_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Facility not found" }, status: :not_found
  end

  def complaint_params
    # Only permit the description from public submissions
    params.require(:complaint).permit(:description)
  end
end