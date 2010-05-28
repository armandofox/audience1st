# support for stubbing out some Facebooker functionality for unit and
# integration tests
  
module AuthenticatedSystem
  @@fb_user = nil
  def self.set_fake_facebook_user!(user) ;  @@fb_user = user ;  end
  def reset_stubbed_facebook_user! ;        @@fb_user = nil  ;  end
  def login_from_facebook ;  @@fb_user ? current_user = @@fb_user : nil ;  end
end

class SessionsController < ApplicationController
  after_filter :reset_stubbed_facebook_user!, :only => :destroy
end
  
class Customer
  # stub this method as needed for testing; by default, users behave like regular users
  # who aren't logged in via FB Connect
  def facebook_user? ; nil ; end
end
