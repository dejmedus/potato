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

  def test_function_call_return
    output = run_potato(<<~POTATO)
      wow (msg) msg
      say wow( wow ("hello"))
    POTATO

    assert_equal "hello\n", output
  end
end
