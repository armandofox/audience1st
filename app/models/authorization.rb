require 'bcrypt'
# class Authorization < ActiveRecord::Base
class Authorization < OmniAuth::Identity::Models::ActiveRecord
  belongs_to :customer, foreign_key: "customer_id"
  # validates_presence_of :customer_id, :provider
  # validates_uniqueness_of :uid, :scope => :provider
  # validates :provider, :uid, :presence => true
  # creates a customer and an auth belonging to that customer. Return the customer
  def self.find_or_create_user auth
    if (auth["provider"] == "identity")
      if user_auth = find(auth["uid"])
        c = user_auth.customer
      end
    elsif user_auth = find_by_provider_and_uid(auth["provider"], auth["uid"])
      c = user_auth.customer
    end
    unless c
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
  def self.find_user(uid)
    find(uid).customer
  end
  def self.create_user(auth_hash, customer_params, password)
    if customer_params["email"]
      password = String.random_string(6) if password.blank?
      puts password
      if auth = find(auth_hash[:uid])
        puts "found auth"
        if !!auth.provider
          puts "identity already exists"
          auth.customer
        else
          puts "new auth, creating customer and updating with relevant information"
          puts "current info: "
          puts "uid"
          puts auth.uid
          puts "password_digest"
          puts auth.password_digest
          puts "isItTheRightPasssword?"
          puts !!auth.authenticate(password)

          customer_hash = customer_params.permit("first_name", "last_name", "street", "city", "state", "zip", "day_phone", "eve_phone", "blacklist", "email", "e_blacklist").to_h #convert params object to safe hash with given info only
          cust = Customer.find_or_create!(Customer.new(customer_hash))

          auth.provider = "identity"
          auth.customer = cust
          auth.password = password
          auth.email = customer_hash["email"]
          auth.save!


          puts "password_digest"
          puts auth.password_digest
          puts "isItTheRightPasssword?"
          puts !!auth.authenticate(password)
        end
      else
        puts "couldn't find an identity with the relevant uid"
      end
    else
      puts "No Identity could be found because customer does not have an email"
    end
    cust
  end

  def self.update_or_create_identity(cust)
    if cust.email
      password = BCrypt::Password.create(cust.password).to_s unless cust.password.blank?       
      if auth = find_by_provider_and_uid("identity", cust.email)
        puts "found auth"
        if(password && BCrypt::Password.new(auth.password_digest) != cust.password)
          puts "updating password"
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
      puts "No Identity could be found because customer does not have an email"
    end
    auth
  end

  # updates an auth's email
  def self.update_identity_email(cust)
    if auth = find_by_provider_and_customer_id("identity", cust.id)
      auth.uid = cust.email
      auth.save!
    end
    auth
  end

end