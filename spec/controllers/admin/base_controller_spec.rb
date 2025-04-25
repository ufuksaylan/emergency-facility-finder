require 'rails_helper'

RSpec.describe Admin::BaseController, type: :controller do
  controller do
    def index
      render json: { authenticated: true }
    end
  end

  describe 'authentication' do
    let(:user) { create(:user) }
    let(:valid_token) { 'valid.token.here' }
    let(:expired_token) { 'expired.token.here' }
    let(:invalid_token) { 'invalid.token.here' }
    let(:decoded_valid_token) { { user_id: user.id, email: user.email } }

    context 'with valid token' do
      before do
        allow(JsonWebToken).to receive(:decode).with(valid_token).and_return(decoded_valid_token)
        request.headers['Authorization'] = valid_token
      end

      it 'allows access to the action' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('authenticated' => true)
      end

      it 'sets current_admin_user' do
        get :index
        expect(controller.send(:current_admin_user)).to eq(user)
      end
    end

    context 'with invalid token' do
      before do
        allow(JsonWebToken).to receive(:decode).with(invalid_token).and_return(nil)
        request.headers['Authorization'] = invalid_token
      end

      it 'returns unauthorized status' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with no token' do
      it 'returns unauthorized status' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with user that does not exist' do
      before do
        allow(JsonWebToken).to receive(:decode).with(valid_token).and_return({ user_id: 9999 })
        request.headers['Authorization'] = valid_token
      end

      it 'returns unauthorized status' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end