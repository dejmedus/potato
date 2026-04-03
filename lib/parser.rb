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

    OPERATORS = { ADD: 10, EQUALS_EQUALS: 5, GREATER_THAN: 5, GREATER_EQUALS: 5, OR: 2, AND: 3, IF: 1, ELSE: 0 }

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