
module Potato
  class IR
    Push = Struct.new(:value)
    LoadVar = Struct.new(:index)
    StoreVar = Struct.new(:index)
    Add = Struct.new
    Equality = Struct.new
    Print = Struct.new
    Call = Struct.new(:name, :arg_count)
    Return = Struct.new
  end

  class Lowering
    def initialize(scope)
      @global_scope = scope
      @cur_scope = scope
      @instructions = []
      @function_table = {}
      @func_defs = []
    end

    def self.lower(ast, scope)
      new(scope).lower(ast)
    end

    def next_free_index
      @instructions.size
    end

    def lower(ast)
      ast.each { |node| node.type == :function ? @func_defs << node : ir(node) }
      @func_defs.each { |fn| func_ir(fn) }
      [@instructions, @function_table]
    end

    def func_ir(node)
      @function_table[node.value] = next_free_index

      @cur_scope = @cur_scope.children.find { |c| c.name == "local:#{node.value}" }

      params_node = node.children[0]
      params_node.children.each { |p|
        @instructions << IR::StoreVar.new(@cur_scope.resolve(p.value))
      }

      body_node = node.children[1]
      body_node.children.each { |s| ir(s) }

      @instructions << IR::Return.new
      @cur_scope = @cur_scope.parent
    end

    def ir(node)
      case node.type
      when :number, :string, :boolean
        @instructions << IR::Push.new(node.value)

      when :add
        node.children.each { |child| ir(child) }
        @instructions << IR::Add.new

      when :print
        node.children.each { |child| ir(child) }
        @instructions << IR::Print.new

      when :variable
        @instructions <<  IR::LoadVar.new(@cur_scope.find_var(node.value))

      when :assign
        ir(node.children[1])

        var_name = node.children[0].value
        index = @cur_scope.find_var(var_name)

        @instructions << IR::StoreVar.new(index)

      when :func_call
        node.children.each { |child| ir(child) }
        @instructions << IR::Call.new(node.value, node.children.size)

      when :equals_equals
        node.children.each { |child| ir(child) }
        @instructions << IR::Equality.new
      end
    end
  end
end