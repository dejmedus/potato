
module Potato
  class IR
    Push = Struct.new(:value)
    LoadVar = Struct.new(:index)
    StoreVar = Struct.new(:index)
    Add = Struct.new
    Equality = Struct.new
    Print = Struct.new
    Call = Struct.new(:target, :arg_count)
    Return = Struct.new
    Jump = Struct.new(:target)
  end

  class Lowering
    def initialize(scope)
      @global_scope = scope
      @cur_scope = scope
      @instructions = []
    end

    def self.lower(ast, scope)
      new(scope).lower(ast)
    end

    def next_free_index
      @instructions.size
    end

    def lower(ast)
      ast.each { |node| ir(node) }
      @instructions
    end

    def func_ir(node)
      jump_index = next_free_index
      @instructions << IR::Jump.new(nil)

      sym = @cur_scope.find_var(node.value)
      sym.instruction_index = next_free_index

      @cur_scope = @cur_scope.children.find { |c| c.name == node.value }

      params_node = node.children[0]
      params_node.children.each { |p|
        @instructions << IR::StoreVar.new(@cur_scope.find_var(p.value).index)
      }

      body_node = node.children[1]
      body_node.children.each { |s| ir(s) }

      @instructions << IR::Return.new
      @instructions[jump_index].target = next_free_index
      @cur_scope = @cur_scope.parent
    end

    def ir(node)
      case node.type
      when :function
        func_ir(node)

      when :number, :string, :boolean
        @instructions << IR::Push.new(node.value)

      when :add
        node.children.each { |child| ir(child) }
        @instructions << IR::Add.new

      when :print
        node.children.each { |child| ir(child) }
        @instructions << IR::Print.new

      when :variable
        @instructions <<  IR::LoadVar.new(@cur_scope.find_var(node.value).index)

      when :assign
        ir(node.children[1])
        var_name = node.children[0].value
        index = @cur_scope.find_var(var_name)&.index
        @instructions << IR::StoreVar.new(index)

      when :func_call
        node.children.each { |child| ir(child) }
        @instructions << IR::Call.new(@cur_scope.find_var(node.value).instruction_index, node.children.size)

      when :equals_equals
        node.children.each { |child| ir(child) }
        @instructions << IR::Equality.new
      end
    end
  end
end