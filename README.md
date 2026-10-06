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
```

In order for the google search to work, you'd need to setup the environment variables GOOGLE_ENGINE_ID and GOOGLE_API_KEY with valid credentials.

For bing search you'd need to provide a bing subscription key using the environment variable BING_SUBSCRIPTION_KEY

You'd also need a redis instance running, the rails app will try to connect by default to ```localhost:6379```, you can also provide a custon redis url setting the environment variable REDIS_URL before running the rails server.

Environment variables are set in a .env file (you can use the .env.sample as a template to create your own).

You could then run the server like this:

```
bundle exec rails s
```

## Testing

To run the test suite simply run rspec

```
bundle exec rspec
```

## Docker image

You can build a docker image of the project by simply running:

```
docker build . -t omnisearch-rails
```

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

- Rails
- HTTParty
- Redis
- Rspec (+ mock-redis)
- Docker

## Author

👤 **Eleazar Meza**

- Github: [@zarmeza](https://github.com/zarmeza)
- Twitter: [@zarmeza](https://twitter.com/zarmeza)
- Linkedin: [Eleazar Meza](https://www.linkedin.com/in/zarmeza/)
