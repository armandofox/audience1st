module ShowsHelper

  def link_to_show_tickets(show, args={})
    action = (show.special? ? 'special' : 'index')
    url_for({:only_path => false, :controller => 'store', :action => action,
        :show_id => show.id}.merge(args))
  end

  def link_to_showdate_tickets(showdate, args={})
    action = (showdate.show.special? ? 'special' : 'index')
    url_for({:only_path => false, :controller => 'store', :action => action,
        :showdate_id => showdate.id}.merge(args))
  end

end
