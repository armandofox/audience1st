module NavigationHelpers
  def underscorize(str) ;  str.downcase.gsub(/ /,'_') ; end
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in webrat_steps.rb
  #
  def path_to(page_name)
    case page_name
    when /the login page/i              then login_path
    when /the login with secret question page/i then secret_question_path
    when /the change secret question page/i then '/customers/change_secret_question'
    when /the home ?page/i              then '/customers/welcome'
    when /the subscriber home ?page/i   then '/customers/welcome'
    when /the edit contact info page for customer "(.*) +(.*)"/i
      @customer = Customer.find_by_first_name_and_last_name!($1, $2)
      visit "/customers/switch_to/#{@customer.id}"
      "/customers/edit/#{@customer.id}"
    when /the edit contact info page$/  then '/customers/edit'
    when /the change password page/i    then '/customers/change_password'
    when /the forgot password page/i    then '/customers/forgot_password'
    when /the new customer page/i       then '/customers/new'
      # admin-facing voucher management
    when /the add comps page/i          then '/vouchers/addvoucher'
      # store purchase flow
    when /the store page for "(.*)"/    then "/store?show_id=#{Show.find_by_name!($1).id}"
    when /the store page/i              then '/store'
    when /the special events page/      then '/store/special'
    when /the subscriptions page/i      then '/store/subscribe'
    when /the shipping info page/i      then '/store/shipping_address'
    when /the checkout page/i           then '/store/checkout'
    when /the order confirmation page/i then '/store/place_order'
      # reporting pages 
    when /the donations page/i          then '/donations/'
    when /the reports page/i            then '/reports'
    when /the vouchertypes page$/i       then '/vouchertypes'
    when /the vouchertypes page for the (\d+) season/ then "/vouchertypes/index?season=$1"
    when /the walkup sales page for (.*)$/
      @showdate = Showdate.find_by_thedate!(Time.parse($1))
      "/box_office/walkup/#{@showdate.id}"
    when /the walkup sales page/i       then "/box_office/walkup/#{@showdate.id}"
    when /the walkup sales report for "?(.*)?"$/ then "/box_office/walkup_report/#{(@showdate = Showdate.find_by_thedate!(Time.parse($1))).id}"
    when /the checkin page for "?(.*)"?$/ then "/box_office/checkin/#{(@showdate = Showdate.find_by_thedate(Time.parse($1))).id}"
    when /the checkin page$/i            then "/box_office/checkin/#{@showdate.id}"

    when /the door list for "?(.*)"?$/ then "/box_office/door_list/#{(@showdate = Showdate.find_by_thedate(Time.parse($1))).id}"
    when /the door list$/i            then "/box_office/door_list/#{@showdate.id}"

    when /the admin:(.*) page/i
      page = $1
      case page
      when /settings/i    then '/options/edit' 
      when /bulk import/i then '/bulk_downloads/new'
      when /import/i      then '/imports/new'
      else                raise "No mapping for admin:#{page}"
      end

    when /the show details page for "(.*)"/i
      @show = Show.find_by_name($1)
      @show.should_not be_nil
      "/shows/#{@show.id}/edit"
    when /the new showdate page for "(.*)"/i
      @show = Show.find_by_name($1)
      "/showdates/new?show_id=#{@show.id}"

    when /the donation landing page coded for fund (.*)/i
      "/store/donate_to_fund/#{AccountCode.find_by_code($1).id}"
    when /the donation landing page coded for a nonexistent fund/i
      '/store/donate_to_fund?account_code=9999999'
      # edit RESTful resource

    when /the edit page for the "(.*)" vouchertype/ then "/vouchertypes/#{Vouchertype.find_by_name($1).id}/edit"

      # create new RESTful resource (non-nested associations)

    when /the list of shows page for "(.*)"/i      then "/shows?season=#{$1}"
    when /the new show page/i           then '/shows/new'
    when /the new vouchertypes? page/i  then '/vouchertypes/new'
    when /^the new (.*)s? page$/i       then eval("new_#{underscorize($1)}_path")

      # RESTful index
      
    when /^the (.*s) page$/i      then eval(underscorize($1) << '_path')
      
    else
      raise "Can't find mapping for \"#{page_name}\" in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
