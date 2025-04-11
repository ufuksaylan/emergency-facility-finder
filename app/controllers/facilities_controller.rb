class FacilitiesController < ApplicationController
  FILTER_PARAMS = FacilityFinder::FILTER_PARAMS

  def index
    @facilities = FacilityFinder.new(filter_params).call
  end

  private

  def filter_params
    params.permit(FILTER_PARAMS)
  end
end
