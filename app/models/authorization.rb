class Authorization < ActiveRecord::Base
  belongs_to :customer, foreign_key: "customer_id"
  validates :provider, :uid, :presence => true

  # creates a customer and an auth belonging to that customer. Return the customer
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
      create :customer => c, :provider => auth["provider"], :uid => auth["uid"]
    end
    c
  end

  def self.update_or_create_identity(cust)
    if cust.email
      if cust.password.blank?
        password = String.random_string(6)
      else
        password = BCrypt::Password.create(cust.password).to_s
      end
      if auth = find_by_provider_and_uid("Identity", cust.email)
        auth.password_digest = password
        auth.save!
      else
        auth = create! :customer => cust, :provider => "Identity", :uid => cust.email, :password_digest => password
      end
    else
      auth = Authorization.new
      auth.errors.add :email, "No Identity could be found because customer does not have an email"
    end
    auth
  end

  # updates an auth's email
  def self.update_identity_email(cust)
    auth = find_by_provider_and_customer_id("Identity", cust.id)
    self.uid = email
    self.save!
  end

end