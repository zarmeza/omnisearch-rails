# frozen_string_literal: true

require 'active_support/testing/time_helpers'

# Shared fixtures and helpers for stubbing the external search providers.
#
# Every provider response in this suite comes from a fixture in this file. No
# test is allowed to reach the network: a suite that depends on Google, Bing or
# a third-party echo service is a suite whose failures belong to somebody else.
module SearchResponseHelpers
  GOOGLE_OK = {
    'items' => [
      { 'title' => 'Omnisearch', 'link' => 'https://github.com/zarmeza/omnisearch-rails' },
      { 'title' => 'Omni - a metasearch engine', 'link' => 'https://example.org/omni' }
    ]
  }.freeze

  # Minimal Bing result markup: the service parses with Nokogiri and selects
  # `.b_algo h2 a`, so the fixture must contain that structure.
  BING_OK = <<~HTML.freeze
    <html><body>
      <li class="b_algo">
        <h2><a href="https://example.org/omni">Omni - a metasearch engine</a></h2>
      </li>
    </body></html>
  HTML

  # A double shaped like HTTParty::Response. Built with a plain `double` rather
  # than `instance_double(HTTParty::Response, ...)`: HTTParty's delegators are
  # defined on its own subclasses, so verifying against the base class fails
  # for methods that genuinely exist at runtime.
  def http_response(code:, body:, message: 'OK')
    double('HTTParty::Response', code: code, body: body, message: message)
  end

  # Stub a provider's HTTP call with a canned 200.
  def stub_provider(url_matcher, body:)
    allow(HTTParty).to receive(:get).with(url_matcher, any_args)
                              .and_return(http_response(code: 200, body: body))
  end

  # A cache store that fails on every operation, standing in for an unavailable
  # Solid Cache database. Used to prove a cache outage is never a 500.
  def broken_cache_store
    Class.new do
      def read(*) = raise(ActiveRecord::StatementInvalid, 'cache unavailable')
      def write(*, **) = raise(ActiveRecord::StatementInvalid, 'cache unavailable')
    end.new
  end
end

RSpec.configure do |config|
  config.include SearchResponseHelpers

  config.before do
    WebMock.enable!
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  config.after { WebMock.reset! }
end
