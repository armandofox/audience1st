# A1 hasn't been verified as thread-safe, so we use only workers, not threads.
# Heroku says "2 to 4" workers should be able to run within the memory
# footprint of a single dyno.  The values here can be overridden by
# setting envariables.
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 1)
threads threads_count, threads_count

preload_app!

port        ENV['PORT']     || 3000
environment ENV['RAILS_ENV'] || 'development'
