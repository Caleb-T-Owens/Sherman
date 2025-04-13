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
end
