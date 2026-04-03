### 🥔 Potato

A made up [bytecode interpreter](https://notes.juliab.dev/thoughts/fancier-potato) that started out as a made up [tree-walking interpreter](https://notes.juliab.dev/thoughts/potato)! (I wrote about it for CS 2130 & 3110) 

Potato knows how to:

- add
- ... and that's about it

![./assets/potato.png](./assets/potato.png)
![./assets/output.png](./assets/output.png)


#### types

- integers: `2`, `20000000000`
- strings: `"wow!"`, `"a string!"`
- booleans: `:)`, `:(`

#### comments

```
🍠 this is a comment
say "hello" 🍠 this is an inline comment
```

#### functions

`()` connect function names to their body. Statements can be separated by commas. The last value is returned

```potato
double (n) n potato n
say double (5)
say double (double (3)) 

frog (a, b) say a, say b
frog ("ribbet", "is that a fly?") 
```

#### `is`

Assigns a value

```potato
dog is "cute!"
say dog 
```

####  `potato` 

Adds numbers and concatenates strings

```potato
2 potato 2  
"hi" potato " bob" 
```

####  `equals?`

`:)` if both are equal, otherwise `:(` 

```potato
:) equals? :)    🍠 true
:) equals? :(    🍠 false
10 equals? 10    🍠 true
"a" equals? "b"  🍠 false
10 equals? "10"  🍠 false
```

####  `greater?`, `atleast?`

- `:)` if greater
- `:)` if greater or equal 

```potato
10 greater? 10   🍠 false
10 atleast? 10   🍠 true
``` 

####  `and`, `or`

- `:)` if both are true
- `:)` if either is true

```potato
:) and :)    🍠 true
:) and :(    🍠 false
:) or :(     🍠 true
:( or :(     🍠 false
```

####  `?`, `:`, and `nothing`

- `?` if
- `:` else, it can chain 
- `nothing` means nothings there (its falsey)

```potato
a is :) ? "true"
say a 🍠 "true"

b is :( ? "true" : "false"
say b 🍠 "false"

c is :( ? "true"
say c 🍠 nil

d is :) ? nothing
say d 🍠 nil
```

✨ aspirations ✨

unfortunately i've learned about self-hosting
 - fix recursion
 - more comparison
 - conditionals + loops
 - actual string helpers
 - heap
 - maybe? real stack

machine code
