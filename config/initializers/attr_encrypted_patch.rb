# config/initializers/attr_encrypted_patch.rb
# Force Active Record to initialize the hash that the gem relies on.

# Remove when PR #191 is closed

ActiveSupport.on_load(:active_record) do
  class ActiveRecord::Base
    def self.encrypted_attributes
      @encrypted_attributes ||= {}
    end
  end
end
