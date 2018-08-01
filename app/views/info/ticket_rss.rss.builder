xml.instruct!

xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1" do
  xml.channel do

    xml.title       "#{@venue} Ticket Availability"
    xml.link do
      xml.cdata! url_for(:only_path => false, :controller => 'store').html_safe
    end
    xml.description "Ticket Availability for #{@venue}"

    unless (@showdate_avail.nil? || @showdate_avail.empty?)
      @showdate_avail.each do |avail|
        xml.item do
          sd,desc,link = avail
          xml.title       "#{sd.printable_name} - #{desc}"
          if link
            xml.link do
              xml.cdata! link_to_showdate_tickets(sd)
            end
          end
          xml.guid :isPermaLink => false do
            xml.cdata! link_to_showdate_tickets(sd, :ts => Time.current.to_i)
          end
        end
      end
    else                        # no upcoming shows
      xml.item do
        xml.title         "No performances this weekend"
        xml.description   "No performances this weekend"
      end
    end
  end
end
