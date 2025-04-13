class Executor
  def initialize(node_name:)
    @node = Rails.configuration.nodes[node_name]
    if @node.nil?
      raise "Node #{node_name} not found"
    end
  end

  def execute(command)
    if @node[:name] == "self"
      `#{command}`
    else
      `ssh #{@node[:charm][:url]} #{command}`
    end
  end

  def copy_file(source, destination)
    if @node[:name] == "self"
      `cp #{source} #{destination}`
    else
      `scp #{source} #{@node[:charm][:url]}:#{destination}`
    end
  end

  def copy_directory(source, destination)
    if @node[:name] == "self"
      `cp -r #{source} #{destination}`
    else
      `scp -r #{source} #{@node[:charm][:url]}:#{destination}`
    end
  end
end