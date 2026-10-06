# app/services/search_cache.rb

# A best-effort cache in front of an external search provider.
#
# The cache must never be the reason a search fails. Redis being absent, slow,
# or misconfigured degrades to "no caching" — it does not degrade to a 500.
#
# Two implementations:
#
#   SearchCache::RedisStore — the real thing, used when Redis is reachable
#   SearchCache::NullStore  — a no-op, used when it is not
#
# Every rescue is `Redis::BaseError`, the ancestor of all client errors
# (CannotConnectError, TimeoutError, CommandError, ...). Rescuing narrower
# classes means a new Redis error class silently escapes and reintroduces the
# 500 this exists to prevent.
#
# `SearchCache.build` probes Redis once and picks one. Probing costs one PING,
# so it happens once per process rather than on every request.
class SearchCache
  # How long a cached provider response stays fresh, in seconds.
  TTL = 900

  # Seconds to wait for the probe before giving up and running without a cache.
  PROBE_TIMEOUT = 0.5

  def self.build(url: nil)
    RedisStore.new(url: url)
  rescue Redis::BaseError => e
    Rails.logger.warn("[SearchCache] Redis unavailable (#{e.class}), caching disabled: #{e.message}")
    NullStore.new
  end

  def get(_key)
    nil
  end

  def set(_key, _value, _ttl)
    nil
  end

  # No-op store. Reads always miss, writes always discard.
  class NullStore
    def get(_key)
      nil
    end

    def set(_key, _value, _ttl)
      nil
    end
  end

  # Real Redis-backed store.
  #
  # Every operation rescues Redis errors. A cache that raises mid-request turns
  # a transient Redis blip into a user-visible 500, which is strictly worse than
  # an uncached response.
  class RedisStore
    def initialize(url: nil)
      @store = url ? Redis.new(url: url) : Redis.new
      probe
    end

    def get(key)
      @store.get(key)
    rescue Redis::BaseError => e
      warn_once(e)
      nil
    end

    def set(key, value, ttl)
      @store.set(key, value, ex: ttl)
    rescue Redis::BaseError => e
      warn_once(e)
      nil
    end

    private

    # Fail fast at construction if Redis is not actually reachable, so
    # SearchCache.build can fall back instead of every request paying a timeout.
    def probe
      @store.ping
    rescue Redis::BaseError
      # Re-raise so SearchCache.build can swap in the NullStore.
      raise
    end

    def warn_once(error)
      @warned ||= false
      return if @warned

      @warned = true
      Rails.logger.warn("[SearchCache] #{error.class}, continuing uncached: #{error.message}")
    end
  end
end
