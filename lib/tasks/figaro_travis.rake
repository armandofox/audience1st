namespace :figaro do
  namespace :travis do
    desc "Set Figaro's (config/application.yml) environment variables for Travis CI REPO (e.g. yourusername/reponame) using TRAVIS_TOKEN for authentication.  Does not affect Travis env variables not listed in application.yml."
    task :set => :environment do
      # because it's the TEST environment, don't let Webmock block our API requests!
      WebMock.disable! if defined?(WebMock)
      abort 'Usage: RAILS_ENV=test [REPO=myname/myrepo] [TRAVIS_TOKEN=travis-api-token] rake figaro:travis:set' if
        ! Rails.env.test?  ||
        (repo = ENV['REPO']).blank?  ||
        (token = ENV['TRAVIS_TOKEN']).blank?
      Travis.access_token = token
      env_vars = Travis::Repository.find(repo).env_vars
      Figaro.load.each_pair do |key,value|
        env_vars.upsert(key, value, :public => false)
      end
    end
  end
end

      
