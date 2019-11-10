xml.instruct!

# NOTE: for XML elements that include URLs, must do
#   xml.link do ; xml << link_string ; end
# to prevent XML builder from URI-escaping the link string. D'oh.

xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1", "xmlns:audience1st" => "https://www.audience1st.com/audience1st" do
  xml.channel do
    xml.title "#{@venue} Ticket Availability"
    xml.link do
      xml.cdata! store_url.html_safe
    end
    if @showdates.nil?
      xml.description "No Tickets Currently On Sale"
    else                  
      xml.description "Ticket Availability for #{@venue}"
      @showdates.each do |sd|
        xml.item do
          xml.title h(sd.printable_name)
          xml.link do 
            xml.cdata! link_to_showdate_tickets(sd)
          end
          xml.guid :isPermaLink => false do 
            xml.cdata! link_to_showdate_tickets(sd) 
          end
          xml.__send__('audience1st:show', sd.show.name)
          xml.__send__('audience1st:showDateTime', sd.thedate.strftime('%a, %b %e, %l:%M%p'))
          xml.__send__('audience1st:showDateTime8601', sd.thedate.strftime('%FT%R'))
          xml.__send__('audience1st:availabilityGrade', sd.availability_grade)
          minprice,maxprice = sd.price_range
          xml.__send__('audience1st:priceRange', "#{number_to_currency minprice} - #{number_to_currency maxprice}")
        end
      end
    end
  end
end
