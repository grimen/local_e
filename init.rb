Dir[File.expand_path(File.join(File.dirname(__FILE__), 'lib', '**', '*.rb'))].uniq.each do |file|
  require file
end

ActionController::Base.class_eval do
  include LocalE
end