require_relative "printer"
require_relative "tokenizer"
require_relative "parser"
require_relative "desugar"
require_relative "analysis"
require_relative "lowering"
require_relative "compiler"
require_relative "vm"

module Potato
  def self.run_file(path, options = {})
    source = File.read(path)
    ast = Parser.parse(source)
    ast = Desugar.desugar(ast)
    PrintTree.print(ast) if options[:ast]
    scope = ScopeTree.build(ast)
    PrintTree.print(scope) if options[:scope]
    ir = Lowering.lower(ast, scope)
    PrintTree.print(ir) if options[:ir]
    Compiler.compile(scope, ir)
  end
end

module PotatoVM
  def self.run
    VM.run
  end
end

def err(msg, line_num = nil)
  line = line_num ? "L#{line_num} " : ""
  abort "#{line}\e[31m#{msg}\e[0m"
end

