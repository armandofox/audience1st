module Hominid
  module Security
    
    # SECURITY RELATED METHODS
    
    def add_api_key(username, password)
      # Add an API Key to your account. We will generate a new key for you and return it.
      #
      # Parameters:
      # username (String) = Your Mailchimp account username.
      # password (String) = Your Mailchimp account password.
      #
      # Returns:
      # A new API Key that can be immediately used.
      #
      @chimpApi.call("apikeyAdd", username, password, @config[:api_key])
    end
    
    def api_keys(username, password, expired = false)
      # Retrieve a list of all MailChimp API Keys for this User.
      #
      # Parameters:
      # username (String)   = Your Mailchimp account username.
      # password (String)   = Your Mailchimp account password.
      # expired  (Boolean)  = Whether or not to include expired keys, defaults to false.
      #
      # Returns:
      # An array of API keys including:
      #   apikey      (String) = The api key that can be used.
      #   created_at  (String) = The date the key was created.
      #   expired_at  (String) = The date the key was expired.
      #
      @chimpApi.call("apikeys", username, password, @config[:api_key], expired)
    end
    
    def expire_api_key(username, password)
      # Expire a Specific API Key.
      #
      # Returns:
      # True if successful, error code if not.
      #
      @chimpApi.call("apikeyExpire", username, password, @config[:api_key])
    end
    
  end
end