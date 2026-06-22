# frozen_string_literal: true

module Potato
  module AST
    class Node
      attr_reader :type, :value, :children, :line

      def initialize(type, value = nil, children = [], line = Potato.current_line)
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
        Potato.current_line = index + 1

        tokens = Tokenizer.tokenize(line)
        next if tokens.empty?

        node = ast(tokens)
        nodes << node if node
      end
    end

    EXPR_START = [:NUMBER, :STRING, :VARIABLE, :BOOLEAN, :NONE, :LPAREN].freeze
    OPERATORS = { ADD: 10, EQUALS_EQUALS: 5, NOT_EQUALS: 5, GREATER_THAN: 5, GREATER_EQUALS: 5, LESSER_THAN: 5, LESSER_EQUALS: 5, OR: 2, AND: 3, IF: 1, ELSE: 0 }.freeze

    def self.ast(tokens)
      case tokens[0]&.type
      when :PRINT then parse_print(tokens)
      when :VARIABLE then parse_var_statement(tokens)
      when :COMMENT then nil
      else Potato.err "Expected a statement"
      end
    end

    def self.parse_print(tokens)
      Potato.err "Say what?" unless tokens[1..].size >= 1
      AST::Node.new(:print, nil, [parse_expression(tokens[1..])])
    end

    def self.parse_var_statement(tokens)
      variable = tokens[0].value
      case tokens[1]&.type
      when :LPAREN then parse_func_def_or_call(variable, tokens)
      when :EQUALS then parse_assign(variable, tokens)
      when :ADD_EQUALS then parse_add_assign(variable, tokens)
      else parse_expression(tokens)
      end
    end

    def self.parse_func_def_or_call(variable, tokens)
      close = closing_rparen(tokens, 1)
      Potato.err "Expected )" unless close

      param_tokens = tokens[2...close]
      body_tokens = tokens[close + 1..]

      if body_tokens.any?
        parse_func_def(variable, param_tokens, body_tokens)
      else
        AST::Node.new(:func_call, variable, parse_params(param_tokens))
      end
    end

    def self.parse_func_def(variable, param_tokens, body_tokens)
      params = param_tokens.reject { |t| t.type == :SEPARATOR }.map(&:value)
      statements = split_on_separator(body_tokens)

      AST::Node.new(:function, variable, [
        AST::Node.new(:params, nil, params.map { |p| AST::Node.new(:param, p) }),
        AST::Node.new(:body, nil, statements.map { |s| ast(s) })
      ])
    end

    def self.parse_assign(variable, tokens)
      Potato.err "#{variable} is what?" unless tokens[2..].size >= 1
      AST::Node.new(:assign, nil, [
        AST::Node.new(:variable, variable),
        parse_expression(tokens[2..])
      ])
    end

    def self.parse_add_assign(variable, tokens)
      Potato.err "#{variable} gains what?" unless tokens[2..].size >= 1
      AST::Node.new(:add_assign, nil, [
        AST::Node.new(:variable, variable),
        parse_expression(tokens[2..])
      ])
    end

    def self.parse_expression(tokens)
      node, = parse_expr(tokens, 0, 0)
      node
    end

    def self.parse_expr(tokens, index, cur_precedence)
      left, index = parse_chunk(tokens, index)

      loop do
        node_type = tokens[index]&.type
        break unless node_type

        if EXPR_START.include?(node_type)
          Potato.err "Missing operator between expressions"
        end

        if node_type == :IF && cur_precedence < 1
          index += 1 # consume ?

          true_branch, index = parse_expr(tokens, index, 0)

          if tokens[index]&.type == :CONNECTOR
            index += 1 # consume :
            false_branch, index = parse_expr(tokens, index, 0)
            left = AST::Node.new(:conditional, nil, [left, true_branch, false_branch])
          else
            left = AST::Node.new(:conditional, nil, [left, true_branch])
          end
          next
        end

        precedence = OPERATORS[node_type]
        break unless precedence && precedence > cur_precedence

        index += 1 # consume operator
        right, index = parse_expr(tokens, index, precedence)
        left = AST::Node.new(node_type.downcase.to_sym, nil, [left, right])
      end

      [left, index]
    end

    def self.parse_chunk(tokens, index)
      node = parse_token(tokens[index])
      index += 1 # consume token

      if node.type == :variable && tokens[index]&.type == :LPAREN
        close = closing_rparen(tokens, index)

        Potato.err "Expected )" unless close

        node = AST::Node.new(:func_call, node.value, parse_params(tokens[index + 1...close]))
        index = close + 1 # consume )
      end

      [node, index]
    end

    def self.parse_token(token)
      Potato.err "Should this be an expression?" if token.nil?

      case token.type
      when :NUMBER   then AST::Node.new(:number, token.value)
      when :VARIABLE then AST::Node.new(:variable, token.value)
      when :STRING   then AST::Node.new(:string, token.value)
      when :BOOLEAN  then AST::Node.new(:boolean, token.value == ":)")
      when :NONE     then AST::Node.new(:none, nil)
      else Potato.err "Unknown expression: #{token.type}"
      end
    end

    def self.parse_params(tokens)
      split_on_separator(tokens).map { |param_tokens| parse_expression(param_tokens) }
    end

    def self.split_on_separator(tokens)
      depth  = 0
      groups = [[]]
      tokens.each do |t|
        case t.type
        when :LPAREN then depth += 1
        when :RPAREN then depth -= 1
        when :SEPARATOR then groups << [] and next if depth.zero?
        end
        groups.last << t
      end

      groups.reject(&:empty?)
    end

    def self.closing_rparen(tokens, loc)
      depth = 0
      tokens[loc..].each_with_index do |t, i|
        depth += 1 if t.type == :LPAREN
        depth -= 1 if t.type == :RPAREN
        return loc + i if depth.zero?
      end
      nil
    end
  end
end
