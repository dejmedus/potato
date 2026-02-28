module Potato
  class Parser
    def self.parse(source)
      source.lines.each_with_index.with_object([]) do |(line, index), nodes|
        tokens = Tokenizer.tokenize(line)
        next if tokens.empty?
        node = ast(tokens, index + 1)
        nodes << node if node
      end
    end

    def self.ast(tokens, line)
      case tokens[0]&.type
      when :PRINT
        err "Say what?", line unless tokens[1..].size >= 1
        AST::Node.new(:print, nil, [parse_expression(tokens[1..])])

      when :VARIABLE
        head_value = tokens[0].value
        case tokens[1]&.type
        when :LPAREN
          close = tokens.index { |t| t.type == :RPAREN }
          err "Expected )", line unless close

          param_tokens = tokens[2...close]
          body_tokens = tokens[close+1..]

          if body_tokens.any?
            params = param_tokens.reject { |t| t.type == :SEPARATOR }.map(&:value)
            statements = split_on_separator(body_tokens)

            AST::Node.new(:function, head_value, [
              AST::Node.new(:params, nil, params.map { |p| AST::Node.new(:param, p, []) }),
              AST::Node.new(:body, nil, statements.map { |s| ast(s, line) })
            ])
          else
            args = param_tokens.reject { |t| t.type == :SEPARATOR }
            AST::Node.new(:func_call, head_value,
              args.map { |t| parse_token(t) }
            )
          end

        when :EQUALS
          err "#{head_value} is what?", line unless tokens[2..].size >= 1

          AST::Node.new(:assign, nil, [
            AST::Node.new(:variable, head_value, []),
            parse_expression(tokens[2..])
          ])

        when :ADD_EQUALS
          err "#{head_value} gains what?", line unless tokens[2..].size >= 1
          
          AST::Node.new(:add_assign, nil, [
            AST::Node.new(:variable, head_value, []),
            parse_token(tokens[2])
          ])

        else
          parse_expression(tokens)
        end

      when :COMMENT then nil
      else nil # unexecuted code
      end
    end

    def self.split_on_separator(tokens)
      tokens.slice_when { |t, _| t.type == :SEPARATOR }
            .map { |group| group.reject { |t| t.type == :SEPARATOR } }
    end

    def self.parse_expression(tokens)
      node, _ = parse_expr(tokens, 0, 0)
      node
    end

    def self.parse_token(token)
      case token.type
      when :NUMBER   then AST::Node.new(:number, token.value, [])
      when :VARIABLE then AST::Node.new(:variable, token.value, [])
      when :STRING   then AST::Node.new(:string, token.value, [])
      when :BOOLEAN  then AST::Node.new(:boolean, token.value == ":)", [])
      else err "Unknown expression: #{token.type}"
      end
    end

    def self.parse_expr(tokens, index, cur_precedence)
      left = parse_token(tokens[index])
      index += 1  # consume value

      loop do
        node_type = tokens[index]&.type
        break unless node_type

        precedence = { ADD: 10, EQUALS_EQUALS: 5  }[node_type]
        break unless precedence && precedence > cur_precedence

        index += 1  # consume operator
        right, index = parse_expr(tokens, index, precedence)
        left = AST::Node.new(node_type.downcase.to_sym, nil, [left, right])
      end

      [left, index]
    end
  end
end