require_relative "tokenizer"
require_relative "ast"
require_relative "parser"
require_relative "compiler"
require_relative "vm"

module Potato
  def self.run_file(path, options = {})
    source = File.read(path)
    ast = Parser.parse(source)
    AST::Tree.print(ast) if options[:ast]
    Compiler.compile(ast)
  end
end

module PotatoVM
  def self.run
    VM.run
  end
end

def err(msg)
  abort "\e[31m#{msg}\e[0m"
end