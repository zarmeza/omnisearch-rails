# frozen_string_literal: true

require 'rails_helper'

# Uses a local fixture rather than a third-party echo service. The old URL
# (http://md5.jsontest.com) meant this file's pass/fail depended on somebody
# else's uptime. With network disabled suite-wide, a real request now raises
# instead of silently succeeding against the internet.
ENGINE_URL = 'https://search.example.test/query'

describe SearchService do
  let(:body) { '{"ok":true}' }

  describe '::map_data' do
    it 'must be implemented by a subclass' do
      expect { SearchService.map_data({}) }.to raise_error(NotImplementedError)
    end
  end

  describe '::provider_name' do
    it 'must be implemented by a subclass' do
      expect { SearchService.provider_name }.to raise_error(NotImplementedError)
    end
  end

  describe '::parse_response' do
    it 'must be implemented by a subclass' do
      expect { SearchService.parse_response('') }.to raise_error(NotImplementedError)
    end
  end

  # A concrete subclass, so these examples exercise the real base-class logic
  # instead of stubbing the three methods the base class declares abstract.
  let(:provider_class) do
    Class.new(SearchService) do
      def self.provider_name = :test
      def self.parse_response(body) = JSON.parse(body)
      def self.map_data(data) = data
    end
  end

  subject(:service) { provider_class.new(ENGINE_URL) }

  describe '#perform_request' do
    before { allow(HTTParty).to receive(:get).and_return(http_response(code: 200, body: body)) }

    context 'when there is no cached response' do
      before { allow(Rails.cache).to receive(:read).and_return(nil) }

      it 'performs an http get request' do
        expect(HTTParty).to receive(:get)

        service.call
      end

      it 'returns an ok status with the parsed payload' do
        result = service.call

        expect(result[:status]).to eq(:ok)
        expect(result[:provider]).to eq(:test)
        expect(result[:data]).to eq('ok' => true)
      end

      it 'reports no error messages on success' do
        # The public contract is `error_messages` is always an array, so a client
        # can iterate without checking for nil. This is the case that was never
        # asserted: `Array(nil)` turning into [] is the whole reason for the
        # normalization in SearchService#call.
        expect(service.call[:error_messages]).to eq([])
      end

      it 'caches the request response' do
        expect(Rails.cache).to receive(:write)
          .with(ENGINE_URL, body, expires_in: SearchCache::TTL)

        service.call
      end
    end

    context 'when there is a cached response' do
      before { allow(Rails.cache).to receive(:read).and_return(body) }

      it 'does not perform an http get request' do
        expect(HTTParty).not_to receive(:get)

        service.call
      end

      it 'serves the cached payload' do
        expect(service.call[:data]).to eq('ok' => true)
      end
    end

    context 'when the provider returns a non-200' do
      before { allow(HTTParty).to receive(:get).and_return(http_response(code: 500, body: '', message: 'Internal Server Error')) }

      it 'reports an error status rather than caching it' do
        result = service.call

        expect(result[:status]).to eq(:error)
        expect(result[:error_messages]).to eq(['Internal Server Error'])
      end
    end

    context 'when the provider is unreachable' do
      before { allow(HTTParty).to receive(:get).and_raise(HTTParty::Error, 'boom') }

      it 'reports an error status instead of raising' do
        result = service.call

        expect(result[:status]).to eq(:error)
        expect(result[:error_messages]).to eq(['boom'])
      end
    end

    context 'when the cache raises mid-request' do
      before do
        allow(Rails.cache).to receive(:read).and_raise(ActiveRecord::StatementInvalid, 'cache gone')
      end

      it 'still performs the request rather than 500-ing' do
        expect { service.call }.not_to raise_error
      end
    end
  end
end
