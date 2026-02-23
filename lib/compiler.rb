class Compiler
  @symbol_table = {}

  def self.compile(ast)
    create_symbol_table(ast)

    File.open("potat.o", "wb") do |f|
      write_symbol_table(f)
      write_ir(ast, f)
    end
  end

  def self.write_ir(ast, f)
    ast.each { |node| ir(node, f) }
  end

  def self.write_symbol_table(f)
    f.write([@symbol_table.size].pack("L>"))

    @symbol_table.each do |var, index|
      f.write([var.bytesize].pack("C"))
      f.write(var)
      f.write([index].pack("L>"))
    end
  end

  def self.ir(node, f)
    case node.type
    when :number
      f.write([0x01].pack("C"))
      f.write([node.value].pack("L>"))

    when :string
      f.write([0x06].pack("C"))
      f.write([node.value.bytesize].pack("L>"))
      f.write(node.value)

    when :add
      node.children.each { |child| ir(child, f) }
      f.write([0x02].pack("C"))

    when :print
      node.children.each { |child| ir(child, f) }
      f.write([0x03].pack("C"))

    when :variable
      index = @symbol_table[node.value]
      err "Unknown variable: #{node.value}" unless index
      f.write([0x04].pack("C"))
      f.write([index].pack("L>"))

    when :assign
      ir(node.children[1], f)

      var_name = node.children[0].value
      index = @symbol_table[var_name]

      f.write([0x05].pack("C"))       
      f.write([index].pack("L>"))

    when :equals_equals
      node.children.each { |child| ir(child, f) }
      f.write([0x07].pack("C"))
    end
  end

  def self.create_symbol_table(ast)
    for node in ast
      collect_symbols(node)
    end
  end

  def self.collect_symbols(node)
    case node.type
    when :assign
      var = node.children[0].value
      @symbol_table[var] ||= @symbol_table.size
    end

    node.children.each { |child| collect_symbols(child) }
  end
end

