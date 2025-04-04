# app/controllers/facilities_controller.rb
class FacilitiesController < ApplicationController
  FILTER_PARAMS = %i[
    facility_type city postcode wheelchair_accessible has_emergency specialization
    latitude longitude distance
  ].freeze

  def index
    @facilities = Facility.all

    standard_filters = filter_params(params).except(:latitude, :longitude, :distance)
    standard_filters.each do |key, value|
      next unless FILTER_PARAMS.include?(key.to_sym)

      if Facility.column_for_attribute(key).type == :boolean
        bool_value = value.to_s.downcase == 'true'
        @facilities = @facilities.where(key => bool_value)
      elsif value.present?
        @facilities = @facilities.where(key => value)
      end
    end

    lat_param = params[:latitude].presence
    lng_param = params[:longitude].presence

    if lat_param && lng_param
      begin
        lat_f = Float(lat_param)
        lng_f = Float(lng_param)

        point_text = "POINT(#{lng_f} #{lat_f})"
        point_geography_sql = Arel.sql("ST_SetSRID(ST_GeomFromText('#{point_text}'), 4326)::geography")

        @facilities = @facilities.order(Arel.sql("ST_Distance(location, #{point_geography_sql}) ASC"))

      rescue ArgumentError, TypeError
        Rails.logger.warn("Invalid latitude/longitude parameters received: lat=#{lat_param}, lng=#{lng_param}. Skipping distance sort.")
      end
    end

  end

  private

  def filter_params(params)
    params.permit(FILTER_PARAMS)
  end
end
