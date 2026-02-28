require_relative "tokenizer"
require_relative "ast"
require_relative "parser"
require_relative "desugar"
require_relative "analysis"
require_relative "compiler"
require_relative "vm"

module Potato
  def self.run_file(path, options = {})
    source = File.read(path)
    ast = Parser.parse(source)
    ast = Desugar.desugar(ast)
    AST::Printer.print(ast) if options[:ast]
    scope = Analysis.analyze(ast)
    scope.pretty_print if options[:scope]
    # Compiler.compile(ast)
  end
end

module PotatoVM
  def self.run
    VM.run
  end
end

def err(msg, line_num = "?")
  abort "L#{line_num} \e[31m#{msg}\e[0m"
end