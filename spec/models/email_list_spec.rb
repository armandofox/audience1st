require 'rails_helper'

describe EmailList do
  before(:each) do
    @l = EmailList.new('a5d35b24aaa29563837f56c9db670e00-us1')
    @known_emails = %w(af-theater@reinysfox.com af-www@reinysfox.com fox@a1patronsystems.com)
    # StaticSeg1 contains the first 2, StaticSeg2 contains the third
  end

  it 'returns list of static segments' do
    VCR.use_cassette('segments') do
      segs = @l.get_sublists
      expect(segs.sort).to eq(['StaticSeg1', 'StaticSeg2'])
    end
  end

  describe 'adding to a static segment' do
    it 'adds to segment' do
      customers = [create(:customer, :email => 'fox@a1patronsystems.com')]
      VCR.use_cassette('adds_to_segment') do
        expect(@l.add_to_sublist('StaticSeg1',customers)).to eq(1)
      end
    end
    it 'ignores unknown emails' do
      customers = %w(nobody@me.com af-theater@reinysfox.com).map { |c| create(:customer, :email => c)}
      VCR.use_cassette('ignores_unknown_emails') do
        expect(@l.add_to_sublist('StaticSeg2', customers)).to eq(1)
      end
    end
  end

  describe 'creating new static segment' do
    it 'creates a new segment with names in it' do
      customers = @known_emails.map { |c| create(:customer, :email => c) }
      VCR.use_cassette('create_new_segment') do
        expect(@l.create_sublist_with_customers('StaticSeg3', customers)).to eq(3)
      end
    end
    VCR.use_cassette('verify_new_segment') do
      it 'shows up as a static segment' do
        expect(@l.get_sublists).to include('StaticSeg3')
      end
    end
  end
  
end

