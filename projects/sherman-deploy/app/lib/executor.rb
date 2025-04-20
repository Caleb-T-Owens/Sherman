class Executor
  def initialize(node_name:)
    unless Rails.configuration.nodes[:nodes].key?(node_name)
      raise "Node #{node_name} not found"
    end

    @node = Rails.configuration.nodes[:nodes][node_name]
    @node_name = node_name
  end

  def execute(command)
    if @node_name == :self
      `#{command}`
    else
      `ssh #{@node[:url]} #{command}`
    end
  end

  def execute_in_path(path, command)
    if @node_name == :self
      `cd #{self_path(path)} && #{command}`
    else
      execute("cd #{path} && #{command}")
    end
  end

  def delete(path)
    if @node_name == :self
      `rm -rf #{self_path(path)}`
    else
      execute("rm -rf #{path}")
    end
  end

  def copy(source, destination)
    if @node_name == :self
      Rails.logger.info("Copying directory #{source} to #{self_path(destination)}")
      `mkdir -p #{self_path(destination).parent}`
      `cp -r #{source} #{self_path(destination)}`
    else
      execute("mkdir -p #{destination}")
      `scp -r #{source} #{@node[:url]}:#{destination}`
    end
  end

  def self_path(path)
    Rails.root.join("self").join(path)
  end
end