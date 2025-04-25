require 'rails_helper'

RSpec.describe ComplaintsController, type: :controller do
  describe 'POST #create' do
    let(:facility) { create(:facility) }
    let(:valid_attributes) { { description: 'This is a valid complaint description' } }
    let(:invalid_attributes) { { description: 'Too short' } }

    context 'with valid params' do
      it 'creates a new Complaint' do
        expect {
          post :create, params: { facility_id: facility.id, complaint: valid_attributes }
        }.to change(Complaint, :count).by(1)
      end

      it 'returns the created complaint in the response' do
        post :create, params: { facility_id: facility.id, complaint: valid_attributes }
        expect(response).to have_http_status(:created)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include('description' => valid_attributes[:description])
        expect(Complaint.find(parsed_response['id'])).to be_present
      end

      it 'renders created status with the complaint data' do
        post :create, params: { facility_id: facility.id, complaint: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to include('description' => valid_attributes[:description])
      end
    end

    context 'with invalid params' do
      it 'does not create a new Complaint' do
        expect {
          post :create, params: { facility_id: facility.id, complaint: invalid_attributes }
        }.to change(Complaint, :count).by(0)
      end

      it 'returns errors with unprocessable_entity status' do
        post :create, params: { facility_id: facility.id, complaint: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('errors')
      end
    end

    context 'with non-existent facility' do
      it 'returns not_found status' do
        post :create, params: { facility_id: 999999, complaint: valid_attributes }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end