require 'rails_helper'

RSpec.describe Admin::FacilitiesController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:authenticate_admin_request!).and_return(true)
    allow(controller).to receive(:current_admin_user).and_return(user)
  end

  describe 'GET #index' do
    let!(:facilities) { create_list(:facility, 3) }

    it 'returns all facilities with specialties' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(3)
    end
  end

  describe 'GET #show' do
    let!(:facility) { create(:facility, :with_specialties) }

    it 'returns the requested facility with specialties' do
      get :show, params: { osm_id: facility.osm_id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['osm_id']).to eq(facility.osm_id)
      expect(JSON.parse(response.body)).to have_key('specialties')
    end

    it 'returns not found for non-existent facility' do
      get :show, params: { osm_id: 'nonexistent' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    let(:specialty) { create(:specialty) }
    let(:valid_attributes) do
      {
        osm_id: 12345,
        name: 'New Facility',
        facility_type: 'hospital',
        latitude: '54.6872',
        longitude: '25.2797',
        specialty_ids: [specialty.id]
      }
    end

    let(:invalid_attributes) do
      {
        name: 'Invalid Facility',
        facility_type: nil
      }
    end

    it 'creates a new facility with specialties' do
      expect {
        post :create, params: { facility: valid_attributes }
      }.to change(Facility, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['name']).to eq('New Facility')
      expect(JSON.parse(response.body)['specialties']).not_to be_empty
    end

    it 'returns errors for invalid attributes' do
      post :create, params: { facility: invalid_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key('errors')
    end
  end

  describe 'PATCH #update' do
    let!(:facility) { create(:facility) }
    let(:specialty) { create(:specialty) }

    let(:valid_update_attributes) do
      {
        name: 'Updated Facility',
        latitude: '54.6872',
        longitude: '25.2797',
        specialty_ids: [specialty.id]
      }
    end

    let(:invalid_update_attributes) do
      {
        facility_type: nil
      }
    end

    it 'updates the facility and its specialties' do
      patch :update, params: { osm_id: facility.osm_id, facility: valid_update_attributes }
      facility.reload

      expect(response).to have_http_status(:ok)
      expect(facility.name).to eq('Updated Facility')
      expect(facility.specialties).to include(specialty)
    end

    it 'returns not found for non-existent facility' do
      patch :update, params: { osm_id: 'nonexistent', facility: valid_update_attributes }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let!(:facility) { create(:facility) }

    it 'destroys the requested facility' do
      expect {
        delete :destroy, params: { osm_id: facility.osm_id }
      }.to change(Facility, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns not found for non-existent facility' do
      delete :destroy, params: { osm_id: 'nonexistent' }
      expect(response).to have_http_status(:not_found)
    end
  end
end