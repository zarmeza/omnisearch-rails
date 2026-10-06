require 'rails_helper'

RSpec.describe 'Search', type: :request do
  describe 'GET /search' do
    # `before`, not `before(:all)`: rails_helper stubs Redis.new with a
    # MockRedis in a before(:each), so under before(:all) that stub does not
    # exist yet and the request hits a real Redis connection.
    context 'with invalid search parameters' do
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
        stub_provider(/customsearch/, body: SearchResponseHelpers::GOOGLE_OK.to_json)
        stub_provider(/bing\.com/, body: SearchResponseHelpers::BING_OK)
        get search_path(engine: 'both', text: 'test')
        @json_response = JSON.parse(response.body, symbolize_names: true)
      end

      it 'responds with a 200 status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the expected keys in the response' do
        expect(@json_response.keys).to match_array([:query, :status, :status_by_provider, :results])
      end

      it 'echoes the query back' do
        expect(@json_response[:query]).to eq('test')
      end
    end

    context 'when the cache store is unavailable' do
      # The regression this pins: a cache that cannot be reached used to be a
      # hard dependency, so the search returned a 500 instead of a result.
      before do
        allow(SearchCache).to receive(:new).and_return(SearchCache.new(broken_cache_store))
        stub_provider(/customsearch/, body: SearchResponseHelpers::GOOGLE_OK.to_json)
        get search_path(engine: 'google', text: 'test')
        @json_response = JSON.parse(response.body, symbolize_names: true)
      end

      it 'still responds with a 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'still returns results' do
        expect(@json_response[:results]).not_to be_empty
      end
    end
  end
end
