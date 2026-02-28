module Potato
  class Scope
    attr_reader :parent, :children, :symbol_table, :name

    def initialize(name, parent: nil)
      @parent = parent
      @children = []
      @symbol_table = {}
      @name = name
    end

    def add_to_scope(name)
      return if symbol_table.key?(name)
      symbol_table[name] = next_free_index
    end

    def next_free_index
      symbol_table.size
    end

    def find_var(name)
      self.symbol_table.key?(name)
    end

    def pretty_print(indent = 0, prefix = "", is_last = true)
      connector = indent == 0 ? "" : is_last ? "└── " : "├── "
      puts "#{prefix}#{connector}#{@name}"

      child_prefix = prefix + (indent == 0 ? "" : is_last ? "    " : "│   ")

      symbol_table.each_with_index do |(name, index), i|
        is_last_entry = i == symbol_table.size - 1 && children.empty?
        puts "#{child_prefix}#{is_last_entry ? "└── " : "├── "}#{name} → #{index}"
      end

      children.each_with_index do |child, i|
        child.pretty_print(indent + 1, child_prefix, i == children.size - 1)
      end
    end
  end

  class Analysis
    def initialize
      @global_scope = Scope.new("global")
      @cur_scope = @global_scope
    end

    def self.analyze(ast)
      new.analyze(ast)
    end

    def analyze(ast)
      ast.map { |node| analyze_node(node) }
      @global_scope
    end

    def analyze_node(node)
      case node.type
      when :function 
          @cur_scope.add_to_scope(node.value)
          new_scope = Scope.new("local:#{node.value}", parent: @cur_scope)
          @cur_scope.children << new_scope
          @cur_scope = new_scope

          params_node = node.children[0]
          body_node = node.children[1]

          params_node.children.each { |p| @cur_scope.add_to_scope(p.value) }
          body_node.children.each { |s| analyze_node(s) }

          @cur_scope = @cur_scope.parent

      when :assign
        var_name = node.children[0].value
        @cur_scope.add_to_scope(var_name)
        analyze_node(node.children[1])

      when :variable 
        var_name = node.value
        scope = @cur_scope

        until scope.nil?
          break if scope.find_var(var_name)
          scope = scope.parent
        end
        
        err "Undefined variable: #{var_name}" if scope.nil?

      else         
        node.children.each { |c| analyze_node(c) }
      end
    end
  end
end
