# omnisearch-rails

A simple rails api application that provides search results from google and/or bing

## API endpoints

### GET /search

**Parameters**

|          Name | Required |  Type   | Description                                                                                                                                                           |
| -------------:|:--------:|:-------:| --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|     `engine` | required | string  | Search engine(s) to be used. <br/><br/> Supported values: `google, bing, both`.                                                                     |
|     `text` | required | string  | Search query.                                                                     |

**Sample request**

```http://localhost:3000/search?engine=both&text=zarmeza```

**Response**
```json
{
  "query": "zarmeza",
  "status": "ok",
  "status_by_provider": [
    {
      "provider": "google",
      "status": "ok",
      "error_messages": null
    },
    {
      "provider": "bing",
      "status": "ok",
      "error_messages": null
    }
  ],
  "results": [
    {
      "provider": "google",
      "title": "zarmeza (Eleazar Meza) · GitHub",
      "link": "https://github.com/zarmeza"
    },
    {
      "provider": "bing",
      "title": "El shaka: qué significa la señal y dónde se originó",
      "link": "https://www.elnacional.com/gda/el-shaka-que-significa-la-senal-y-donde-se-origino/"
    },
    {
      "provider": "google",
      "title": "Mn Kebd Kebd Elshaka by Maged Elkedwany on Amazon Music ...",
      "link": "https://www.amazon.com/Mn-Kebd-Elshaka-Maged-Elkedwany/dp/B085R8H58G"
    },
    {
      "provider": "bing",
      "title": "Sergio Vega \"El Shaka\" - Quién Es Usted - YouTube",
      "link": "https://www.youtube.com/watch?v=s3_tYVxnOCE"
    },
    {
      "provider": "google",
      "title": "Mexican singer El Shaka killed after denying his murder - BBC News",
      "link": "https://www.bbc.com/news/10429934"
    },
    {
      "provider": "bing",
      "title": "El shaka: qué significa esta señal y dónde se originó",
      "link": "https://www.eluniversal.com.mx/destinos/el-shaka-que-significa-esta-senal-y-donde-se-origino"
    },
    {
      "provider": "google",
      "title": "Sergio Vega (singer) - Wikipedia",
      "link": "https://en.wikipedia.org/wiki/Sergio_Vega_(singer)"
    },
    {
      "provider": "bing",
      "title": "El Shaka (letra y canción) - El Halcon de la sierra ...",
      "link": "https://www.musica.com/letras.asp?letra=1093055"
    },
    {
      "provider": "google",
      "title": "Ahmed Elshaka (@ahmedelshaka) • Instagram photos and videos",
      "link": "https://www.instagram.com/ahmedelshaka/"
    },
    {
      "provider": "bing",
      "title": "Un saludo surfero: El Shaka | Surfeando un charco",
      "link": "https://surfeandouncharco.com/saludo-surfero/"
    },
    {
      "provider": "google",
      "title": "Emara fi elshaka Fi eloda 123 no | Grammar Quiz - Quizizz",
      "link": "https://quizizz.com/admin/quiz/5c7536ac613075001a2be023/emara-fi-elshaka-fi-eloda-123-no"
    },
    {
      "provider": "bing",
      "title": "Sergio Vega - Wikipedia, la enciclopedia libre",
      "link": "https://es.wikipedia.org/wiki/Sergio_Vega"
    },
    {
      "provider": "google",
      "title": "Elshaka Rivera | Facebook",
      "link": "https://www.facebook.com/elshaka.rivera.1"
    },
    {
      "provider": "bing",
      "title": "El Shaka (2012) Online - Película Completa en Español ...",
      "link": "https://www.fulltv.com.ar/peliculas/el-shaka-2012.html"
    },
    {
      "provider": "google",
      "title": "The Violent Death of Sergio 'El Shaka' Vega, Drug Balladeer - WSJ",
      "link": "https://www.wsj.com/articles/BL-SEB-39394"
    },
    {
      "provider": "bing",
      "title": "Shaka - Wikipedia, la enciclopedia libre",
      "link": "https://es.wikipedia.org/wiki/Shaka"
    },
    {
      "provider": "google",
      "title": "Bank Alrahaman Awad Elshaka | Facebook",
      "link": "https://www.facebook.com/bankalrahamanawad.elshaka/photos"
    },
    {
      "provider": "google",
      "title": "Ahmed Elshaka - Bayt.com",
      "link": "https://people.bayt.com/ahmed-elshaka/"
    }
  ]
}
```

## Live version

No longer deployed — the original Heroku app is down and the free tier it used is gone.
Run it locally with `bundle install && rails server`; see the Docker section below for the
containerized version.

## Installation and getting started

```
git clone https://github.com/zarmeza/omnisearch-rails
cd 'omnisearch-rails'
bundle install
cp .env.sample .env      # then fill in whichever providers you have keys for
bundle exec rails s
```

Then prepare the cache database (see [Caching](#caching-solid-cache) below):

```
bundle exec ruby bin/prepare-cache
bundle exec rails s
```

That is the whole setup. **No external service is required** — no Redis, no
database server, nothing to install beyond the gems. The cache is a SQLite file
the app creates for itself.

### Environment variables

| Variable | Required | Purpose |
|---|---|---|
| `GOOGLE_ENGINE_ID` | for Google | Custom Search engine id |
| `GOOGLE_API_KEY` | for Google | Custom Search API key |
| `BING_SUBSCRIPTION_KEY` | reserved | Not yet used; the Bing integration scrapes `bing.com` and needs no key |

Both search providers are optional. A search runs against whichever are
configured, and the response reports the status of each provider individually.

### Caching (Solid Cache)

Provider responses are cached for 15 minutes to stay inside API quotas, using
[Solid Cache](https://github.com/rails/solid_cache) — the Rails 8 default. It
stores entries in the app's own database, so there is no Redis to install or
operate.

The cache lives in its own SQLite file (`db/cache_development.sqlite3`), separate
from the primary database. That is deliberate: the cache is disposable, so
deleting it should cost one cold search and nothing else. A corrupt or oversized
cache can never take the primary database with it.

Prepare it once per environment:

```
bundle exec ruby bin/prepare-cache          # development
RAILS_ENV=test bundle exec ruby bin/prepare-cache   # test
```

If the cache is unavailable the app **runs uncached rather than failing**. A
cache outage logs one warning per process and degrades performance, never
availability — the reasoning is in `app/services/search_cache.rb`.

### Testing

```
bundle exec rspec
```

The suite needs no external service: no network, no database server, no Redis.
WebMock is enabled suite-wide with `disable_net_connect!`, so a test that forgets
to stub an HTTP call fails loudly instead of quietly depending on Google, Bing,
or any other third party.

Seven examples exercise the **real** Solid Cache stack against a SQLite file, so
they assert on the actual schema rather than a mock. They **skip themselves** if
the test cache database has not been prepared, which keeps a fresh clone green:

```
RAILS_ENV=test bundle exec ruby bin/prepare-cache
bundle exec rspec
```

Line coverage is **99.8%**. The `coverage/` report is generated locally and
gitignored.

## Docker

### With docker compose

One service. The cache database is created on first boot and kept in a named
volume:

```
cp .env.sample .env    # add your provider keys
docker compose up
```

### Building the image directly

```
docker build . -t omnisearch-rails
```

The image runs `bin/prepare-cache` before starting the server, so the cache
schema is in place on first boot.

Then a simple way to run a container with it could be:


```
docker run --network host \
--env GOOGLE_ENGINE_ID=<YOUR GOOGLE ENGINE ID> \
--env GOOGLE_API_KEY=<YOUR GOOGLE API KEY> \
--env BING_SUBSCRIPTION_KEY=<YOUR BING SUBSCRIPTION KEY> \
omnisearch-rails
```

The server should be available at ```localhost:3000``` just as if you would be running it locally.

## Technologies used

- Rails 8.1
- Ruby 4.0
- HTTParty
- Solid Cache (cache in the app's own database, degrades gracefully)
- SQLite
- RSpec, SimpleCov, WebMock
- Docker

## Author

👤 **Eleazar Meza**

- Github: [@zarmeza](https://github.com/zarmeza)
- Twitter: [@zarmeza](https://twitter.com/zarmeza)
- Linkedin: [Eleazar Meza](https://www.linkedin.com/in/zarmeza/)
