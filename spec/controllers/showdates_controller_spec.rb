require 'spec_helper'
include Utils

describe ShowdatesController do
  fixtures :customers
  before :each do
    login_as :boxoffice_manager
  end
  before :all do
    @show = BasicModels.create_generic_show("A Show", :opening_date => Time.parse("January 2, 2013"))
  end
  describe "creating multiple" do
    before(:each) do
      @params = {
        :show_id => @show,
        :sales_cutoff => 44,
        :max_sales => 55,
        :time => {:hour => 15, :minute => 0},
        :start => {:year => 2011, :month => 12, :day => 23},
        :end => {:year => 2011, :month => 12, :day => 26},
        :day => ['4', '5', '6']
      }
    end
    it "should set up date list correctly" do
      controller.should_receive(:showdates_from_date_list).
        with([Time.parse("12/23/2011 3:00pm"), Time.parse("12/24/2011 3:00pm")], anything()).
        and_return([])
      post :create, @params
    end
  end

end
