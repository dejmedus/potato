
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
      @byte_offset = 0
    end

    def self.lower(ast, scope)
      new(scope).lower(ast)
    end

    def write(instruction)
      @instructions << instruction
      @byte_offset += case instruction

      when IR::Push then instruction.value.is_a?(String) ? 5 + instruction.value.bytesize : 5
      when IR::Call then 9
      when IR::Add, IR::Print, IR::Equality, IR::Return then 1
      else 5
      end
    end

    def next_free_byte
      @byte_offset
    end

    def lower(ast)
      ast.each { |node| ir(node) }
      @instructions
    end

    def func_ir(node)
      jump_index = @instructions.size
      write IR::Jump.new(nil)

      func = @cur_scope.lookup(node.value)
      func.bytecode_location = next_free_byte

      @cur_scope = @cur_scope.children.find { |c| c.name == node.value }

      body_node = node.children[1]
      body_node.children.each { |s| ir(s) }

      write IR::Return.new
      @instructions[jump_index].target = next_free_byte
      @cur_scope = @cur_scope.parent
    end

    def ir(node)
      case node.type
      when :function
        func_ir(node)

      when :number, :boolean
        write IR::Push.new(node.value)

      when :string
        write IR::Push.new(node.value)

      when :add
        node.children.each { |child| ir(child) }
        write IR::Add.new

      when :print
        node.children.each { |child| ir(child) }
        write IR::Print.new

      when :variable
        write IR::LoadVar.new(@cur_scope.lookup(node.value).locals_index)

      when :assign
        ir(node.children[1])
        var_name = node.children[0].value
        index = @cur_scope.lookup(var_name)&.locals_index
        write IR::StoreVar.new(index)

      when :func_call
        node.children.each { |child| ir(child) }
        write IR::Call.new(@cur_scope.lookup(node.value).bytecode_location, node.children.size)

      when :equals_equals
        node.children.each { |child| ir(child) }
        write IR::Equality.new
      end
    end
  end
end