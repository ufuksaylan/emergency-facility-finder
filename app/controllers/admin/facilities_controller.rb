# app/controllers/admin/facilities_controller.rb

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

    set_location_from_params

    unless @facility.errors.empty?
      render json: { errors: @facility.errors.full_messages }, status: :unprocessable_entity
      return
    end

    if @facility.save
      update_specialties(association_params[:specialty_ids]) if association_params.key?(:specialty_ids)
      render json: @facility.as_json(include: :specialties), status: :created
    else
      render json: { errors: @facility.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    core_params = facility_core_params
    association_params = facility_association_params

    set_location_from_params

    unless @facility.errors.empty?
      render json: { errors: @facility.errors.full_messages }, status: :unprocessable_entity
      return
    end

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
      :website, :email
    ]
  end

  def facility_core_params
    permitted = params.require(:facility).permit(*core_facility_attributes)
    if action_name == 'create' && params[:facility][:osm_id].present?
      permitted[:osm_id] = params[:facility][:osm_id]
    elsif action_name != 'create'
      permitted.delete(:osm_id) if permitted.key?(:osm_id)
    end
    permitted
  end

  def facility_association_params
    params.require(:facility).permit(specialty_ids: [])
  end

  def set_location_from_params
    return unless @facility && params[:facility]

    latitude_str = params[:facility][:latitude]&.to_s.presence
    longitude_str = params[:facility][:longitude]&.to_s.presence

    latitude = latitude_str ? latitude_str.to_f : nil
    longitude = longitude_str ? longitude_str.to_f : nil

    return unless latitude_str || longitude_str

    if latitude.nil? || longitude.nil?
      @facility.errors.add(:location, "Both latitude and longitude must be provided if updating location.")
      return
    end

    if longitude.between?(-180, 180) && latitude.between?(-90, 90)
      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      @facility.location = factory.point(longitude, latitude)
    else
      @facility.errors.add(:location, "Invalid latitude or longitude values.")
    end
  end

  def update_specialties(ids)
    @facility.specialty_ids = ids
  end

  def record_not_found_response(exception)
    render json: { error: "Facility with osm_id '#{params[:osm_id]}' not found" }, status: :not_found
  end
end
