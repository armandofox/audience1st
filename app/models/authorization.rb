require 'bcrypt'
# class Authorization < ActiveRecord::Base
class Authorization < OmniAuth::Identity::Models::ActiveRecord
  belongs_to :customer, foreign_key: "customer_id"
  validates :uid,
            uniqueness: true,
            format: {:with => /\A\S+@\S+\z/}, 
            allow_blank: true,
            on: :create
  validates :password, :length => {:within => 1..20}
  SELF_TXN_COMMENT = 'new customer self-signup'
  ADMIN_TXN_COMMENT = 'new customer added'

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
  def self.find_or_create_user_identity(auth_hash, customer_params, admin_created, admin_id)
    if auth = find_by(uid: auth_hash[:uid], provider: auth_hash[:provider])
      # find
      puts "found old auth"
      cust = auth.customer
    elsif auth = find_by(uid: auth_hash[:uid], provider: nil)
      # edge case that an auth was user created with no email given. No way to check this until now, so destroy auth and return error 
      puts "create"
      puts "admin_created:"
      puts admin_created
      puts "uid: "
      puts auth_hash[:uid]

      if !admin_created && auth_hash[:uid].blank?
        puts "edge case"  
        auth.destroy
        auth = Authorization.new
        auth.errors.add(:Email, "is invalid")
        return auth
      end
      puts "after that one"
      # create
      
      # convert params object to safe hash with given info only
      customer_hash = customer_params.permit("first_name", "last_name", "street", "city", "state", "zip",
        "day_phone", "eve_phone", "blacklist", "e_blacklist", "birthday", "comments",
        "secret_question", "secret_answer", "company", "title", "company_url", "company_address_line_1",
        "company_address_line_2", "company_city", "company_state", "company_zip",
        "cell_phone", "work_phone", "work_fax", "best_way_to_contact").to_h

      # create the customer
      cust = Customer.find_or_create!(Customer.new(customer_hash))
      cust.email = auth_hash[:uid]
      cust.save

      # update authorization with new info
      auth.provider = auth_hash[:provider]
      auth.customer = cust
      auth.save
      
      # add txn audit record
      if admin_created
        Txn.add_audit_record(:txn_type => 'edit',
        :customer_id => cust.id,
        :comments => SELF_TXN_COMMENT)
      else
        Txn.add_audit_record(:txn_type => 'edit',
        :customer_id => cust.id,
        :comments => ADMIN_TXN_COMMENT,
        :logged_in_id => admin_id)
      end

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
        auth = new :customer => cust, :provider => "identity", :uid => cust.email, :password_digest => password
        auth.password = cust.password
        auth.save
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