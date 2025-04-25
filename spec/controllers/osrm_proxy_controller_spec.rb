require 'rails_helper'

RSpec.describe OsrmProxyController, type: :controller do
  describe 'GET #route' do
    let(:profile) { 'driving' }
    let(:osrm_path) { '25.279651,54.687157;25.308441,54.680773' }
    let(:query_string) { 'geometries=geojson&alternatives=true' }
    let(:mock_response) do
      instance_double(
        Net::HTTPResponse,
        body: '{"routes":[]}',
        code: '200',
        content_type: 'application/json'
      )
    end

    let(:uri) do
      URI::HTTP.build(
        host: OsrmProxyController::OSRM_CONFIG[:host],
        port: OsrmProxyController::OSRM_CONFIG[:ports]['driving'],
        path: "/route/v1/driving/#{osrm_path}",
        query: query_string
      )
    end

    context 'with valid params' do
      before do
        http_double = instance_double(Net::HTTP)
        request_double = instance_double(Net::HTTP::Get)

        allow(Net::HTTP).to receive(:start).with(
          uri.host,
          uri.port,
          read_timeout: OsrmProxyController::OSRM_CONFIG[:timeout],
          open_timeout: OsrmProxyController::OSRM_CONFIG[:timeout]
        ).and_yield(http_double)

        allow(Net::HTTP::Get).to receive(:new).with(uri.request_uri).and_return(request_double)
        allow(http_double).to receive(:request).with(request_double).and_return(mock_response)

        request.env['QUERY_STRING'] = query_string
        get :route, params: { profile: profile, osrm_path: osrm_path }
      end

      it 'proxies the request to OSRM service' do
        expect(Net::HTTP).to have_received(:start)
      end

      it 'returns the response from OSRM' do
        expect(response.body).to eq(mock_response.body)
        expect(response.status).to eq(200)
        expect(response.content_type).to include('application/json')
      end
    end



    context 'when OSRM times out' do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout.new('timeout error'))
        get :route, params: { profile: profile, osrm_path: osrm_path }
      end

      it 'returns a server error' do
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)).to have_key('error')
      end
    end

    context 'when OSRM connection is refused' do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED.new('connection refused'))
        get :route, params: { profile: profile, osrm_path: osrm_path }
      end

      it 'returns a server error' do
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)).to have_key('error')
      end
    end
  end
end