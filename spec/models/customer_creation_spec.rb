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
    it "should require first name" do ; @c.without(:first_name).should_not be_valid ;  end
    it "should require last name" do ;  @c.without(:last_name).should_not be_valid;    end
    it "should be valid if email but no phone" do ; @c.without(:day_phone).should be_valid ; end
    it "should be valid if phone but no email" do ; @c.without(:email).should be_valid ; end
    it "should be invalid if neither phone nor email" do
      @c.without(:email).without(:day_phone).should_not be_valid
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
      @customer.should be_valid
      lambda { @customer.save! }.should_not raise_error
    end
    it "should not require password" do
      @customer.password = @customer.password_confirmation = nil
      @customer.should be_valid
      lambda { @customer.save! }.should_not raise_error
    end
    it "should be valid if only first initial and last name provided" do
      @customer = new_by_admin(:first_name => 'A', :last_name => 'Fox')
      @customer.should be_valid
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
        lambda { @customer.save! }.should_not raise_error
        @customer.should be_valid
      end
    end
    describe "should react to duplicate email" do
      before :each do
        @existing = create(:customer)
        @customer.email = @existing.email
      end
      it "without raising an exception" do
        lambda { @customer.save! }.should_not raise_error
      end
      it "by blanking out email" do
        @customer.save!
        @customer.email.should be_blank
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
      @customer.should be_valid
    end
    it "should allow /" do
      @customer.last_name = "Smith/Jones"
      @customer.should be_valid
    end
    it "should allow lists" do
      @customer.first_name = "John, Mary, & Joan"
      @customer.should be_valid
    end
    it "should disallow potential HTML/Javascript tags" do
      @customer.last_name = "<Doe>"
      @customer.should_not be_valid
    end
    it "should require valid email address" do
      @customer.email = nil
      @customer.should_not be_valid
    end
    it "should reject invalid email address" do
      @customer.email = "NotValidAddress"
      @customer.should_not be_valid
      @customer.errors[:email].should_not be_empty
    end
    it "should require password" do
      @customer.password = @customer.password_confirmation = ''
      @customer.should_not be_valid
      @customer.errors[:password].join(",").should match(/too short/i)
    end
    it "should require nonblank password confirmation" do
      @customer.password_confirmation = ''
      @customer.should_not be_valid
      @customer.errors[:password].should match(/doesn't match confirmation/i)
    end
    it "should require matching password confirmation" do
      @customer.password_confirmation = "DoesNotMatch"
      @customer.should_not be_valid
      @customer.errors[:password].should match(/doesn't match confirmation/i)
    end
  end
end
