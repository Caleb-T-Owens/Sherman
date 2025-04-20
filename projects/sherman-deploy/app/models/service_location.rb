class ServiceLocation < ApplicationRecord
  belongs_to :source
  
  validates :path, presence: true
  validates :name, presence: true, uniqueness: true

  def exist?
    source.git.include?(path)
  end

  def services
    output = []
    nodes = Rails.configuration.nodes

    source.git.ls_tree(path).each do |entry|
      next unless entry.directory?
      sherman_deploy = entry.get("sherman-deploy.yml")
      next unless sherman_deploy.present? && sherman_deploy.file?

      parsed_config = YAML.load(sherman_deploy.read_file).deep_symbolize_keys
      parsed_config[:nodes] = parsed_config[:nodes].map(&:to_sym)

      next unless parsed_config[:nodes].all? { |node_name| nodes[:nodes].key?(node_name) }

      output << Service.new(self, service_config: parsed_config, path: entry.full_path)
    end

    output
  end

  def upload_sources
    services.each do |service|
      service.nodes.each do |node|
        exec = Executor.new(node_name: node)

        exec.delete(service_node_path_for(service:))

        exec.copy(source_path_for(service:), service_node_path_for(service:))

        service.resources.each do |resource|
          exec.copy(source.checkout_directory.join(resource[:before]), service_node_path_for(service:).join(resource[:after]))
        end
      end
    end
  end

  def start_services
    services.each do |service|
      service.nodes.each do |node|
        exec = Executor.new(node_name: node)

        exec.execute_in_path(service_node_path_for(service:), "docker compose -p #{service.name} -f #{service.compose_file_path} up -d --force-recreate --remove-orphans")
      end
    end
  end

  def service_status
    services.each do |service|
      service.nodes.each do |node|
        exec = Executor.new(node_name: node)

        unparsed_status = exec.execute_in_path(service_node_path_for(service:), "docker compose ps --format=json")
        parsed_status = JSON.parse(unparsed_status)

        pp parsed_status
      end
    end

    nil
  end

  def source_path_for(service:)
    source.checkout_directory.join(service.path)
  end

  def service_node_path_for(service:)
    Pathname.new("services/#{service.name}")
  end
end
