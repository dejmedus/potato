require_relative "tokenizer"
require_relative "ast"
require_relative "parser"
require_relative "interpreter"

module Potato
  def self.parse(input)
    tokens = Tokenizer.tokenize(input)
    Parser.render(tokens)
  end

  def self.run_file(path)
    source = File.read(path)
    Parser.parse(source)
  end
end
