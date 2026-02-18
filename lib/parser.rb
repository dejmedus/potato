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
      return unless tokens[0]&.type == :PRINT
      return unless tokens.any? { |t| t.type == :ADD }

      numbers = tokens.select { |t| t.type == :NUMBER }.map(&:value)
      raise "More numbers please" unless numbers.size >= 2

      add_node = AST::Node.new(:add, nil, numbers.map { |n| AST::Node.new(:number, n, []) })
      print_node = AST::Node.new(:print, nil, [add_node])
      
      print_node
    end
  end
end