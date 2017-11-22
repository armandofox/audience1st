require 'bcrypt'
# class Authorization < ActiveRecord::Base
class Authorization < OmniAuth::Identity::Models::ActiveRecord
  belongs_to :customer, foreign_key: "customer_id"
  validates_presence_of :customer_id, :provider
  validates_uniqueness_of :uid, :scope => :provider
  # validates :provider, :uid, :presence => true
  # creates a customer and an auth belonging to that customer. Return the customer
  def self.find_or_create_user auth
    if (auth["provider"] == "identity")
      if user_auth = find_by_email(auth["info"]["email"])
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
      create :customer => c, :provider => auth["provider"], :email => auth["info"]["email"]
    end
    c
  end

  def self.update_or_create_identity(cust)
    if cust.email
      password = BCrypt::Password.create(cust.password).to_s unless cust.password.blank?       
      if auth = find_by_provider_and_uid("Identity", cust.email)
        puts "found auth"
        if(password && BCrypt::Password.new(auth.password_digest) != cust.password)
          puts "updating password"
          auth.password_digest = password
          auth.save!
        end
      else
        password = String.random_string(6) if cust.password.blank?
        auth = create! :customer => cust, :provider => "Identity", :email => cust.email, :password_digest => password
      end
    else
      puts "No Identity could be found because customer does not have an email"
    end
    auth
  end

  # updates an auth's email
  def self.update_identity_email(cust)
    if auth = find_by_provider_and_customer_id("Identity", cust.id)
      auth.uid = cust.email
      auth.save!
    end
    auth
  end

end