require File.dirname(__FILE__) + '/../test_helper'


class EmailGoldstarTestMailer < ActionMailer::Base
  def receive(e); e; end
end

class EmailGoldstarTest < Test::Unit::TestCase

  fixtures :shows, :showdates, :vouchertypes, :valid_vouchers
  require 'enumerator'

  @@testfilesdir = File.dirname(__FILE__)+"/../goldstar_email/"

  # each parse test case includes the show date and time;
  # for each ticket offer, the name of the ticket type, price, qty offered and
  # qty sold; for each customer, the last name, first name, # tix, type,
  # goldstar purchase ID.
  PARSETESTS =
    [{:date => "3/11/2007 2:00 PM",
       :offers => {"General Admittance" => {:price =>10, :qty =>20, :sold=>0}},
       :sales => []},
     {:date => "1/10/2012 8:00 PM",
       :offers =>
       { "General Admittance" => {:price => 10, :qty => 20, :sold => 2}},
       :sales => 
       [['Lineberry', 'Mari', 2, 'General Admittance', '00539799']] },
     {:date => "1/11/2012 8:00 PM",
       :offers =>
       { "Promotional Special (limit 2)" => {:price=>0, :qty=>10, :sold=>4},
         "General Admittance" => {:price=>10, :qty=>20, :sold=>3}},
       :sales =>
       [['Goradia', 'Kuntal', 2, 'Promotional special (limit 2)', '00548547'],
        ['Schrader', 'Matthew', 3, 'General Admittance', '00553292'],
        ['Wong', 'Choi Yee', 2, 'Promotional special (limit 2)', '00547482']]},
   ]

  def test_001_parse_valid_spreadsheets
    PARSETESTS.each_with_index do |t,i|
      offerlist,orderlist=EmailGoldstar.prepare(@@testfilesdir+"test#{i}.xls")
      if t[:date].nil?
        assert  offerlist.empty?
        assert  orderlist.empty?
      else
        # showdate matches?
        testdate = Time.parse(t[:date])
        offerlist.keys.map do |k|
          # all offer types represented?
          assert_not_nil offer=t[:offers][k], "Testcase: #{i}/Offer name: #{k}"
          o = offerlist[k]
          assert_equal testdate, o.showdate.thedate
          assert_equal offer[:price], o.price
          assert_equal offer[:qty], o.noffered
          assert_equal offer[:sold], o.nsold
        end
        # pairwise comparison of each TicketOrder returned with
        # the corresponding test data
        assert_equal t[:sales].length, orderlist.length
        orderlist.zip(t[:sales]) do |order|
          parsedata,testdata = order[0],order[1]
          assert_equal testdata[0], parsedata.last_name
          assert_equal testdata[1], parsedata.first_name
          assert_equal testdata[2], parsedata.qty
          assert_equal testdata[4], parsedata.order_key
        end
      end
    end
    
    def test_002_email_report
      # test that report is sent when parsing complete
      # check both an error case and a good case
    end
    
  end
end
