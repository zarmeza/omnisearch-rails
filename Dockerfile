FROM ruby:4.0.7
WORKDIR /app

# Install gems.
COPY Gemfile Gemfile.lock /app/
RUN bundle install --jobs 4 --retry 3

# App files
COPY . /app/

# Create the cache schema on boot. The cache database is disposable, so this is
# a schema load rather than a migration — there is no history to preserve.
RUN chmod +x bin/prepare-cache

EXPOSE 3000
CMD ["sh", "-c", "bundle exec ruby bin/prepare-cache && bundle exec rails s -p 3000"]
