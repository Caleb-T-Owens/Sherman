class ServiceLocation < ApplicationRecord
  belongs_to :source
  
  validates :path, presence: true
  validates :name, presence: true, uniqueness: { scope: :source_id }

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

      output << Service.new(self, parsed_config)
    end

    output
  end
end
