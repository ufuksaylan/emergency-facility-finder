class Admin::FacilitiesController < Admin::BaseController
  before_action :set_facility_by_osm_id, only: [:show, :update, :destroy]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found_response

  def index
    @facilities = Facility.includes(:specialties).order(:name)
    render json: @facilities.as_json(include: :specialties)
  end

  def show
    render json: @facility.as_json(include: :specialties)
  end

  def create
    core_params = facility_core_params
    association_params = facility_association_params

    @facility = Facility.new(core_params)
    set_location_from_params(core_params)

    if @facility.save
      update_specialties(association_params[:specialty_ids])
      render json: @facility.as_json(include: :specialties), status: :created
    else
      render json: { errors: @facility.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    core_params = facility_core_params
    association_params = facility_association_params

    set_location_from_params(core_params)

    @facility.assign_attributes(core_params)

    if @facility.save
      update_specialties(association_params[:specialty_ids]) if association_params.key?(:specialty_ids)
      render json: @facility.as_json(include: :specialties)
    else
      render json: { errors: @facility.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @facility.destroy
      head :no_content
    else
      error_message = @facility.errors.full_messages.join(', ')
      render json: { errors: ["Failed to delete facility: #{error_message}"] }, status: :internal_server_error
    end
  end

  private

  def set_facility_by_osm_id
    @facility = Facility.includes(:specialties).find_by!(osm_id: params[:osm_id])
  end

  def core_facility_attributes
    [
      :name, :facility_type, :street, :house_number, :city, :postcode,
      :opening_hours, :phone, :wheelchair_accessible, :has_emergency,
      :specialization,
      :website, :email, :latitude, :longitude
    ]
  end

  def facility_core_params
    permitted = params.require(:facility).permit(*core_facility_attributes)
    permitted[:osm_id] = params[:facility][:osm_id] if params[:facility][:osm_id].present? && action_name == 'create'
    permitted.except(:osm_id) unless action_name == 'create'
    permitted
  end

  def facility_association_params
    params.require(:facility).permit(specialty_ids: [])
  end

  def update_specialties(ids)
    @facility.specialty_ids = ids if ids
  end

  def set_location_from_params(params_hash)
    return unless @facility

    latitude = params_hash[:latitude]&.to_f
    longitude = params_hash[:longitude]&.to_f

    return unless latitude && longitude

    if longitude.between?(-180, 180) && latitude.between?(-90, 90)
      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      @facility.location = factory.point(longitude, latitude)
    else
      @facility.errors.add(:location, "Invalid latitude or longitude values.") if params_hash.key?(:latitude) || params_hash.key?(:longitude)
    end
  end

  def record_not_found_response(exception)
    render json: { error: "Facility with osm_id '#{params[:osm_id]}' not found" }, status: :not_found
  end
end