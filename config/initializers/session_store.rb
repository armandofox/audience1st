# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_trunk_session_', 
  :secret      => 'b6f7065cfaf7af10e429231efa4d33d55dca47265fc48eaf24338db4991bcaa7139e6c7266a7626253ecfff845618deaa75cb6c7ad2d2af845992e896825a110'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
