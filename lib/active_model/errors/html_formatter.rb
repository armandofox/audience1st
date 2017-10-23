module ActiveModel
  class Errors
    module HtmlFormatter
      def as_html
        messages = self.full_messages
        if messages.length <= 1
          '<p class="errors">' << messages[0].to_s << '</p>'
        else
          "<ul class=\"errors\">\n" <<
          self.full_messages.map { |m| "  <li>#{m}</li>" }.join("\n") <<
            "</ul>"
        end
      end
    end
  end
end
