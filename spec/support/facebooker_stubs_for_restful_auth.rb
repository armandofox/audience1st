# support for stubbing out some Facebooker functionality for unit and
# integration tests
  
# module AuthenticatedSystem
#   @@fb_user = nil
#   def self.set_fake_facebook_user!(user) ;  @@fb_user = user ;  end
#   def reset_stubbed_facebook_user! ;        @@fb_user = nil  ;  end
#   # redefine some functions from the original module for testing
#   def login_from_facebook ;  @@fb_user ? current_user = @@fb_user : nil ;  end
# end

class ApplicationController < ActionController::Base
  @@fake_facebook_session = nil
  def facebook_session ; @@fake_facebook_session ; end
  def set_fake_facebook_session!(ses) ; @@fake_facebook_session = ses ; end
  def reset_fake_facebook_session! ; @@fake_facebook_session = nil ; end
end


# class SessionsController < ApplicationController
#   after_filter :reset_stubbed_facebook_user!, :only => :destroy
# end
  
