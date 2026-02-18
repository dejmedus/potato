class Compiler
  def self.compile(ast)
    File.open("potat.o", "wb") do |f|
      self.ir(ast, f)
    end
  end

  def self.ir(node, f)
    case node.type
    when :number
      f.write([0x01].pack("C"))
      f.write([node.value].pack("L>"))
    
    when :add
      node.children.each { |child| ir(child, f) }
      f.write([0x02].pack("C"))

    when :print
      node.children.each { |child| ir(child, f) }
      f.write([0x03].pack("C"))
    end
  end
end

