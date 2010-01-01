require 'xmlrpc/client'
require 'ostruct'

module Hominid

  class StandardError < ::StandardError
  end

  class APIError < StandardError
    def initialize(error)
      super("<#{error.faultCode}> #{error.message}")
    end
  end
  
  class CampaignError < APIError
  end
  
  class ListError < APIError
  end
  
  class UserError < APIError
  end
  
  class ValidationError < APIError
  end

  class CommunicationError < StandardError
    def initialize(message)
      super(message)
    end
  end
  
end

require 'hominid/campaign'
require 'hominid/helper'
require 'hominid/list'
require 'hominid/security'
require 'hominid/base'
