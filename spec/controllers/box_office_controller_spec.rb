require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BoxOfficeController do

  include StubUtils
  before(:each) do
    stub_globals_and_userlevel(:boxoffice, :boxoffice_manager)
  end
    
  describe "visiting boxoffice page with bad showdate", :shared => true do
    it "should redirect to next show if there is one" do
      Showdate.stub!(:current_or_next).and_return(@m = mock_model(Showdate))
      get :walkup, :id => @id
      response.should redirect_to(:action => 'walkup', :id => @m)
    end
    it "should redirect to any show when there is no next show" do
      Showdate.stub!(:current_or_next).and_return(nil)
      Showdate.stub!(:find).and_return(@m = mock_model(Showdate))
      get :walkup, :id => @id
      response.should redirect_to(:action => 'walkup', :id => @m)
    end
    it "should redirect to Shows page with a message when there are no shows at all" do
      Showdate.stub!(:find).and_return(nil)
      get :walkup, :id => @id
      response.should redirect_to(:controller => 'shows', :action => 'index')
    end
  end
  describe "visiting boxoffice page with no showdate" do
    @id = nil
    it_should_behave_like "visiting boxoffice page with bad showdate"
  end
  describe "visiting boxoffice page with nonexistent showdate" do
    @id = 999999
    it_should_behave_like "visiting boxoffice page with bad showdate"
  end

  describe "transferring already-sold walkup vouchers" do
    context "no transfer is attempted", :shared => true do
      it "should not attempt to transfer" do
        Voucher.should_not_receive(:destroy_multiple)
        Voucher.should_not_receive(:transfer_multiple)
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
        flash[:warning].should match(/you didn't select any vouchers/i)
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
        flash[:warning].should match(/no changes were made/i)
      end
    end
    context "when neither Transfer nor Destroy is pressed" do
      before(:each) do
        @params = {:vouchers => [Voucher.create!.id], :commit => 'nothing'}
      end
      it_should_behave_like "no transfer is attempted"
      it "should display appropriate error" do
        post :modify_walkup_vouchers, @params
        flash[:warning].should match(/unrecognized action/i)
      end
    end
    context "when target showdate doesn't exist" do
      before(:each) do
        @params = {:vouchers => [Voucher.create!(:showdate_id => 2)], :commit => 'Transfer',
          :to_showdate => '99999'}
      end
      it_should_behave_like "no transfer is attempted"
      it "should display error if showdate not found" do
        post :modify_walkup_vouchers, @params
        flash[:warning].should match(/couldn't find showdate with id=99999/i)
      end
      it "should display error if showdate not specified" do
        @params.delete(:to_showdate)
        post :modify_walkup_vouchers, @params
        flash[:warning].should match(/couldn't find showdate without an ID/i)
      end
    end
    context "when all vouchers exist" do
      before(:each) do
        @v1 = Voucher.create!
        @v2 = Voucher.create!
        @params = {:vouchers => [@v1.id, @v2.id]}
      end
      describe "transferring" do
        before(:each) do
          @showdate = BasicModels.create_one_showdate(Time.now)
          @params[:commit] = 'Transfer'
          @params[:to_showdate] = @showdate.id
        end
        context "when no errors occur" do
          before(:each) do
            Voucher.should_receive(:transfer_multiple).with(kind_of(Array), kind_of(Showdate), anything())
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
          Voucher.should_receive(:transfer_multiple).and_raise("boom!")
          post :modify_walkup_vouchers, @params
          flash[:warning].should match(/no changes were made/i)
          flash[:warning].should match(/boom!/)
        end
      end
      describe "destroying" do
        before(:each) do ; @params[:commit] = 'Destroy' ; end
        context "when no errors occur" do
          before(:each) do
            Voucher.should_receive(:destroy_multiple).with(kind_of(Array), anything())
          end
          it "should attempt to destroy the vouchers" do
            post :modify_walkup_vouchers, @params
          end
          it "should display confirmation" do
            post :modify_walkup_vouchers, @params
            flash[:notice].should == "2 vouchers destroyed."
          end
        end
        it "should display error message when errors occur" do
          Voucher.should_receive(:destroy_multiple).and_raise("boom!")
          post :modify_walkup_vouchers, @params
          flash[:warning].should match(/no changes were made/i)
          flash[:warning].should match(/boom!/)
        end
      end
    end
  end

  describe "walkup sale" do
    it "should associate the correct showdate with the voucher"
    it "should associate the ticket with Walkup Customer"
  end

end
