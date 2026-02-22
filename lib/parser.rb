module Potato
  class Parser
    def self.parse(source)
      source.lines.each_with_object([]) do |line, nodes|
        tokens = Tokenizer.tokenize(line)
        next if tokens.empty?
        node = ast(tokens)
        nodes << node if node
      end
    end

    def self.ast(tokens)
      case tokens[0]&.type
      when :PRINT
        err "Say what?" unless tokens[1..].size >= 1

        AST::Node.new(:print, nil, [parse_expression(tokens[1..])])
      when :VARIABLE
        parse_expression(tokens) unless tokens[1]&.type == :EQUALS

        err "Equals what?" unless tokens[2..].size >= 1

        AST::Node.new(:assign, nil, [
          AST::Node.new(:variable, tokens[0].value, []),
          parse_expression(tokens[2..])
        ])
 
      when :COMMENT then nil
      else nil # unexecuted code
      end
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
      else err "Unknown expression: #{token.type}"
      end
    end

    def self.parse_expr(tokens, index, cur_precedence)
      left = parse_token(tokens[index])
      index += 1  # consume value

      loop do
        node_type = tokens[index]&.type
        break unless node_type

        precedence = { ADD: 10 }[node_type]
        break unless precedence && precedence > cur_precedence

        index += 1  # consume operator
        right, index = parse_expr(tokens, index, precedence)
        left = AST::Node.new(node_type.downcase.to_sym, nil, [left, right])
      end

      [left, index]
    end
  end
end


