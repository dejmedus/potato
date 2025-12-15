module Potato
  module AST
    Node = Struct.new(:type, :value, :children)
  end

  class PrintAST
    def self.print(node, indent = 0)
      prefix = "  " * indent
      case node.type
      when :print
        puts "#{prefix}Print"
        node.children.each { |child| print(child, indent + 1) }
      when :add
        puts "#{prefix}Add"
        node.children.each { |child| print(child, indent + 1) }
      when :number
        puts "#{prefix}Number(#{node.value})"
      else
        puts "#{prefix}#{node.type}(#{node.value})"
      end
    end
  end
end