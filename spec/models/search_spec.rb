require 'rails_helper'

describe Search, type: :model do
  describe '#engine' do
    it 'validates inclusion in supported values' do
      s = Search.new
      s.valid?
      expect(s.errors.has_key? :engine).to be true

      s.engine = 'unsupported'
      s.valid?
      expect(s.errors.has_key? :engine).to be true

      Search::ENGINE_OPTIONS.each do |engine_option|
        s.engine = engine_option
        s.valid?
        expect(s.errors.has_key? :engine).to be false
      end
    end
  end

  describe '#text' do
    it 'validates presence' do
      s = Search.new
      s.valid?
      expect(s.errors.has_key? :text).to be true
    end
  end

  describe '#results' do
    # `before`, not `before(:all)`: rails_helper stubs Redis.new with a
    # MockRedis in a before(:each), so under before(:all) that stub does not
    # exist yet and the real client tries to connect to 127.0.0.1:6379.
    before do
      stub_provider(/customsearch/, body: SearchResponseHelpers::GOOGLE_OK.to_json)
      stub_provider(/bing\.com/, body: SearchResponseHelpers::BING_OK)
      @results = Search.new(engine: 'both', text: 'test').results
    end

    it 'agreggates results into a single array with the expected keys' do
      @results[:results].each do |result|
        expect(result.keys).to match_array([:provider, :title, :link])
      end
    end

    it 'returns a status of ok when at least one provider succeeds' do
      expect(@results[:status]).to eq(:ok)
    end

    it 'reports the status of each provider separately' do
      expect(@results[:status_by_provider].map { |s| s[:provider] })
        .to match_array(%i[google bing])
    end

    describe 'aggregation' do
      it 'deduplicates results that both providers returned' do
        shared = 'https://example.org/omni'
        allow(GoogleSearch).to receive(:call).and_return(
          provider: :google, status: :ok, error_message: nil,
          data: [{ title: 'Google', link: shared }]
        )
        allow(BingSearch).to receive(:call).and_return(
          provider: :bing, status: :ok, error_message: nil,
          data: [{ title: 'Bing', link: shared }]
        )

        results = Search.new(engine: 'both', text: 'test').results

        expect(results[:results].size).to eq(1)
      end

      it 'marks the aggregate unavailable when every provider fails' do
        allow(GoogleSearch).to receive(:call)
          .and_return(provider: :google, status: :error, error_message: 'boom', data: [])
        allow(BingSearch).to receive(:call)
          .and_return(provider: :bing, status: :error, error_message: 'boom', data: [])

        results = Search.new(engine: 'both', text: 'test').results

        expect(results[:status]).to eq(:service_unavailable)
      end
    end
  end
end
