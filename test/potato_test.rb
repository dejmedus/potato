require_relative 'test_helper'

class PotatoTest < Minitest::Test
  include PotatoTestHelper

  def test_basic_arithmetic
    assert_equal "30\n", run_potato(<<~POTATO)
      result is 10 potato 20
      say result
    POTATO
  end

  def test_string_concatenation
    assert_equal "Hello World\n", run_potato(<<~POTATO)
      greeting is "Hello" potato " " potato "World"
      say greeting
    POTATO
  end

  def test_boolean_equality_true
    assert_equal "true\n", run_potato(<<~POTATO)
      result is :) is? :)
      say result
    POTATO
  end

  def test_boolean_equality_false
    assert_equal "false\n", run_potato(<<~POTATO)
      result is :) is? :(
      say result
    POTATO
  end

  def test_equality
    assert_equal "false\n", run_potato(<<~POTATO)
      result is 2 potato 2 is? 4 potato 10
      say result
    POTATO
  end

  def test_not_equality
    assert_equal "true\n", run_potato(<<~POTATO)
      result is 2 not? 4 potato 10
      say result
    POTATO
  end

  def test_greater_equals
    assert_equal "true\ntrue\nfalse\n", run_potato(<<~POTATO)
      say 2 atleast? 2 
      say 4 atleast? 2 
      say 1 atleast? 2 
    POTATO
  end

  def test_lesser_equals
    assert_equal "true\nfalse\ntrue\n", run_potato(<<~POTATO)
      say 2 atmost? 2 
      say 4 atmost? 2 
      say 1 atmost? 2 
    POTATO
  end

  def test_greater_than
    assert_equal "false\ntrue\nfalse\n", run_potato(<<~POTATO)
      say 2 bigger? 2
      say 4 bigger? 2
      say 1 bigger? 2
    POTATO
  end

  def test_lesser_than
    assert_equal "false\nfalse\ntrue\n", run_potato(<<~POTATO)
      say 2 smaller? 2
      say 4 smaller? 2
      say 1 smaller? 2
    POTATO
  end

  def test_or
    assert_equal "true\ntrue\nfalse\n", run_potato(<<~POTATO)
      say :) or :(
      say :) or :)
      say :( or :(
    POTATO
  end

  def test_and
    assert_equal "false\ntrue\nfalse\n", run_potato(<<~POTATO)
      say :) and :(
      say :) and :)
      say :( and :(
    POTATO
  end

  def test_function_call
    assert_equal "Potato\n", run_potato(<<~POTATO)
      greet (name) say name
      greet ("Potato")
    POTATO
  end

  def test_function_with_multiple_params
    assert_equal "30\n", run_potato(<<~POTATO)
      add (a, b) say a potato b
      add (10, 20)
    POTATO
  end

  def test_add_equals_operator
    assert_equal "15\n", run_potato(<<~POTATO)
      x is 5
      x gains 10
      say x
    POTATO
  end

  def test_add_operator
    assert_equal "25\ntrue\n", run_potato(<<~POTATO)
      x is 5
      x is x potato 10 potato 10
      say x

      say 10 potato 10 is? 20
    POTATO
  end

  def test_multiple_statements
    assert_equal "first\nsecond\nthird\n", run_potato(<<~POTATO)
      say "first"
      say "second"
      say "third"
    POTATO
  end

  def test_variable_reassignment
    assert_equal "20\n", run_potato(<<~POTATO)
      x is 10
      x is 20
      say x
    POTATO
  end

  def test_complex_arithmetic
    assert_equal "10\n", run_potato(<<~POTATO)
      result is 1 potato 2 potato 3 potato 4
      say result
    POTATO
  end

  def test_function_param_order
    assert_equal "local\ntrue\n2\n", run_potato(<<~POTATO)
      func_name (scope, bool, num) say scope, say bool, say num
      func_name ("local", :), 2)
    POTATO
  end

  def test_function_using_globals
    assert_equal "local\n10\n", run_potato(<<~POTATO)
      a_var is 10
      func_name (scope, bool, num) what_scope is scope, say what_scope, say a_var
      func_name ("local", :), 2)
    POTATO
  end

  def test_complex_function_call
    assert_equal "local\n10\n4\n2\n", run_potato(<<~POTATO)
      a_var is 10
      func_name (scope, other_num) s is scope, say s, num is 4, say a_var, say num, say other_num
      func_name ("local", 2)
    POTATO
  end

  def test_function_call_return
    assert_equal "a\n", run_potato(<<~POTATO)
      wow (msg) msg
      say wow ("a")
    POTATO
  end

  def test_function_call_return_nested
    assert_equal "hello\n", run_potato(<<~POTATO)
      wow (msg) msg
      say wow( wow ("hello"))
    POTATO
  end

  def test_recursive_function_calls
    assert_equal "6\n", run_potato(<<~POTATO)
      add (num) num gains 2, num is? 4 ? add(num) : num
      say add(2)
    POTATO
  end

  def test_if_statement
    assert_equal "true\nnone\n", run_potato(<<~POTATO)
      x is :) ? "true"
      say x

      y is :( ? "true"
      say y
    POTATO
  end

  def test_if_else_statement
    assert_equal "true\n", run_potato(<<~POTATO)
      say :) ? "true" : "false"
    POTATO
  end

  def test_elseif_statement
    assert_equal "a\na\na\nnone\n", run_potato(<<~POTATO)
      say "a" is? "a" ? "a" : "a" is? "c" ? "nope" : "nope"
      say "a" is? "b" ? "nope" : "a" is? "a" ? "a" : "nope"
      say "a" is? "b" ? "nope" : "a" is? "c" ? "nope" : "a"
      say "a" is? "b" ? "nope" : "a" is? "c" ? "nope"
    POTATO
  end

  def test_static_undefined_function_call
    output = run_potato(<<~POTATO)
      add2 (a, b) a potato b
      say add3 (2, 2)
    POTATO

    assert_includes output, "main.potato:2: error: Is this defined?: add3"
  end

  def test_static_non_function_call
    output = run_potato(<<~POTATO)
      x is 2
      say x()
    POTATO

    assert_includes output, "main.potato:2: error: Should be a function: x"
  end
end
