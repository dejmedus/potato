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
      var_regex = /\A(?:[_\p{L}\p{Extended_Pictographic}])(?:[\p{Word}\p{Extended_Pictographic}\u200D\uFE0F]*)\z/u
      
      result = []
      lexemes.each_with_index do |token, index|
        case token.downcase
        when "🍠"
          result << Token.new(:COMMENT, lexemes[index..])
          break
        when "say"   then result << Token.new(:PRINT, nil)
        when "potato" then result << Token.new(:ADD, nil)
        when "nothing" then result << Token.new(:NULL, nil)
        when "is"     then result << Token.new(:EQUALS, nil)
        when "(" then result << Token.new(:LPAREN, nil)
        when ")" then result << Token.new(:RPAREN, nil)
        when "gains"  then result << Token.new(:ADD_EQUALS, nil)
        when "or" then result << Token.new(:OR, nil)
        when "and" then result << Token.new(:AND, nil)
        when "equals?"  then result << Token.new(:EQUALS_EQUALS, nil)
        when "greater?"  then result << Token.new(:GREATER_THAN, nil)
        when "smaller?"  then result << Token.new(:LESSER_THAN, nil)
        when "atleast?"  then result << Token.new(:GREATER_EQUALS, nil)
        when "atmost?"  then result << Token.new(:LESSER_EQUALS, nil)
        when "isnt?" then result << Token.new(:NOT_EQUALS, nil)
        when "?"  then result << Token.new(:IF, nil)
        when ":"  then result << Token.new(:ELSE, nil)
        when ","  then result << Token.new(:SEPARATOR, nil)
        when /^\d+$/  then result << Token.new(:NUMBER, token.to_i)
        when /^".*"$/ then result << Token.new(:STRING, token[1..-2])
        when ":(" then result << Token.new(:BOOLEAN, token)
        when ":)" then result << Token.new(:BOOLEAN, token)
        when var_regex then result << Token.new(:VARIABLE, token)
        else err "Unknown token: #{token}"
        end
      end
      
      result
    end
  end
end