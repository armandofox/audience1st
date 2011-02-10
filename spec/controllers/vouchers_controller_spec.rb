require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include Utils

describe VouchersController do
  before(:all) do
    @vt_regular = Vouchertype.create!(:fulfillment_needed => false,
      :name => 'regular voucher',
      :category => 'revenue',
      :account_code => AccountCode.default_account_code,
      :price => 10.00,
      :season => Time.now.year)
  end
  before(:each) do
    stub_globals_and_userlevel(:boxoffice_manager, :boxoffice)
  end
  describe "transferring vouchers" do
    before(:each) do
      @vouchers = Array.new(3) do
        v = Voucher.new_from_vouchertype(@vt_regular,:purchasemethod => mock_model(Purchasemethod))
        v.save!
        Voucher.find(v)
      end
      @vouchers_hash = {'voucher' => Hash[*(@vouchers.map { |v| [v.id.to_s,""] }.flatten)]}
    end
    describe "redirect to welcome", :shared => true do
      it "should redirect to the welcome page" do
        response.should redirect_to(:controller => 'customers', :action => 'welcome')
      end
    end
    describe "no transfers", :shared => true do
      it "should not transfer any vouchers" do
        @vouchers.each { |v| v.should_not_receive(:transfer_to_customer) }
      end
    end
    context "when recipient exists" do
      before(:all) do
        @recip = BasicModels.create_generic_customer
      end
      context "and all selected vouchers exist" do
        it "should transfer the vouchers" do
          @vouchers.each do |v|
            Voucher.should_receive(:find_by_id).with(v.id.to_s).and_return(v)
          end
          post :manage, :commit => "Transfer", :select => @vouchers_hash,
          :xfer_id => @recip.id.to_s
        end
        it "should display success message" do
          post :manage, :commit => "Transfer", :select => @vouchers_hash,
          :xfer_id => @recip.id.to_s
          flash[:notice].should == "Vouchers #{@vouchers_hash['voucher'].keys.sort.join(',')} were transferred to #{@recip.full_name}'s account."
        end
        it "should redirect to the welcome page" do
          post :manage, :commit => "Transfer", :select => @vouchers_hash,
          :xfer_id => @recip.id.to_s
          response.should redirect_to(:controller => 'customers', :action => 'welcome')
        end
      end
      context "and no vouchers are selected" do
        before(:each) do
          post :manage, :commit => "Transfer", :xfer_id => @recip.id.to_s
        end
        it_should_behave_like "no transfers"
        it_should_behave_like "redirect to welcome"
        it "should display an error message" do
          flash[:notice].should == "No vouchers were selected."
        end
      end
    end
    context "when recipient doesn't exist" do
      before(:each) do
        post :manage, :commit => "Transfer", :xfer_id => "99999",
        :select => @vouchers_hash
      end
      it_should_behave_like "no transfers"
      it "should display an error message" do
        flash[:notice].should match("Recipient isn't in customer list")
      end
      it "should redirect to the page to create a new customer" do
        response.should redirect_to(:controller => 'customers', :action => 'new')
      end
    end
  end
end
