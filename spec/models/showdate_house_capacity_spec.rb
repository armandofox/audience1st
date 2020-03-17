require 'rails_helper'

describe Showdate do
  describe 'house capacity for reserved seating' do
    it 'cannot be assigned in edit view'
    it 'changes if seatmap changes'
  end
  describe 'house capacity for general admission' do
    it 'can be assigned in edit view'
    it 'cannot be reduced below number of tickets sold'
  end
end
