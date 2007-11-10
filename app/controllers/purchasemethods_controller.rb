class PurchasemethodsController < ApplicationController

  before_filter :is_admin_filter

  scaffold :purchasemethod

end
