# rspec-rails 1.3.x redirect_to matcher doesn't work if the 
module Spec
  module Rails
    module Matchers
      class RedirectToPath < RedirectTo
        def initialize(request, opts)
          super
        end
        def expected_url
          @expected
        end
      end
      def redirect_to_path(opts)
        RedirectToPath.new(request, opts)
      end
    end
  end
end
