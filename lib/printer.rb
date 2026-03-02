module Potato
  class PrintTree
    def self.print(obj)
      case obj
      when Array then obj.each { |node| walk(node) }
      when Scope then walk(obj)
      end

      puts "\n"
    end

    private

    def self.walk(obj, indent = 0, prefix = "", is_last = true)
      connector = indent == 0 ? "" : is_last ? "└── " : "├── "
      puts "#{prefix}#{connector}#{label(obj)}"

      child_prefix = prefix + (indent == 0 ? "" : is_last ? "    " : "│   ")
      children(obj).each_with_index do |child, i|
        walk(child, indent + 1, child_prefix, i == children(obj).size - 1)
      end
    end

    def self.label(obj)
      case obj
      when Scope then obj.name
      when String then obj
      when AST::Node then obj.value ? "#{obj.type.to_s.upcase} #{obj.value}" : obj.type.to_s.upcase
      else obj.inspect
      end
    end

    def self.children(obj)
      case obj
      when Scope
        locals = obj.symbol_table.reject { |_, s| s.kind == :function }.map do |name, sym|
          "#{sym.kind == :param ? "@" : ""}#{name} #{sym.locals_index}"
        end
        locals + obj.children
      when AST::Node then obj.children
      else []
      end
    end
  end
end