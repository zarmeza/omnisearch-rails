# frozen_string_literal: true

require 'rails_helper'

# The contract under test: a cache outage must never become a user-visible 500.
#
# Redis being absent is the normal case for a fresh clone, a CI runner, and a
# developer who never installed it. These specs pin that down so it cannot
# regress into a hard dependency.
describe SearchCache do
  describe '.build' do
    # rails_helper stubs Redis.new with MockRedis globally. These examples are
    # about the client raising, so undo that stub first and hand back a double
    # that behaves the way each example needs.
    let(:client) { instance_double(Redis) }

    before { allow(Redis).to receive(:new).and_return(client) }

    it 'falls back to NullStore when Redis cannot be reached' do
      allow(client).to receive(:ping).and_raise(Redis::CannotConnectError.new('refused'))

      expect(described_class.build).to be_a(described_class::NullStore)
    end

    it 'logs why caching was disabled' do
      allow(client).to receive(:ping).and_raise(Redis::CannotConnectError.new('refused'))
      allow(Rails.logger).to receive(:warn)

      described_class.build

      expect(Rails.logger).to have_received(:warn).with(/Redis unavailable/)
    end

    it 'uses RedisStore when Redis answers the probe' do
      allow(client).to receive(:ping).and_return('PONG')

      expect(described_class.build).to be_a(described_class::RedisStore)
    end

    it 'passes a configured url through to the client' do
      allow(client).to receive(:ping).and_return('PONG')
      expect(Redis).to receive(:new).with(url: 'redis://example:6379').and_return(client)

      described_class.build(url: 'redis://example:6379')
    end

    it 'builds a default client when no url is configured' do
      allow(client).to receive(:ping).and_return('PONG')
      expect(Redis).to receive(:new).with(no_args).and_return(client)

      described_class.build(url: nil)
    end
  end

  describe described_class::NullStore do
    it 'always misses on read' do
      expect(described_class.new.get('anything')).to be_nil
    end

    it 'discards writes without raising' do
      expect { described_class.new.set('key', 'value', 900) }.not_to raise_error
    end
  end

  describe described_class::RedisStore do
    let(:client) { instance_double(Redis, ping: 'PONG') }

    subject(:store) { described_class.new }

    before { allow(Redis).to receive(:new).and_return(client) }

    it 'reads through to Redis' do
      allow(client).to receive(:get).with('key').and_return('value')

      expect(store.get('key')).to eq('value')
    end

    it 'writes with the given ttl' do
      expect(client).to receive(:set).with('key', 'value', ex: 900)

      store.set('key', 'value', 900)
    end

    it 'returns nil instead of raising when a read fails' do
      allow(client).to receive(:get).and_raise(Redis::TimeoutError.new('slow'))

      expect(store.get('key')).to be_nil
    end

    it 'swallows a write failure' do
      allow(client).to receive(:set).and_raise(Redis::CannotConnectError.new('gone'))

      expect { store.set('key', 'value', 900) }.not_to raise_error
    end

    it 'logs a Redis failure only once, to keep logs readable' do
      allow(client).to receive(:get).and_raise(Redis::CannotConnectError.new('gone'))
      allow(Rails.logger).to receive(:warn)

      5.times { store.get('key') }

      expect(Rails.logger).to have_received(:warn).once
    end
  end

  describe 'end-to-end without redis' do
    it 'still serves a search when no cache is available' do
      client = instance_double(Redis)
      allow(client).to receive(:ping).and_raise(Redis::CannotConnectError.new('refused'))
      allow(Redis).to receive(:new).and_return(client)
      allow(HTTParty).to receive(:get).and_return(
        double('HTTParty::Response', code: 200, body: '{"items":[]}', message: 'OK')
      )

      results = Search.new(engine: 'google', text: 'test').results

      expect(results[:status]).to eq(:ok)
      expect(results[:results]).to eq([])
    end
  end
end
