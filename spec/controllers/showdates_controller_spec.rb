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

  describe "creating" do
    before(:each) do
      @hours_cutoff = 3
      stub_option!(:advance_sales_cutoff, @hours_cutoff * 60)
      get :new, :show_id => @show.id
      response.should be_success
      @showdate = assigns[:showdate]
      @showdate.should be_a_kind_of(Showdate)
    end
    context "when no showdates exist" do
      it "should set date to opening night, 8pm" do
        @showdate.thedate.should == Time.parse("January 2, 2013, 8:00pm")
      end
      it "should set max sales to zero" do
        @showdate.max_sales.should == 0
      end
      it "should set advance sales stop to #{@hours_cutoff} hours before showtime" do
        @showdate.end_advance_sales.should == @showdate.thedate - @hours_cutoff.hours
      end
    end
    context "when showdates exist" do
      before(:all) do
        @old_showdate = @show.showdates.create!(
          :thedate => Time.parse("January 10, 2013, 7:00pm"),
          :end_advance_sales => Time.parse("January 10, 2013, 5:30pm"),
          :max_sales => 200)
        @new_showdate = @show.showdates.create!(
          :thedate => Time.parse("January 4, 2013, 6:00pm"),
          :end_advance_sales => Time.parse("January 4, 2013, 2:00pm"),
          :max_sales => 101)
        Show.connection.execute(
          "UPDATE showdates SET updated_at='#{30.seconds.from_now.to_formatted_s(:db)}'
                WHERE id=#{@new_showdate.id}")
        @show.showdates.find(:first, :order => 'updated_at DESC').should == @new_showdate
      end
      after (:all) do
        @old_showdate.destroy
        @new_showdate.destroy
      end
      it "should set date 1 day after most recently created" do
        @showdate.thedate.should == @new_showdate.thedate + 1.day
      end
      it "should set end advance sales based on most recently created" do
        @showdate.end_advance_sales.should == @new_showdate.end_advance_sales + 1.day
      end
      it "should set max sales based on most recently created" do
        @showdate.max_sales.should == @new_showdate.max_sales
      end
    end
  end
end
