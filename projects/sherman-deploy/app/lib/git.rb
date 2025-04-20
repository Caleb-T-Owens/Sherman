class Git
  def initialize(directory:, git_url:)
    @directory = directory
    @checkout_directory = File.join(@directory, "checkout")
    @git_url = git_url
  end

  def initialized?
    Dir.exist?(@checkout_directory) && Dir.exist?(File.join(@checkout_directory, ".git"))
  end

  def clone
    FileUtils.cd(@directory) do
      %x{git clone #{@git_url} #{@checkout_directory}}
    end
  end

  def pull
    FileUtils.cd(@checkout_directory) do
      %x{git pull}
    end
  end

  def include?(path)
    includes = false
    FileUtils.cd(@checkout_directory) do
      %x{git rev-parse HEAD:#{path}}
      includes = $?.success?
    end
    includes
  end

  def ls_tree(path = nil)
    entries = []
    FileUtils.cd(@checkout_directory) do
      output = %x{git ls-tree HEAD:#{path}}.lines.map(&:strip)
      if $?.success?
        output.each do |line|
          entries << TreeEntry.new(raw_tree_entry: line, directory: path, git: self)
        end
      else
        raise "Failed to run git ls-tree"
      end
    end
    entries
  end

  def cat_file(sha)
    output = nil
    FileUtils.cd(@checkout_directory) do
      output = %x{git cat-file -p #{sha}}
    end
    output
  end

  class TreeEntry
    attr_reader :permission, :type, :sha, :name

    def initialize(raw_tree_entry:, directory:, git:)
      permission, type, sha, name = raw_tree_entry.split(" ", 4)
      @permission = permission
      @type = type
      @sha = sha
      @name = name
      @directory = directory
      @git = git
    end

    def directory
      @directory
    end

    def full_path
      File.join(@directory, @name)
    end

    def file?
      @type == "blob"
    end

    def directory?
      @type == "tree"
    end

    def children
      return nil unless directory?
      @git.ls_tree(full_path)
    end

    def get(name)
      children.find { _1.name == name }
    end

    def read_file
      return nil unless file?
      @git.cat_file(sha)
    end
  end
end
