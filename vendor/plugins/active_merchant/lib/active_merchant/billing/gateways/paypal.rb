module ActiveMerchant
  module Billing
    class PaypalGateway < Gateway
      TEST_URL = 'https://api.sandbox.paypal.com/2.0/'
      LIVE_URL = 'https://api-aa.paypal.com/2.0/'
      LIVE_REDIRECT_URL = 'https://www.paypal.com/cgibin/webscr?cmd=_express-checkout&token='
      TEST_REDIRECT_URL = 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token='

      def self.redirect_url
        Base.gateway_mode == :test ? TEST_REDIRECT_URL : LIVE_REDIRECT_URL 
      end
      
      def self.redirect_url_for(token)
        "#{self.redirect_url}#{token}"
      end
      
      attr_reader :url
      attr_reader :options
      attr_reader :response
      #
      # <tt>:pem</tt>         The text of your PayPal PEM file. Note
      #                       this is not the path to file, but its
      #                       contents. If you are only using one PEM
      #                       file on your site you can declare it
      #                       globally and then you won't need to
      #                       include this option
      cattr_accessor :pem_file

      # <tt>:cert_path</tt> - Old style location of certs.
      #
      #   # :cert_path => 'config/paypal'
      #   config/paypal/api_cert_chain.crt
      #   config/paypal/sandbox.crt   (Base.gateway_mode == :test)
      #   config/paypal/sandbox.key   (Base.gateway_mode == :test)
      #   config/paypal/live.crt      (Base.gateway_mode != :test)
      #   config/paypal/live.key      (Base.gateway_mode != :test)
      #
      def initialize(options = {})
        requires!(options, :login, :password)

        @options = options
        @pem = load_pem(options)

        super
      end

      def self.supported_cardtypes
        [:visa, :master, :american_express, :discover]
      end
      
      def setup_express_authorization(money, options = {})
        requires!(options, :return_url, :cancel_return_url)
        
        commit 'SetExpressCheckout', build_setup_request('Authorization', money, options)
      end
      
      def setup_express_purchase(money, options = {})
        requires!(options, :return_url, :cancel_return_url)
        
        commit 'SetExpressCheckout', build_setup_request('Sale', money, options)
      end

      def get_express_details(token)
        commit 'GetExpressCheckoutDetails', build_get_details_request(token)
      end

      def authorize(money, credit_card, options = {})
        if options[:express]
          requires!(options, :token, :payer_id)

          commit 'DoExpressCheckoutPayment', build_payment_request('Authorization', money, options)
        else
          requires!(options, :ip)

          commit 'DoDirectPayment', build_purchase_request('Authorization', money, credit_card, options), test_result_from_cc_number(credit_card.number)
        end
      end

      def purchase(money, credit_card, options = {})
        if options[:express]
          requires!(options, :token, :payer_id)
        
          commit 'DoExpressCheckoutPayment', build_payment_request('Sale', money, options)
        else
          requires!(options, :ip)
        
          commit 'DoDirectPayment', build_purchase_request('Sale', money, credit_card, options), test_result_from_cc_number(credit_card.number)
        end
      end

      def capture(money, authorization, options = {})
        commit 'DoCapture', build_capture_request(money, authorization, options)
      end

      def void(authorization, options = {})
        commit 'DoVoid', build_void_request(authorization, options)
      end

      private

      def commit(action, request, test_credit_card_result = nil)
        return test_credit_card_result if test_credit_card_result
        data = ssl_post build_request(request)
        
        @response = parse(action, data)
       
        success = @response[:ack] == "Success"
        message = @response[:message] || @response[:ack]

        Response.new(success, message, @response,
          :test => test?,
          :authorization => response[:transaction_id]
        )
      end

      def build_purchase_request(action, money, credit_card, options)
        xml = Builder::XmlMarkup.new :indent => 2
        
        xml.tag! 'DoDirectPaymentReq', 'xmlns' => 'urn:ebay:api:PayPalAPI' do
          xml.tag! 'DoDirectPaymentRequest', 'xmlns:n2' => 'urn:ebay:apis:eBLBaseComponents' do
            xml.tag! 'n2:Version', '2.0'
            xml.tag! 'n2:DoDirectPaymentRequestDetails' do
              xml.tag! 'n2:PaymentAction', action
              xml.tag! 'n2:PaymentDetails' do
                xml.tag! 'n2:OrderTotal', amount(money), 'currencyID' => currency(money)
                xml.tag! 'n2:NotifyURL', options[:notify_url]
              end
              add_credit_card(xml, credit_card, options[:billing_address] || options[:address])
              xml.tag! 'n2:IPAddress', options[:ip]
            end
          end
        end

        xml.target!        
      end
      
      def build_capture_request(money, authorization, options)
        xml = Builder::XmlMarkup.new :indent => 2
        
        xml.tag! 'DoCaptureReq', 'xmlns' => 'urn:ebay:api:PayPalAPI' do
          xml.tag! 'DoCaptureRequest', 'xmlns:n2' => 'urn:ebay:apis:eBLBaseComponents' do
            xml.tag! 'n2:Version', '2.0'
            xml.tag! 'AuthorizationID', authorization
            xml.tag! 'Amount', amount(money), 'currencyID' => currency(money)
            xml.tag! 'CompleteType', 'Complete'
            xml.tag! 'Note', options[:description]
          end
        end

        xml.target!        
      end
      
      def build_void_request(authorization, options)
        xml = Builder::XmlMarkup.new :indent => 2
        
        xml.tag! 'DoVoidReq', 'xmlns' => 'urn:ebay:api:PayPalAPI' do
          xml.tag! 'DoVoidRequest', 'xmlns:n2' => 'urn:ebay:apis:eBLBaseComponents' do
            xml.tag! 'n2:Version', '2.0'
            xml.tag! 'AuthorizationID', authorization
            xml.tag! 'Note', options[:description]
          end
        end

        xml.target!        
      end
      
      def build_get_details_request(token)
        xml = Builder::XmlMarkup.new :indent => 2
        xml.tag! 'GetExpressCheckoutDetailsReq', 'xmlns' => 'urn:ebay:api:PayPalAPI' do
          xml.tag! 'GetExpressCheckoutDetailsRequest', 'xmlns:n2' => 'urn:ebay:apis:eBLBaseComponents' do
            xml.tag! 'n2:Version', '2.0'
            xml.tag! 'Token', token
          end
        end

        xml.target!
      end
      
      def build_payment_request(action, money, options)
        xml = Builder::XmlMarkup.new :indent => 2
        xml.tag! 'DoExpressCheckoutPaymentReq', 'xmlns' => 'urn:ebay:api:PayPalAPI' do
          xml.tag! 'DoExpressCheckoutPaymentRequest', 'xmlns:n2' => 'urn:ebay:apis:eBLBaseComponents' do
            xml.tag! 'n2:Version', '2.0'
            xml.tag! 'n2:DoExpressCheckoutPaymentRequestDetails' do
              xml.tag! 'n2:PaymentAction', action
              xml.tag! 'n2:Token', options[:token]
              xml.tag! 'n2:PayerID', options[:payer_id]
              xml.tag! 'n2:PaymentDetails' do
                xml.tag! 'n2:OrderTotal', amount(money), 'currencyID' => currency(money)
                xml.tag! 'n2:NotifyURL', options[:notify_url]
              end
            end
          end
        end

        xml.target!
      end

      def build_setup_request(action, money, options)
        xml = Builder::XmlMarkup.new :indent => 2
        xml.tag! 'SetExpressCheckoutReq', 'xmlns' => 'urn:ebay:api:PayPalAPI' do
          xml.tag! 'SetExpressCheckoutRequest', 'xmlns:n2' => 'urn:ebay:apis:eBLBaseComponents' do
            xml.tag! 'n2:Version', '2.0'
            xml.tag! 'n2:SetExpressCheckoutRequestDetails' do
              xml.tag! 'n2:PaymentAction', action
              xml.tag! 'n2:OrderTotal', amount(money), 'currencyID' => currency(money)
              xml.tag! 'n2:MaxAmount', amount(options[:max_amount]), 'currencyID' => currency(options[:max_amount]) if options[:max_amount]
              add_address(xml, options[:billing_address] || options[:address])
              #xml.tag! 'n2:AddressOverride', 1
              #xml.tag! 'n2:NoShipping', 1
              xml.tag! 'n2:PageStyle', options[:page_style] unless options[:page_style].blank?
              xml.tag! 'n2:ReturnURL', options[:return_url]
              xml.tag! 'n2:CancelURL', options[:cancel_return_url]
              xml.tag! 'n2:IPAddress', options[:ip]
              xml.tag! 'n2:OrderDescription', options[:description]
              xml.tag! 'n2:BuyerEmail', options[:email] unless options[:email].blank?
              xml.tag! 'n2:InvoiceID', options[:order_id]
        
              # This should be set to the same locale as the shop
              # localeCode          - String
            end
          end
        end

        xml.target!
      end

      def add_credit_card(xml, credit_card, address)
        xml.tag! 'n2:CreditCard' do
          xml.tag! 'n2:CreditCardType', credit_card_type(credit_card.type)
          xml.tag! 'n2:CreditCardNumber', credit_card.number
          xml.tag! 'n2:ExpMonth', sprintf("%.2i", credit_card.month)
          xml.tag! 'n2:ExpYear', sprintf("%.4i", credit_card.year)
          xml.tag! 'n2:CVV2', credit_card.verification_value
          
          xml.tag! 'n2:CardOwner' do
            xml.tag! 'n2:PayerName' do
              xml.tag! 'n2:FirstName', credit_card.first_name
              xml.tag! 'n2:LastName', credit_card.last_name
            end
            add_address(xml, address)
          end
        end
      end        

      def ssl_post(data)
        uri = URI.parse(test? ? TEST_URL : LIVE_URL)

        http = Net::HTTP.new(uri.host, uri.port)

        http.verify_mode    = OpenSSL::SSL::VERIFY_PEER
        http.use_ssl        = true
        http.cert           = OpenSSL::X509::Certificate.new(@pem)
        http.key            = OpenSSL::PKey::RSA.new(@pem)
        http.ca_file        = File.dirname(__FILE__) + '/paypal/api_cert_chain.crt'

        http.post(uri.path, data).body
      end

      def parse(action, xml)
        response = {}
        xml = REXML::Document.new(xml)
        root = REXML::XPath.first(xml, "//#{action}Response")

        root.elements.to_a.each do |node|
          case node.name
          when 'Errors'
            response[:message] = node.elements.to_a('//LongMessage').collect{|error| error.text}.join('.')
          else
            parse_element(response, node)
          end
        end unless xml.root.nil?

        response
      end

      def parse_element(response, node)
        if node.has_elements?
          node.elements.each{|e| parse_element(response, e) }
        else
          response[node.name.underscore.to_sym] = node.text
          node.attributes.each do |k, v|
            response["#{node.name.underscore}_#{k.underscore}".to_sym] = v if k == 'currencyID'
          end
        end
      end

      def response_type_for(action)
        case action
        when 'Authorization', 'Purchase'
          'DoDirectPaymentResponse'
        when 'Void'
          'DoVoidResponse'
        when 'Capture'
          'DoCaptureResponse'
        end
      end

      def load_pem(options)
        if result = options[:pem] || PaypalGateway.pem_file
          result
        elsif options[:cert_path]
          # Backwards compatibility
          key = File.read File.join(options[:cert_path], "#{test? ? 'sandbox' : 'live'}.key")
          cert = File.read File.join(options[:cert_path], "#{test? ? 'sandbox' : 'live'}.crt")
          "#{key}\n#{cert}"
        else 
          raise ArgumentError, "You need to pass in your pem file using the :pem parameter or set it globally using ActiveMerchant::Billing::PaypalGateway.pem_file = File.read( File.dirname(__FILE__) + '/../mycert.pem' ) or similar"
        end
      end  

      def build_request(body)
        xml = Builder::XmlMarkup.new :indent => 2
  
        namespaces = { 'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                       'xmlns:env' => 'http://schemas.xmlsoap.org/soap/envelope/',
                       'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
                     }

        xml.instruct!
        
        xml.tag! 'env:Envelope', namespaces do
          xml.tag! 'env:Header' do
            add_credentials(xml)
          end
          
          xml.tag! 'env:Body' do
            xml << body
          end
        end
        xml.target!
      end
     
      def add_credentials(xml)
        namespaces = { 'xmlns' => 'urn:ebay:api:PayPalAPI',
                       'xmlns:n1' => 'urn:ebay:apis:eBLBaseComponents',
                       'env:mustUnderstand' => '0'
                     }

        xml.tag! 'RequesterCredentials', namespaces do
          xml.tag! 'n1:Credentials' do
            xml.tag! 'Username', @options[:login]
            xml.tag! 'Password', @options[:password]
            xml.tag! 'Subject', @options[:subject]
          end
        end
      end
      
      def add_address(xml, address)
        return if address.nil?
        xml.tag! 'n2:Address' do
          xml.tag! 'n2:Name', address[:name]
          xml.tag! 'n2:Street1', address[:address1]
          xml.tag! 'n2:Street2', address[:address2]
          xml.tag! 'n2:CityName', address[:city]
          xml.tag! 'n2:StateOrProvince', address[:state]
          xml.tag! 'n2:Country', address[:country]
          xml.tag! 'n2:PostalCode', address[:zip]
          xml.tag! 'n2:Phone', address[:phone]
        end
      end

      def currency(money)
        money.respond_to?(:currency) ? money.currency : 'USD'
      end
        
      def credit_card_type(type)
        case type
        when 'visa'             then 'Visa'
        when 'master'           then 'MasterCard'
        when 'discover'         then 'Discover'
        when 'american_express' then 'Amex'
        end
      end
    end
  end
end
