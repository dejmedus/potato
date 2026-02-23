module Potato
  module AST
    class Printer
      def self.print(ast)
        ast.each { |node| node.pretty_print }
      end
    end

    class Node
      attr_reader :type, :value, :children

      def initialize(type, value = nil, children = [])
        @type = type
        @value = value
        @children = children
      end

      def pretty_print(indent = 0, prefix = "", is_last = true)
        connector = indent == 0 ? "" : is_last ? "└── " : "├── "
        label = value ? "#{type.to_s.upcase} #{value}" : type.to_s.upcase
        puts "#{prefix}#{connector}#{label}"

        child_prefix = prefix + (indent == 0 ? "" : is_last ? "    " : "│   ")
        children.each_with_index do |child, i|
          child.pretty_print(indent + 1, child_prefix, i == children.size - 1)
        end
      end
    end
  end
end