FROM ruby:4.0.7
WORKDIR /app

# Install gems.
COPY Gemfile Gemfile.lock /app/
RUN bundle install --jobs 4 --retry 3

# App files
COPY . /app/

EXPOSE 3000
CMD ["bundle", "exec", "rails", "s", "-p", "3000"]
