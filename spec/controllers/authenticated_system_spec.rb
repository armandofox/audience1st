require File.dirname(__FILE__) + '/../spec_helper'

include AuthenticatedSystem
describe SessionsController do
  fixtures :customers
  
  before do
    # FIXME -- sessions controller not testing xml logins 
    stub!(:authenticate_with_http_basic).and_return nil
    stub!(:reset_shopping)
    stub!(:logger).and_return(mock('logger',:null_object => true))
  end    
  describe "logout_killing_session!" do
    before do
      login_as :quentin
      stub!(:reset_session)
    end
    it 'resets the session'         do should_receive(:reset_session);         logout_killing_session! end
    it 'kills my auth_token cookie' do should_receive(:kill_remember_cookie!); logout_killing_session! end
    it 'nils the current user'      do logout_killing_session!; current_user.should be_false end
    it 'kills :user_id session' do
      session.stub!(:[]=)
      session.should_receive(:[]=).with(:cid, nil).at_least(:once)
      logout_killing_session!
    end
    it 'forgets me' do    
      current_user.remember_me
      current_user.remember_token.should_not be_nil; current_user.remember_token_expires_at.should_not be_nil
      Customer.find(9991).remember_token.should_not be_nil
      Customer.find(9991).remember_token_expires_at.should_not be_nil
      logout_killing_session!
      Customer.find(9991).remember_token.should     be_nil
      Customer.find(9991).remember_token_expires_at.should     be_nil
    end
  end

  describe "logout_keeping_session!" do
    before do
      login_as :quentin
      stub!(:reset_session)
    end
    it 'does not reset the session' do should_not_receive(:reset_session);   logout_keeping_session! end
    it 'kills my auth_token cookie' do should_receive(:kill_remember_cookie!); logout_keeping_session! end
    it 'nils the current user'      do logout_keeping_session!; current_user.should be_false end
    it 'kills :user_id and admin id of session' do
      session.should_receive(:[]=).with(:cid, nil).at_least(:once).and_return(nil)
      session.should_receive(:[]=).with(:admin_id, nil).at_least(:once).and_return(nil)    
      logout_keeping_session!
    end
    it 'forgets me' do    
      current_user.remember_me
      current_user.remember_token.should_not be_nil
      current_user.remember_token_expires_at.should_not be_nil
      Customer.find(9991).remember_token.should_not be_nil
      Customer.find(9991).remember_token_expires_at.should_not be_nil
      logout_keeping_session!
      Customer.find(9991).remember_token.should     be_nil
      Customer.find(9991).remember_token_expires_at.should     be_nil
    end
  end
  
  #
  # Cookie Login
  #
  describe "Logging in by cookie" do
    def set_remember_token token, time
      @user[:remember_token]            = token; 
      @user[:remember_token_expires_at] = time
      @user.save!
    end    
    before do 
      @user = customers(:tom)
      set_remember_token 'hello!', 5.minutes.from_now
    end    
    it 'logs in with cookie' do
      stub!(:cookies).and_return({ :auth_token => 'hello!' })
      logged_in?.should be_true
    end
    
    it 'fails cookie login with bad cookie' do
      should_receive(:cookies).at_least(:once).and_return({ :auth_token => 'i_haxxor_joo' })
      logged_in?.should_not be_true
    end
    
    it 'fails cookie login with no cookie' do
      set_remember_token nil, nil
      should_receive(:cookies).at_least(:once).and_return({ })
      logged_in?.should_not be_true
    end
    
    it 'fails expired cookie login' do
      set_remember_token 'hello!', 5.minutes.ago
      stub!(:cookies).and_return({ :auth_token => 'hello!' })
      logged_in?.should_not be_true
    end
  end
  
  describe "admin switching" do
    before(:each) do
      @boxoffice_manager = customers(:boxoffice_manager)
      @quentin = customers(:quentin)
      login_as(:boxoffice_manager)
      current_user.id.should == @boxoffice_manager.id
      current_admin.id.should == @boxoffice_manager.id
    end
    context "any switching operation", :shared => true do
      it "should not change the admin user" do ; current_admin.id.should == @boxoffice_manager.id  ; end
    end
    context "to an existing user" do
      before(:each) do ; act_on_behalf_of(@quentin) ; end
      it "should change the active user" do
        current_user.id.should == @quentin.id
      end
      it_should_behave_like "any switching operation"
    end
    context "to a nonexistent user" do
      before(:each) do ; act_on_behalf_of(nil) ; end
      it "should not switch the user" do
        current_user.id.should == @boxoffice_manager.id
      end
      it_should_behave_like "any switching operation"
    end
  end
end
