require_relative "tokenizer"
require_relative "ast"
require_relative "parser"
require_relative "interpreter"
require_relative "compiler"
require_relative "vm"

module Potato
  def self.run_file(path)
    source = File.read(path)
    ast = Parser.parse(source)
    Compiler.compile(ast)
  end
end

module PotatoVM
  def self.run
    VM.run
  end
end
