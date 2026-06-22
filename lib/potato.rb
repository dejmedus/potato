# frozen_string_literal: true

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
  class << self
    attr_accessor :current_line

    @current_line = 0
    @current_file = "main.potato"

    def run_file(path, options = {})
      @current_file = path.split("/").last
      run(File.read(path), path, options)
    end

    def err(msg)
      raise "#{@current_file}:#{@current_line}: error: #{msg}"
    end

    def run(source, path, options = {})
      cache = Cache.load(path) unless options[:no_cache]

      bytes = cache || begin
        ast = Parser.parse(source)
        ast = Desugar.desugar(ast)
        PrintTree.print(ast) if options[:ast]
        scope = ScopeTree.build(ast)
        PrintTree.print(scope) if options[:scope]
        ir = Lowering.lower(ast, scope)
        PrintTree.print(ir) if options[:ir]
        bytes = Compiler.compile(ir)
        Cache.save(path, bytes) unless options[:no_cache]
        bytes
      end

      PotatoVM::VM.new(bytes).run
    end
  end
end
