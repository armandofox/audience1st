require 'rails_helper'
module ImportTestHelper

  def self.extended(base)
    @@klass = base
  end

  def pretend_uploaded(file,type='text/csv')
    allow(self).to receive(:uploaded_data).and_return IO.read(file)
    self
  end

end
