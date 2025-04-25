require 'rails_helper'

RSpec.describe Admin::ComplaintsController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:authenticate_admin_request!).and_return(true)
    allow(controller).to receive(:current_admin_user).and_return(user)
  end

  describe 'GET #index' do
    let!(:complaints) { create_list(:complaint, 3) }

    it 'returns all complaints ordered by creation date' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(3)
    end
  end

  describe 'GET #show' do
    let!(:complaint) { create(:complaint) }

    it 'returns the requested complaint with facility info' do
      get :show, params: { id: complaint.id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['id']).to eq(complaint.id)
      expect(JSON.parse(response.body)).to have_key('facility')
    end

    it 'returns not found for non-existent complaint' do
      get :show, params: { id: 9999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH #update' do
    let!(:complaint) { create(:complaint, status: 'submitted') }

    context 'with valid status update' do
      let(:update_params) { { status: 'resolved', resolution_notes: 'Issue has been addressed' } }

      it 'updates the complaint status' do
        patch :update, params: { id: complaint.id, complaint: update_params }
        complaint.reload

        expect(response).to have_http_status(:ok)
        expect(complaint.status).to eq('resolved')
        expect(complaint.resolution_notes).to eq('Issue has been addressed')
      end

      it 'sets resolved_at when moving to terminal state' do
        patch :update, params: { id: complaint.id, complaint: update_params }
        complaint.reload

        expect(complaint.resolved_at).not_to be_nil
      end

      it 'clears resolved_at when moving from terminal to non-terminal state' do
        # First set to resolved (terminal)
        patch :update, params: { id: complaint.id, complaint: { status: 'resolved' } }
        complaint.reload
        expect(complaint.resolved_at).not_to be_nil

        # Then set back to under_review (non-terminal)
        patch :update, params: { id: complaint.id, complaint: { status: 'under_review' } }
        complaint.reload
        expect(complaint.resolved_at).to be_nil
      end
    end

    context 'with invalid status update' do
      let(:invalid_params) { { status: 'invalid_status' } }

      it 'returns errors for invalid status' do
        patch :update, params: { id: complaint.id, complaint: invalid_params }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('errors')
      end
    end

    it 'returns not found for non-existent complaint' do
      patch :update, params: { id: 9999, complaint: { status: 'resolved' } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let!(:complaint) { create(:complaint) }

    it 'destroys the requested complaint' do
      expect {
        delete :destroy, params: { id: complaint.id }
      }.to change(Complaint, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns not found for non-existent complaint' do
      delete :destroy, params: { id: 9999 }
      expect(response).to have_http_status(:not_found)
    end
  end
end