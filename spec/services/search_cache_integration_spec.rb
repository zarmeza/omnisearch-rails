# frozen_string_literal: true

require 'rails_helper'

# These examples only mean something when a real Redis is reachable. They are
# skipped otherwise, so the suite still passes on a machine with no Redis
# installed — but on a machine that has one, they prove the cache is actually
# used and actually expires.
#
#   docker run -d -p 6379:6379 --name omnisearch-redis redis:7-alpine
describe 'caching against a real redis', :requires_redis do
  let(:url) { 'https://search.example.test/caching' }

  let(:provider_class) do
    Class.new(SearchService) do
      def self.provider_name = :test
      def self.parse_response(body) = JSON.parse(body)
      def self.map_data(data) = data
    end
  end

  subject(:service) { provider_class.new(url) }

  # A raw client for assertions. SearchCache deliberately exposes only get/set —
  # inspection is the test's business, not the cache's API.
  let(:raw) { Redis.new(url: redis_url) }

  before do
    skip 'no Redis reachable on REDIS_URL' unless redis_available?
    raw.del(url)
    allow(HTTParty).to receive(:get).and_return(
      double('HTTParty::Response', code: 200, body: '{"hits":1}', message: 'OK')
    )
  end

  after { raw.del(url) if redis_available? }

  let(:redis_url) { ENV.fetch('REDIS_URL', 'redis://localhost:6379') }

  def redis_available?
    return @redis_available if defined?(@redis_available)

    @redis_available = SearchCache.build(url: redis_url)
                            .is_a?(SearchCache::RedisStore)
  end

  it 'stores the response body under the request url' do
    service.call

    expect(raw.get(url)).to eq('{"hits":1}')
  end

  it 'sets a TTL so entries do not live forever' do
    service.call

    ttl = raw.ttl(url)
    expect(ttl).to be > 0
    expect(ttl).to be <= SearchCache::TTL
  end

  it 'serves the second identical request from the cache' do
    service.call
    expect(HTTParty).not_to receive(:get)

    expect(service.call[:data]).to eq('hits' => 1)
  end
end
