require 'spec_helper'

describe BoxOfficeController do

  fixtures :customers

  before(:each) do
    login_as(:boxoffice_manager)
  end
    
  describe "showdate-dependent boxoffice action" do
    context 'with bad showdate' do
      before :each do
        @id = 999999
        @m = create(:showdate, :date => 1.day.from_now)
      end
      it 'should instead use current-or-next showdate if there is one' do
        Showdate.stub!(:current_or_next).and_return(@m)
        get :walkup, :id => @id
        assigns(:showdate).should == @m
      end
      it 'should use any existing showdate if no next showdate' 
      it 'should redirect to shows controller if no showdates at all' do
        Showdate.delete_all
        get :walkup, :id => @id
        response.should redirect_to(:controller => 'shows', :action => 'index')
      end
    end
    context 'with good showdate' do
      it "should work with valid showdate even if no others exist" do
        @m = create(:showdate, :date => 1.year.ago)
        get :walkup, :id => @m.id
        response.should render_template(:walkup)
      end
    end
  end
  describe "transferring already-sold walkup vouchers" do
    context "no transfer is attempted", :shared => true do
      it "should not attempt to transfer" do
        Voucher.should_not_receive(:change_showdate_multiple)
        post :modify_walkup_vouchers, @params
      end
      it "should redirect" do
        post :modify_walkup_vouchers, @params
        response.should be_redirect
      end
    end
    context "when no vouchers are checked" do
      before(:each) do ;  @params = {} ; end
      it_should_behave_like "no transfer is attempted"
      it "should display appropriate error" do
        post :modify_walkup_vouchers, @params
        flash[:alert].should match(/you didn't select any vouchers/i)
      end
    end
    context "when at least one voucher is not found" do
      before(:each) do
        found_voucher_id = Voucher.create!.id
        not_found_id = found_voucher_id + 1
        @params = {:vouchers => [found_voucher_id, not_found_id] }
      end
      it_should_behave_like "no transfer is attempted"
      it "should display appropriate error" do
        post :modify_walkup_vouchers, @params
        flash[:alert].should match(/no changes were made/i)
      end
    end
    context "when target showdate doesn't exist" do
      before(:each) do
        @params = {:vouchers => [create(:revenue_voucher, :walkup => true, :showdate_id => 2)],
          :commit => 'Transfer',
          :to_showdate => '99999'}
      end
      it_should_behave_like "no transfer is attempted"
      it "should display error if showdate not found" do
        post :modify_walkup_vouchers, @params
        flash[:alert].should match(/couldn't find showdate with id=99999/i)
      end
      it "should display error if showdate not specified" do
        @params.delete(:to_showdate)
        post :modify_walkup_vouchers, @params
        flash[:alert].should match(/couldn't find showdate without an ID/i)
      end
    end
    context "when all vouchers exist" do
      before(:each) do
        @v1 = create(:walkup_voucher)
        @v2 = create(:walkup_voucher)
        @params = {:vouchers => [@v1.id, @v2.id]}
      end
      describe "transferring" do
        before(:each) do
          @showdate = create(:showdate, :date => Time.now)
          @params[:commit] = 'Transfer'
          @params[:to_showdate] = @showdate.id
        end
        context "when no errors occur" do
          before(:each) do
            Voucher.should_receive(:change_showdate_multiple).with(kind_of(Array), kind_of(Showdate), anything())
          end
          it "should do the transfer" do
            post :modify_walkup_vouchers, @params
          end
          it "should display confirmation" do
            post :modify_walkup_vouchers, @params
            flash[:notice].should == "2 vouchers transferred to #{@showdate.printable_name}."
          end
        end
        it "when errors occur should display a message" do
          Voucher.should_receive(:change_showdate_multiple).and_raise("boom!")
          post :modify_walkup_vouchers, @params
          flash[:alert].should match(/no changes were made/i)
          flash[:alert].should match(/boom!/)
        end
      end
    end
  end

  describe "walkup sale" do
    it "should associate the correct showdate with the voucher"
    it "should associate the ticket with Walkup Customer"
  end

end
