module LocalE
  module Locale
    def self.included(base)
      base.class_eval do
        include InstanceMethods
      end
    end
    
    module InstanceMethods
      
      EXTRACT_LOCALE_METHODS = [:params, :session, :top_level_domain, :sub_domain, :header, :ip, :default].freeze
      DEFAULT_EXTRACT_LOCALE_METHODS = [:params, :session, :header, :ip, :default].freeze
      
      def extract_locale(methods_in_priority_order, only_available_locales = false)
        locale = nil, method = nil
        
        if methods_in_priority_order          
          methods_in_priority_order.uniq.each do |method|
            if method.is_a?(Symbol)
              extract_method = "extract_locale_from_#{method}".to_sym
              locale = self.send(extract_method) if self.respond_to?(extract_method)
            else
              extract_method = "extract_locale_from_value".to_sym
              locale = self.send(extract_method, method) if self.respond_to?(extract_method)
            end
            break if locale
          end
          # filter_locale(locale, only_available_locales)
        end
        
        unless locale.blank?
          LocalE.log "LOCALE found: #{method} => #{locale}", 'locale'
        else
          LocalE.log "No LOCALE found with specified methods, using default: I18n.default_locale => #{I18n.default_locale}", 'locale'
        end
        
        locale ||= extract_locale_from_default
      end
      
      def extract_locale_from_default
        parsed_locale = I18n.default_locale
        LocalE.log_result 'I18n.default_locale', I18n.default_locale, parsed_locale, 'no valid default locale', 'locale'
        parsed_locale
      end
      
      def extract_locale_from_value(value, only_available_locales = false)
        value = value.to_s.strip
        parsed_locale = value if valid_format_of_locale?(value)
        parsed_locale = filter_locale(parsed_locale, only_available_locales)
        LocalE.log_result 'value', value, parsed_locale, 'no valid value', 'locale'
        parsed_locale
      end
      
      def extract_locale_from_params(only_available_locales = false)
        parsed_locale = params[:locale].strip rescue nil
        parsed_locale = filter_locale(parsed_locale, only_available_locales)
        LocalE.log_result 'params[:locale]', params[:locale], parsed_locale, 'no valid params value', 'locale'
        parsed_locale
      end
      
      def extract_locale_from_session(only_available_locales = false)
        parsed_locale = session[:locale].strip rescue nil
        parsed_locale = filter_locale(parsed_locale, only_available_locales)
        LocalE.log_result 'session[:locale]', session[:locale], parsed_locale, 'no valid session value', 'locale'
        parsed_locale
      end
      
      # Get locale from request HTTP Accept Language header
      def extract_locale_from_header(only_available_locales = false)
        parsed_locale = request.env['HTTP_ACCEPT_LANGUAGE'].split(',').first.strip rescue nil
        parsed_locale = filter_locale(parsed_locale, only_available_locales)
        LocalE.log_result 'http accept language', request.env['HTTP_ACCEPT_LANGUAGE'], parsed_locale, 'no valid http accept language header', 'locale'
        parsed_locale
      end
      
      # Get locale from request IP
      def extract_locale_from_ip(only_available_locales = false)
        begin
          location = LocalE.geoip_db.look_up(request.remote_ip)
          parsed_locale = location[:country_code].strip rescue nil
          parsed_locale = filter_locale(parsed_locale, only_available_locales)
        rescue
          parsed_locale = nil
        end
        LocalE.log_result 'ip', request.remote_ip, parsed_locale, 'unknown ip location', 'locale'
        parsed_locale
      end
      
      # Get locale from request top-level domain (like http://app.se)
      # Put something like:
      #   127.0.0.1 application.com
      #   127.0.0.1 application.se
      # in "/etc/hosts" file to try this out locally
      def extract_locale_from_top_level_domain(only_available_locales = false)
        parsed_locale = request.host.split('.').last.strip rescue nil
        parsed_locale = nil if parsed_locale =~ /localhost/
        parsed_locale = filter_locale(parsed_locale, only_available_locales)
        LocalE.log_result 'domain', request.host, parsed_locale, 'no valid top level domain', 'locale'
        parsed_locale
      end 
      
      # Get locale from request subdomain (like http://se.app.com)
      #
      # Put something like:
      #   127.0.0.1 com.application.local
      #   127.0.0.1 se.application.local
      # in "/etc/hosts" file to try this out locally
      def extract_locale_from_sub_domain(only_available_locales = false)
        parsed_locale = request.subdomains.first.strip rescue nil
        parsed_locale = filter_locale(parsed_locale, only_available_locales)
        LocalE.log_result 'subdomains', request.subdomains, parsed_locale, 'no valid sub domain', 'locale'
        parsed_locale
      end
      
      # Return nil if the specified locale is not available in the current app
      # Note: Method "available_locales" needs to be defined (see Rails I18i documentation)
      def filter_locale(locale, only_available_locales)
        return nil if locale.blank?
        if only_available_locales
          (defined?(available_locales) && available_locales.include?(locale)) ? locale : nil
        else
          locale
        end
      end
      
      def valid_format_of_locale?(iso_locale)
        iso_locale.blank? ? false : (iso_locale =~ /^[a-z]{2}(-[A-Z]{2}){0,1}$/)
      end
      
    end
  end
end