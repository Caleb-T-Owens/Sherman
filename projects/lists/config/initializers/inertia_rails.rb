InertiaRails.configure do |config|
  config.version = ViteRuby.digest if defined?(ViteRuby)
end
