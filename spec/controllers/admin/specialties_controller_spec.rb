require 'rails_helper'

RSpec.describe Admin::SpecialtiesController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:authenticate_admin_request!).and_return(true)
    allow(controller).to receive(:current_admin_user).and_return(user)
  end

  describe 'GET #index' do
    let!(:specialties) { create_list(:specialty, 3) }

    it 'returns all specialties ordered by name' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(3)
    end
  end
end