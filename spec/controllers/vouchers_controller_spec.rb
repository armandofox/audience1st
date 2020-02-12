require 'rails_helper'

describe VouchersController do
  describe 'confirming' do
    before :each do
      @customer = create(:customer)
      login_as @customer
      @vouchers = Array.new(3) { build(:subscriber_voucher, :customer => @customer) }
      @vouchers.each do |v|
        allow(v).to receive(:reserve_for).and_return(true)
      end
      @showdate = create(:showdate, :thedate => 1.week.from_now)
      allow(Voucher).to receive(:find).and_return(@vouchers)
      @params = {:customer_id => @customer.id, :voucher_ids => @vouchers.map(&:id), :showdate_id => @showdate.id}
    end
    shared_examples_for 'all reservations' do
      it "redirects to welcome" do ; expect(response).to redirect_to customer_path(@customer) ; end
    end
    describe 'successful reservations' do
      describe 'for all 3 vouchers' do
        before :each do ; @successful = 3 ; post :confirm_multiple, @params.merge(:number => 3) ; end
        it 'notifies' do ; expect(flash[:notice]).to match(/^An email confirmation was sent to #{@customer.email}/) ; end
        it_should_behave_like 'all reservations'
      end
      describe 'for 2 vouchers' do
        before :each do
          allow(@vouchers[2]).to receive(:reserve_for).and_raise("Shouldn't have tried to reserve this one")
          @successful = 2
          post :confirm_multiple, @params.merge(:number => 2)
        end
        it 'notifies' do ; expect(flash[:notice]).to match(/^An email confirmation was sent to #{@customer.email}./) ; end
        it_should_behave_like 'all reservations'
      end
    end
    describe 'reservation with errors' do
      before :each do
        allow(@vouchers[1]).to receive(:reserve_for) do |*args|
          @vouchers[1].errors.add :base,"An error occurred"
          false
        end
      end
      describe 'for 3 vouchers' do
        before :each do ; @successful = 2; post :confirm_multiple, @params.merge(:number => 3) ; end
        it 'notifies' do
          expect(flash[:alert]).to match(/could not be completed:/)
          expect(flash[:alert]).to match(/An error occurred/)
        end
        it_should_behave_like 'all reservations'
      end
    end
  end
end
