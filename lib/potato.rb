require_relative "tokenizer"
require_relative "parser"

module Potato
  def self.run_file(path)
    source = File.read(path)
    Parser.parse(source)
  end
end
