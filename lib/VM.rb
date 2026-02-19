module PotatoVM
  class VM
    def self.run
      stack = []
      symbol_table = []
      locals = Array.new(symbol_table.size)

      File.open("potat.o", "rb") do |f|
        symbols_num = f.read(4).unpack1("L>")

        symbols_num.times do
          var_length = f.read(1).unpack1("C")
          var = f.read(var_length)
          index = f.read(4).unpack1("L>")
          symbol_table[index] = var
        end

        until f.eof?
          byte = f.read(1).unpack1("C")
          case byte
          when 0x01 # number
            value_bytes = f.read(4)     
            value = value_bytes.unpack1("L>")
            stack.push(value)
          when 0x02 # add
            number = stack.reduce(:+)
            stack.clear
            stack.push(number)
          when 0x03 # print
            puts stack.pop
          when 0x04 # variable
            index = f.read(4).unpack1("L>")
            stack.push(locals[index])
            raise "Oop: #{symbol_table[index]}?" if locals[index].nil?
            
          when 0x05 # assign
            index_bytes = f.read(4)
            index = index_bytes.unpack1("L>")
            value = stack.pop
            locals[index] = value
          end
        end
      end
    end
  end
end

