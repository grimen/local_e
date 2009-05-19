namespace :local_e do
  
  desc 'Setup app.'
  task :setup => :environment do |task, args|
    Rake::Task['local_e:install:geoip_city'].invoke
  end
  
  namespace :install do
    
    desc 'Install gem "geoip_city" and dependencies.'
    task :geoip_city => :environment do |task, args|
      
      # No Windows support...
      if RUBY_PLATFORM =~ /win32/ 
        puts 'NOTE: Windows not supported. Install gem "geoip_city" manually.'
        return
      end
      
      geoip_files = `locate GeoIP`
      
      if geoip_files.present?
        puts 'NOTE: GeoIP C API already installed'
      else
        puts 'Installing dependency GeoIP C API...'
        `cd /tmp`
        `sudo curl -O http://geolite.maxmind.com/download/geoip/api/c/GeoIP-1.4.6.tar.gz`
        `sudo tar -zxvf GeoIP-1.4.6.tar.gz`
        `sudo cd GeoIP-1.4.6`
        `sudo env ARCHFLAGS="-arch i386" ./configure --prefix=/opt/GeoIP`
        `sudo env ARCHFLAGS="-arch i386" make`
        `sudo env ARCHFLAGS="-arch i386" make install`
      end
      
      if geoip_files.present? && geoip_files['GeoIP.dat'].present?
        puts 'NOTE: GeoLiteCity database already installed'
      else
        puts 'Installing GeoLiteCity database...'
        `cd /tmp`
        `sudo -O http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz`
        `sudo gunzip GeoLiteCity.dat.gz`
        `sudo mv GeoLiteCity.dat /opt/GeoIP/share/GeoIP/`
      end
      
      puts "Installing gem geoip-city..."
      `sudo env ARCHFLAGS="-arch i386" gem install geoip_city -- --with-geoip-dir=/opt/GeoIP`
      
      puts "** Dependency geoip-city installed successfully"
    end
    
  end
  
end