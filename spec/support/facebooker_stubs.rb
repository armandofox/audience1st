# support for stubbing out some Facebooker functionality for unit and
# integration tests
  
module AuthenticatedSystem
  @@fb_user = nil
  def self.set_fake_facebook_user!(user)
    @@fb_user = user
  end
  def login_from_facebook
    @@fb_user ? current_user = @@fb_user : nil
  end
end

