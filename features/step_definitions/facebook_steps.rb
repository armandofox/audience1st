Given /^I am logged in with linked Facebook account "(.*)"$/ do |cust|
  @customer = customers(cust.to_sym)
  AuthenticatedSystem.set_fake_facebook_user!(@customer)
  @customer.stub!(:facebook_user?).and_return(true)
  current_user = @customer
end

Given /^"(.*)" is logged in with unlinked Facebook account "(.*) +(.*)"$/ do
  @customer = customers(cust.to_sym)
  
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
