module NavigationHelpers
  def underscorize(str) ;  str.downcase.gsub(/ /,'_') ; end
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in webrat_steps.rb
  #
  def sd(time)
    Showdate.find_by_thedate!(Time.zone.parse time)
  end
  def path_to(page_name)
    @customer = find_or_create_customer($1,$2) if page_name =~ /for customer "(.*) (.*)"/
    @show = (Show.find_by_name($1) || create(:show, :name => $1)).id if page_name =~ /for the show "(.*)"/
    
    case page_name
    when /the (".*") RSS feed/      then availability_rss_path
    when /login page/i              then login_path
    when /login with secret question page/i then new_from_secret_session_path
    when /change secret question page/      then change_secret_question_customer_path(@customer)
    when /home page/                        then customer_path(@customer)
    when /edit contact info page/           then edit_customer_path(@customer)
    when /change password page/i            then change_password_for_customer_path(@customer)
    when /the forgot password page/i        then forgot_password_customers_path
      # customer donations.  See notes in routes.rb
    when /the record donation page/         then new_customer_donation_path(@customer)
    when /the new customer page/i           then new_customer_path
      # admin-facing voucher management and customer help
    when /the add customer page for staff/  then admin_new_customers_path
    when /the list of customers page/i      then customers_path
    when /the add comps page/i              then new_customer_voucher_path(@customer)
    when /the transfer vouchers page/i  then customer_vouchers_path(@customer)
    when /the orders page/i             then orders_path(:customer_id => @customer)
      # store purchase flow
    when /the order page for that order/ then order_path(@order)
    when /the store page/i              then store_path(@customer,({:show_id => @show} if @show))
    when /the special events page/      then store_path(:what => 'Special Event')
    when /the classes and camps page/   then store_path(:what => 'Class')
    when /the subscriptions page/i      then store_subscribe_path(@customer)
    when /the shipping info page/i      then shipping_address_path(@customer)
    when /the checkout page for customer "(.*) (.*)"/i then checkout_path(@customer = find_customer($1,$2))
    when /the checkout page/i           then checkout_path(@customer)
    when /the order confirmation page/i then place_order_path(@customer)
      # reporting pages 
    when /the quick donation page/      then quick_donate_path
    when /the donations page/i          then '/donations/'
    when /the reports page/i            then '/reports'
    when /the vouchertypes page$/i       then '/vouchertypes'
    when /the vouchertypes page for the (\d+) season/ then "/vouchertypes?season=#{$1}"
    when /the edit ticket redemptions page for "(.*)"/ then new_valid_voucher_path(:show_id => Show.find_by!(:name => $1))
    when /the walkup sales page for (.*)$/ then walkup_sale_path(sd $1)
    when /the walkup report page for (.*)$/ then report_walkup_sale_path(sd $1)
    when /the checkin page for (.*)$/ then checkin_path(sd $1)
    when /the door list page for (.*)$/ then door_list_checkin_path(sd $1)

    when /the admin:(.*) page/i
      page = $1
      case page
      when /settings/i    then '/options' 
      when /bulk import/i then '/bulk_downloads/new'
      when /import/i      then '/imports/new'
      else                raise "No mapping for admin:#{page}"
      end

    when /the show details page for "(.*)"/i then edit_show_path(@show = Show.find_by_name!($1))
    when /the new showdate page for "(.*)"/i then new_show_showdate_path(@show = Show.find_by_name!($1))

    when /the edit showdate page for (.*)/i 
      @showdate = Showdate.find_by_thedate! Time.zone.parse($1) unless $1 =~ /that performance/
      edit_show_showdate_path(@showdate.show,@showdate)

    when /the donation landing page coded for fund (.*)/i then donate_to_fund_path(AccountCode.find_by_code!($1))
    when /the donation landing page coded for a nonexistent fund/i then donate_to_fund_path('999999')

    when /the edit page for the "(.*)" vouchertype/ then edit_vouchertype_path(Vouchertype.find_by_name!($1))

    when /the list of shows page for "(.*)"/i      then shows_path(:season => $1)
    when /^the new (.*)s? page$/i       then eval("new_#{underscorize($1)}_path")

    when /^the account codes page$/ then account_codes_path

    else
      raise "Can't find mapping for \"#{page_name}\" in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
