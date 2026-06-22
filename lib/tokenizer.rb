# frozen_string_literal: true

module Potato
  class Token
    attr_reader :type, :value

    def initialize(type, value = nil)
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
        when "say" then result << Token.new(:PRINT)
        when "potato" then result << Token.new(:ADD)
        when "nothing" then result << Token.new(:NONE)
        when "is"     then result << Token.new(:EQUALS)
        when "(" then result << Token.new(:LPAREN)
        when ")" then result << Token.new(:RPAREN)
        when "gains"  then result << Token.new(:ADD_EQUALS)
        when "or" then result << Token.new(:OR)
        when "and" then result << Token.new(:AND)
        when "is?" then result << Token.new(:EQUALS_EQUALS)
        when "bigger?" then result << Token.new(:GREATER_THAN)
        when "smaller?"  then result << Token.new(:LESSER_THAN)
        when "atleast?"  then result << Token.new(:GREATER_EQUALS)
        when "atmost?" then result << Token.new(:LESSER_EQUALS)
        when "not?" then result << Token.new(:NOT_EQUALS)
        when "?"  then result << Token.new(:IF)
        when ":"  then result << Token.new(:CONNECTOR)
        when ","  then result << Token.new(:SEPARATOR)
        when /^\d+$/  then result << Token.new(:NUMBER, token.to_i)
        when /^".*"$/ then result << Token.new(:STRING, token[1..-2])
        when ":(" then result << Token.new(:BOOLEAN, token)
        when ":)" then result << Token.new(:BOOLEAN, token)
        when var_regex then result << Token.new(:VARIABLE, token)
        else Potato.err "Unknown token: #{token}"
        end
      end

      result
    end
  end
end
