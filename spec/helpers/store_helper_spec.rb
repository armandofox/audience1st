require 'rails_helper'

describe StoreHelper, focus: true do
  describe 'cart voucher order' do
    describe 'for bundles' do
      before(:each) do
        @vt1,@vt2,@vt3 = 
                create(:vouchertype_included_in_bundle, :name => 'Rent', :display_order => 10),
        create(:vouchertype_included_in_bundle, :name => 'Hair', :display_order => 20),
        create(:vouchertype_included_in_bundle, :name => 'Hamlet', :display_order => 20)
        @v1, @v2, @v3 =
                  create(:subscriber_voucher, :vouchertype => @vt1),
                  create(:subscriber_voucher, :vouchertype => @vt2),
                  create(:subscriber_voucher, :vouchertype => @vt3)
        @sub = create(:bundle_voucher, :including => {@v1 => 1, @v2 => 1, @v3 => 1})
      end
      it 'sorts bundles first' do
        3.times do
          @list = helper.vouchers_grouped_for_cart([@v1,@v1,@v2,@v2,@v3,@v3,@sub,@sub].shuffle)
          expect(@list[0]).to eq([@sub,2])
        end
      end
      it 'sorts regular vouchers' do
        3.times do
          @list = helper.vouchers_grouped_for_cart([@v1,@v1,@v1,@v2,@v2,@v2].shuffle)
          expect(@list).to eq([[@v1,3],[@v2,3]])
        end
      end
    end
  end
end

        
        
