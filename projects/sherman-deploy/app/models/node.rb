class Node
  def initialize(name:, config:)
    @name = name
    @config = config
  end

  def name
    @config[:name]
  end

  def url
    @config[:url]
  end

  def kind
    @name == :self ? :local : :remote
  end

  def executor
    @executor ||= Executor.new(node: self)
  end

  def list_running_projects
    list = executor.execute("docker compose ls --format=json")

    if list.empty?
      []
    else
      JSON.parse(list)
    end
  end

  def self.all
    Rails.configuration.nodes.values
  end

  def self.find(name)
    Rails.configuration.nodes[name.to_sym]
  end

  def self.exists?(name)
    Rails.configuration.nodes.key?(name.to_sym)
  end
end
