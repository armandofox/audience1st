require 'spec_helper'

describe OrdersController do
  before do
    login_as :boxoffice_manager
  end
  fixtures :customers
end
