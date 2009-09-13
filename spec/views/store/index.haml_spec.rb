require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
include Utils

describe "store/index" do
  before(:each) do
    template.stub!(:sanitize_option_text).and_return("dummy")
    template.stub!(:options_with_default).and_return([])
  end
  describe "greeting message" do
    it "should be the nonsubscriber message if not logged in" do
      assigns[:gNobodyReallyLoggedIn] = true
      render 'store/index'
      response.should have_selector("div#storeBannerNonSubscriber")
    end
    it "should be the nonsubscriber message if not a subscriber" do
      assigns[:gNobodyReallyLoggedIn] = false
      render 'store/index'
      response.should have_selector("div#storeBannerNonSubscriber")
    end
    it "should be the subscriber banner if subscriber logged in" do
      assigns[:gNobodyReallyLoggedIn] = false
      assigns[:subscriber] = true
      render 'store/index'
      response.should have_selector('div#storeBannerSubscriber')
      response.should_not have_selector('div#storeBannerNextSeasonSubscriber')
    end
    it "should be the next-season subscriber banner if next-season subscriber logged in" do
      assigns[:gNobodyReallyLoggedIn] = false
      assigns[:next_season_subscriber] = true
      render 'store/index'
      response.should have_selector('div#storeBannerNextSeasonSubscriber')
      response.should_not have_selector('div#storeBannerSubscriber')
    end
  end
end
