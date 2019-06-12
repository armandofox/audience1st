require 'rails_helper'

describe WalkupSalesController do

  before(:each) do
    login_as_boxoffice_manager
    @showdate = create(:showdate, :date => 1.day.from_now)
  end

  
  describe "transferring already-sold walkup vouchers" do
    shared_examples "no transfer is attempted" do
      it "should not attempt to transfer" do
        expect(Voucher).not_to receive(:change_showdate_multiple)
        put :update, @params
      end
      it "should redirect" do
        put :update, @params
        expect(response).to be_redirect
      end
    end
    context "when no vouchers are checked" do
      before(:each) do ;  @params = {:id => @showdate.id} ; end
      it_should_behave_like "no transfer is attempted"
      it "should display appropriate error" do
        put :update, @params
        expect(flash[:alert]).to match(/you didn't select any vouchers/i)
      end
    end
    context "when at least one voucher is not found" do
      before(:each) do
        found_voucher_id = create(:revenue_voucher).id
        not_found_id = 9999999
        @params = {:vouchers => [found_voucher_id, not_found_id], :id => @showdate.id }
      end
      it_should_behave_like "no transfer is attempted"
      it "should display appropriate error" do
        put :update, @params
        expect(flash[:alert]).to match(/no changes were made/i)
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
        expect(flash[:alert]).to match(/NO changes were made.*couldn't find showdate with 'id'=99999/i)
      end
      it "should display error if showdate not specified" do
        @params.delete(:to_showdate)
        put :update, @params
        expect(flash[:alert]).to match(/NO changes were made.*couldn't find showdate without an id/i)
      end
    end
    context "when all vouchers exist" do
      before(:each) do
        @v1 = create(:walkup_voucher)
        @v2 = create(:walkup_voucher)
        @params = {:vouchers => [@v1.id, @v2.id], :id => @showdate.id }
        @showdate = create(:showdate, :date => Time.current)
        @params[:commit] = 'Transfer'
        @params[:to_showdate] = @showdate.id
      end
      context "and no errors" do
        before(:each) do
          expect(Voucher).to receive(:change_showdate_multiple).with(kind_of(Array), kind_of(Showdate), anything())
        end
        it "should do the transfer" do
          put :update, @params
        end
        it "should display confirmation" do
          put :update, @params
          expect(flash[:notice]).to eq("2 vouchers transferred to #{@showdate.printable_name}.")
        end
      end
      specify "and errors occur should display a message" do
        expect(Voucher).to receive(:change_showdate_multiple).and_raise("boom!")
        put :update, @params
        expect(flash[:alert]).to match(/no changes were made/i)
        expect(flash[:alert]).to match(/boom!/)
      end
    end
  end
end
