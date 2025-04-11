class FacilityFinder
  attr_reader :params, :distance_handled

  FILTER_PARAMS = %i[
    facility_type city postcode wheelchair_accessible has_emergency specialization
    latitude longitude distance specializations
  ].freeze
  GEO_PARAMS = %i[latitude longitude].freeze
  STANDARD_FILTER_KEYS = FILTER_PARAMS - GEO_PARAMS - %i[specializations distance].freeze

  def initialize(raw_params)
    @params = raw_params.slice(*FILTER_PARAMS)
    @distance_handled = false
  end

  def call
    scope = Facility.all
    scope = apply_standard_filters(scope)
    scope = apply_specialization_filter(scope)
    apply_distance_ordering(scope)
  end

  private

  def apply_standard_filters(scope)
    STANDARD_FILTER_KEYS.each_with_object(scope) do |key, current_scope|
      value = params[key]
      next current_scope if value.blank?

      if Facility.column_for_attribute(key).type == :boolean
        bool_value = value.to_s.downcase == 'true'
        current_scope.where!(key => bool_value)
      else
        current_scope.where!(key => value)
      end
    end
  end

  def apply_specialization_filter(scope)
    specializations_param = params[:specializations].presence
    return scope unless specializations_param

    specialty_ids = specializations_param.split(',').map(&:strip).map(&:to_i).reject(&:zero?)
    return scope if specialty_ids.empty?

    scope = scope.joins(:specialties).where(specialties: { id: specialty_ids })

    lat, lng = parse_lat_lng

    if lat && lng
      point_text = "POINT(#{lng} #{lat})"
      distance_sql = "ST_Distance(location, ST_SetSRID(ST_GeomFromText('#{point_text}'), 4326)::geography)"
      @distance_handled = true
      scope.select("facilities.*, #{distance_sql} AS distance").distinct.order('distance ASC')
    else
      scope.distinct
    end
  end

  def apply_distance_ordering(scope)
    return scope if distance_handled

    lat, lng = parse_lat_lng
    return scope unless lat && lng

    point_text = "POINT(#{lng} #{lat})"
    point_geography_sql = Arel.sql("ST_SetSRID(ST_GeomFromText('#{point_text}'), 4326)::geography")
    scope.order(Arel.sql("ST_Distance(location, #{point_geography_sql}) ASC"))
  end

  def parse_lat_lng
    lat = Float(params[:latitude]) rescue nil
    lng = Float(params[:longitude]) rescue nil
    [lat, lng] if lat && lng
  end
end