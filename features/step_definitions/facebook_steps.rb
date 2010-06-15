Given /^I am logged in with linked Facebook account "(.*)"$/ do |cust|
  @customer = customers(cust.to_sym)
  AuthenticatedSystem.set_fake_facebook_user!(@customer)
  @customer.stub!(:facebook_user?).and_return(true)
  current_user = @customer
end

Given /^"(.*)" is logged in with unlinked Facebook account "(.*) +(.*)"$/ do |cust,first,last|
  @customer = customers(cust.to_sym)
  current_user = @customer
end
  
When /^I link with Facebook user "(.*)" id "(.*)"/ do |name,id|
  facebooker = create_facebook_user name, id
  fake_session = stub('fake_fb_session', :user => facebooker)
  controller.set_fake_facebook_session!(fake_session)
  get '/customers/link_user_accounts'
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

def create_facebook_user(name, id=nil)
  Facebooker::User.new(:id => id||rand(1e9), :name => name)
end
