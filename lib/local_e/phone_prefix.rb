module LocalE
  module PhonePrefix
    def self.included(base)
      base.class_eval do
        include InstanceMethods
      end
    end
    
    module InstanceMethods
      
      EXTRACT_PHONE_PREFIX_METHODS = [:locale, :default].freeze
      DEFAULT_EXTRACT_PHONE_PREFIX_METHODS = [:locale, :default].freeze
      
      def extract_phone_prefix(methods_in_priority_order)
        phone_prefix = nil, method = nil
        
        methods_in_priority_order.uniq.each do |method|
          if method.is_a?(Symbol)
            extract_method = "extract_phone_prefix_from_#{method}".to_sym
            phone_prefix = self.send(extract_method) if self.respond_to?(extract_method)
          else
            extract_method = "extract_phone_prefix_from_value".to_sym
            phone_prefix = self.send(extract_method, method) if self.respond_to?(extract_method)
          end
          break if phone_prefix
        end
        
        unless phone_prefix.blank?
          LocalE.log "PHONE PREFIX found: #{method} => #{phone_prefix}", 'phone_prefix'
        else
          LocalE.log "NO PHONE PREFIX found with specified methods, using default: nil", 'phone_prefix'
        end
        
        phone_prefix ||= extract_phone_prefix_from_default
      end
      
      protected
      
      def extract_phone_prefix_from_default
        parsed_phone_prefix = nil
        LocalE.log_result 'default', nil, parsed_phone_prefix, 'no default value', 'phone_prefix'
        parsed_phone_prefix
      end
      
      def extract_phone_prefix_from_value(value)
        value = value.to_s
        parsed_phone_prefix = valid_format_of_phone_prefix?(value) ? value.to_i : nil
        LocalE.log_result 'value', value, parsed_phone_prefix, 'no valid value', 'phone_prefix'
        parsed_phone_prefix
      end
      
      def extract_phone_prefix_from_locale(locale)
        parsed_phone_prefix = phone_prefixes[locale.to_sym] || nil
        LocalE.log_result 'locale', locale, parsed_phone_prefix, 'no valid locale', 'phone_prefix'
        parsed_phone_prefix
      end
      
      def phone_prefixes
        @phone_prefixs ||= load_phone_prefixes
      end
      
      # Data: http://en.wikipedia.org/wiki/List_of_country_calling_codes#Complete_Listing
      def load_phone_prefixes
        begin
          LocalE.load_yaml('phone_prefix_by_country').sort_by { |c| c.last }.collect { |c| {:country => c.first, :prefix => c.last} }
        rescue
          nil
        end
      end
      
      def valid_format_of_phone_prefix?(value)
        value.blank? ? false : (value =~ /^[0-9]{1,4}$/)
      end
      
      def isofy(value)
        value.to_i
      end
      
    end
  end
end