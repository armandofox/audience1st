module ActiveModel
  class Errors
    module HtmlFormatter
      def as_html
        "<ul class=\"errors\">\n" <<
          self.full_messages.map { |m| "  <li>#{m}</li>" }.join("\n") <<
          "</ul>"
      end
    end
  end
end
