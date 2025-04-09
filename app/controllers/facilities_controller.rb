# app/controllers/facilities_controller.rb
class FacilitiesController < ApplicationController
  FILTER_PARAMS = %i[
    facility_type city postcode wheelchair_accessible has_emergency specialization
    latitude longitude distance specializations
  ].freeze

  def index
    @facilities = Facility.all

    standard_filters = filter_params(params).except(:latitude, :longitude, :distance, :specializations)
    standard_filters.each do |key, value|
      next unless FILTER_PARAMS.include?(key.to_sym)
      next if key.to_s == "specializations"

      if Facility.column_for_attribute(key).type == :boolean
        bool_value = value.to_s.downcase == "true"
        @facilities = @facilities.where(key => bool_value)
      elsif value.present?
        @facilities = @facilities.where(key => value)
      end
    end

    # Handle specialties filtering (comma-separated IDs)
    if params[:specializations].present?
      specialty_ids = params[:specializations].split(",").map(&:strip).map(&:to_i)

      if specialty_ids.any?
        @facilities = @facilities.joins(:specialties).where(specialties: { id: specialty_ids })

        # When using specializations filter, we need a different approach to ordering by distance
        lat_param = params[:latitude].presence
        lng_param = params[:longitude].presence

        if lat_param && lng_param
          begin
            lat_f = Float(lat_param)
            lng_f = Float(lng_param)

            point_text = "POINT(#{lng_f} #{lat_f})"
            distance_sql = "ST_Distance(location, ST_SetSRID(ST_GeomFromText('#{point_text}'), 4326)::geography)"

            # Use select with the distance calculation to satisfy PostgreSQL's DISTINCT requirements
            @facilities = @facilities
                            .select("facilities.*, #{distance_sql} AS distance")
                            .distinct
                            .order("distance ASC")

            return # Skip the standard distance ordering below
          rescue ArgumentError, TypeError
            Rails.logger.warn("Invalid latitude/longitude parameters received: lat=#{lat_param}, lng=#{lng_param}. Skipping distance sort.")
          end
        else
          @facilities = @facilities.distinct # Apply distinct here only if not ordering by distance
        end
      end
    end

    # Standard distance ordering (used when no specializations filter)
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
