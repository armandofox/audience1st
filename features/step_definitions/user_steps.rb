RE_User      = %r{(?:(?:the )? *(\w+) *)}
RE_User_TYPE = %r{(?: *(\w+)? *)}

#
# Setting
#

Given "an anonymous customer" do
  log_out!
end

Given "$an $user_type custome with $attributes" do |_, user_type, attributes|
  create_user! user_type, attributes.to_hash_from_story
end

Given "$an $user_type customer named '$login'" do |_, user_type, login|
  create_user! user_type, named_user(login)
end

Given "$an $user_type customer logged in as '$login'" do |_, user_type, login|
  create_user! user_type, named_user(login)
  log_in_user!
end

Given "$actor is logged in" do |_, login|
  log_in_user! @user_params || named_user(login)
end

Given "there is no $user_type customer named '$login'" do |_, login|
  @user = Customer.find_by_login(login)
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
  user = named_user(login)
  user['password_confirmation'] = user['password']
  create_user user
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
Then "$actor should be invited to sign in" do |_|
  response.should render_template('/sessions/new')
end

Then "$actor should not be logged in" do |_|
  controller.logged_in?.should_not be_true
end

Then "$login should be logged in" do |login|
  controller.logged_in?.should be_true
  controller.current_user.should === @user
  controller.current_user.login.should == login
end

def named_user login
  user_params = {
    'admin'   => {'id' => 1, 'login' => 'addie', 'password' => '1234addie', 'email' => 'admin@example.com', :first_name => 'Addie', :last_name => 'Admin'    },
    'oona'    => {          'login' => 'oona',   'password' => '1234oona',  'email' => 'unactivated@example.com', :first_name => 'Oona', :last_name => 'Ooblick' },
    'reggie'  => {          'login' => 'reggie', 'password' => 'monkey',    'email' => 'registered@example.com', :first_name => 'Reggie', :last_name => 'Registered'},
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
end

def log_out!
  log_out
  response.should redirect_to(login_path)
  follow_redirect!
end

def create_user(user_params={})
  @user_params       ||= user_params
  post "/customers/user_create", :customer => user_params
  @user = Customer.find_by_login(user_params['login'])
  @user.should_not be_nil
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
  @user = Customer.find_by_login(user_params['login'])
  controller.current_user
end

def log_in_user! *args
  log_in_user *args
  follow_redirect!
  response.should contain("Welcome,")
end
