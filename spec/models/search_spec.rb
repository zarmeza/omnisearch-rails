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
    # `before`, not `before(:all)`: rails_helper used to stub Redis.new with a
    # MockRedis in a before(:each), so under before(:all) that stub did not exist
    # yet and the real client tried to connect to 127.0.0.1:6379.
    #
    # Lazy, via `let`, on purpose. A `before` would be inherited by every nested
    # group below and would populate the cache with a successful search, so any
    # example asserting on a provider failure would read that cached success
    # instead of its own stub.
    let(:results) do
      stub_provider(/customsearch/, body: SearchResponseHelpers::GOOGLE_OK.to_json)
      stub_provider(/bing\.com/, body: SearchResponseHelpers::BING_OK)
      Search.new(engine: 'both', text: 'test').results
    end

    it 'agreggates results into a single array with the expected keys' do
      results[:results].each do |result|
        expect(result.keys).to match_array([:provider, :title, :link])
      end
    end

    it 'returns a status of ok when at least one provider succeeds' do
      expect(results[:status]).to eq(:ok)
    end

    it 'reports the status of each provider separately' do
      expect(results[:status_by_provider].map { |s| s[:provider] })
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

        expect(results[:results].size).to eq(1)
      end

    end

    # A separate context, deliberately without the shared `before` above: that
    # one performs a successful search and leaves the response in the cache, so
    # an example asserting on a provider failure would read the cached success
    # instead of the stubbed failure.
    describe 'provider failure reporting' do
      it 'forwards a real provider failure message through to status_by_provider' do
        # The regression this pins. SearchService#call emitted `error_message`
        # (singular) while status_by_provider read `error_messages` (plural),
        # so the key never matched, the value was always nil, and the API
        # reported a provider failure with `error_messages: null`. Ruby hashes
        # do not raise on a missing key, and nothing tested the handoff between
        # the two objects, so it survived every test run.
        #
        # The stub is on HTTParty, not on GoogleSearch. Stubbing the provider
        # would bypass SearchService entirely and hand status_by_provider a hash
        # it could not have received in production — which is how the original
        # bug survived in the first place.
        stub_provider(/customsearch/, code: 403, body: '', message: 'quota exceeded')

        results = Search.new(engine: 'google', text: 'test').results

        expect(results[:status_by_provider].first[:error_messages])
          .to eq(['quota exceeded'])
      end

      it 'reports an empty message list for a provider that succeeded' do
        stub_provider(/customsearch/, body: SearchResponseHelpers::GOOGLE_OK.to_json)

        results = Search.new(engine: 'google', text: 'test').results

        expect(results[:status_by_provider].first[:error_messages]).to eq([])
      end
    end

    describe 'aggregation failures' do
      before do
        stub_provider(/customsearch/, body: SearchResponseHelpers::GOOGLE_OK.to_json)
        stub_provider(/bing\.com/, body: SearchResponseHelpers::BING_OK)
      end

      it 'marks the aggregate unavailable when every provider fails' do
        allow(GoogleSearch).to receive(:call)
          .and_return(provider: :google, status: :error, error_message: 'boom', data: [])
        allow(BingSearch).to receive(:call)
          .and_return(provider: :bing, status: :error, error_message: 'boom', data: [])

        expect(results[:status]).to eq(:service_unavailable)
      end
    end
  end
end
