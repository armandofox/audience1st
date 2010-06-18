RE_User      = %r{(?:(?:the )? *(\w+) *)}
RE_User_TYPE = %r{(?: *(\w+)? *)}

#
# Setting
#

Given "an anonymous customer" do
  log_out!
end

Given "$an $user_type customer with $attributes" do |_, user_type, attributes|
  create_user! user_type, attributes.to_hash_from_story
end

Given "$an $user_type customer named '$email'" do |_, user_type, email|
  create_user! user_type, named_user(email)
end

Given "$an $user_type customer logged in as '$email'" do |_, user_type, email|
  create_user! user_type, named_user(email)
  log_in_user!
end

Given "$actor is logged in" do |_, email|
  log_in_user! @user_params || named_user(email)
end

Given "there is no $user_type customer named '$email'" do |_, email|
  @user = Customer.find_by_email(email)
  @user.destroy! if @user
  @user.should be_nil
end

#
# Actions
#
When "$actor logs out" do
  log_out
end

When "$actor registers an account as the preloaded '$login'" do |_, login|
  @user = named_user(login)
  @user['password_confirmation'] = @user['password']
  create_user @user
end

When "$actor registers an account with $attributes" do |_, attributes|
  create_user attributes.to_hash_from_story
end


When "$actor logs in with $attributes" do |_, attributes|
  log_in_user attributes.to_hash_from_story
end

#
# Result
#
Then "show the errors" do
  puts @user.errors.full_messages.join("\n")
end

Then "$actor should be invited to sign in" do |_|
  response.should render_template('/sessions/new')
end

Then "$actor should not be logged in" do |_|
  controller.send(:logged_in?).should_not be_true
end

Then "$login should be logged in" do |email|
  controller.send(:logged_in?).should be_true
  controller.send(:current_user).email.should == email
end

def named_user login
  user_params = {
    'admin'   => {'id' => 1, 'password' => '1234addie', 'email' => 'admin@example.com', :first_name => 'Addie', :last_name => 'Admin'    },
    'oona'    => {           'password' => '1234oona',  'password_confirmation' => '1234oona','email' => 'unactivated@example.com', :first_name => 'Oona', :last_name => 'Ooblick' },
    'reggie'  => {           'password' => 'monkey',    'email' => 'registered@example.com', :first_name => 'Reggie', :last_name => 'Registered'},
    }
  user_params[login.downcase]
end

#
# User account actions.
#
# The ! methods are 'just get the job done'.  It's true, they do some testing of
# their own -- thus un-DRY'ing tests that do and should live in the user account
# stories -- but the repetition is ultimately important so that a faulty test setup
# fails early.
#

def log_out
  get '/sessions/destroy'
  controller.send(:current_user).should be_false
end

def log_out!
  log_out
  response.should redirect_to(login_path)
  follow_redirect!
end

def create_user(user_params={})
  @user_params       ||= user_params
  post "/customers/user_create", :customer => user_params
end

def create_user!(user_type, user_params)
  user_params['password_confirmation'] ||= user_params['password'] ||= user_params['password']
  create_user user_params
  follow_redirect!
end



def log_in_user user_params=nil
  @user_params ||= user_params
  user_params  ||= @user_params
  post "/session", user_params
  @user = Customer.find_by_email(user_params['email'])
  controller.send(:current_user)
end

def log_in_user! *args
  log_in_user *args
  follow_redirect!
  response.should contain("Welcome,")
end
