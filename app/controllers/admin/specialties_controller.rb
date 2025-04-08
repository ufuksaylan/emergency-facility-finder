class Admin::SpecialtiesController < Admin::BaseController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found_response

  def index
    @specialties = Specialty.order(:name)
    render json: @specialties.as_json
  end

end
