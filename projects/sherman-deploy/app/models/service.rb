class Service
  def initialize(service_location, service_config)
    @service_location = service_location
    @service_config = service_config
  end
  
  def name
    @service_config[:name]
  end

  def nodes
    @service_config[:nodes]
  end
end
