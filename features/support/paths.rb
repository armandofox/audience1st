module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in webrat_steps.rb
  #
  def path_to(page_name)
    case page_name
    when /the login page/i
      '/login'
    when /the home ?page/i
      '/customers/welcome'
    when /the subscriber home ?page/i
      '/customers/welcome'
    when /the edit contact info page/i
      "/customers/edit/#{@customer.id}"
    when /the walkup sales page/i
      "/box_office/walkup/#{@showdate.id}"
    when /the admin:(.*) page/i
      page = $1
      case page
      when /settings/i ; '/options/edit' 
      when /bulk import/i ; '/bulk_downloads/new'
      when /import/i   ; '/imports/new'
      else ; raise "No mapping for admin:#{page}"
      end
    # Add more mappings here.
    # Here is a more fancy example:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(Customer.find_by_login($1))
    when /the new show page/i
      "/shows/new"
    when /the show details page for "(.*)"/i
      @show = Show.find_by_name($1)
      @show.should_not be_nil
      "/shows/edit/#{@show.id}"
    when /the new showdate page for "(.*)"/i
      @show = Show.find_by_name($1)
      "/showdates/new?show_id=#{@show.id}"
    when /the store page/i
      "/store/index"
    when /the subscriptions page/i
      "/store/subscribe"
    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
