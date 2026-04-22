require 'stringio'
require_relative "printer"
require_relative "cache"
require_relative "tokenizer"
require_relative "parser"
require_relative "desugar"
require_relative "analysis"
require_relative "lowering"
require_relative "compiler"
require_relative "vm"

module Potato
  def self.run(source, path, options = {})
    cache = Cache.load(path) unless options[:no_cache]

    bytes =  cache || begin
      ast = Parser.parse(source)
      ast = Desugar.desugar(ast)
      PrintTree.print(ast) if options[:ast]
      scope = ScopeTree.build(ast)
      PrintTree.print(scope) if options[:scope]
      ir = Lowering.lower(ast, scope)
      PrintTree.print(ir) if options[:ir]
      bytes = Compiler.compile(scope, ir)
      Cache.save(path, bytes) unless options[:no_cache]
      bytes
    end

    PotatoVM::VM.run(bytes)
  end

  def self.run_file(path, options = {})
    run(File.read(path), path, options)
  end
end

def err(msg, line_num = nil)
  line = line_num ? "L#{line_num} " : ""
  raise "#{line}\e[31m#{msg}\e[0m"
end

