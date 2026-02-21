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
        raise "Say what?" unless tokens[1..].size >= 1
        AST::Node.new(:print, nil, [ast_expression(tokens[1..])])
      when :VARIABLE
        if tokens[1]&.type == :EQUALS
          raise "Equals what?" unless tokens[2..].size >= 1
          AST::Node.new(:assign, nil, [
            AST::Node.new(:variable, tokens[0].value, []),
            ast_expression(tokens[2..])
          ])
        else
          ast_expression(tokens)
        end
      when :STRING
        AST::Node.new(:string, tokens[0].value, [])
      when :ADD
        raise "More numbers please" unless tokens[1..].size >= 2
        AST::Node.new(:add, nil, tokens[1..].map { |t| ast_expression([t]) })
      when :COMMENT
        nil
      else
        raise "Unknown statement: #{tokens[0].type}"
      end
    end

    def self.ast_expression(tokens)
      return nil if tokens.empty?

      if tokens.size == 1
        token = tokens.first
        case token.type
        when :NUMBER
          return AST::Node.new(:number, token.value, [])
        when :VARIABLE
          return AST::Node.new(:variable, token.value, [])
        when :STRING
          return AST::Node.new(:string, token.value, [])
        else
          raise "Unknown expression: #{token.type}"
        end
      end

      add_index = tokens.find_index { |t| t.type == :ADD }
      if add_index
        left_tokens = tokens[0...add_index]
        right_tokens = tokens[(add_index + 1)..]

        left_node = ast_expression(left_tokens)
        right_node = ast_expression(right_tokens)

        AST::Node.new(:add, nil, [left_node, right_node])
      else
        ast_expression([tokens.first])
      end
    end
  end
end