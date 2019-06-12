require 'rails_helper'
describe Customer do
  describe 'secret question' do
    before(:each) do
      @c = create(:customer)
    end
    it 'should be the empty question by default' do
      expect(@c.secret_question).to eq(0)
      expect(@c).to be_valid
    end
    it 'should be invalid with too-large secret question index' do
      @c.secret_question = 9999
      expect(@c).not_to be_valid
    end
    it 'should make customer invalid if question selected but no answer' do
      @c.secret_question = 1
      expect(@c).not_to be_valid
      expect(@c.errors[:secret_answer]).to include_match_for(/must be given if you specify a question/)
    end
  end
  describe 'authenticating with secret question' do
    context 'should fail' do
      scenarios = [['Email doesn\'t exist', 'nosuchemail@here', 2, 'answer', /can't find that email/i],
        ['Email not given', '', 2, 'answer', /please provide your email/i],
        ['Answer not given', 'nosuchemail@here', 2, '', /please provide.*answer/i],
      ]
      scenarios.each do |s|
        it "if #{s[0]}" do
          u = Customer.authenticate_from_secret_question(s[1], s[2], s[3])
          expect(u.errors[:login_failed]).to include_match_for(s[4])
        end
      end
      it 'if user hasn\'t setup a secret question' do
        c = create(:customer, :secret_question => 0)
        u = Customer.authenticate_from_secret_question(c.email, 2, 'foo')
        expect(u.errors[:login_failed]).to include_match_for(/never set up a secret question/)
        expect(u.errors[:no_secret_question]).not_to be_nil
      end
      it 'if answer incorrect' do
        c = create(:customer, :secret_answer => 'blah',:secret_question => 2)
        u = Customer.authenticate_from_secret_question(c.email, 2, 'answer')
        expect(u.errors[:login_failed]).to include_match_for(/isn't the answer/)
      end
    end
  end
  describe 'secret answer' do
    before(:each) do
      @c = create(:customer)
    end
    it 'should be valid if blank' do
      expect(@c.secret_answer).to be_blank
      expect(@c).to be_valid
    end
    it 'should be invalid if too long' do
      @c.secret_answer = 'foo' * 30
      expect(@c).not_to be_valid
      expect(@c.errors[:secret_answer]).to include_match_for(/too long/)
    end
    context 'when there is a secret question' do
      before(:each) do
        @c.update_attributes(:secret_answer => 'The Foo   bar', :secret_question => 1)
      end
      it 'should always be wrong if blank' do
        expect(@c.check_secret_answer('')).to be_nil
      end
      it 'should match case-insensitively' do
        expect(@c.check_secret_answer('the foo bar')).to be_truthy
      end
      it 'should match if whitespace collapsed' do
        expect(@c.check_secret_answer('The Foo bar')).to be_truthy
      end
      it 'should match if whitespace expanded' do
        expect(@c.check_secret_answer('The Foo bar')).to be_truthy
      end
    end
    context 'when there is no secret question' do
      before(:each) do
        @c.update_attributes(:secret_answer => 'foo', :secret_question => 0)
      end
      it 'should always be wrong' do
        expect(@c.check_secret_answer('foo')).to be_nil
      end
      it 'should make customer invalid if secret answer provided' do
        @c.secret_answer = 'foo'
        expect(@c).not_to be_valid
        expect(@c.errors[:secret_answer]).to include_match_for(/specify a question/i)
      end
    end
  end
end
