module Potato
  class Token
    attr_reader :type, :value

    def initialize(type, value)
      @type = type
      @value = value
    end

    def to_s
      "#{type} #{value}" 
    end
  end

  class Tokenizer
    def self.tokenize(line)
      lexemes = line.scan(/"(?:\\.|[^"])*"|:\)|:\(|[(),]|[^\s(),]+/).reject(&:empty?)
      
      result = []
      lexemes.each_with_index do |token, index|
        case token.downcase
        when "🍠"
          result << Token.new(:COMMENT, lexemes[index..])
          break
        when "say"   then result << Token.new(:PRINT, nil)
        when "potato" then result << Token.new(:ADD, nil)
        when "is"     then result << Token.new(:EQUALS, nil)
        when "(" then result << Token.new(:LPAREN, nil)
        when ")" then result << Token.new(:RPAREN, nil)
        when "gains"  then result << Token.new(:ADD_EQUALS, nil)
        when "equals?"  then result << Token.new(:EQUALS_EQUALS, nil)
        when ","  then result << Token.new(:SEPARATOR, nil)
        when /^\d+$/  then result << Token.new(:NUMBER, token.to_i)
        when /^".*"$/ then result << Token.new(:STRING, token[1..-2])
        when ":(" then result << Token.new(:BOOLEAN, token)
        when ":)" then result << Token.new(:BOOLEAN, token)
        when /^[a-zA-Z_]\w*$/ then result << Token.new(:VARIABLE, token)
        else err "Unknown token: #{token}"
        end
      end
      
      result
    end
  end
end