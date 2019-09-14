require 'rails_helper'

describe Customer do
  describe "when created as gift recipient only" do
    class Customer
      def without(attr)
        self.send("#{attr}=", '')
        self
      end
    end
    before(:each) do
      @c = Customer.new({
          :first_name => "Tom", :last_name => "Turkey",
          :street => "742 Evergreen Terr", :city => "Springfield",
          :state => "MA", :zip => "02222",
          :day_phone => "999-999-9999",
          :email => "tom@turkey.com"
        })
      @c.created_by_admin = nil
      @c.gift_recipient_only = true
    end
    it "should require first name" do ; expect(@c.without(:first_name)).not_to be_valid ;  end
    it "should require last name" do ;  expect(@c.without(:last_name)).not_to be_valid;    end
    it "should be valid if email but no phone" do ; expect(@c.without(:day_phone)).to be_valid ; end
    it "should be valid if phone but no email" do ; expect(@c.without(:email)).to be_valid ; end
    it "should be invalid if neither phone nor email" do
      expect(@c.without(:email).without(:day_phone)).not_to be_valid
    end
  end
  
  describe "when created by admin" do
    def new_by_admin(args={})
      (c = Customer.new(args)).created_by_admin = true
      c
    end
    before(:each) do
      @customer = new_by_admin(:first_name => "John", :last_name => "Do",
        :email => "johndoe111@yahoo.com",
        :password => "pass", :password_confirmation => "pass")
    end
    it "should not require email address" do
      @customer.email = nil
      expect(@customer).to be_valid
      expect { @customer.save! }.not_to raise_error
    end
    it "should not require password" do
      @customer.password = @customer.password_confirmation = nil
      expect(@customer).to be_valid
      expect { @customer.save! }.not_to raise_error
    end
    it "should be valid if only first initial and last name provided" do
      @customer = new_by_admin(:first_name => 'A', :last_name => 'Fox')
      expect(@customer).to be_valid
    end
  end
  describe "when created using force_valid" do
    before :each do 
      @customer = build(:customer)
      @customer.force_valid = true
    end
    attrs = [
      :first_name, '<bad',
      :email, 'N/A',
      :email, nil,
      :last_name, '',
      :first_name, 'A',
      :zip, 'N/A',
      :street, nil,
      :city, 'N/A',
      :state, ' ',
    ]
    attrs.each_slice(2) do |attr|
      it "should survive invalid #{attr[0]}" do
        @customer.send("#{attr[0]}=", attr[1])
        expect { @customer.save! }.not_to raise_error
        expect(@customer).to be_valid
      end
    end
    describe "should react to duplicate email" do
      before :each do
        @existing = create(:customer)
        @customer.email = @existing.email
      end
      it "without raising an exception" do
        expect { @customer.save! }.not_to raise_error
      end
      it "by blanking out email" do
        @customer.save!
        expect(@customer.email).to be_blank
      end
    end
  end
  describe "when self-created" do
    before(:each) do
      @customer = Customer.new(:first_name => "John", :last_name => "Do",
        :email => "johndoe111@yahoo.com",
        :street => '123 Fake St', :city => 'Oakland', :state => 'CA', :zip => '94611',
        :password => "pass", :password_confirmation => "pass")
    end
    it "should allow &" do
      @customer.first_name = "John & Mary"
      expect(@customer).to be_valid
    end
    it "should allow /" do
      @customer.last_name = "Smith/Jones"
      expect(@customer).to be_valid
    end
    it "should allow lists" do
      @customer.first_name = "John, Mary, & Joan"
      expect(@customer).to be_valid
    end
    it "should disallow potential HTML/Javascript tags" do
      @customer.last_name = "<Doe>"
      expect(@customer).not_to be_valid
    end
    it "should require valid email address" do
      @customer.email = nil
      expect(@customer).not_to be_valid
    end
    it "should reject invalid email address" do
      @customer.email = "NotValidAddress"
      expect(@customer).not_to be_valid
      expect(@customer.errors[:email]).not_to be_empty
    end
    context "with email domain restriction" do
      it "rejects nonmatching address" do
        Option.first.update_attributes!(:restrict_customer_email_to_domain => 'audience1st.com')
        @customer.email = 'bob@not.gmail.com'
        expect(@customer).not_to be_valid
        expect(@customer.errors[:email]).to include_match_for(/must end in 'audience1st.com'/)
      end
      it "allows matching address" do
        Option.first.update_attributes!(:restrict_customer_email_to_domain => 'audience1st.com')
        @customer.email = 'bob_joyc123@Audience1st.COM'
        expect(@customer).to be_valid
      end
      it "exempts existing customers" do
        @customer.email = 'bob@not-gmail.com'
        @customer.save!
        Option.first.update_attributes!(:restrict_customer_email_to_domain => 'audience1st.com')
        @customer.last_name = 'Jones'
        expect(@customer).to be_valid
        expect { @customer.save! }.not_to raise_error
      end
    end
    it "should allow any subdomain if admin-specified restriction is blank" do
      @customer.email = 'bob@not.gmail.com'
      expect(@customer).to be_valid
    end
    it "should require password" do
      @customer.password = @customer.password_confirmation = ''
      expect(@customer).not_to be_valid
      expect(@customer.errors[:password].join(",")).to match(/too short/i)
    end
    it "should require nonblank password confirmation" do
      @customer.password_confirmation = ''
      expect(@customer).not_to be_valid
      expect(@customer.errors[:password_confirmation]).to include_match_for(/doesn't match/i)
    end
    it "should require matching password confirmation" do
      @customer.password_confirmation = "DoesNotMatch"
      expect(@customer).not_to be_valid
      expect(@customer.errors[:password_confirmation]).to include_match_for(/doesn't match/i)
    end
  end
end
