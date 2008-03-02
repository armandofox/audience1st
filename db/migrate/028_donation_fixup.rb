class DonationFixup < ActiveRecord::Migration
  def self.up
    #  for all existing donations, correctly set purchasemethod as follows:
    #    - if entered by daniel or diana (processed_by), probably a check
    #    - if entered by WALKUP CUSTOMER, assume check
    #    - else assume web/credit card

    # add a purchasemethod to account for "in kind" donations
    ActiveRecord::Base.connection.execute "INSERT INTO `purchasemethods` (`id`,`description`,`shortdesc`) VALUES ('10','In-Kind Goods or Services', 'in_kind')"

    daniel = Customer.find_by_first_name_and_last_name("Daniel","Zilber").id
    diana = Customer.find_by_first_name_and_last_name("Diana","Moore").id
    walkup = Customer.walkup_customer.id
    check = Purchasemethod.find_by_shortdesc("box_chk").id
    cc = Purchasemethod.find_by_shortdesc("web_cc").id
    ActiveRecord::Base.connection.execute <<EOQ1
     UPDATE donations SET purchasemethod_id=#{check} WHERE
      processed_by IN (#{daniel},#{diana},#{walkup})
EOQ1
    ActiveRecord::Base.connection.execute  <<EOQ2
     UPDATE donations SET purchasemethod_id=#{cc} WHERE
      processed_by NOT IN (#{daniel},#{diana},#{walkup})
EOQ2

    # other random schema improvements:
    #  add a "landing page URL" field to Show info
    add_column :shows, :landing_page_url,:string,:null => true, :default =>nil
    # allow show-specific email message to be >255 characters
    change_column :shows, :patron_notes, :text
    #  allow most options to be >255 characters long if a string
    change_column :options, :value, :text
    change_column :options, :typ, :enum, :limit => [:int,:string,:email,:float,:text], :null => false, :default => :string
    # set some of the options to :text
    [3020,3030,3040,3050,3060,3070,3080].each do |id|
      Option.find(id).update_attribute(:typ => :text)
    end
  end

  def self.down
  end
end
