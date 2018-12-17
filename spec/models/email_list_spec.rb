require 'rails_helper'

describe EmailList do
  before(:each) do
    @l = EmailList.new('a5d35b24aaa29563837f56c9db670e00-us1')
  end

  it 'returns list of static segments' do
    VCR.use_cassette('segments') do
      segs = @l.get_sublists
      expect(segs.sort).to eq(['StaticSeg1', 'StaticSeg2'])
    end
  end

end

