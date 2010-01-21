module BasicModels
  def self.create_customer_by_name_and_email(args)
      Customer.create!(:first_name => args[0],
        :last_name => args[1], :email => args[2])
  end
end

      
