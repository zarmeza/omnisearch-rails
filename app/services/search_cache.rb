# app/services/search_cache.rb

# A best-effort cache in front of an external search provider.
#
# The cache must never be the reason a search fails. If Solid Cache or its
# database is unavailable, slow, or misconfigured, this degrades to "no caching"
# — it does not degrade to a 500.
#
# This is a thin adapter over `Rails.cache` (Solid Cache), not a second cache
# implementation. It exists for one reason: `Rails.cache` raises on read and
# write when the store is unavailable, and a cache that can take the API down is
# worse than no cache at all.
#
# An uncached search costs one upstream HTTP request. A raised exception costs
# the caller a 500.
#
# Reach for `Rails.cache` directly anywhere that is not a search path. This
# class is only for provider calls, where the failure mode above is the concern.
class SearchCache
  # How long a cached provider response stays fresh, in seconds.
  TTL = 900

  def initialize(store = Rails.cache)
    @store = store
  end

  # A cached response body, or nil on a miss.
  def get(key)
    @store.read(key)
  rescue StandardError => e
    warn_and_continue(e)
    nil
  end

  # Store a response body. Returns truthy on success, nil if the cache refused.
  def set(key, value)
    @store.write(key, value, expires_in: TTL)
  rescue StandardError => e
    warn_and_continue(e)
    nil
  end

  private

  # Log once per instance rather than once per read, so a sustained outage
  # produces one log line per process instead of one per request.
  def warn_and_continue(error)
    return if @warned

    @warned = true
    Rails.logger.warn(
      "[SearchCache] #{error.class}, continuing uncached: #{error.message}"
    )
  end
end
