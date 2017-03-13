require 'spec_helper'

describe WalkupSalesController do

  fixtures :customers
  before(:each) do
    login_as(:boxoffice_manager)
    @showdate = create(:showdate, :date => 1.day.from_now)
  end

  
  describe "transferring already-sold walkup vouchers" do
    context "no transfer is attempted", :shared => true do
      it "should not attempt to transfer" do
        Voucher.should_not_receive(:change_showdate_multiple)
        put :update, @params
      end
      it "should redirect" do
        put :update, @params
        response.should be_redirect
      end
    end
    context "when no vouchers are checked" do
      before(:each) do ;  @params = {:id => @showdate.id} ; end
      it_should_behave_like "no transfer is attempted"
      it "should display appropriate error" do
        put :update, @params
        flash[:alert].should match(/you didn't select any vouchers/i)
      end
    end
    context "when at least one voucher is not found" do
      before(:each) do
        found_voucher_id = Voucher.create!.id
        not_found_id = 9999999
        @params = {:vouchers => [found_voucher_id, not_found_id], :id => @showdate.id }
      end
      it_should_behave_like "no transfer is attempted"
      it "should display appropriate error" do
        put :update, @params
        flash[:alert].should match(/no changes were made/i)
      end
    end
    context "when target showdate doesn't exist" do
      before(:each) do
        @params = {:vouchers => [create(:revenue_voucher, :walkup => true)],
          :id => @showdate.id,
          :commit => 'Transfer',
          :to_showdate => '99999'}
      end
      it_should_behave_like "no transfer is attempted"
      it "should display error if showdate not found" do
        put :update, @params
        flash[:alert].should match(/couldn't find showdate with id=99999/i)
      end
      it "should display error if showdate not specified" do
        @params.delete(:to_showdate)
        put :update, @params
        flash[:alert].should match(/couldn't find showdate without an ID/i)
      end
    end
    context "when all vouchers exist" do
      before(:each) do
        @v1 = create(:walkup_voucher)
        @v2 = create(:walkup_voucher)
        @params = {:vouchers => [@v1.id, @v2.id], :id => @showdate.id }
        @showdate = create(:showdate, :date => Time.now)
        @params[:commit] = 'Transfer'
        @params[:to_showdate] = @showdate.id
      end
      context "and no errors" do
        before(:each) do
          Voucher.should_receive(:change_showdate_multiple).with(kind_of(Array), kind_of(Showdate), anything())
        end
        it "should do the transfer" do
          put :update, @params
        end
        it "should display confirmation" do
          put :update, @params
          flash[:notice].should == "2 vouchers transferred to #{@showdate.printable_name}."
        end
      end
      specify "and errors occur should display a message" do
        Voucher.should_receive(:change_showdate_multiple).and_raise("boom!")
        put :update, @params
        flash[:alert].should match(/no changes were made/i)
        flash[:alert].should match(/boom!/)
      end
    end
  end
end
