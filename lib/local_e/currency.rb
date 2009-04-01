module LocalE
  module Currency
    def self.included(base)
      base.class_eval do
        include InstanceMethods
      end
    end
    
    module InstanceMethods
      
      EXTRACT_CURRENCY_METHODS = [:params, :session, :locale, :default].freeze
      DEFAULT_EXTRACT_CURRENCY_METHODS = [:params, :session, :locale, :default].freeze
      
      def extract_currency(methods_in_priority_order)
        currency = nil, method = nil
        
        methods_in_priority_order.uniq.each do |method|
          if method.is_a?(Symbol)
            extract_method = "extract_currency_from_#{method}".to_sym
            currency = self.send(extract_method) if self.respond_to?(extract_method)
          else
            extract_method = "extract_currency_from_value".to_sym
            currency = self.send(extract_method, method) if self.respond_to?(extract_method)
          end
          break if currency
        end
        
        unless currency.blank?
          LocalE.log "CURRENCY found: #{method} => #{currency}", 'currency'
        else
          LocalE.log "No CURRENCY found with specified methods, using default: nil", 'currency'
        end
        
        currency ||= extract_currency_from_default
      end
      
      protected
      
      def extract_currency_from_default
        parsed_currency = nil
        LocalE.log_result 'default', nil, parsed_currency, 'no default value', 'currency'
        parsed_currency
      end
      
      def extract_currency_from_value(value)
        value = value.to_s.strip
        parsed_currency = value if valid_format_of_currency?(value)
        LocalE.log_result 'value', value, parsed_currency, 'no valid value', 'currency'
        parsed_currency
      end
      
      def extract_currency_from_params
        parsed_currency = params[:currency].strip rescue nil
        LocalE.log_result 'params[:currency]', params[:currency], parsed_currency, 'no valid params value', 'currency'
        parsed_currency
      end
      
      def extract_currency_from_session
        parsed_currency = session[:currency].strip rescue nil
        LocalE.log_result 'session[:currency]', session[:currency], parsed_currency, 'no valid session value', 'currency'
        parsed_currency
      end
      
      def extract_currency_from_locale(locale)
        parsed_currency = currencies[locale.to_sym] rescue nil
        LocalE.log_result 'locale', locale, parsed_currency, 'no valid locale', 'currency'
        parsed_currency
      end
      
      def currencies
        @currencies ||= load_currencies
      end
      
      # Data: http://en.wikipedia.org/wiki/ISO_4217
      def load_currencies
        begin
          LocalE.load_yaml('currency_by_country').sort_by { |c| c.last }.collect { |c| {:country => c.first, :prefix => c.last} }
        rescue
          nil
        end
      end
      
      def valid_format_of_currency?(iso_currency)
        iso_currency.blank? ? false : (iso_currency =~ /^[A-Z]{3}$/)
      end
      
    end
  end
end