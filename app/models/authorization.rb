class Authorization < ActiveRecord::Base
belongs_to :customer
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

end
