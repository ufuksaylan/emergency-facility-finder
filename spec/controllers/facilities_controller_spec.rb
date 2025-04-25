require 'rails_helper'

RSpec.describe FacilitiesController, type: :controller do
  describe 'GET #index' do
    let(:filter_params) { { facility_type: 'hospital', city: 'Vilnius' } }
    let(:filtered_facilities) { double('filtered_facilities') }
    let(:finder_instance) { instance_double(FacilityFinder, call: filtered_facilities) }

    before do
      allow(FacilityFinder).to receive(:new).with(instance_of(ActionController::Parameters)).and_return(finder_instance)
    end

    it 'initializes a FacilityFinder with the filtered params' do
      get :index, params: filter_params, format: :json
      expect(FacilityFinder).to have_received(:new)
    end

    it 'calls the service' do
      expect(finder_instance).to receive(:call)
      get :index, params: filter_params, format: :json
    end

    it 'returns a successful response' do
      get :index, params: filter_params, format: :json
      expect(response).to be_successful
    end
  end
end