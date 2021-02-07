require 'rails_helper'

# WARNING. The specs here use VCR to replay responses from the real Mailchimp.
# Should you ever need to re-generate those cassettes, YOU MUST SETUP THE INITIAL
# CONDITIONS IN MAILCHIMP as describe in the befor(:each) block below (StaticSeg1 and
# StaticSeg2 should contain the names indicated, and StaticSeg3 should not exist).

describe EmailList do

  before(:each) do
    @l = EmailList.new('ffffffffffffffffffffffffffffffff-us1')
    @known_emails = %w(af-theater@reinysfox.com af-www@reinysfox.com fox@a1patronsystems.com)
    @customers = @known_emails.map { |c| create(:customer, :email => c) }
    # StaticSeg1 contains the first 2, StaticSeg2 contains the third
  end

  describe 'segment manipulation' do
    it 'returns list of static segments' do
      VCR.use_cassette('segments') do
        segs = @l.get_sublists
        expect(segs.sort).to eq(['StaticSeg1', 'StaticSeg2'])
      end
    end

    describe 'adding to a static segment' do
      it 'adds to segment' do
        VCR.use_cassette('adds_to_segment') do
          expect(@l.add_to_sublist('StaticSeg1',[@customers[2]])).to eq(1)
        end
      end
      it 'ignores unknown emails' do
        customers = [create(:customer, :email => 'nobody@me.com'), @customers[0]]
        VCR.use_cassette('ignores_unknown_emails') do
          expect(@l.add_to_sublist('StaticSeg2', customers)).to eq(1)
        end
      end
    end

    describe 'creating new static segment' do
      it 'creates a new segment with names in it' do
        VCR.use_cassette('create_new_segment') do
          expect(@l.create_sublist_with_customers('StaticSeg3', @customers)).to eq(3)
        end
      end
      it 'shows up as a static segment' do
        VCR.use_cassette('verify_new_segment') do
          expect(@l.get_sublists).to include('StaticSeg3')
        end
      end
    end
  end

  describe 'subscribing' do
    it 'succeeds for new address' do
      VCR.use_cassette('subscribe_new_member') do
        c = create(:customer, :email => 'new@email.com')
        expect(@l.subscribe(c)).to be_truthy
      end
    end
    it 'succeeds if address already subscribed' do
      VCR.use_cassette('subscribe_already_existing') do
        expect(@l.subscribe(@customers[0])).to be_truthy
      end
    end
  end
  it 'updates existing subscriber' do
    VCR.use_cassette('update_existing') do
      old = @customers[0].email
      @customers[0].email = 'my_new@address.com'
      expect(@l.update(@customers[0], old)).to be_truthy
    end
  end
  describe 'unsubscribing' do
    it 'successfully removes address from list' do
      VCR.use_cassette('unsubscribe_existing') do
        expect(@l.unsubscribe(@customers[1])).to be_truthy
      end
    end
    it 'succeeds even if address was not on list' do
      VCR.use_cassette('unsubscribe_nonmember') do
        c = create(:customer, :email => 'not_in@list.com')
        expect(@l.unsubscribe(c)).to be_truthy
      end
    end
  end
end
