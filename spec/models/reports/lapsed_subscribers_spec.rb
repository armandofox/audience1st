require 'spec_helper'

describe LapsedSubscribers do
  before :each do ;  @report = LapsedSubscribers.new ; end
  context 'when called with empty array(s)' do
    it 'should not raise error' do
      lambda { @report.generate() }.should_not raise_error
    end
    it 'should return nil' do
      @report.generate.should be_nil
    end
    it 'should include an error' do
      @report.generate
      @report.errors.should include_match_for(/specify at least one/)
    end
  end
  context 'when one array is empty' do
    it 'should not call purchased_any if have[] is empty' do
      Customer.should_not_receive(:purchased_any_vouchertypes)
      Customer.should_receive(:purchased_no_vouchertypes).with([1,2]).and_return([])
      @report.generate(:have_vouchertypes => '-1,0', :dont_have_vouchertypes => '0,1,2')
    end
    it 'should not call purchased_none if dont_have[] empty' do
      Customer.should_receive(:purchased_any_vouchertypes).and_return([])
      Customer.should_not_receive(:purchased_no_vouchertypes).with([1,2])
      @report.generate(:dont_have_vouchertypes => '-1,0', :have_vouchertypes => '0,1,2')
    end
    it 'should call both scopes if both arrays nonempty' do
      Customer.should_receive(:purchased_any_vouchertypes).and_return([])
      Customer.should_receive(:purchased_no_vouchertypes).and_return([])
      @report.generate(:dont_have_vouchertypes => '1,0', :have_vouchertypes => '0,1,2').should be_empty
    end
  end
end
