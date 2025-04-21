class Executor
  def initialize(node:)
    @node = node
  end

  def execute(command)
    if @node.kind == :local
      `#{command}`
    else
      `ssh #{@node.url} #{command}`
    end
  end

  def execute_in_path(path, command)
    if @node.kind == :local
      `cd #{self_path(path)} && #{command}`
    else
      execute("cd #{path} && #{command}")
    end
  end

  def delete(path)
    if @node.kind == :local
      `rm -rf #{self_path(path)}`
    else
      execute("rm -rf #{path}")
    end
  end

  def copy(source, destination)
    if @node.kind == :local
      Rails.logger.info("Copying directory #{source} to #{self_path(destination)}")
      `mkdir -p #{self_path(destination).parent}`
      `cp -r #{source} #{self_path(destination)}`
    else
      execute("mkdir -p #{destination}")
      `scp -r #{source} #{@node.url}:#{destination}`
    end
  end

  def self_path(path)
    Rails.root.join("self").join(path)
  end
end
