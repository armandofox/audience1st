Given /^I am logged in via Facebook as "(.*)"$/ do |name|
  @customer = create_generic_user_with_facebook_id
  @current_user = @customer
  # User#facebook_user returns a Facebook::User instance, i decided to mock the session in here since i am not
  # sure what the behavior might be if it will be in the actual model.
  @current_user.facebook_user.session =
    Facebooker::MockSession.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
  # Initialize facebooker session
  @integration_session = open_session
  @integration_session.default_request_params.merge!(
    :fb_sig_user => @current_user.facebook_id)
end

Given /^I have a Facebook friend "(.*)"$/ do |name|
  # add some friends
  @current_user.facebook_user.friends << create_facebook_user(name)
  @integration_session.default_request_params.merge(:fb_sig_friends => @current_user.facebook_user.friends.map(&:id).join(',') )
end


def create_generic_user_with_facebook_id
  u = Customer.new(:fb_user_id => 1)
  u.save(false)
  u
end

def create_facebook_user(name)
  Facebooker::User.new(:id => rand(1e9), :name => name)
end
  
