# frozen_string_literal: true
# AUTO-GENERATED — do not edit by hand.
# Run `rake bundle` to regenerate from lib/*.rb
# Generated: 2026-04-05 11:50:34

# ── printer.rb ────────────────────────────────────────────────────────────────

module Potato
  class PrintTree
    def self.print(obj)
      case obj
      when Array then obj.each { |node| walk(node) }
      when Scope then walk(obj)
      end

      puts "\n"
    end

    private

    def self.walk(obj, indent = 0, prefix = "", is_last = true)
      connector = indent == 0 ? "" : is_last ? "└── " : "├── "
      puts "#{prefix}#{connector}#{label(obj)}"

      child_prefix = prefix + (indent == 0 ? "" : is_last ? "    " : "│   ")
      children(obj).each_with_index do |child, i|
        walk(child, indent + 1, child_prefix, i == children(obj).size - 1)
      end
    end

    def self.label(obj)
      case obj
      when Scope then obj.name
      when String then obj
      when AST::Node then obj.value ? "#{obj.type.to_s.upcase} #{obj.value}" : obj.type.to_s.upcase
      else obj.inspect
      end
    end

    def self.children(obj)
      case obj
      when Scope
        locals = obj.symbol_table.reject { |_, s| s.kind == :function }.map do |name, sym|
          "#{sym.kind == :param ? "@" : sym.kind == :captured ? "&" : ""}#{name} #{sym.locals_index}"
        end
        locals + obj.children
      when AST::Node then obj.children
      else []
      end
    end
  end
end


# ── tokenizer.rb ──────────────────────────────────────────────────────────────

module Potato
  class Token
    attr_reader :type, :value

    def initialize(type, value)
      @type = type
      @value = value
    end

    def to_s
      "#{type} #{value}" 
    end
  end

  class Tokenizer
    def self.tokenize(line)
      lexemes = line.scan(/"(?:\\.|[^"])*"|:\)|:\(|[(),]|[^\s(),]+/).reject(&:empty?)
      var_regex = /\A(?:[_\p{L}\p{Extended_Pictographic}])(?:[\p{Word}\p{Extended_Pictographic}\u200D\uFE0F]*)\z/u
      
      result = []
      lexemes.each_with_index do |token, index|
        case token.downcase
        when "🍠"
          result << Token.new(:COMMENT, lexemes[index..])
          break
        when "say"   then result << Token.new(:PRINT, nil)
        when "potato" then result << Token.new(:ADD, nil)
        when "nothing" then result << Token.new(:NULL, nil)
        when "is"     then result << Token.new(:EQUALS, nil)
        when "(" then result << Token.new(:LPAREN, nil)
        when ")" then result << Token.new(:RPAREN, nil)
        when "gains"  then result << Token.new(:ADD_EQUALS, nil)
        when "or" then result << Token.new(:OR, nil)
        when "and" then result << Token.new(:AND, nil)
        when "equals?"  then result << Token.new(:EQUALS_EQUALS, nil)
        when "bigger?"  then result << Token.new(:GREATER_THAN, nil)
        when "smaller?"  then result << Token.new(:LESSER_THAN, nil)
        when "atleast?"  then result << Token.new(:GREATER_EQUALS, nil)
        when "atmost?"  then result << Token.new(:LESSER_EQUALS, nil)
        when "not?" then result << Token.new(:NOT_EQUALS, nil)
        when "?"  then result << Token.new(:IF, nil)
        when ":"  then result << Token.new(:ELSE, nil)
        when ","  then result << Token.new(:SEPARATOR, nil)
        when /^\d+$/  then result << Token.new(:NUMBER, token.to_i)
        when /^".*"$/ then result << Token.new(:STRING, token[1..-2])
        when ":(" then result << Token.new(:BOOLEAN, token)
        when ":)" then result << Token.new(:BOOLEAN, token)
        when var_regex then result << Token.new(:VARIABLE, token)
        else err "Unknown token: #{token}"
        end
      end
      
      result
    end
  end
end


# ── parser.rb ─────────────────────────────────────────────────────────────────

module Potato
  module AST
    class Node
      attr_reader :type, :value, :children, :line

      def initialize(type, value = nil, children = [], line = nil)
        @type = type
        @value = value
        @children = children
        @line = line
      end
    end
  end

  class Parser
    def self.parse(source)
      source.lines.each_with_index.with_object([]) do |(line, index), nodes|
        tokens = Tokenizer.tokenize(line)
        next if tokens.empty?
        node = ast(tokens, index + 1)
        nodes << node if node
      end
    end

    EXPR_START = [:NUMBER, :STRING, :VARIABLE, :BOOLEAN, :NULL, :LPAREN]
    OPERATORS = { ADD: 10, EQUALS_EQUALS: 5, NOT_EQUALS: 5, GREATER_THAN: 5, GREATER_EQUALS: 5, LESSER_THAN: 5, LESSER_EQUALS: 5, OR: 2, AND: 3, IF: 1, ELSE: 0 }

    def self.ast(tokens, l)
      case tokens[0]&.type
      when :PRINT
        err "Say what?", l unless tokens[1..].size >= 1
        AST::Node.new(:print, nil, [parse_expression(tokens[1..], l)], l)

      when :VARIABLE
        head_value = tokens[0].value
        case tokens[1]&.type
        when :LPAREN
          close = closing_rparen(tokens, 1) 
          err "Expected )", l unless close

          param_tokens = tokens[2...close]
          body_tokens = tokens[close+1..]

          if body_tokens.any?
            params = param_tokens.reject { |t| t.type == :SEPARATOR }.map(&:value)
            statements = split_on_separator(body_tokens)

            AST::Node.new(:function, head_value, [
              AST::Node.new(:params, nil, params.map { |p| AST::Node.new(:param, p, []) }),
              AST::Node.new(:body, nil, statements.map { |s| ast(s, l) })
            ], l)
          else
            AST::Node.new(:func_call, head_value, parse_params(param_tokens, l), l)
          end

        when :EQUALS
          err "#{head_value} is what?", l unless tokens[2..].size >= 1
          AST::Node.new(:assign, nil, [
            AST::Node.new(:variable, head_value, [], l),
            parse_expression(tokens[2..], l)
          ], l)

        when :ADD_EQUALS
          err "#{head_value} gains what?", l unless tokens[2..].size >= 1
          AST::Node.new(:add_assign, nil, [
            AST::Node.new(:variable, head_value, [], l),
            parse_expression(tokens[2..], l)
          ], l)

        else
          parse_expression(tokens, l)
        end

      when :COMMENT then nil
      else
        err "Expected a statement", l
      end
    end

    def self.parse_expression(tokens, l = nil)
      node, _ = parse_expr(tokens, 0, 0, l)
      node
    end

    def self.parse_expr(tokens, index, cur_precedence, l = nil)
      left, index = parse_chunk(tokens, index, l)

      loop do
        node_type = tokens[index]&.type
        break unless node_type

        if EXPR_START.include?(node_type)
          err "Missing operator between expressions", l
        end

        if node_type == :IF && cur_precedence < 1
          index += 1  # consume ?

          true_branch, index = parse_expr(tokens, index, 0, l)

          if tokens[index]&.type == :ELSE
            index += 1  # consume :
            false_branch, index = parse_expr(tokens, index, 0)
            left = AST::Node.new(:conditional, nil, [left, true_branch, false_branch], l)
          else
            left = AST::Node.new(:conditional, nil, [left, true_branch])
          end
          next
        end

        precedence = OPERATORS[node_type]
        break unless precedence && precedence > cur_precedence

        index += 1  # consume operator
        right, index = parse_expr(tokens, index, precedence, l)
        left = AST::Node.new(node_type.downcase.to_sym, nil, [left, right])
      end

      [left, index]
    end

    def self.parse_chunk(tokens, index, l)
      node = parse_token(tokens[index], l)
      index += 1 # consume token

      if node.type == :variable && tokens[index]&.type == :LPAREN
        close = closing_rparen(tokens, index)

        err "Expected )", l unless close

        node = AST::Node.new(:func_call, node.value, parse_params(tokens[index+1...close], l), l)
        index = close + 1 # consume remaining
      end

      [node, index]
    end

    def self.parse_token(token, l = nil)
      case token.type
      when :NUMBER   then AST::Node.new(:number, token.value, [])
      when :VARIABLE then AST::Node.new(:variable, token.value, [], l)
      when :STRING   then AST::Node.new(:string, token.value, [])
      when :BOOLEAN  then AST::Node.new(:boolean, token.value == ":)", [])
      when :NULL     then AST::Node.new(:null, nil, [])
      else err "Unknown expression: #{token.type}"
      end
    end

    def self.parse_params(tokens, l)
      split_params(tokens).map { |param_tokens| parse_expression(param_tokens, l) }
    end

    def self.split_params(tokens)
      depth  = 0
      groups = [[]]
      tokens.each do |t|
        case t.type
        when :LPAREN then depth += 1
        when :RPAREN then depth -= 1
        when :SEPARATOR then groups << [] and next if depth == 0
        end
        groups.last << t
      end

      groups.reject(&:empty?)
    end

    def self.split_on_separator(tokens)
      tokens.slice_when { |t, _| t.type == :SEPARATOR }
            .map { |group| group.reject { |t| t.type == :SEPARATOR } }
    end

    def self.closing_rparen(tokens, loc)
      depth = 0
      tokens[loc..].each_with_index do |t, i|
        depth += 1 if t.type == :LPAREN
        depth -= 1 if t.type == :RPAREN
        return loc + i if depth == 0
      end
      nil
    end
  end
end


# ── desugar.rb ────────────────────────────────────────────────────────────────

module Potato
  class Desugar
    def self.desugar(ast)
      ast.map { |node| desugar_node(node) }
    end

    def self.desugar_node(node)
      case node.type
      when :add_assign
        var = node.children[0]
        value = node.children[1]

        AST::Node.new(:assign, nil, [
          var,
          AST::Node.new(:add, nil, [var, value])
        ], node.line)
      
      when :greater_equals
        left = node.children[0]
        right = node.children[1]

        AST::Node.new(:or, nil, [
          AST::Node.new(:greater_than, nil, [left, right], node.line),
          AST::Node.new(:equals_equals, nil, [left, right], node.line)
        ], node.line)

      else
        AST::Node.new(
          node.type,
          node.value,
          node.children.map { |c| desugar_node(c) },
          node.line
        )
      end
    end
  end
end


# ── analysis.rb ───────────────────────────────────────────────────────────────

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


# ── lowering.rb ───────────────────────────────────────────────────────────────

module Potato
  class IR
    Push = Struct.new(:value)
    LoadVar = Struct.new(:index)
    LoadCaptured = Struct.new(:index)
    StoreVar = Struct.new(:index)
    Add = Struct.new
    Equality = Struct.new
    NotEquality = Struct.new
    GreaterThan = Struct.new
    LesserThan = Struct.new
    GreaterEquals = Struct.new
    LesserEquals = Struct.new
    Or = Struct.new
    And = Struct.new
    Print = Struct.new
    Call = Struct.new(:target, :arg_count)
    Return = Struct.new
    Jump = Struct.new(:target)
    JumpIfFalse = Struct.new(:target)
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

    OPERATORS = {
      equals_equals: IR::Equality,
      not_equals:    IR::NotEquality,
      greater_equals: IR::GreaterEquals,
      lesser_equals: IR::LesserEquals,
      greater_than:  IR::GreaterThan,
      lesser_than:   IR::LesserThan,
      or:            IR::Or,
      and:           IR::And,
      add:           IR::Add
    }

    def write(instruction)
      @instructions << instruction
      @byte_offset += case instruction

      when IR::Push then instruction.value.is_a?(String) ? 5 + instruction.value.bytesize : instruction.value.nil? ? 1 : 5
      when IR::Call then 9
      when *OPERATORS.values, IR::Print, IR::Return then 1
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

    def conditional_ir(node)
      ir(node.children[0])  # condition

      jump_false_index = @instructions.size
      write IR::JumpIfFalse.new(nil)

      ir(node.children[1])  # true

      if node.children[2]
        jump_end_index = @instructions.size
        write IR::Jump.new(nil)
        @instructions[jump_false_index].target = next_free_byte
        ir(node.children[2]) # else true
        @instructions[jump_end_index].target = next_free_byte
      else
        jump_end_index = @instructions.size
        write IR::Jump.new(nil) 
        @instructions[jump_false_index].target = next_free_byte  # false 
        write IR::Push.new(nil)
        @instructions[jump_end_index].target = next_free_byte
      end
    end

    def ir(node)
      case node.type
      when :function
        func_ir(node)

      when :number, :boolean
        write IR::Push.new(node.value)

      when :string
        write IR::Push.new(node.value)

      when :null
        write IR::Push.new(nil)

      when :print
        node.children.each { |child| ir(child) }
        write IR::Print.new

      when :variable
        symbol = @cur_scope.lookup(node.value)
        
        if symbol.kind == :captured
          write IR::LoadCaptured.new(symbol.locals_index)
        else
          write IR::LoadVar.new(symbol.locals_index)
        end

      when :assign
        ir(node.children[1])
        var_name = node.children[0].value
        index = @cur_scope.lookup(var_name)&.locals_index
        write IR::StoreVar.new(index)

      when :conditional
        conditional_ir(node)

      when :func_call
        node.children.each { |child| ir(child) }
        write IR::Call.new(@cur_scope.lookup(node.value).bytecode_location, node.children.size)

      when *OPERATORS.keys
        node.children.each { |child| ir(child) }
        write OPERATORS[node.type].new
      end
    end
  end
end


# ── compiler.rb ───────────────────────────────────────────────────────────────

module Potato
  class Compiler
    def self.compile(scope, ir)
      buf = StringIO.new("".b)
      write_ir(ir, buf)
      buf.string
    end

    def self.write_ir(ir, f)
      ir.each { |instruction| ir(instruction, f) }
    end

    def self.write(f, opcode, value = nil)
      f.write([opcode].pack("C"))
      f.write([value].pack("L>")) if value
    end

    def self.ir(instruction, f)
      case instruction
      when IR::Push
        case instruction.value
        when Integer
          write(f, 0x01, instruction.value)
        when String
          write(f, 0x06, instruction.value.bytesize)
          f.write(instruction.value)
        when TrueClass, FalseClass
          write(f, 0x08, instruction.value ? 1 : 0)
        when NilClass
          write(f, 0x11)
        end
      when IR::LoadVar
        write(f, 0x04, instruction.index)
      when IR::LoadCaptured
        write(f, 0x0C, instruction.index)
      when IR::StoreVar
        write(f, 0x05, instruction.index)
      when IR::Add
        write(f, 0x02)
      when IR::Equality
        write(f, 0x07)
      when IR::NotEquality
        write(f, 0x15)
      when IR::GreaterThan
        write(f, 0x0D)
      when IR::LesserThan
        write(f, 0x12)
      when IR::GreaterEquals
        write(f, 0x13)
      when IR::LesserEquals
        write(f, 0x14)
      when IR::Or
        write(f, 0x0E)
      when IR::And
        write(f, 0x0F)
      when IR::Print
        write(f, 0x03)
      when IR::Call
        write(f, 0x09, instruction.target)
        f.write([instruction.arg_count].pack("L>")) 
      when IR::Return
        write(f, 0x0A)
      when IR::Jump
        write(f, 0x0B, instruction.target)
      when IR::JumpIfFalse
        write(f, 0x10, instruction.target)
      end
    end
  end
end


# ── vm.rb ─────────────────────────────────────────────────────────────────────

module PotatoVM
  class VM
    
    # otherwise we can't compare 
    # to real nil values
    Null = Object.new
    def Null.to_s = "nil"

    def self.read(bytes = 4)
      value = @bytecode[@pos, bytes].pack("C*").unpack1("L>")
      @pos += bytes
      value
    end

    def self.run(bytecode)
      @bytecode = bytecode.bytes
      @pos = 0

      stack = []
      scopes = []
      locals = Array.new(100)

      until @pos >= @bytecode.size
        byte = @bytecode[@pos]
        @pos += 1

        case byte
        when 0x01 # number
          stack.push(read)
        when 0x02 # add
          right = stack.pop
          left = stack.pop

          if !left.is_a?(Numeric) || !right.is_a?(Numeric)
            left = left.to_s
            right = right.to_s
          end

          stack.push(left + right)
        when 0x03 # print
          puts stack.pop
        when 0x04 # variable
          index = read
          stack.push(locals[index])
          err "Unknown variable" if locals[index].nil?
        when 0x0C # captured variable
          index = read
          parent_locals = scopes.last[:locals]
          stack.push(parent_locals[index])
          err "Unknown captured variable" if parent_locals[index].nil?
        when 0x05 # assign
          index = read
          value = stack.pop
          locals[index] = value
        when 0x06 # string
          length = read
          value = @bytecode[@pos, length].pack("C*")
          @pos += length
          stack.push(value)
        when 0x07 # == operator
          right = stack.pop
          left = stack.pop
          stack.push(left == right)
        when 0x15 # != operator
          right = stack.pop
          left = stack.pop
          stack.push(left != right)
        when 0x0E # || operator
          right = stack.pop
          left = stack.pop
          stack.push(left || right)
        when 0x0F # && operator
          right = stack.pop
          left = stack.pop
          stack.push(left && right)
        when 0x0D # > operator
          right = stack.pop
          left = stack.pop
          stack.push(left > right)
        when 0x12 # < operator
          right = stack.pop
          left = stack.pop
          stack.push(left < right)
        when 0x13 # >= operator
          right = stack.pop
          left = stack.pop
          stack.push(left >= right)
        when 0x14 # <= operator
          right = stack.pop
          left = stack.pop
          stack.push(left <= right)
        when 0x08 # boolean
          value = read
          stack.push(value == 1)
        when 0x11 # nil
          stack.push(Null)
        when 0x09 # call
          target = read
          arg_count = read
          scopes.push({ locals: locals, call_site: @pos })
          locals = Array.new(100)
          args = stack.pop(arg_count)
          args.each_with_index { |arg, i| locals[i] = arg }
          @pos = target
        when 0x0A # return
          return_value = stack.pop
          scope = scopes.pop
          locals = scope[:locals]
          @pos = scope[:call_site]
          stack.push(return_value)
        when 0x0B # jump
          @pos = read
        when 0x10 # jump if false
          target = read
          falsey = [false, Null]
          @pos = target if falsey.include?(stack.pop)
        end
      end
    end
  end
end


# ── potato.rb ─────────────────────────────────────────────────────────────────

require 'stringio'








module Potato
  def self.run(source, options = {})
    ast = Parser.parse(source)
    ast = Desugar.desugar(ast)
    PrintTree.print(ast) if options[:ast]
    scope = ScopeTree.build(ast)
    PrintTree.print(scope) if options[:scope]
    ir = Lowering.lower(ast, scope)
    PrintTree.print(ir) if options[:ir]
    bytes = Compiler.compile(scope, ir)
    PotatoVM::VM.run(bytes)
  end

  def self.run_file(path, options = {})
    run(File.read(path), options)
  end
end

def err(msg, line_num = nil)
  line = line_num ? "L#{line_num} " : ""
  abort "#{line}\e[31m#{msg}\e[0m"
end
