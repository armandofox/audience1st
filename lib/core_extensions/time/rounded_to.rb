module CoreExtensions
  module Time
    module RoundedTo
      def rounded_to(component)
        self.change(component => 0)
      end
    end
  end
end
