module PotatoVM
  class VM
    def self.run
      stack = []

      File.open("potat.o", "rb") do |f|
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
          else
            raise "Unknown #{byte}"
          end
        end
      end
    end
  end
end

