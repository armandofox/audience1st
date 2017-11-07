require 'rails_helper'

# Be sure to include AuthenticatedTestHelper in spec/rails_helper.rb instead
# Then, you can remove it from this and the units test.

describe SessionsController do
  before(:each) do 
    ApplicationController.send(:public, :current_user, :current_user)
    @user  = create(:customer)
    @login_params = { :email => 'quentin@email.com', :password => 'test' }
    allow(Customer).to receive(:authenticate).with(@login_params[:email], @login_params[:password]).and_return(@user)
    allow(@user).to receive(:bcrypted?).and_return(true)
  end
  it "links existing users to omniauth accounts" do
    request.env['omniauth.auth'] = true
    (@controller).stub(:logged_in?).and_return(true)
    (@controller).stub(:current_user).and_return(@user)
    expect(@user).to receive(:add_provider).with(true).and_return(nil)
    post(:create, @login_params)
  end
  it "creates or finds omniauth accounts" do
    request.env['omniauth.auth'] = true
    (@controller).stub(:logged_in?).and_return(false)
    expect(Authorization).to receive(:find_or_create_user).with(true).and_return(nil)
    post(:create, @login_params)
  end 
  it "bcrypts passwords if necessary" do
    # (@controller).stub(:u).and_return(@user)
    allow(@user).to receive(:bcrypted?).and_return(false)
    expect(@user).to receive(:bcrypt_password_storage).at_least(:once).with('test').and_return(nil)
    post(:create, @login_params)
  end
  # Login for an admin
  describe 'admin view' do
    before(:each) do
      login_as_boxoffice_manager
      # we must set an action FROM WHICH this request was given
      request.env['HTTP_REFERER'] = customer_path(:boxoffice_manager)
    end
    it 'can be disabled' do
      get :temporarily_disable_admin
      @controller.send(:is_boxoffice).should_not be_truthy
    end
    it 'can be reenabled' do
      get :reenable_admin
      @controller.send(:is_boxoffice).should be_truthy
    end
  end

  describe "on successful login," do
    [ [:nil,       nil,            nil],
      [:expired,   'valid_token',  15.minutes.ago],
      [:different, 'i_haxxor_joo', 15.minutes.from_now], 
      [:valid,     'valid_token',  15.minutes.from_now]
        ].each do |has_request_token, token_value, token_expiry|
      [ true, false ].each do |want_remember_me|
        describe "my request cookie token is #{has_request_token.to_s}," do
          describe "and ask #{want_remember_me ? 'to' : 'not to'} be remembered" do 
            before do
              allow(@user).to receive(:login_message).and_return ""
              @home_page = customer_path(@user)
              @ccookies = double('cookies')
              allow(controller).to receive(:cookies).and_return(@ccookies)
              allow(@ccookies).to receive(:[]).with(:auth_token).and_return(token_value)
              allow(@ccookies).to receive(:delete).with(:auth_token)
              allow(@ccookies).to receive(:[]=)
              allow(@user).to receive(:remember_me) 
              allow(@user).to receive(:refresh_token) 
              allow(@user).to receive(:forget_me)
              allow(@user).to receive(:remember_token).and_return(token_value) 
              allow(@user).to receive(:remember_token_expires_at).and_return(token_expiry)
              allow(@user).to receive(:remember_token?).and_return(has_request_token == :valid)
              if want_remember_me
                @login_params[:remember_me] = '1'
              else 
                @login_params[:remember_me] = '0'
              end
            end
            it "updates my last_login" do
              expect(@user).to receive(:update_attribute) do |meth,arg|
                meth.should == :last_login
                arg.should be_a_kind_of(Time)
              end
              post(:create, @login_params)
            end
            it "kills existing login"        do expect(controller).to receive(:logout_keeping_session!); post(:create, @login_params); end    
            it "logs me in"                  do post(:create, @login_params); controller.send(:logged_in?).should  be_truthy  end    
            it "sets/resets/expires cookie"  do expect(controller).to receive(:handle_remember_cookie!).with(want_remember_me); post(:create, @login_params) end
            it "sends a cookie"              do expect(controller).to receive(:send_remember_cookie!);  post(:create, @login_params) end
            it 'redirects to the home page'  do post(:create, @login_params); response.should redirect_to(@home_page)   end
            it "does not reset my session"   do expect(controller).not_to receive(:reset_session); post(:create, @login_params) end # change if you uncomment the reset_session path
            if (has_request_token == :valid)
              it 'does not make new token'   do expect(@user).not_to receive(:remember_me);   post(:create, @login_params) end
              it 'does refresh token'        do expect(@user).to receive(:refresh_token);     post(:create, @login_params) end 
              it "sets an auth cookie"       do post(:create, @login_params);  end
            else
              if want_remember_me
                it 'makes a new token'       do expect(@user).to receive(:remember_me);       post(:create, @login_params) end 
                it "does not refresh token"  do expect(@user).not_to receive(:refresh_token); post(:create, @login_params) end
                it "sets an auth cookie"       do post(:create, @login_params);  end
              else 
                it 'does not make new token' do expect(@user).not_to receive(:remember_me);   post(:create, @login_params) end
                it 'does not refresh token'  do expect(@user).not_to receive(:refresh_token); post(:create, @login_params) end 
                it 'kills user token'        do expect(@user).to receive(:forget_me);         post(:create, @login_params) end 
              end
            end
          end # inner describe
        end
      end
    end
  end
  
  describe "on failed login" do
    before do
      var = 4
      expect(Customer).to receive(:authenticate).with(anything(), anything()).and_return(nil)
      login_as create(:customer, :email => 'quentin@email.com')
    end
    it 'logs out keeping session'   do expect(controller).to receive(:logout_keeping_session!); post(:create, @login_params) end
    it 'flashes an error'           do post(:create, @login_params); flash[:alert].should =~ /Couldn't log you in as 'quentin@email.com'/ end
    it 'renders the log in page'    do post(:create, @login_params); response.should render_template('new')  end
    it "doesn't log me in"          do post(:create, @login_params); controller.send(:logged_in?).should == false end
    it "doesn't send password back" do 
      @login_params[:password] = 'FROBNOZZ'
      post(:create, @login_params)
      response.should_not have_text(/FROBNOZZ/i)
    end
  end

  describe "on signout" do
    def do_destroy
      get :destroy
    end
    before do 
      login_as create(:customer, :email => 'quentin@email.com')
    end
    it 'logs me out'                   do expect(controller).to receive(:logout_killing_session!); do_destroy end
    it 'redirects me to the home page' do do_destroy; response.should be_redirect     end
  end
  
end
