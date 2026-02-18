module Potato
 class Parser
    def self.parse(source)
      source.lines.each do |line|
        tokens = Tokenizer.tokenize(line)
        next if tokens.empty?
        return ast(tokens)
      end
    end

    def self.ast(tokens)
      return unless tokens[0]&.type == :PRINT
      return unless tokens.any? { |t| t.type == :ADD }

      numbers = tokens.select { |t| t.type == :NUMBER }.map(&:value)
      return unless numbers.size >= 2

      add_node = AST::Node.new(:add, nil, numbers.map { |n| AST::Node.new(:number, n, []) })
      print_node = AST::Node.new(:print, nil, [add_node])
      
      # PrintAST.print(print_node)
      # Interpreter.eval(print_node)
      return print_node
    end
  end
end