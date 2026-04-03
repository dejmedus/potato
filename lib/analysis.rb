module Potato
  Symbol = Struct.new(:name, :locals_index, :kind, :bytecode_location)

  class Scope
    attr_reader :parent, :children, :symbol_table, :name

    def initialize(name, parent: nil)
      @parent = parent
      @children = []
      @symbol_table = {}
      @name = name
    end

    def add_to_scope(name, kind:, index: nil)
      return if symbol_table.key?(name)
      symbol_table[name] = Symbol.new(name, index || next_free_index, kind, nil)
    end

    def next_free_index
      symbol_table.size
    end

    def lookup(name)
      return symbol_table[name] if symbol_table.key?(name)

      parent_lookup = parent&.lookup(name)
      if parent_lookup
        return parent_lookup if parent_lookup.kind == :function
        add_to_scope(name, kind: :captured, index: parent_lookup.locals_index)
        return symbol_table[name]
      end
    end
  end

  class ScopeTree
    def initialize
      @global_scope = Scope.new("global")
      @cur_scope = @global_scope
    end

    def self.build(ast)
      new.build(ast)
    end

    def build(ast)
      ast.each { |node| scope_node(node) }
      @global_scope
    end

    def scope_node(node)
      case node.type
      when :function
        @cur_scope.add_to_scope(node.value, kind: :function)
        new_scope = Scope.new(node.value, parent: @cur_scope)
        @cur_scope.children << new_scope
        @cur_scope = new_scope

        params_node = node.children[0]
        body_node = node.children[1]
        params_node.children.each { |p| @cur_scope.add_to_scope(p.value, kind: :param) }
        body_node.children.each { |s| scope_node(s) }

        @cur_scope = @cur_scope.parent

      when :assign
        var_name = node.children[0].value
        @cur_scope.add_to_scope(var_name, kind: :local)
        scope_node(node.children[1])

      when :variable
        if @cur_scope.lookup(node.value).nil?
          err "Undefined variable: #{node.value}", node.line
        end

      else
        node.children.each { |c| scope_node(c) }
      end
    end
  end
end
