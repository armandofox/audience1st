require 'rails_helper'

describe LapsedSubscribers do
  before :each do ;  @report = LapsedSubscribers.new ; end
  context 'when called with empty array(s)' do
    it 'should not raise error' do
      expect { @report.generate() }.not_to raise_error
    end
    it 'should return nil' do
      expect(@report.generate).to be_nil
    end
    it 'should include an error' do
      @report.generate
      expect(@report.errors).to match /specify at least one/
    end
  end
  context 'when one array is empty' do
    it 'should not call purchased_any if have[] is empty' do
      expect(Customer).not_to receive(:purchased_any_vouchertypes)
      expect(Customer).to receive(:purchased_no_vouchertypes).with([1,2]).and_return(Customer.none)
      @report.generate(:dont_have_vouchertypes => ['0,1,2'])
    end
    it 'should not call purchased_none if dont_have[] empty' do
      expect(Customer).to receive(:purchased_any_vouchertypes).and_return(Customer.none)
      expect(Customer).not_to receive(:purchased_no_vouchertypes).with([1,2])
      @report.generate(:have_vouchertypes => ['0,1,2'])
    end
    it 'should call both scopes if both arrays nonempty' do
      expect(Customer).to receive(:purchased_any_vouchertypes).and_return(Customer.none)
      expect(Customer).to receive(:purchased_no_vouchertypes).and_return(Customer.none)
      expect(@report.generate(:dont_have_vouchertypes => ['1,0'], :have_vouchertypes => ['0,1,2'])).to be_empty
    end
  end
end
