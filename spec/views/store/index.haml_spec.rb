require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "store/index" do

  describe "when not logged in" do
    it "should display the nonsubscriber message" do
      assigns[:all_showdates] = []
      assigns[:sd] = nil
      render 'store/index'
      response.should have_selector("div.storeBannerNonSubscriber")
    end
  end
end
