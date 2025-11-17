module Potato
  class Parser
    def self.parse(source)
      tokens = Tokenizer.tokenize(source)

      if tokens[0].type == :SAY
         has_add = tokens.any? { |t| t.type == :ADD }
        
        if has_add
          left = nil
          right = nil
          tokens.each_with_index do |token, index|
            if token.type == :NUMBER && left.nil?
              left = token.value
            elsif token.type == :NUMBER && !left.nil?
              right = token.value
            end
          end
          expression = left + right
          puts expression
        end
      end
    end
  end
end


# Say → instruction node
# Add → operator node
# Number → literal node

#Say
#  └── Add
#       ├── Number(2)
#       └── Number(4)
#       
#
# token types
# Number
# Potato (Add)
# Say