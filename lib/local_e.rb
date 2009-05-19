module LocalE
  def self.included(base)
    extend SingletonMethods
    base.class_eval do
      include InstanceMethods
    end
  end
  
  module SingletonMethods
    
    DEFAULT_GEOIP_DB_PATH = '/opt/GeoIP/share/GeoIP/GeoLiteCity.dat'.freeze
    
    DEFAULT_OPTIONS = {
        :locale => {
            :only_available => false,
            :set_time_zone => true,
            :strip_variant => true,
            :ensure_format => :iso,
            :mappings => {
              :com => 'en',
              :net => 'en',
              :nu => 'sv'
            }
          },
        :time_zone => {
          },
        :country => {
            :ensure_format => :iso,
            :mappings => {
            }
          },
        :geoip_db_path => DEFAULT_GEOIP_DB_PATH,
        :whiny_logging => true
      }.freeze
      
    def options
      @options ||= DEFAULT_OPTIONS
    end
    
    def geoip_db
      @geoip_db ||= load_geoip_db
    end
    
    def log(message, context = [])
      seperator = '/'
      context_path = context.to_a * seperator
      context_path = "#{seperator}#{context_path}" unless context_path.blank?
      ActionController::Base.logger.debug "[local_e#{context_path}]: #{message}" unless Rails.env == 'production' || options[:whiny_logging] == false
    end
    
    def log_result(before_label, before_value, after_value, no_value, context = [])
      LocalE.log "  * #{before_label}:".ljust(30) +
        " #{before_value.to_json}".ljust(25) +
        "=>  %s" % (after_value ? "#{after_value.to_json}  # ok" : "#{after_value.to_json}  # #{no_value}"), context
    end
    
    def load_yaml(file_name)
      YAML::load(File.open(File.join('..', 'config', 'i18n', "#{file_name}.yml")))
    end
    
    # def ip_info(*args)
    #       options, args = extract_options_with_defaults!(args, :ip => request.remote_ip)
    #       if key = args.first
    #         @geoip_db.lookup(options[:ip])[key.to_sym].strip rescue nil
    #       else
    #         @geoip_db.lookup(options[:ip]) rescue {}
    #       end
    #     end
    
    def country_from_locale(locale)
      begin
        locale_data = locale.split('-')
        locale_data[1].upcase # Extract region
        # TODO: check if valid country
      rescue
        nil
      end
    end
    
    protected
    
    # Alternative: http://www.iplocationtools.com
    def load_geoip_db
      if defined?(GeoIPCity)
        LocalE.log "gem loaded", 'geoip_city'
        LocalE.log "loading database '#{LocalE.options[:geoip_db_path]}'...", 'geoip_city'
        if File.exist?(LocalE.options[:geoip_db_path])
          geoip_db ||= GeoIPCity::Database.new(LocalE.options[:geoip_db_path])
          if geoip_db
            LocalE.log "database loaded", 'geoip_city'
          else
            LocalE.log "failure: database could not be loaded", 'geoip_city'
          end
        else
          LocalE.log "failure: database file missing at '#{LocalE.options[:geoip_db_path]}'", 'geoip_city'
        end
      else
        raise "failure: gem 'geoip_city' not installed or properly initialized", 'geoip_city'
      end
      geoip_db
    end
    
  end
  
  module InstanceMethods
    
    include LocalE::Locale
    include LocalE::TimeZone
    include LocalE::Country
    
    def ip_info(*args)
      options, args = extract_options_with_defaults!(args, :ip => request.remote_ip)
      if key = args.first
        @geoip_db.lookup(options[:ip])[key.to_sym].strip rescue nil
      else
        @geoip_db.lookup(options[:ip]) rescue {}
      end
    end
    def self.ip_info(*args)
      self.ip_info(args)
    end
    
    def session_value(key)
      session[key.to_sym].strip rescue nil
    end
    
    def params_value(key)
      params[key.to_sym].strip rescue nil
    end
    
    def http_accept_language
      begin
        header_data = http_accerequest.env['HTTP_ACCEPT_LANGUAGE'].split(',')
        header.split(',').first.strip if header_data
      rescue
        nil
      end
    end
    
    def subdomain
      subdomain.request.subdomains.first.strip rescue nil
    end
    
    def top_level_domain
      begin
        host_data = request.host.split('.')
        host_data.last.strip if host_data && host_data.size > 1
      rescue
        nil 
      end
    end
    
    protected
    
    # set_locale_by :ip, @user.locale, :params, 'en', :default, ...
    def set_locale_by(*args)
      options, args = extract_options_with_defaults!(args,
          :only_available => LocalE.options[:locale][:only_available],
          :set_time_zone => LocalE.options[:locale][:set_time_zone],
          :strip_variant => LocalE.options[:locale][:strip_variant],
          :ensure_format => LocalE.options[:locale][:ensure_format],
          :map => LocalE.options[:locale][:mappings]
        )
      args = fill_in_defaults(args, :defaults, DEFAULT_EXTRACT_LOCALE_METHODS)
      LocalE.log "SET_LOCALE :using => %s" % args.to_json, 'locale'
      found_locale = extract_locale(args.compact, options[:only_available])
      found_locale = strip_variant(found_locale) if options[:strip_variant] || options[:ignore_variant]
      found_locale = map_locale(found_locale, options[:map] || options[:mappings])
      
      set_if_specified(:time_zone, options[:set_time_zone] || options[:set_time_zone_by])
      
      I18n.locale = found_locale
    end
    alias :set_locale :set_locale_by
    
    # set_time_zone_by :ip, @user.time_zone, :params, 'en', :default, ...
    def set_time_zone_by(*args)
      options, args = extract_options_with_defaults!(args)
      args = fill_in_defaults(args, :defaults, DEFAULT_EXTRACT_TIME_ZONE_METHODS)
      LocalE.log "SET_TIME_ZONE :using => %s" % args.to_json, 'time_zone'
      Time.zone = extract_time_zone(args.compact)
    end
    alias :set_time_zone :set_time_zone_by
    
    def set_country_by(*args)
      options, args = extract_options_with_defaults!(args)
      args = fill_in_defaults(args, :defaults, DEFAULT_EXTRACT_COUNTRY_METHODS)
      LocalE.log "SET_COUNTRY :using => %s" % args.to_json, 'country'
    end
    alias :set_country :set_country_by
    
    def extract_options_with_defaults!(args, defaults = {})
      options = args.extract_options!
      options = options.symbolize_keys
      options = options.reverse_merge(defaults)
      return options, args
    end
    
    def reformat_locale(locale, format = :downcase)
      lang, variant = locale.split('-')
      lang = lang.downcase
      variant = (format == :downcase) ? variant.downcase : variant.upcase
      "#{lang}-#{variant}"
    end
    
    def strip_variant(locale)
      lang = locale.split('-').first
    end
    
    def map_locale(locale, mappings)
      return if mappings.blank?
      mappings = mappings.symbolize_keys
      mapped_locale = mappings[locale.to_sym]
      mapped_locale ? mapped_locale : locale
    end
    
    def get_default_country(locale)
      load_yaml('default_locale_by_locale')
    end
    
    def fill_in_defaults(args, defaults_symbol, defaults)
      args = defaults if args.blank?
      if args && args.include?(defaults_symbol)
        args.collect! { |value| (value == defaults_symbol) ? (defaults - args) : value }
      end
      args.flatten
    end
    
    def set_if_specified(property, args)
      unless args.blank? || args.is_a?(FalseClass)
        forward_args = (args.is_a?(Array) ? args : :defaults)
        self.send("set_#{property}_by".to_sym, forward_args)
      end
    end
    
  end
  
end
