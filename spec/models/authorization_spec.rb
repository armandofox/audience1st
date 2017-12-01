require 'rails_helper'
require 'bcrypt'

describe Authorization do

  describe "moving a customer to the new system" do
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

  describe "creating authorizations with omniauth-identity" do
    
    before(:each) do
      @auth_hash = {}
      @auth_hash[:uid] = "email@email.com"
      @auth_hash[:provider] = "identity"
      @customer_params = instance_double("params", :to_h => {})
      allow(@customer_params).to receive(:permit).and_return(@customer_params)
    end

    it "should update automatically created identities" do
      create(:authorization, :provider => nil, :customer => nil, :uid => "email@email.com")
      auth = Authorization.create_user_identity("email@email.com", 2, "pass").identity

      expect(auth).not_to be_nil
      expect(auth.provider).to eq("identity")
      expect(auth.customer_id).to eq(2) 
    end

     it "should delete wrongly created identity" do
      create(:authorization, :provider => nil, :customer => nil, :uid => nil)
      auth = Authorization.create_user_identity(nil, 2, nil)
      expect(auth).to be_nil
    end

  end

end