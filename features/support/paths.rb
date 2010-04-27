module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in webrat_steps.rb
  #
  def path_to(page_name)
    case page_name
    when /the home ?page/i
      '/customers/welcome'
    when /the subscriber home ?page/i
      '/customers/welcome_subscriber'
    when /the walkup sales page/i
      "/box_office/walkup/#{@showdate.id}"
    # Add more mappings here.
    # Here is a more fancy example:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(Customer.find_by_login($1))
    when /the new show page/i
      "/shows/new"
    when /the store page/i
      "/store"
    when /the subscriptions page/i
      "/store/subscribe"
    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
