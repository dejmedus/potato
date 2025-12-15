module Potato
  class Interpreter
    def self.eval(node)
      case node.type
      when :print
        result = self.eval(node.children.first)
        puts result
      when :add
        node.children.map { |child| self.eval(child) }.reduce(:+)
      when :number
        node.value
      end
    end
  end
end