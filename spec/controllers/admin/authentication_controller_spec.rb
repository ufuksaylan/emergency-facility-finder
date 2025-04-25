require 'rails_helper'

RSpec.describe Admin::AuthenticationController, type: :controller do
  describe 'POST #login' do
    let(:valid_email) { 'admin@example.com' }
    let(:valid_password) { 'password123' }
    let(:user) { create(:user, email: valid_email, password: valid_password) }
    let(:valid_credentials) { { email: valid_email, password: valid_password } }
    let(:invalid_credentials) { { email: valid_email, password: 'wrong_password' } }
    let(:token_payload) { { user_id: user.id, email: user.email, issued_at: Time.now.to_i } }
    let(:mock_token) { 'mock.jwt.token' }

    before do
      allow(JsonWebToken).to receive(:encode).and_return(mock_token)
      allow(JsonWebToken).to receive(:decode).and_return({ user_id: user.id, email: user.email, exp: 1.hour.from_now.to_i })
    end

    context 'with valid credentials' do
      before do
        post :login, params: { authentication: valid_credentials }
      end

      it 'returns a JWT token' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('token' => mock_token)
      end

      it 'returns user information' do
        expect(JSON.parse(response.body)['user']).to include('id' => user.id, 'email' => user.email)
      end

      it 'includes token expiration time' do
        expect(JSON.parse(response.body)).to have_key('exp')
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized status when password is wrong' do
        post :login, params: { authentication: invalid_credentials }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized status when email does not exist' do
        post :login, params: { authentication: { email: 'nonexistent@example.com', password: valid_password } }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with root-level params' do
      it 'accepts credentials provided at root level' do
        post :login, params: valid_credentials
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('token' => mock_token)
      end
    end
  end
end
