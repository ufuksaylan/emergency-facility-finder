require 'rails_helper'

RSpec.describe SpecialtiesController, type: :controller do
  describe 'GET #index' do
    let!(:specialties) { create_list(:specialty, 3) }

    it 'returns all specialties in order by name' do
      get :index
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(3)
    end
  end
end
