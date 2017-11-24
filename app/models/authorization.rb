require 'bcrypt'
# class Authorization < ActiveRecord::Base
class Authorization < OmniAuth::Identity::Models::ActiveRecord
  belongs_to :customer, foreign_key: "customer_id"
  validates :email,
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
      auth = create :customer => c, :provider => auth["provider"], :email => auth["info"]["email"]
      auth.uid = auth.id
      auth.save
    end
    c
  end

  # create customer and update authorization for omniauth-identity
  def self.find_or_create_user(auth_hash, customer_params)
    if auth = find_by(uid: auth_hash[:uid], provider: auth_hash[:provider])
      cust = auth.customer
    elsif auth = find_by(id: auth_hash[:uid], provider: nil)
      # need to create a customer for this user
      customer_hash = customer_params.permit("first_name", "last_name", "street", "city", "state", "zip", "day_phone", "eve_phone", "blacklist", "email", "e_blacklist").to_h #convert params object to safe hash with given info only
      cust = Customer.find_or_create!(Customer.new(customer_hash))
      
      auth.provider = auth_hash[:provider]
      auth.uid = auth_hash[:uid]
      auth.customer = cust
      auth.save!

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
      if auth = find_by_provider_and_uid("identity", cust.email)
        if(password && BCrypt::Password.new(auth.password_digest) != cust.password)
          auth.password_digest = password
          auth.save
        end
      else
        password = String.random_string(6) if cust.password.blank?
        auth = create! :customer => cust, :provider => "identity", :email => cust.email, :password_digest => password
        auth.uid = auth.id
        auth.save
      end
    else
    end
    auth
  end
  def self.update_password(cust, password)
    if auth = find_by(customer_id: cust.id, provider: "identity")
      puts "old"
      puts auth.password_digest
    
      auth.password = password
      bool = auth.save!
    end
    puts "new"
    puts auth.password_digest
    # password_digest = BCrypt::Password.create(password).to_s
    bool
  end
  # updates the email of a given customer
  def self.update_identity_email(cust)
    if auth = find_by(customer_id: cust.id, provider: "identity")
      auth.email = cust.email
      auth.save!
    end
    auth
  end

end