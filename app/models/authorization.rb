require 'bcrypt'
# class Authorization < ActiveRecord::Base
class Authorization < OmniAuth::Identity::Models::ActiveRecord
  belongs_to :customer, foreign_key: "customer_id"
  validates :uid,
            uniqueness: true,
            format: {:with => /\A\S+@\S+\z/}, 
            allow_blank: true,
            on: :create
  before_validation do
    if self.password.blank?
      self.password = String.random_string(6) 
      self.password_confirmation = self.password
    end
  end
  # validates :password, allow_blank: true, length: { maximum: 20 }


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
  def self.find_or_create_user_identity(auth_hash, cust)
    if auth = find_by(uid: auth_hash[:uid], provider: auth_hash[:provider])
      # find
      cust = auth.customer
    elsif auth = find_by(uid: auth_hash[:uid], provider: nil)
      # create

      # edge case that an auth was user created with no email given. No way to check this until now, so destroy auth and return error 
      if auth_hash[:uid].blank?
        auth.destroy
        return
      end
    
      # update authorization with new info
      auth.provider = auth_hash[:provider]
      auth.customer_id = cust
      auth.save

    else
      puts "couldn't find identity"
    end
    cust
  end

  # create an authorization for omniauth identity given an existing customer (used to migrate an old-style user into the new system)
  def self.create_identity_for_customer(cust) 
    if cust.email
      unless auth = find_by_provider_and_uid("identity", cust.email)
        password = cust.password.blank? ? String.random_string(6) : cust.password 
        auth = new :customer => cust, :provider => "identity", :uid => cust.email, :password_digest => BCrypt::Password.create(password).to_s
        auth.password = password
        auth.password_confirmation = password
        auth.save
      end
    else
      auth = Authorization.new
      auth.errors.add(:Email, "is invalid")
    end
    auth
  end

  # updates the password of a given customer
  def self.update_password(cust, password)
    if auth = find_by(customer_id: cust.id, provider: "identity")
      auth.password = password
      if success = auth.save
        auth.update(password_digest: auth.password_digest)      
      end
    end
    success
  end

  # updates the email of a given customer
  def self.update_identity_email(cust)
    if auth = find_by(customer_id: cust.id, provider: "identity")
      auth.update(uid: cust.email)      
    end
    cust.email
  end

end