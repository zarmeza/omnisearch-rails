# frozen_string_literal: true

require 'rails_helper'

# The contract under test: a cache outage must never become a user-visible 500.
#
# With Solid Cache the store is the app's own database, so "unavailable" now
# means a missing table or an unwritable file rather than a missing daemon.
# Those specs cover this by injecting a store that raises, which is the same
# code path either way.
describe SearchCache do
  let(:raising) { broken_cache_store }

  describe '#get' do
    it 'reads through to Rails.cache' do
      store = instance_double(ActiveSupport::Cache::Store, read: 'body')
      expect(SearchCache.new(store).get('key')).to eq('body')
    end

    it 'returns nil on a miss' do
      store = instance_double(ActiveSupport::Cache::Store, read: nil)

      expect(SearchCache.new(store).get('key')).to be_nil
    end

    it 'returns nil instead of raising when the store fails' do
      expect(SearchCache.new(raising).get('key')).to be_nil
    end

    it 'logs a store failure only once, so an outage is not one line per request' do
      allow(Rails.logger).to receive(:warn)
      cache = SearchCache.new(raising)

      5.times { cache.get('key') }

      expect(Rails.logger).to have_received(:warn).once
    end
  end

  describe '#set' do
    it 'writes with the search TTL' do
      store = instance_double(ActiveSupport::Cache::Store)
      expect(store).to receive(:write).with('key', 'body', expires_in: SearchCache::TTL)

      SearchCache.new(store).set('key', 'body')
    end

    it 'swallows a store failure' do
      expect { SearchCache.new(raising).set('key', 'body') }.not_to raise_error
    end
  end

  describe 'TTL' do
    it 'is fifteen minutes' do
      expect(described_class::TTL).to eq(900)
    end
  end

  describe 'end-to-end without a cache' do
    it 'still serves a search when the cache store raises' do
      allow(SearchCache).to receive(:new).and_return(described_class.new(raising))
      allow(HTTParty).to receive(:get).and_return(
        double('HTTParty::Response', code: 200, body: '{"items":[]}', message: 'OK')
      )

      results = Search.new(engine: 'google', text: 'test').results

      expect(results[:status]).to eq(:ok)
      expect(results[:results]).to eq([])
    end
  end
end
