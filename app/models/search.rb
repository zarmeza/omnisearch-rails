# app/models/search.rb
class Search
  ENGINE_OPTIONS = %w[google bing both].freeze

  include ActiveModel::Validations

  attr_accessor :engine, :text

  validates :engine, inclusion: {
    in: ENGINE_OPTIONS,
    message: "%{value} is not a valid engine option. Valid engine options: #{ENGINE_OPTIONS}"
  }
  validates :text, presence: true

  def initialize(params = {})
    @engine = params[:engine]
    @text = params[:text]
  end

  def results
    return nil unless valid?

    responses = case engine
                      when 'both'
                        [GoogleSearch.call(text), BingSearch.call(text)]
                      else
                        ["#{engine.capitalize}Search".constantize.call(text)]
                      end

    agreggate_responses(responses)
  end

  def agreggate_responses(responses)
    {
      query: text,
      status: self.class.aggregate_statuses(responses),
      status_by_provider: self.class.status_by_provider(responses),
      results: self.class.aggregate_results(responses),
    }
  end

  def self.aggregate_statuses(responses)
    responses.any? { |response| response[:status] == :ok } ? :ok : :service_unavailable
  end

  # One entry per provider, forwarded into the API response.
  #
  # `error_messages` is normalized to an array here so the JSON shape does not
  # depend on which provider ran or whether it happened to fail: a caller can
  # always iterate. `Array(nil)` gives `[]`, and `Array()` on a string gives
  # `["..."]` — which is why the service emits a real array and this is a cheap
  # second line of defence rather than the primary guarantee.
  def self.status_by_provider(responses)
    responses.map do |response|
      {
        provider: response[:provider],
        status: response[:status],
        error_messages: Array(response[:error_messages])
      }
    end
  end

  def self.aggregate_results(responses)
    head, *tail = responses.map do |response|
      response[:data].map do |result|
        {
          provider: response[:provider],
          title: result[:title],
          link: result[:link]
        }
      end
    end

    tail.reduce(head) { |s, i| s.zip i }.flatten.compact.uniq { |result| result[:link] }
  end
end
