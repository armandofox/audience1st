require 'spec_helper'

describe VouchersController do
  describe 'confirming' do
    before :each do
      @customer = create(:customer)
      login_as @customer
      @vouchers = Array.new(3) { Voucher.new }
      @vouchers.each do |v|
        v.stub(:customer).and_return(@customer)
        v.stub(:reserve_for).and_return(true)
      end
      @showdate = create(:showdate, :thedate => 1.week.from_now)
      Voucher.stub(:find).and_return(@vouchers)
      @params = {:customer_id => @customer.id, :voucher_ids => @vouchers.map(&:id), :showdate_id => @showdate.id}
    end
    shared_examples_for 'all reservations' do
      it "redirects to welcome" do ; response.should redirect_to customer_path(@customer) ; end
    end
    describe 'successful reservations' do
      describe 'for all 3 vouchers' do
        before :each do ; @successful = 3 ; post :confirm_multiple, @params.merge(:number => 3) ; end
        it 'notifies' do ; flash[:notice].should match(/^Your reservations are confirmed./) ; end
        it_should_behave_like 'all reservations'
      end
      describe 'for 2 vouchers' do
        before :each do
          @vouchers[2].stub(:reserve_for).and_raise("Shouldn't have tried to reserve this one")
          @successful = 2
          post :confirm_multiple, @params.merge(:number => 2)
        end
        it 'notifies' do ; flash[:notice].should match(/^Your reservations are confirmed./) ; end
        it_should_behave_like 'all reservations'
      end
    end
    describe 'reservation with errors' do
      before :each do
        @vouchers[1].stub(:reserve_for) do |*args|
          @vouchers[1].errors.add_to_base "An error occurred"
          false
        end
      end
      describe 'for 3 vouchers' do
        before :each do ; @successful = 2; post :confirm_multiple, @params.merge(:number => 3) ; end
        it 'notifies' do ; flash[:alert].should match(/could not be completed: An error occurred/) ; end
        it_should_behave_like 'all reservations'
      end
    end
  end
end

