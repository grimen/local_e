module LocalE
  module TimeZone
    def self.included(base)
      base.class_eval do
        include InstanceMethods
      end
    end
    
    module InstanceMethods
      
      # TODO: add :locale as option
      EXTRACT_TIME_ZONE_METHODS = [:params, :session, :ip, :default].freeze
      DEFAULT_EXTRACT_TIME_ZONE_METHODS = [:params, :session, :ip, :default].freeze
      
      protected
      
      def extract_time_zone(methods_in_priority_order)
        time_zone = nil, method = nil
        
        methods_in_priority_order.uniq.each do |method|
          if method.is_a?(Symbol)
            extract_method = "extract_time_zone_from_#{method}".to_sym
            time_zone = self.send(extract_method) if self.respond_to?(extract_method)
          else
            extract_method = "extract_time_zone_from_value".to_sym
            time_zone = self.send(extract_method, method) if self.respond_to?(extract_method)
          end
          break if time_zone
        end
        
        unless time_zone.blank?
          LocalE.log "TIME ZONE found: #{method} => #{time_zone}", 'time_zone'
        else
          LocalE.log "NO TIME ZONE found with specified methods, using default: Time.zone => #{Time.zone}", 'time_zone'
        end
        
        time_zone ||= extract_time_zone_from_default
      end
      
      def extract_time_zone_from_default
        parsed_time_zone = Time.zone.name
        LocalE.log_result 'Time.zone', Time.zone.name, parsed_time_zone, 'no valid default time zone', 'time_zone'
        parsed_time_zone
      end
      
      def extract_time_zone_from_value(value)
        value = value.to_s.strip
        parsed_time_zone = value if valid_format_of_time_zone?(value)
        LocalE.log_result 'value', value, parsed_time_zone, 'no valid value', 'time_zone'
        parsed_time_zone
      end
      
      def extract_time_zone_from_params
        parsed_time_zone = self.params_value(:time_zone)
        LocalE.log_result 'params[:time_zone]', params[:time_zone], parsed_time_zone, 'no valid params value', 'time_zone'
        parsed_time_zone
      end
      
      def extract_time_zone_from_session
        parsed_time_zone = self.session_value(:time_zone)
        LocalE.log_result 'session[:time_zone]', session[:time_zone], parsed_time_zone, 'no valid session value', 'time_zone'
        parsed_time_zone
      end
      
      # http://ws.geonames.org/timezone?lat=47.01&lng=10.2
      def extract_time_zone_from_ip
        parsed_time_zone = self.ip_info(:city)
        LocalE.log_result 'ip', request.remote_ip, parsed_time_zone, 'unknown ip location', 'time_zone'
        parsed_time_zone
      end
      
      # NOTE: To messy to implement
      
      def valid_format_of_time_zone?(value)
        !value.blank?
      end
      
      def isofy(value)
        value
      end
      
    end
  end
end