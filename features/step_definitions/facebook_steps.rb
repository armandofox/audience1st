Given /^I am logged in with linked Facebook account "(.*)"$/ do |cust|
  # Initializer facebooker session
  @integration_session = open_session
  @current_user = customers(cust.to_sym)
  @current_user.update_attribute(:fb_user_id, 1)
  # User#facebook_user returns a Facebook::User instance, i decided to mock the session in here since i am not
  # sure what the behavior might be if it will be in the actual model.
  # @current_user.facebook_user.session = Facebooker::MockSession.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
  #   #@current_user.facebook_user.friends = [ Facebooker::User.new(:id => 2, :name => 'Bob'),
  #   Facebooker::User.new(:id => 3, :name => 'Sam')]
  @integration_session.default_request_params.merge!( :fb_sig_user => @current_user.fb_user_id)
  # , :fb_sig_friends => @current_user.facebook_user.friends.map(&:id).join(',') )
end


Given /^blah I am logged in with linked Facebook account "(.*)"$/ do |cust|
  visit '/logout'
  @customer = customers(cust.to_sym)
  facebooker = create_facebook_user(@customer.first_name)
  @customer.update_attribute(:fb_user_id, facebooker.id)
  fake_session = mock("fake_session_for_#{facebooker}", :user => facebooker)
  controller.stub_facebook_session_with(fake_session)
  login_as(@customer)
end

When /^I login with unlinked Facebook account "(.*)"$/ do |name|
  visit '/logout'
  When "I link with Facebook user \"#{name}\" id \"8888\""
  @customer = controller.send(:current_user)
end
  
When /^I link with Facebook user "(.*)" id "([0-9]+)"$/ do |name,id|
  facebooker = create_facebook_user name, id
  controller.stub_facebook_session_with(mock("fake_session_for_#{facebooker}", :user => facebooker))
  visit '/customers/link_user_accounts'
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
