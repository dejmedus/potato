module Potato
  class Desugar
    def self.desugar(ast)
      ast.map { |node| desugar_node(node) }
    end

    def self.desugar_node(node)
      case node.type
      when :plus_assign
        var = node.children[0]
        value = node.children[1]

        AST::Node.new(:assign, nil, [
          var,
          AST::Node.new(:add, nil, [var, value])
        ])
      else
        AST::Node.new(
          node.type,
          node.value,
          node.children.map { |c| desugar_node(c) }
        )
      end
    end
  end
end