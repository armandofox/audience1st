require 'bcrypt'
# class Authorization < ActiveRecord::Base
class Authorization < OmniAuth::Identity::Models::ActiveRecord
  belongs_to :customer, foreign_key: "customer_id"
  validates :uid ,
            uniqueness: true,
            format: {
              with: /\A[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}\z/i,
              message: "must be formatted correctly"
            }, 
            allow_blank: true,
            on: :create

  # find or create authorization and customer for non-identity omniauth strategies
  def self.find_or_create_user auth
    if user_auth = find_by_provider_and_uid(auth["provider"], auth["uid"])
      c = user_auth.customer
    else
      # create customer
      c = Customer.new
      c.email = auth["info"]["email"]
      customer_name = auth["info"]["name"].split(" ")
      c.first_name = customer_name[0]
      customer_name.shift if customer_name[1]
      c.last_name = customer_name.join("")
      c = Customer.find_or_create! c
      # create authorization
      auth = create :customer => c, :provider => auth["provider"], :uid => auth["uid"]
    end
    c
  end

  def uid
    if respond_to?("read_attribute")
      return nil if read_attribute("uid").nil?
      read_attribute("uid")
    else
      raise NotImplementedError 
    end
  end

  # create customer and update authorization for omniauth-identity
  def self.find_or_create_user_identity(auth_hash, customer_params)
    if auth = find_by(uid: auth_hash[:uid], provider: auth_hash[:provider])
      cust = auth.customer
    elsif auth = find_by(uid: auth_hash[:uid], provider: nil)

      # need to create a customer for this user
      customer_hash = customer_params.permit("first_name", "last_name", "street", "city", "state", "zip", "day_phone", "eve_phone", "blacklist", "e_blacklist").to_h #convert params object to safe hash with given info only
      cust = Customer.find_or_create!(Customer.new(customer_hash))
      
      auth.provider = auth_hash[:provider]
      auth.customer = cust
      auth.save
      
      Txn.add_audit_record(:txn_type => 'edit',
      :customer_id => cust.id,
      :comments => 'new customer self-signup')
    else
      puts "couldn't find identity to create a user for"
    end
    cust
  end

  # create an authorization for omniauth identity given an existing customer (used to migrate an old-style user into the new system)
  def self.create_identity_for_customer(cust) 
    if cust.email
      password = BCrypt::Password.create(cust.password).to_s unless cust.password.blank?       
      unless auth = find_by_provider_and_uid("identity", cust.email)
        password = String.random_string(6) if cust.password.blank?
        auth = create! :customer => cust, :provider => "identity", :uid => cust.email, :password_digest => password
      end
    else
      auth = Authorization.new
      auth.errors.add(:email, "is required to create an identity")
    end
    auth
  end

  # updates the password of a given customer
  def self.update_password(cust, password)
    if auth = find_by(customer_id: cust.id, provider: "identity")
      auth.password = password
      auth.update(password_digest: auth.password_digest)      
    end
    password
  end

  # updates the email of a given customer
  def self.update_identity_email(cust)
    if auth = find_by(customer_id: cust.id, provider: "identity")
      auth.update(uid: cust.email)      
    end
    cust.email
  end

end