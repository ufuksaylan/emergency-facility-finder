class FacilitiesController < ApplicationController
  FILTER_PARAMS = %i[facility_type city postcode wheelchair_accessible has_emergency specialization].freeze

  def index
    @facilities = Facility.all

    filter_params(params).each do |key, value|
      if %w[true false].include?(value.to_s.downcase) && Facility.column_for_attribute(key).type == :boolean
        @facilities = @facilities.where(key => value.to_s.downcase == 'true')
      elsif value.present?
        @facilities = @facilities.where(key => value)
      end
    end
  end

  private

  def filter_params(params)
    params.permit(FILTER_PARAMS)
  end
end
