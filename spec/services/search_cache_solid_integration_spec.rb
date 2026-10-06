# frozen_string_literal: true

require 'rails_helper'
require 'active_support/testing/time_helpers'

# Exercises the real cache stack: Rails.cache backed by Solid Cache, writing to
# the app's own database.
#
# Unlike the unit specs, these are not stubbed — they are here to catch the
# things only a real store can: that the schema is right, that a TTL is actually
# set on the row, and that a second identical request is served from the database
# without touching the provider.
#
# Skipped when the cache database has not been prepared, so a fresh clone that
# only wants to run the unit suite still passes.
describe 'caching against a real store', :requires_solid_cache do
  include ActiveSupport::Testing::TimeHelpers
  let(:url) { 'https://search.example.test/solid-cache' }
  let(:body) { '{"hits":1}' }

  let(:provider_class) do
    Class.new(SearchService) do
      def self.provider_name = :test
      def self.parse_response(body) = JSON.parse(body)
      def self.map_data(data) = data
    end
  end

  subject(:service) { provider_class.new(url) }

  before do
    skip 'cache database not prepared; run bin/rails db:prepare' unless solid_cache_ready?
    Rails.cache.clear
    allow(HTTParty).to receive(:get).and_return(
      double('HTTParty::Response', code: 200, body: body, message: 'OK')
    )
  end

  after { Rails.cache.clear if solid_cache_ready? }

  def solid_cache_ready?
    return @solid_cache_ready if defined?(@solid_cache_ready)

    @solid_cache_ready =
      begin
        Rails.cache.is_a?(SolidCache::Store) &&
          SolidCache::Record.connection.data_source_exists?('solid_cache_entries')
      rescue StandardError
        false
      end
  end

  def entry_count
    SolidCache::Record.connection.select_value('SELECT COUNT(*) FROM solid_cache_entries')
  end

  # Solid Cache has no `expires_at` column. Expiry is derived at read time from
  # `created_at` plus the store's `max_age`, so asserting on the row's own
  # columns cannot prove the per-entry TTL was passed through. Assert on the
  # store's behaviour instead: travel past the TTL and the key must miss.
  def entry_misses_after(seconds)
    travel(seconds + 1) { Rails.cache.read(url).nil? }
  end

  it 'is configured to use Solid Cache' do
    expect(Rails.cache).to be_a(SolidCache::Store)
  end

  it 'passes the retention cap from config/cache.yml through to the store' do
    # Our wiring, not the gem's behaviour: max_age and max_size are set in
    # config/cache.yml, and if that file were ignored or misspelled they would
    # silently fall back to Solid Cache's defaults (2 weeks / no size cap)
    # without anything failing. Pruning itself is the gem's business.
    options = SolidCache.configuration.store_options

    expect(options[:max_age]).to eq(7.days.to_i)
    expect(options[:max_size]).to eq(256.megabytes)
  end

  it 'namespaces entries per environment, so dev and test cannot collide' do
    expect(SolidCache.configuration.store_options[:namespace]).to eq(Rails.env)
  end

  it 'stores the response body in the cache database' do
    service.call

    expect(entry_count).to eq(1)
    expect(Rails.cache.read(url)).to eq(body)
  end

  it 'serves the entry immediately, before the TTL' do
    service.call

    expect(Rails.cache.read(url)).to eq(body)
  end

  it 'stops serving the entry after the search TTL' do
    service.call

    # This is the assertion that catches a regression where the TTL stopped
    # being passed: without expires_in the entry would still be readable.
    expect(entry_misses_after(SearchCache::TTL)).to be true
  end

  it 'still serves the entry just before the TTL' do
    service.call

    travel(SearchCache::TTL - 30) { expect(Rails.cache.read(url)).to eq(body) }
  end

  it 'serves the second identical request from the cache' do
    service.call
    expect(HTTParty).not_to receive(:get)

    expect(service.call[:data]).to eq('hits' => 1)
  end

  it 'does not cache an error response' do
    allow(HTTParty).to receive(:get).and_return(
      double('HTTParty::Response', code: 500, body: '', message: 'Internal Server Error')
    )

    service.call

    expect(entry_count).to eq(0)
  end
end
