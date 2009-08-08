require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "store/_credit_card.haml" do

  describe "when no credit card info is supplied" do
    before(:each) do
      cc = ActiveMerchant::Billing::CreditCard.new
      render :partial => 'store/credit_card', :locals => { :credit_card => cc }
    end

    it "card number and CVV fields should be empty" do
      response.should have_tag('input#credit_card_number')
      response.should have_tag('input#credit_card_verification_value')
    end

    it "year and month should default to today" do
      response.should have_tag('select#credit_card_year') do
        with_tag('option[selected=?]', 'selected', Date.today.year.to_s)
      end
      response.should have_tag('select#credit_card_month') do
        with_tag('option[selected=?][value=?]', 'selected', Date.today.month.to_s)
      end
    end
  end

  describe "when credit card info is supplied" do
    before(:each) do
      @month = Date.today.month + 1
      @year = Date.today.year + 1
      @number = '0123456776543210'
      cc = ActiveMerchant::Billing::CreditCard.new(:month => @month,
                                                   :year => @year,
                                                   :number => @number)
      render :partial => 'store/credit_card', :locals => { :credit_card => cc }
    end
    it "should match credit card number" do
      response.should have_tag('input#credit_card_number[value=?]', @number)
    end
    it "should match credit card year and month" do
      response.should have_tag('select#credit_card_year') do
        with_tag('option[selected=?][value=?]', 'selected', @year)
      end
      response.should have_tag('select#credit_card_month') do
        with_tag('option[selected=?][value=?]', 'selected', @month)
      end
    end
    it "should leave unspecified fields blank" do
      response.should have_tag('input#credit_card_verification_value', '')
    end
  end

end




