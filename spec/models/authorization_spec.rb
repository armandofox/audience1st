require 'rails_helper'
require 'bcrypt'

describe Authorization do

  describe "moving a customer to the new system" do

    describe "creating an identity" do
      before(:each) do 
        crypted_password = BCrypt::Password.create("pass").to_s
      end
      
      it "can't create an identity without an email" do
        cust = create(:customer, :email => nil, :force_valid => true)
        auth = Authorization.create_identity_for_customer(cust)
        expect(auth.errors).to have(1).error_on(:email)
      end
      
      it "should create a new identity" do
        cust = create(:customer, :email => 'email@email.com', :password => "pass")
        auth = Authorization.create_identity_for_customer(cust)
        crypted_password = BCrypt::Password.create("password").to_s
        expect(auth).not_to be_nil
        expect(auth.provider).to eq("identity")
        expect(auth.uid).to eq("email@email.com")
        expect(BCrypt::Password.new(auth.password_digest)).to eq("pass")
      end
      
      it "should survive no password" do
      	cust = create(:customer, :email => 'email@email.com', :password => nil, :force_valid => true)
        auth = Authorization.create_identity_for_customer(cust)
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
      	cust = create(:customer, :email => 'email@email.com', :password => "pass1")
        Authorization.update_password(cust, "pass2")
        expect(BCrypt::Password.new(cust.identity.password_digest)).to eq("pass2")
      end

      it "should survive no password" do
      	cust = create(:customer, :email => 'email@email.com', :password => nil, :force_valid => true)
        auth = Authorization.create_identity_for_customer(cust)
        expect(auth).not_to be_nil
        expect(auth.password_digest).not_to be_nil
        expect(auth.password_digest.length).to eq(6) # random 6 digit password is created initially, and calling create_identity_for_customer again does not update password to nil
      end
    end
  end

  describe "the identity update methods" do
  
    before(:each) do 
      @cust = create(:customer, :email => 'email@email.com', :password => "pass1")
    end

    it "should update existing password" do
      @crypted_password_2 = BCrypt::Password.create("pass2").to_s
      Authorization.update_password(@cust, "pass2")
      expect(BCrypt::Password.new(@cust.identity.password_digest)).to eq("pass2")
    end

    it "should update existing email" do
      @cust.email = "email2@email.com"
      @cust.save!
      # Authorization.update_identity_email(@cust)
      expect(identity = @cust.identity).not_to be_nil
      expect(identity.uid).to eq("email2@email.com")
    end
  end


end