class Authorization < ActiveRecord::Base
belongs_to :customer
validates :provider, :uid, :presence => true
    
  # creates a customer and an auth belonging to that customer. Return the customer
  def self.find_or_create_user auth
    unless find_by_provider_and_uid(auth["provider"], auth["uid"])
      # create customer
      c = Customer.new
      c.email = auth["info"]["email"]
      c = Customer.find_or_create! c
      # create authorization
  	  create :customer => c, :provider => auth["provider"], :uid => auth["uid"] 
    end
    c
  end

end
