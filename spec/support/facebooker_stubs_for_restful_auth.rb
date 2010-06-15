# support for stubbing out some Facebooker functionality for unit and
# integration tests
  
module AuthenticatedSystem
  @@fb_user = nil
  def self.set_fake_facebook_user!(user) ;  @@fb_user = user ;  end
  def reset_stubbed_facebook_user! ;        @@fb_user = nil  ;  end
  # redefine some functions from the original module for testing
  def login_from_facebook ;  @@fb_user ? current_user = @@fb_user : nil ;  end
end

## this doesn't work.  facebook_session itself has to be stubbed, to
##  evaluate to 'true' when referenced by itself (if facebook_session ...)
##  and to be able to stub facebook_session.user (returns an FB User)
##  and facebook_session.user.id.  Then login_from_facebook above won't
##  have to be stubbed, because that screws up testing the 'link my
##  existing acct to fb' flow.

class ApplicationController < ActionController::Base
  @@fake_facebook_session = nil
  def facebook_session ; @@fake_facebook_session ; end
  def set_fake_facebook_session!(ses) ; @@fake_facebook_session = ses ; end
  def reset_fake_facebook_session! ; @@fake_facebook_session = nil ; end
end


class SessionsController < ApplicationController
  after_filter :reset_stubbed_facebook_user!, :only => :destroy
end
  
