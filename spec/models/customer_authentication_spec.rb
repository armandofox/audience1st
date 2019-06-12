require 'rails_helper'

describe Customer, 'authentication' do
  before :each do
    @quentin = create :customer, first_name: 'quentin', last_name: 'q', email: 'quentin@example.com', password: 'monkey', password_confirmation: 'monkey', created_at: 5.days.ago, remember_token_expires_at: 1.day.from_now, remember_token: '77de68daecd823babbb58edb1c8e14d7106e83bb'
  end
  it 'resets password' do
    expect(@quentin.update_attributes!(:password => 'new password', :password_confirmation => 'new password')).not_to be_falsey
    expect(Customer.authenticate(@quentin.email, 'new password')).to eq(@quentin)
  end

  it 'does not rehash password' do
    expect(@quentin.update_attributes(:email => 'quentin2@email.com')).not_to be_falsey
    expect(Customer.authenticate('quentin2@email.com', 'monkey')).to eq(@quentin)
  end

  #
  # Authentication
  #

  it 'authenticates user' do
    expect(Customer.authenticate(@quentin.email, 'monkey')).to eq(@quentin)
    expect(Customer.authenticate(@quentin.email, 'monkey').errors).to be_empty
  end

  context "invalid login" do
    it "should display a password-incorrect message for bad password" do
      expect(Customer.authenticate(@quentin.email, 'invalid_password').errors[:login_failed]).
        to include_match_for(/password seems to be incorrect/i)
    end
    it "should display an unknown-username message for bad username" do
      expect(Customer.authenticate('asdkfljhadf@email.com', 'pass').errors[:login_failed]).
        to include_match_for(/can't find that email/i)
    end
  end

  # old-school passwords
  it "authenticates a user against a hard-coded old-style password" do
    old_password_holder = create :customer, email: 'salty_dog@example.com', salt: '7e3041ebc2fc05a40c60028e2c4901a81035d3cd', crypted_password: '00742970dc9e6319f8019fd54864d3ea740f04b1', created_at: 1.day.ago
    expect(Customer.authenticate(old_password_holder.email, 'test')).to eq(old_password_holder)
  end

  # New installs should bump this up and set REST_AUTH_DIGEST_STRETCHES to give a 10ms encrypt time or so
  desired_encryption_expensiveness_ms = 0.1
  it "takes longer than #{desired_encryption_expensiveness_ms}ms to encrypt a password" do
    test_reps = 100
    start_time = Time.current; test_reps.times{ Customer.authenticate('quentin', 'monkey'+rand.to_s) }; end_time   = Time.current
    auth_time_ms = 1000 * (end_time - start_time)/test_reps
    expect(auth_time_ms).to be > desired_encryption_expensiveness_ms
  end

  #
  # Authentication
  #

  it 'sets remember token' do
    @quentin.remember_me
    expect(@quentin.remember_token).not_to be_nil
    expect(@quentin.remember_token_expires_at).not_to be_nil
  end

  it 'unsets remember token' do
    @quentin.remember_me
    expect(@quentin.remember_token).not_to be_nil
    @quentin.forget_me
    expect(@quentin.remember_token).to be_nil
  end

  it 'remembers me for one week' do
    before = 1.week.from_now.utc
    @quentin.remember_me_for 1.week
    after = 1.week.from_now.utc
    expect(@quentin.remember_token).not_to be_nil
    expect(@quentin.remember_token_expires_at).not_to be_nil
    expect(@quentin.remember_token_expires_at.between?(before, after)).to be_truthy
  end

  it 'remembers me until one week' do
    time = 1.week.from_now.utc
    @quentin.remember_me_until time
    expect(@quentin.remember_token).not_to be_nil
    expect(@quentin.remember_token_expires_at).not_to be_nil
    expect(@quentin.remember_token_expires_at).to eq(time)
  end

  it 'remembers me default two weeks' do
    before = 2.weeks.from_now.utc
    @quentin.remember_me
    after = 2.weeks.from_now.utc
    expect(@quentin.remember_token).not_to be_nil
    expect(@quentin.remember_token_expires_at).not_to be_nil
    expect(@quentin.remember_token_expires_at.between?(before, after)).to be_truthy
  end

end
