ruby '4.0.7'

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 8.1.0'
# Use Puma as the app server
gem 'puma', '~> 6.6'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

gem 'httparty', '~> 0.24'

gem 'redis', '~> 5.4'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails', '~> 8.0'
  gem 'dotenv-rails'
end

group :development do
  gem 'rspec'
end

group :test do
  gem 'simplecov', require: false
  gem 'webmock'
  gem 'mock_redis'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Ruby 4.0 moved these out of the default gem set, so Rails' own requires no
# longer find them. base64, mutex_m and drb were already declared here for the
# same reason.
gem "base64", "~> 0.2.0"
gem "bigdecimal", "~> 3.1"
gem "cgi", "~> 0.5"

gem "mutex_m", "~> 0.2.0"
gem "drb", "~> 2.2"
