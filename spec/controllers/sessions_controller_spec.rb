require 'rails_helper'

# Be sure to include AuthenticatedTestHelper in spec/rails_helper.rb instead
# Then, you can remove it from this and the units test.

describe SessionsController do
  fixtures        :customers
  before(:each) do 
    ApplicationController.send(:public, :current_user, :current_user)
    @user  = mock_user
    @login_params = { :email => 'quentin@email.com', :password => 'test' }
    allow(Customer).to_receive(:authenticate).with(@login_params[:email], @login_params[:password]).and_return(@user)
  end
  # Login for an admin
  describe 'admin view' do
    before(:each) do
      login_as customers(:boxoffice_manager)
      # we must set an action FROM WHICH this request was given
      request.env['HTTP_REFERER'] = customer_path(:boxoffice_manager)
    end
    it 'can be disabled' do
      get :temporarily_disable_admin
      @controller.send(:is_boxoffice).should_not be_true
    end
    it 'can be reenabled' do
      get :reenable_admin
      @controller.send(:is_boxoffice).should be_true
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
              @allow(user).to_receive(:login_message).and_return ""
              @home_page = customer_path(@user)
              @ccookies = mock('cookies')
              allow(controller).to_receive(:cookies).and_return(@ccookies)
              @ccookies.stub!(:[]).with(:auth_token).and_return(token_value)
              @allow(ccookies).to_receive(:delete).with(:auth_token)
              @ccookies.stub!(:[]=)
              @allow(user).to_receive(:remember_me) 
              @allow(user).to_receive(:refresh_token) 
              @allow(user).to_receive(:forget_me)
              @allow(user).to_receive(:remember_token).and_return(token_value) 
              @allow(user).to_receive(:remember_token_expires_at).and_return(token_expiry)
              @allow(user).to_receive(:remember_token?).and_return(has_request_token == :valid)
              if want_remember_me
                @login_params[:remember_me] = '1'
              else 
                @login_params[:remember_me] = '0'
              end
            end
            it "updates my last_login" do
              @user.should_receive(:update_attribute) do |meth,arg|
                meth.should == :last_login
                arg.should be_a_kind_of(Time)
              end
              post(:create, @login_params)
            end
            it "kills existing login"        do controller.should_receive(:logout_keeping_session!); post(:create, @login_params); end    
            it "logs me in"                  do post(:create, @login_params); controller.send(:logged_in?).should  be_true  end    
            it "sets/resets/expires cookie"  do controller.should_receive(:handle_remember_cookie!).with(want_remember_me); post(:create, @login_params) end
            it "sends a cookie"              do controller.should_receive(:send_remember_cookie!);  post(:create, @login_params) end
            it 'redirects to the home page'  do post(:create, @login_params); response.should redirect_to(@home_page)   end
            it "does not reset my session"   do controller.should_not_receive(:reset_session).and_return nil; post(:create, @login_params) end # change if you uncomment the reset_session path
            if (has_request_token == :valid)
              it 'does not make new token'   do @user.should_not_receive(:remember_me);   post(:create, @login_params) end
              it 'does refresh token'        do @user.should_receive(:refresh_token);     post(:create, @login_params) end 
              it "sets an auth cookie"       do post(:create, @login_params);  end
            else
              if want_remember_me
                it 'makes a new token'       do @user.should_receive(:remember_me);       post(:create, @login_params) end 
                it "does not refresh token"  do @user.should_not_receive(:refresh_token); post(:create, @login_params) end
                it "sets an auth cookie"       do post(:create, @login_params);  end
              else 
                it 'does not make new token' do @user.should_not_receive(:remember_me);   post(:create, @login_params) end
                it 'does not refresh token'  do @user.should_not_receive(:refresh_token); post(:create, @login_params) end 
                it 'kills user token'        do @user.should_receive(:forget_me);         post(:create, @login_params) end 
              end
            end
          end # inner describe
        end
      end
    end
  end
  
  describe "on failed login" do
    before do
      Customer.should_receive(:authenticate).with(anything(), anything()).and_return(nil)
      login_as :quentin
    end
    it 'logs out keeping session'   do controller.should_receive(:logout_keeping_session!); post(:create, @login_params) end
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
      login_as :quentin
    end
    it 'logs me out'                   do controller.should_receive(:logout_killing_session!); do_destroy end
    it 'redirects me to the home page' do do_destroy; response.should be_redirect     end
  end
  
end
