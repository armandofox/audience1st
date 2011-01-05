World()

Given /(?:an? )?"([^\"]+)" subscription available to (.*) for \$?([0-9.]+)/ do |name, to_whom, price| 
  @sub = Vouchertype.create!(
    :name => name,
    :price => price,
    :bundle_sales_start => Time.now - 1.day,
    :bundle_sales_end   => Time.now + 1.day,
    :walkup_sale_allowed => false,
    :offer_public => case to_whom
                 when /anyone/ ;     Vouchertype::ANYONE ;
                 when /subscriber/ ; Vouchertype::SUBSCRIBERS ;
                 when /external/ ;   Vouchertype::EXTERNAL ;
                 when /box ?office/ ;Vouchertype::BOXOFFICE ;
                 else raise "Subscription available to whom?"
                 end,
    :category => :bundle,
    :subscription => true,
    :account_code => "9999",
    :season => Time.this_season
    )
end

