module LocalE
  module Country
    def self.included(base)
      base.class_eval do
        include InstanceMethods
      end
    end
    
    module InstanceMethods
      
      EXTRACT_COUNTRY_METHODS = [:params, :session, :locale, :default].freeze
      DEFAULT_EXTRACT_COUNTRY_METHODS = [:params, :session, :locale, :default].freeze
      
      def extract_country(methods_in_priority_order)
        country = nil, method = nil
        
        methods_in_priority_order.uniq.each do |method|
          if method.is_a?(Symbol)
            extract_method = "extract_country_from_#{method}".to_sym
            country = self.send(extract_method) if self.respond_to?(extract_method)
          else
            extract_method = "extract_country_from_value".to_sym
            country = self.send(extract_method, method) if self.respond_to?(extract_method)
          end
          break if country
        end
        
        unless country.blank?
          LocalE.log "COUNTRY found: #{method} => #{country}", 'country'
        else
          LocalE.log "NO COUNTRY found with specified methods, using default: nil", 'country'
        end
        
        country ||= extract_country_from_default
      end
      
      def extract_country_from_default
        parsed_country = nil
        LocalE.log_result 'default', nil, parsed_country, 'no default value', 'country'
        parsed_country
      end
      
      def extract_country_from_value(value)
        value = value.to_s.strip
        parsed_country = value if valid_format_of_country?(value)
        LocalE.log_result 'value', value, parsed_country, 'no valid value', 'country'
        parsed_country
      end
      
      def extract_country_from_params
        parsed_country = self.params_value(:country)
        LocalE.log_result 'params[:currency]', params[:country], parsed_country, 'no valid params value', 'country'
        parsed_country
      end
      
      def extract_country_from_session
        parsed_country = self.session_value(:country)
        LocalE.log_result 'params[:currency]', session[:country], parsed_country, 'no valid params value', 'country'
        parsed_country
      end
      
      def extract_country_from_ip
        parsed_country = self.ip_info(:country_code)
        LocalE.log_result 'ip', request.remote_ip, parsed_country, 'unknown ip location', 'country'
        parsed_country
      end
      
      def extract_country_from_tld
        parsed_country = self.top_level_domain
        LocalE.log_result 'host', request.host, parsed_locale, 'no valid top level domain', 'country'
        parsed_country
      end
      
      def extract_country_from_subdomain
        parsed_country = self.subdomain
        LocalE.log_result 'subdomains', request.subdomains, parsed_country, 'no valid sub domain', 'country'
        parsed_country
      end
      
      def valid_format_of_country?(value)
         value.blank? ? false : (value =~ /^[A-Z]{2}$/)
         # TODO: Check agains country code list
      end
      
      def isofy(value)
        value.to_s.upcase
      end
      
    end
  end
end