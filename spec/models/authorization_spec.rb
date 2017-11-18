require 'rails_helper'
require 'bcrypt'

describe Authorization do
  
  describe "creating an identity" do

    before(:each) do 
      crypted_password = BCrypt::Password.create("pass").to_s
    end

    it "can't create an identity without an email" do
      cust = create(:customer, :email => nil, :force_valid => true)
      auth = Authorization.update_or_create_identity(cust)
      expect(auth).to be_nil
    end

    it "should create a new identity" do
      cust = create(:customer, :email => 'email@email.com', :password => "pass")
      auth = Authorization.update_or_create_identity(cust)
      crypted_password = BCrypt::Password.create("password").to_s
      expect(auth).not_to be_nil
      expect(auth.provider).to eq("Identity")
      expect(auth.uid).to eq("email@email.com")
      expect(BCrypt::Password.new(auth.password_digest)).to eq("pass")
    end

    it "should survive no password" do
    	cust = create(:customer, :email => 'email@email.com', :password => nil, :force_valid => true)
      auth = Authorization.update_or_create_identity(cust)
      expect(auth).not_to be_nil
      expect(auth.password_digest).not_to be_nil
      expect(auth.password_digest.length).to eq(6)
    end
  
  end

  describe "updating an identity" do

    before(:each) do 
    	@crypted_password_1 = BCrypt::Password.create("pass1").to_s
    	@crypted_password_2 = BCrypt::Password.create("pass2").to_s
    end

    it "should update existing password" do
    	cust = create(:customer, :email => 'email@email.com', :password => "pass2")
      old_auth = create(:authorization, :provider => "Identity", :uid => 'email@email.com', :password_digest => @crypted_password_1, :customer => cust)
      
      auth = Authorization.update_or_create_identity(cust)
      expect(auth).not_to be_nil
      expect(BCrypt::Password.new(auth.password_digest)).to eq("pass2")
    end

    it "should survive no password" do
    	cust = create(:customer, :email => 'email@email.com', :password => nil, :force_valid => true)
      auth = Authorization.update_or_create_identity(cust)
      expect(auth).not_to be_nil
      expect(auth.password_digest).not_to be_nil
      expect(auth.password_digest.length).to eq(6) # random 6 digit password is created initially, and calling update_or_create_identity again does not update password to nil
    end

    it "should update email" do
    	cust = create(:customer, :email => 'email2@email.com')
    	old_auth = create(:authorization, :provider => "Identity", :uid => 'email1@email.com', :customer => cust)
    	
    	auth = Authorization.update_identity_email(cust)
    	expect(auth).not_to be_nil
      expect(auth.uid).to eq("email2@email.com")
    end
  
  end

end