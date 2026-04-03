require_relative 'test_helper'

class PotatoTest < Minitest::Test
  include PotatoTestHelper

  def test_basic_arithmetic
    output = run_potato(<<~POTATO)
      result is 10 potato 20
      say result
    POTATO
    
    assert_equal "30\n", output
  end

  def test_string_concatenation
    output = run_potato(<<~POTATO)
      greeting is "Hello" potato " " potato "World"
      say greeting
    POTATO
    
    assert_equal "Hello World\n", output
  end

  def test_boolean_equality_true
    output = run_potato(<<~POTATO)
      result is :) equals? :)
      say result
    POTATO
    
    assert_equal "true\n", output
  end

  def test_boolean_equality_false
    output = run_potato(<<~POTATO)
      result is :) equals? :(
      say result
    POTATO
    
    assert_equal "false\n", output
  end

  def test_equality
    output = run_potato(<<~POTATO)
      result is 2 potato 2 equals? 4 potato 10
      say result
    POTATO
    
    assert_equal "false\n", output
  end

  def test_greater_equals
    output = run_potato(<<~POTATO)
      say 2 atleast? 2 
      say 4 atleast? 2 
      say 1 atleast? 2 
    POTATO
    
    assert_equal "true\ntrue\nfalse\n", output
  end

  def test_greater_than
    output = run_potato(<<~POTATO)
      say 2 greater? 2
      say 4 greater? 2
      say 1 greater? 2
    POTATO
    
    assert_equal "false\ntrue\nfalse\n", output
  end

  def test_greater_than
    output = run_potato(<<~POTATO)
      say 2 greater? 2
      say 4 greater? 2
      say 1 greater? 2
    POTATO
    
    assert_equal "false\ntrue\nfalse\n", output
  end

  def test_or
    output = run_potato(<<~POTATO)
      say :) or :(
      say :) or :)
      say :( or :(
    POTATO
    
    assert_equal "true\ntrue\nfalse\n", output
  end

  def test_and
    output = run_potato(<<~POTATO)
      say :) and :(
      say :) and :)
      say :( and :(
    POTATO
    
    assert_equal "false\ntrue\nfalse\n", output
  end

  def test_function_call
    output = run_potato(<<~POTATO)
      greet (name) say name
      greet ("Potato")
    POTATO
    
    assert_equal "Potato\n", output
  end

  def test_function_with_multiple_params
    output = run_potato(<<~POTATO)
      add (a, b) say a potato b
      add (10, 20)
    POTATO
    
    assert_equal "30\n", output
  end

  def test_add_equals_operator
    output = run_potato(<<~POTATO)
      x is 5
      x gains 10
      say x
    POTATO
    
    assert_equal "15\n", output
  end

  def test_add_operator
    output = run_potato(<<~POTATO)
      x is 5
      x is x potato 10 potato 10
      say x

      say 10 potato 10 equals? 20
    POTATO
    
    assert_equal "25\ntrue\n", output
  end

  def test_multiple_statements
    output = run_potato(<<~POTATO)
      say "first"
      say "second"
      say "third"
    POTATO
    
    assert_equal "first\nsecond\nthird\n", output
  end

  def test_variable_reassignment
    output = run_potato(<<~POTATO)
      x is 10
      x is 20
      say x
    POTATO
    
    assert_equal "20\n", output
  end

  def test_complex_arithmetic
    output = run_potato(<<~POTATO)
      result is 1 potato 2 potato 3 potato 4
      say result
    POTATO
    
    assert_equal "10\n", output
  end

  def test_function_param_order
    output = run_potato(<<~POTATO)
      func_name (scope, bool, num) say scope, say bool, say num
      func_name ("local", :), 2)
    POTATO

    assert_equal "local\ntrue\n2\n", output
  end

  def test_function_using_globals
    output = run_potato(<<~POTATO)
      a_var is 10
      func_name (scope, bool, num) what_scope is scope, say what_scope, say a_var
      func_name ("local", :), 2)
    POTATO

    assert_equal "local\n10\n", output
  end

  def test_complex_function_call
    output = run_potato(<<~POTATO)
      a_var is 10
      func_name (scope, other_num) s is scope, say s, num is 4, say a_var, say num, say other_num
      func_name ("local", 2)
    POTATO

    assert_equal "local\n10\n4\n2\n", output
  end

  def test_function_call_return
    output = run_potato(<<~POTATO)
      wow (msg) msg
      say wow ("a")
    POTATO

    assert_equal "a\n", output
  end

  def test_function_call_return_nested
    output = run_potato(<<~POTATO)
      wow (msg) msg
      say wow( wow ("hello"))
    POTATO

    assert_equal "hello\n", output
  end

  def test_recursive_function_calls
    output = run_potato(<<~POTATO)
      add (num) num gains 2, num equals? 4 ? add(num) : num
      say add(2)
    POTATO

    assert_equal "6\n", output
  end

  def test_if_statement
    output = run_potato(<<~POTATO)
      x is :) ? "true"
      say x

      y is :( ? "true"
      say y
    POTATO

    assert_equal "true\nnil\n", output
  end

  def test_if_else_statement
    output = run_potato(<<~POTATO)
      say :) ? "true" : "false"
    POTATO

    assert_equal "true\n", output
  end

  def test_elseif_statement
    output = run_potato(<<~POTATO)
      say "a" equals? "a" ? "a" : "a" equals? "c" ? "nope" : "nope"
      say "a" equals? "b" ? "nope" : "a" equals? "a" ? "a" : "nope"
      say "a" equals? "b" ? "nope" : "a" equals? "c" ? "nope" : "a"
      say "a" equals? "b" ? "nope" : "a" equals? "c" ? "nope"
    POTATO

    assert_equal "a\na\na\nnil\n", output
  end
end
