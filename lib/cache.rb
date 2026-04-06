
module Cache
  MAGIC = "SPUD".b
  CACHE_DIR = "cellar"

  def self.load(path)
    cache_path = cache_path_for(path)
    return nil unless File.exist?(cache_path)

    File.open(cache_path, "rb") do |f|
      magic = f.read(4)
      return nil unless magic == MAGIC

      mtime, size = f.read(16).unpack("Q>Q>")
      stat = File.stat(path)
      return nil unless mtime == stat.mtime.to_i && size == stat.size

      f.read
    end
  rescue
    # things broke
    nil
  end

  def self.save(path, bytes)
    Dir.mkdir(CACHE_DIR) unless Dir.exist?(CACHE_DIR)
    stat = File.stat(path)

    File.open(cache_path_for(path), "wb") do |f|
      f.write(MAGIC)
      f.write([stat.mtime.to_i, stat.size].pack("Q>Q>"))
      f.write(bytes)
    end
  end

  private

  def self.cache_path_for(path)
    name = File.basename(path, ".*") + ".cellar"
    File.join(CACHE_DIR, name)
  end
end