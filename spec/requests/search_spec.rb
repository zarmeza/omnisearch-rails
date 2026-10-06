require 'rails_helper'

RSpec.describe 'Search', type: :request do
  describe "GET /search" do
    context 'with invalid search parameters' do
      # `before`, not `before(:all)`: rails_helper stubs Redis.new with a
      # MockRedis in a before(:each), so under before(:all) that stub does not
      # exist yet and the request hits a real Redis connection.
      before do
        get search_path
        @json_response = JSON.parse(response.body, symbolize_names: true)
      end

      it 'responds with a 422 status' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'includes an errors key in the response' do
        expect(@json_response).to have_key(:errors)
      end
    end

    context 'with valid search parameters' do
      before do
        get search_path(engine: 'both', text: 'test')
        @json_response = JSON.parse(response.body, symbolize_names: true)
      end

      it 'responds with a 200 status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the expected keys in the response' do
        expect(@json_response.keys).to match_array([:query, :status, :status_by_provider, :results])
      end
    end
  end
end
