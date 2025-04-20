class Service
  def initialize(service_location, service_config:, path:)
    @service_location = service_location
    @service_config = service_config
    @path = path
  end

  def path
    @path
  end

  def name
    @service_config[:name]
  end

  def nodes
    @service_config[:nodes].map(&:to_sym)
  end

  def resources
    @service_config[:resources].map do |resource|
      before, after = resource.split(":")
      {before:, after:}
    end
  end

  def compose_file_path
    @service_config[:compose]
  end

  def ports
    @service_config[:ports]
  end
end
