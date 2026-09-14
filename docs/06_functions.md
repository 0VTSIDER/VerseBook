# Functions

A function takes zero or more arguments and produces a result. You
define the behaviour once and call it wherever it is needed; callers
do not depend on how it is implemented.

Verse function signatures carry effects as well as types, so a
declaration states what a function may do as well as what it takes and
returns. Functions are also values: they can be stored in variables,
passed as arguments, and returned from other functions.

## Parameters

Functions can accept any number of parameters, from none at all to as
many as needed. The syntax follows a straightforward pattern where
each parameter has an identifier and a type, separated by commas:

<!--versetest-->
<!-- 01 -->
```verse
ProcessData(Name:string, Age:int, Score:float):string =
    "{Name} is {Age} years old with a score of {Score}"
```

For functions with many parameters or optional configuration, Verse
supports named and default parameters.

### Named Parameters

Named parameters with defaults make functions more flexible and
ergonomic. They allow you to:

- Specify arguments by name rather than position
- Provide default values for optional parameters
- Call functions with only the arguments you need
- Add new optional parameters without breaking existing code

Named parameters are declared with a `?` prefix and called with the
name and a `:=` followed by a value:

<!--versetest-->
<!-- 02 -->
```verse
# A function with named parameters
Greet(?Name:string, ?Greeting:string):string = "{Greeting} {Name}!"

# A call with named arguments
Greet(?Name := "Alice", ?Greeting := "Hello") = "Hello Alice!"
```

Named parameters with default values are truly optional:

<!--versetest-->
<!-- 03 -->
```verse
# Named parameters with defaults
Log(Message:string, ?Level:int=1, ?Color:string="white"):string =
    "[Level {Level}] {Message} ({Color})"

# Call with all defaults
Log("Starting") = "[Level 1] Starting (white)"

# Call with some arguments
Log("Warning", ?Level := 2) = "[Level 2] Warning (white)"

# Call with arguments in any order
Log("Error", ?Color := "red", ?Level := 3) = "[Level 3] Error (red)"
```

After the first named parameter, all subsequent parameters must also be named:

<!--versetest
assert_semantic_error(3629):
    Invalid(?Named:int, Positional:string):void = {}
<#
-->
<!-- 04 -->
```verse
# Invalid: named followed by positional
Invalid(?Named:int, Positional:string):void = {}  # ERROR
```
<!-- #>-->

When calling functions with named parameters, you must use the
`?Name:=Value` syntax. All parameters without default must be specified.
Positional arguments come first:

<!--versetest
assert_semantic_error(3629, 3509):
    Cfg7(Required:int, ?Option1:string, ?Option2:logic):void = { }
    G7():void =
        Cfg7(?Option1 := "test", 42, ?Option2 := true)
-->
<!-- 05 -->
```verse
Configure(Required:int, ?Option1:string, ?Option2:logic):void = {}

# Valid
Configure(42, ?Option1 := "test", ?Option2 := true)

# Invalid: named arg before positional
# Configure(?Option1 := "test", 42, ?Option2 := true)  # ERROR
```

Verse evaluates default values in the function's defining scope; they
can reference:

  - Module-level definitions
  - Class or interface members
  - Earlier parameters

<!--versetest-->
<!-- 06 -->
```verse
ModuleTimeout:int = 30

# Access module-level definition
Connect(?Timeout:int = ModuleTimeout)<computes>:int = Timeout

# Access member definition
game_config := class:
    DefaultLives:int = 3

    StartGame(?Lives:int = DefaultLives)<computes>:int = Lives

# Access earlier parameter
CreateRange(?Start:int = 0, ?End:int = Start + 10)<computes>:[]int =
    array{Start, End}

Connect() = 30
game_config{}.StartGame() = 3
CreateRange(?Start := 5) = array{5, 15}
```

Default values work with overridden members in class hierarchies:

<!--versetest-->
<!-- 07 -->
```verse
base_game := class:
    DefaultSpeed:float = 1.0

    # The default is read from the current instance
    CurrentSpeed(?Speed:float = DefaultSpeed)<computes>:float = Speed

fast_game := class(base_game):
    DefaultSpeed<override>:float = 2.0

base_game{}.CurrentSpeed() = 1.0
fast_game{}.CurrentSpeed() = 2.0   # The overridden value
```

Named and default parameters interact with the type system.  A
function with default parameters is a subtype of the same function
without those parameters:

<!--versetest-->
<!-- 08 -->
```verse
Process(?Required:int, ?Optional:int = 0):int = Required + Optional

# Can assign to type without optional parameter
F1:type{_(?Required:int):int} = Process
F1(?Required := 5) = 5                          # Uses the default

# Can assign to type with optional parameter
F2:type{_(?Required:int, ?Optional:int):int} = Process
F2(?Required := 5, ?Optional := 3) = 8

# Can even assign to type with no parameters (all have defaults)
DefaultAll(?A:int = 1, ?B:int = 2):int = A + B
F3:type{_():int} = DefaultAll
F3() = 3
```

Function types preserve named parameter names:

<!--versetest
assert_semantic_error(3509):
    Calc15(?Amount:float, ?Rate:float):float = Amount * Rate
    F15:type{_(?Value:float, ?Factor:float):float} = Calc15
-->
<!-- 09 -->
```verse
Calculate(?Amount:float, ?Rate:float):float = Amount * Rate

# Valid: names match
F1:type{_(?Amount:float, ?Rate:float):float} = Calculate

# Invalid: different names
# F2:type{_(?Value:float, ?Factor:float):float} = Calculate  # ERROR
```

Function types do not include default values:

<!--versetest-->
<!-- 10 -->
```verse
F1(?X:int=1):int = X

F2:type{_(?X:int=99):int} = F1    # F1 and F2 are of the same type
```

Named parameters participate in function overload resolution:

<!--versetest-->
<!-- 11 -->
```verse
Process(Value:int):string = "One parameter"
Process(Value:int, ?Option:string):string = "Two parameters"
Process(Value:int, ?Option1:string, ?Option2:logic):string = "Three parameters"

Process(42) = "One parameter"
Process(42, ?Option := "test") = "Two parameters"
Process(42, ?Option1 := "test", ?Option2 := true) = "Three parameters"
```

The compiler selects the overload that matches the provided
arguments. Named parameters make overload resolution more precise
since names must match exactly.

Named parameters have specific rules for *overload distinctness* that
differ from positional parameters. Two function signatures are
indistinct, and so cannot overload, if they could be called with the
same arguments.

Named parameters are matched by name, not position, so reordering does
not create distinctness. Neither does the presence or absence of
default values, if the parameter names are the same. More generally, if
one signature can handle all the calls that another can — as happens
when all parameters of both have defaults, since both can then be
called with no arguments — the two are indistinct:

<!--versetest
assert_semantic_error(3532, 3532, 3532):
    A(?Y:int, ?X:int):int = X + Y
    A(?X:int, ?Y:int):int = X - Y
    B(?X:int = 42):int = X
    B(?X:int):int = X
    C(?X:int = 1, ?Y:int = 2):int = X + Y
    C(?X:int):int = X
<#
-->
<!-- 12 -->
```verse
# Same parameters, different order
A(?Y:int, ?X:int):int = X + Y
A(?X:int, ?Y:int):int = X - Y   # ERROR

# Same parameter name, with and without a default
B(?X:int = 42):int = X
B(?X:int):int = X               # ERROR

# The first accepts every call the second does, including C(?X := 1)
C(?X:int = 1, ?Y:int = 2):int = X + Y
C(?X:int):int = X               # ERROR
```
<!-- #>-->

Distinctness comes from the calls a signature can accept. Functions
with different named parameter names can overload. A named parameter is
distinct from a positional parameter, even with the same name and
type. If the set of required (no default) named parameters differs, the
overloads are distinct. And different positional parameter types make
signatures distinct, even if the named parameters are the same:

<!--versetest-->
<!-- 13 -->
```verse
# Different names
F(?X:int):int = X
F(?Y:int):int = Y

# A named parameter versus a positional one
G(?X:int):int = X
G(X:int):int = X

# Different sets of required parameters
H(?Y:int, ?X:int = 42):int = X
H(?X:int):int = X

# Different positional types
K(Arg:float, ?X:int):int = X
K(Arg:int, ?X:int):int = X
```

### Tuple as Arguments

Tuples can be used to provide positional arguments. However, you
cannot mix a pre-constructed tuple variable with additional named
arguments:

<!--versetest
assert_semantic_error(3509):
    Calc28(A:int, B:int, ?C:int = 0):int = A + B + C
    Args28:tuple(int, int) = (1, 2)
    G28():void =
        Calc28(Args28, ?C := 5)
-->
<!-- 14 -->
```verse
Calculate(A:int, B:int, ?C:int = 0):int = A + B + C

# Valid: tuple provides positional arguments
Args:tuple(int, int) = (1, 2)
Calculate(Args) = 3

# Valid: all arguments provided directly
Calculate(1, 2, ?C := 5) = 8

# Invalid: cannot mix tuple variable with named arguments
# Calculate(Args, ?C := 5)  # ERROR
```

Functions can destructure tuple parameters directly in the parameter
list, allowing you to extract tuple elements inline without manual
indexing:

<!--versetest-->
<!-- 15 -->
```verse
# Destructure tuple parameter in place
Func(A:int, (B:int, C:int), D:int):int =
    A + B + C + D

Func(1, (2, 3), 4) = 10   # Direct tuple literal
X := (2, 3)
Func(1, X, 4) = 10        # Tuple variable
Y := (1, (2, 3), 4)
Func(Y) = 10              # Entire argument list as tuple
```

The parameter `(B:int, C:int)` destructures the tuple, giving direct
access to `B` and `C` instead of requiring `Tuple(0)` and `Tuple(1)`
indexing.

Tuples can be destructured to arbitrary depth:

<!--versetest-->
<!-- 16 -->
```verse
H(A:int, (B:int, (C:int, D:int)), E:int):int =
    A + B + C + D + E

H(1, (2, (3, 4)), 5) = 15
```

You can mix destructured tuple parameters with regular tuple
parameters that are not destructured:

<!--versetest-->
<!-- 17 -->
```verse
# Destructured form - access elements directly
F(A:int, (B:int, C:int), D:int):int =
    A + B + C + D

# Non-destructured form - use tuple indexing
G(A:int, T:tuple(int, int), D:int):int =
    A + T(0) + T(1) + D

# Both work identically
F(1, (2, 3), 4) = 10
G(1, (2, 3), 4) = 10
```

Choose destructured form when you need direct access to individual
elements, and non-destructured when you need to pass the tuple as a
whole to other functions.

Tuple parameters can contain named/optional parameters, allowing for
flexible APIs that combine structural decomposition with optional
values:

<!--versetest-->
<!-- 18 -->
```verse
# Named parameter inside nested tuple
SumValues(A:int, (X:int, (Y:int, ?Z:int = 0))):int =
    A + X + Y + Z

SumValues(1, (2, (3, ?Z := 4))) = 10   # Z provided explicitly
SumValues((1, (2, 3))) = 6             # Z takes its default
```

A tuple can contain multiple named parameters, and they can be
specified in any order:

<!--versetest-->
<!-- 19 -->
```verse
Scale(Base:int, (Value:int, ?Factor:int = 1, ?Offset:int = 0)):int =
    Value * Factor + Offset + Base

Scale(10, 5) = 15                                # Both defaults
Scale(10, (5, ?Factor := 2, ?Offset := 1)) = 21
Scale(10, (5, ?Offset := 1, ?Factor := 2)) = 21  # Order does not matter
```

When a tuple parameter contains **only** named parameters (no
positional parameters), you must provide an empty tuple `()` even when
using all defaults:

<!--versetest
assert_semantic_error(3509):
    Conf34(Base:int, (?Width:int = 10, ?Height:int = 20)):int = Base + Width + Height
    G34():void =
        Conf34(5)
-->
<!-- 20 -->
```verse
# Tuple with only named parameters
Configure(Base:int, (?Width:int = 10, ?Height:int = 20)):int =
    Base + Width + Height

# Must provide empty tuple when using all defaults
Configure(5, ()) = 35

# Cannot omit the tuple entirely
# Configure(5)  # ERROR - tuple parameter required
```

This is a known limitation in the current implementation. When the
tuple contains at least one positional parameter, this restriction
does not apply.

### Flattening and Unflattening

Verse provides automatic conversion between tuples and multiple
arguments at function call sites, enabling flexible calling
conventions without explicit packing or unpacking.

*Flattening:* A function expecting multiple parameters can be called
with a single tuple. In the following, the tuple `Args` is
automatically unpacked into the `Add` function's parameters:

<!--versetest-->
<!-- 21 -->
```verse
Add(X:int, Y:int):int = X + Y
Args := (3, 5)
Add(Args) = 8       # Tuple automatically flattened
```

*Unflattening:* A function expecting a single tuple parameter can be
called with flattened arguments.  The individual arguments of the call
to `F` are automatically packed into the tuple parameter:

<!--versetest-->
<!-- 22 -->
```verse
F(P:tuple(int, int)):int = P(0) + P(1)

F(3, 5) = 8  # Args automatically packed into tuple
```

The empty tuple has the same flattening behavior:

<!--versetest-->
<!-- 23 -->
```verse
F(X:tuple()):int = 42

F(()) = 42   # Explicit empty tuple
F() = 42     # No arguments - automatically creates empty tuple
```

Because of automatic flattening and unflattening, you cannot define
overloads that would be ambiguous. If you define `F(P:tuple(int, int))`, you cannot also define `F(X:int,
Y:int)` because the call `F(3, 5)` could match either signature.
Similarly, `F(P:tuple(int, int))` and `F(Xs:[]int)` are indistinct
because arrays can also be called with the same syntax.

### Evaluation Order

Verse evaluates arguments in a specific order to maintain predictable behavior:

1. *Positional arguments*: Left to right in the call
2. *Named arguments*: Left to right as encountered in the call
3. *Default values*: Filled in for omitted parameters, left to right
   in parameter order

If named arguments appear in a different order than parameters, the
compiler uses temporary variables to preserve the evaluation order you
specified:

<!--versetest-->
<!-- 24 -->
```verse
Process(A:int, ?B:int, ?C:int, ?D:int):string =
    "{A}, {B}, {C}, {D}"

# Evaluated in the order written, 1, 4, 2, 3, but passed to the
# function in parameter order
Process(1, ?D := 4, ?B := 2, ?C := 3) = "1, 2, 3, 4"
```

This ensures that side effects in argument expressions happen in the
order you write them, not in parameter order.

## Extension Methods

Extension methods allow you to add new methods to existing types
without modifying their original definitions. This powerful feature
enables you to extend any type in Verse—including built-in types like
`int`, `string`, arrays, and maps—with custom functionality while
maintaining clean separation between different concerns.

Extension methods are particularly valuable when:

- You want to add domain-specific operations to built-in types
- You need to extend types from libraries you do not control
- You're building fluent or builder-style APIs
- You want to organize related functionality separately from type definitions

Extension methods use a special syntax where the extended type appears
in parentheses before the method name:

<!--versetest-->
<!-- 25 -->
```verse
# Extend int with a custom method
(Value:int).Double()<computes>:int = Value * 2

# Call the extension method using dot notation
X := 5
X.Double() = 10

# Can also call on literals
7.Double() = 14
```

The type in parentheses can be any Verse type: primitives, tuples,
classes, interfaces, arrays, maps, or structs.

Extending primitives:

<!--versetest-->
<!-- 26 -->
```verse
(N:int).IsEven()<decides><computes>:void = Mod[N,2] = 0
(S:string).FirstChar()<decides><computes>:char = S[0]

42.IsEven[]              # Succeeds
"Hello".FirstChar[] = 'H'
```

Extending tuples:

<!--versetest-->
<!-- 27 -->
```verse
# Extend a specific tuple type (Note: Sqrt is <reads>)
(Point:tuple(int, int)).Distance()<reads>:float =
    Sqrt( (Point(0) * Point(0) + Point(1) * Point(1)) * 1.0)

(3, 4).Distance() = 5.0
```

When extending tuples, you must specify the tuple type
explicitly (e.g., `(Point:tuple(int, int))`). You cannot use
destructured parameter syntax (e.g., `(X:int, Y:int)`) for extension
method contexts.

The empty tuple `tuple()` represents the unit type and can have
extension methods:

<!--versetest-->
<!-- 28 -->
```verse
(Unit:tuple()).GetMagicNumber():int = 42

().GetMagicNumber() = 42
```

Extending arrays:

<!--versetest-->
<!-- 29 -->
```verse
(Vals:[]int).Sum()<transacts>:int =
    var Total:int = 0
    for (N:Vals):
        set Total += N
    Total

array{1, 2, 3, 4, 5}.Sum() = 15
```

Extending maps:

<!--versetest-->
<!-- 30 -->
```verse
(M:[int]string).Keys()<computes>:[]int =
    for (Key->X:M):
        Key

map{1=>"a", 2=>"b", 3=>"c"}.Keys() = array{1, 2, 3}
```

Extending classes:

<!--versetest-->
<!-- 31 -->
```verse
player := class:
    Name:string
    var Score:int

# Add method to existing class
(P:player).AddScore(Points:int)<transacts>:void =
    set P.Score += Points

Player1 := player{Name := "Alice", Score := 100}
Player1.AddScore(50)
Player1.Score = 150
```

Extension methods support all parameter features including named and
default parameters:

<!--versetest-->
<!-- 32 -->
```verse
(Text:string).Wrap(Open:string, ?Close:string = ">")<computes>:string =
    "{Open}{Text}{Close}"

"a".Wrap("<") = "<a>"                  # Close takes its default
"a".Wrap("[", ?Close := "]") = "[a]"
```

### Overloading

You can define multiple extension methods with the same name for
different types:

<!--versetest-->
<!-- 33 -->
```verse
# Overloaded Extension method for different types
(N:int).Format():string = "int:{N}"
(B:logic).Format():string = if (B?) {"logic:true"} else {"logic:false"}

42.Format() = "int:42"
true.Format() = "logic:true"
```

The compiler selects the appropriate overload based on the receiver type.

### Rules

Extension methods must be called: they cannot be referenced as
first-class values without calling them:

<!--versetest
assert_semantic_error(3506):
    (N:int).Double50():int = N * 2
    G50():void =
        F := 5.Double50
-->
<!-- 34 -->
```verse
(N:int).Double():int = N * 2

# Valid: calling the method
5.Double() = 10

# Invalid: referencing without calling
# F := 5.Double  # ERROR
```

Extension methods cannot have the same signature as methods defined
directly in classes or interfaces:

<!--versetest
assert_semantic_error(3532):
    player51 := class:
        Health():int = 100
    (P:player51).Health():int = 50
-->
<!-- 35 -->
```verse
player := class:
    Health():int = 100

# Invalid: Conflicts with class method
# (P:player).Health():int = 50  # ERROR
```

This prevents ambiguity and ensures that class methods always take precedence.

Extension methods are scoped like regular functions. They are only
visible where they are defined or imported:

<!--versetest
Utils := module:
    (S:string).Shout<public>():string = "{S}!"

using { Utils }

# Available after importing
CheckShout()<decides>:void = "Hello".Shout() = "Hello!"
<#
-->
<!-- 36 -->
```verse
Utils := module:
    (S:string).Shout<public>():string = "{S}!"

using { Utils }

# Available after importing
CheckShout()<decides>:void = "Hello".Shout() = "Hello!"
```
<!-- #>-->

Extension methods can be defined inside classes and access class
members:

<!--versetest-->
<!-- 37 -->
```verse
game_manager := class:
    Multiplier:int = 10

    (Score:int).ScaledScore()<computes>:int =
        Score * Multiplier  # Accesses class field

    ProcessScore(Value:int)<computes>:int =
        Value.ScaledScore()  # Uses extension method

game_manager{}.ProcessScore(5) = 50
```

This creates a lexical closure where the extension method can
reference the enclosing class's members.

When an extension method has multiple parameters, you can pass a tuple
to provide all arguments at once:

<!--versetest-->
<!-- 38 -->
```verse
point := class<computes>{ X:int; Y:int }

(P:point).Translate(DX:int, DY:int)<allocates>:point =
    point{X := P.X + DX, Y := P.Y + DY}

Origin := point{X := 0, Y := 0}
Delta := (5, 10)
NewPoint := Origin.Translate(Delta)  # Tuple expands to two arguments
NewPoint.Y = 10
```

This works when the tuple type matches the parameter list.

## Lambdas

Lambda expressions with the `=>` operator are not supported in the
current version of Verse. For creating function values and closures,
use nested functions instead.

Functions are first-class values; they can be stored in variables,
passed as parameters, and returned from other functions. This enables
powerful functional programming patterns including higher-order
functions, callbacks, and composable operations. Currently, these
capabilities are provided through nested functions rather than lambda
expressions.

### Types, Variance and Effects

Function types follow specific subtyping rules based on *variance*:

- *Parameters are contravariant*: A function accepting more general
  types can substitute for one accepting specific types.

- *Returns are covariant*: A function returning more specific types
  can substitute for one returning general types.


Consider the following three classes, and some use cases:

<!--versetest
assert_semantic_error(3509, 3509):
    an64 := class:
        Name:string
    dg64 := class(an64):
        Breed:string
    wd64 := class(dg64):
        Work:string
    A2D64(X:an64)<transacts>:dg64 = dg64{Name := X.Name, Breed := "Unknown"}
    D2A64(X:dg64)<transacts>:an64 = X
    W2D64(X:wd64)<transacts>:dg64 = X
    G64()<transacts>:void =
        var P:type{_(:an64)<transacts>:dg64} = A2D64
        set P = D2A64
        set P = W2D64
-->
<!-- 39 -->
```verse
animal := class:
    Name:string

dog := class(animal):
    Breed:string

working_dog := class(dog):
    Work:string

# Some functions on animals
AnimalToDog(X:animal)<transacts>:dog = dog{Name := X.Name, Breed := "Unknown"}
DogToWorkingDog(X:dog)<transacts>:working_dog =
    working_dog{Name := X.Name, Breed := "Unknown", Work := "Guard"}
DogToAnimal(X:dog)<transacts>:animal = X
WorkingDogToDog(X:working_dog)<transacts>:dog = X

var ProcessDog:type{_(:dog)<transacts>:dog} = AnimalToDog

# Valid: Accepts more general (animal), returns exact (dog)
# Contravariant parameter: animal <: dog allows this
set ProcessDog = AnimalToDog  # OK: tuple(animal)->dog <: tuple(dog)->dog

# Valid: Accepts exact (dog), returns more specific (working_dog)
# Covariant return: working_dog <: dog allows this
set ProcessDog = DogToWorkingDog  # OK: tuple(dog)->working_dog <: tuple(dog)->dog

var ProcessAnimal:type{_(:animal)<transacts>:dog} = AnimalToDog
# set ProcessAnimal = DogToAnimal      # ERROR: returns animal, not dog
# set ProcessAnimal = WorkingDogToDog  # ERROR: animal is not a working_dog
```

Effects are part of the function type. A function with fewer effects
can be used where a function with more effects is expected - effects
are **covariant** (fewer effects = subtype):

<!--versetest
assert_semantic_error(3509):
    Pure65()<computes>:int = 42
    Trans65()<transacts>:int = 42
    UsePure65(F()<computes>:int):int = F()
    G65():void =
        UsePure65(Trans65)
-->
<!-- 40 -->
```verse
Pure()<computes>:int = 42
Transactional()<transacts>:int = 42

UsePure(F()<computes>:int)<computes>:int = F()
UseTransactional(F()<transacts>:int)<transacts>:int = F()

UseTransactional(Transactional) = 42

# Covariance: fewer effects can substitute for more effects
UseTransactional(Pure) = 42      # OK: ()<computes>:int <: ()<transacts>:int

# Invalid: more effects cannot substitute for fewer
# UsePure(Transactional)         # ERROR: ()<transacts>:int </: ()<computes>:int
```
A `<computes>` function can be passed where `<transacts>` is expected
because fewer effects means the function is more constrained.

When you assign different functions conditionally, Verse finds the
least upper bound (join) of their types:

<!--versetest-->
<!-- 41 -->
```verse
base := class:
    Value:int

derived := class(base):
    Extra:string

F1()<transacts>:base = base{Value := 1}
F2()<transacts>:derived = derived{Value := 2, Extra := "test"}

# Join: ()->base (common supertype)
G := if (true?) {F1} else {F2}
G().Value = 1  # Can access base members
```


### Using `type{}`

The `type{_(...):...}` syntax declares function types with full
detail. This is the mechanism for creating function type signatures
that include parameter types, return types, and effects. Underscore
`_` is a placeholder for the function name, emphasizing that it
describes a signature, not a specific function:

<!--versetest-->
<!-- 42 -->
```verse
# Function type variable
var Handler:?type{_(:string, :int)<decides>:void} = false

# Nested function matching the signature
MakeHandler(Name:string, Count:int)<decides>:void =
    Print("{Name}: {Count}")
    Count > 0  # Decides effect

set Handler = option{MakeHandler}

# Function accepting function parameter
Process(F:type{_(:int):int}, Value:int):int =
    F(Value)

# Nested function to pass
Double(X:int):int = X * 2
Process(Double, 5) = 10
```

The `type{}` construct *declares function type signatures*:

<!--versetest-->
<!-- 43 -->
```verse
# Type definitions for function signatures
ValidType1 := type{_():int}
ValidType2 := type{_(:string, :int):float}
ValidType3 := type{_()<transacts><decides>:void}
```

Within `type{}`, function declarations must have return types but
*cannot have bodies*.

Function types work as field types in classes:

<!--versetest-->
<!-- 44 -->
```verse
calculator := class:
    Operation:type{_(:int,:int):int}

Add(X:int, Y:int):int = X + Y
Multiply(X:int, Y:int):int = X * Y

# Create instances with different operations
Adder := calculator{Operation := Add}
Multiplier := calculator{Operation := Multiply}

Adder.Operation(5, 3) = 8
Multiplier.Operation(5, 3) = 15
```

Function types can be used for local variables, enabling conditional
function selection:

<!--versetest-->
<!-- 45 -->
```verse
ProcessA():int = 10
ProcessB():int = 20

SelectFunction(UseA:logic):int =
    # Choose function based on condition
    Fn:type{_():int} =
        if (UseA?):
            ProcessA
        else:
            ProcessB
    Fn()

SelectFunction(true) = 10
SelectFunction(false) = 20
```

Combine `type{}` with `?` to create optional function types:

<!--versetest-->
<!-- 46 -->
```verse
DefaultHandler()<computes>:int = -1
CustomHandler()<computes>:int = 42

Process(Handler:?type{_()<computes>:int})<computes><decides>:int =
    # Use handler if provided, otherwise use default
    Handler?() or DefaultHandler()

Process[false] = -1                   # No handler
Process[option{CustomHandler}] = 42   # Custom handler
```

Create arrays of functions sharing the same signature:

<!--versetest-->
<!-- 47 -->
```verse
GetZero():int = 0
GetOne():int = 1
GetTwo():int = 2

SumFunctions(Functions:[]type{_():int}):int =
    var Result:int = 0
    for (Fn : Functions):
        set Result += Fn()
    Result

SumFunctions(array{GetZero, GetOne, GetTwo}) = 3
```

### Examples

Map, filter and reduce are generic over both the element type and the
function passed in:

<!--versetest-->
<!-- 48 -->
```verse
# Generic map
Map(Items:[]t, F(:t)<transacts>:u where t:type, u:type)<transacts>:[]u =
    for (Item:Items):
        F(Item)

# Generic filter
Filter(Items:[]t, Pred(:t)<computes><decides>:void where t:type)<computes>:[]t =
    for (Item:Items, Pred[Item]):
        Item

# Generic fold/reduce
Fold(Items:[]t, Initial:u, F(:u, :t)<transacts>:u where t:type, u:type)<transacts>:u =
    var Acc:u = Initial
    for (Item:Items):
        set Acc = F(Acc, Item)
    Acc

Values := array{1, 2, 3, 4, 5}

# Nested functions supply the operations
Square(X:int)<computes>:int = X * X
IsOdd(X:int)<computes><decides>:void = Mod[X, 2] = 1
AddTo(Acc:int, X:int)<computes>:int = Acc + X

Map(Values, Square) = array{1, 4, 9, 16, 25}
Filter(Values, IsOdd) = array{1, 3, 5}
Fold(Values, 0, AddTo) = 15
```

Composition takes two functions and returns their composite:

<!--versetest-->
<!-- 49 -->
```verse
Compose(F(:b):c, G(:a):b where a:type, b:type, c:type):type{_(:a):c} =
    # Return a nested function that composes F and G
    Composed(X:a):c = F(G(X))
    Composed

Add1(X:int):int = X + 1
Double(X:int):int = X * 2

# Compose: first doubles, then adds 1
DoubleThenIncrement := Compose(Add1, Double)
DoubleThenIncrement(5) = 11  # 5*2 + 1
```

Partial application captures the first argument and returns a function
awaiting the rest:

<!--versetest-->
<!-- 50 -->
```verse
Partial(F(:a, :b):c, X:a where a:type, b:type, c:type):type{_(:b):c} =
    # Return a nested function with X captured
    PartialFunc(Y:b):c = F(X, Y)
    PartialFunc

Add(X:int, Y:int):int = X + Y
Add5 := Partial(Add, 5)
Add5(3) = 8
```

## Nested Functions

!!! warning "Unreleased Feature"
    Nested functions have not yet been released. This section documents planned functionality that is not currently available.

Nested functions (also called local functions) are functions defined
inside other functions. They provide encapsulation, enable closures
over local variables, and help organize complex logic within a
function's scope. Nested functions have names, can be recursive, and
are the primary way to create function values and closures in Verse.

A nested function is declared just like a top-level function, but
inside another function's body:

<!--versetest-->
<!-- 51 -->
```verse
Outer(X:int):int =
    # Nested function definition
    Inner(Y:int):int = Y * 2

    # Call nested function
    Inner(X)

Outer(5) = 10
```

Nested functions are only visible within their enclosing function's
scope. They cannot be accessed from outside.

Nested functions capture (close over) variables from any enclosing
scope, creating powerful closures:

<!--versetest-->
<!-- 52 -->
```verse
MakeGreeter(Name:string):type{_():string} =
    # Greeting captures Name from outer scope
    Greeting():string = "Hello, {Name}!"

    # Return the nested function
    Greeting

SayHello := MakeGreeter("Alice")
SayHello() = "Hello, Alice!"

SayHi := MakeGreeter("Bob")
SayHi() = "Hello, Bob!"
```

Each call to `MakeGreeter` creates a new closure with its own captured
`Name` value.

Nested functions support overloading by parameter types:

<!--versetest-->
<!-- 53 -->
```verse
Process(X:int):string =
    # Overloaded nested functions
    Format(Value:int):string = "int: {Value}"
    Format(Value:string):string = "string: {Value}"

    # Calls appropriate overload
    "{Format(42)}, {Format("x")}"

Process(1) = "int: 42, string: x"
```

Overload resolution works the same as for top-level functions.

### Closures with State

Nested functions can capture `var` variables and mutate them, creating stateful closures:

<!--versetest-->
<!-- 54 -->
```verse
MakeCounter(Initial:int):tuple(type{_():int}, type{_():void}) =
    var Count:int = Initial

    # Getter captures Count
    GetCount():int = Count

    # Incrementer mutates captured Count
    Increment():void = set Count = Count + 1

    (GetCount, Increment)

Counter := MakeCounter(0)
GetValue := Counter(0)
IncrementValue := Counter(1)

GetValue() = 0
IncrementValue()
GetValue() = 1
```

This pattern creates a closure that maintains private mutable state.

### Restrictions

Nested functions have several important restrictions that distinguish
them from top-level functions:

- Nested functions **cannot** have access specifiers like `<public>`,
  `<internal>`, or `<private>`:
- Nested functions are always private to their enclosing function.
- You cannot define classes inside functions (nested or otherwise):

<!--versetest
assert_semantic_error(3502):
    F55():void =
        my_class55 := class {}
-->
<!-- 55 -->
```verse
# ERROR: Cannot define classes in local scope
# F():void =
#     my_class := class {}

# Correct: Define classes at module level
my_class := class {}

F()<transacts>:my_class = my_class{}  # OK - can use class
```

- Nested functions cannot reference variables or other nested
  functions defined later in the same scope (this also means mutually
  recursive nested functions are not allowed):

<!--versetest
assert_semantic_error(3506):
    F56():void =
        X := G56()
        G56():int = 42
-->
<!-- 56 -->
```verse
# ERROR: G used before defined
# F():void =
#     X := G()     # ERROR: G not yet defined
#     G():int = 42

# Correct: Define before use
F():int =
    G():int = 42
    G()          # OK: G is defined
```

- The `(super:)` syntax for calling parent class methods **cannot** be used in nested functions:

<!--versetest
assert_semantic_error(3612):
    base57 := class:
        F(X:int):int = X

    derived57 := class(base57):
        F<override>(X:int):int =
            G():int =
                (super:)F(X)
            G()
-->
<!-- 57 -->
```verse
base_class := class:
    F(X:int):int = X

# ERROR: super not allowed in a nested function
# derived_class := class(base_class):
#     F<override>(X:int):int =
#         G():int =
#             (super:)F(X)
#         G()

# Correct: Use super directly in the overriding method
derived_class := class(base_class):
    F<override>(X:int):int =
        BaseResult := (super:)F(X)  # OK
        G():int = BaseResult * 2
        G()

derived_class{}.F(5) = 10
```

## Parametric Functions

Parametric functions (also called generic functions) allow you to
write code that works with multiple types while maintaining complete
type safety. Rather than writing separate functions for each type, you
define a single function with type parameters that adapt to whatever
types you use them with.

A parametric function declares type parameters using a `where` clause
that specifies constraints on those types:

<!--versetest-->
<!-- 58 -->
```verse
# Simple identity function - works with any type
Identity(X:t where t:type):t = X
# Usage - type parameter inferred automatically
Identity(42) = 42            # t inferred as int
Identity("hello") = "hello"  # t inferred as string
```

The `where t:type` clause declares `t` as a type parameter with the constraint `type`,
meaning it can be any Verse type.
The function signature `(X:t):t` means "takes a value of type `t` and returns a value of that same type `t`."

The generic type parameter `t` captures the complete type information, not just the top-level type. This means containers passed to generic functions preserve their internal structure:

<!--versetest-->
<!-- 59 -->
```verse
# The Identity function preserves exact container types
Identity(X:t where t:type):t = X

# Maps maintain their key and value types
IntToString:[int]string = map{1 => "one"}
Result1:[int]string = Identity(IntToString)

# Arrays maintain element types
IntArray:[]int = array{1, 2, 3}
Result2:[]int = Identity(IntArray)

# Even nested containers preserve structure
NestedMap:[int][]string = map{1 => array{"a", "b"}}
Result3:[int][]string = Identity(NestedMap)
```

This is fundamentally different from using `any`, which would erase type information.

<!--NoCompile-->
<!-- 60 -->
```verse
FunctionName(Parameters where TypeParameter:Constraint, ...):ReturnType = Body
```

- *Type parameters* appear in the `where` clause
- *Constraints* specify requirements (e.g., `type`, `subtype(comparable)`)
- *Multiple type parameters* are comma-separated in the `where` clause

Verse automatically infers type parameters from the arguments you
pass, eliminating the need for explicit type annotations in most
cases:

<!--versetest-->
<!-- 61 -->
```verse
# Function with two type parameters
Pair(X:t, Y:u where t:type, u:type):tuple(t, u) = (X, Y)

# All type parameters inferred
Pair(1, "one") = (1, "one")    # t = int, u = string
Pair(true, 3.14) = (true, 3.14)  # t = logic, u = float
```

Inference with collections:

<!--versetest-->
<!-- 62 -->
```verse
# Generic first element function
First(Items:[]t where t:type)<decides>:t = Items[0]

Values := array{1, 2, 3}
Result:int = First[Values]  # t inferred as int from []int
Result = 1
```

When you pass multiple values to a parametric function expecting a single type parameter, Verse can infer either a tuple or an array:

<!--versetest-->
<!-- 63 -->
```verse
# Returns the argument unchanged
Identity(X:t where t:type):t = X

# Passing multiple values creates a tuple
Result1:tuple(int, int) = Identity(1, 2)  # t = tuple(int, int)

# Can also be treated as an array
Result2:[]int = Identity(1, 2)  # t = []int via conversion
```

### Type Constraints

Type constraints restrict which types can be used with type parameters, enabling operations that require specific capabilities.

The most permissive constraint accepts any type, as the `Identity`
function above shows. The `subtype` constraint instead restricts to
types that are subtypes of a specified type. The function still returns
type `t`, not the base type, which preserves the specific type at the
call site:

<!--versetest-->
<!-- 64 -->
```verse
vehicle := class:
    Speed:float = 0.0

car := class(vehicle):
    NumDoors:int = 4

# Only accepts vehicle or its subtypes
ProcessVehicle(V:t where t:subtype(vehicle))<transacts>:t =
    # Can access Speed because we know V is a vehicle
    Print("Speed: {V.Speed}")
    V

ProcessVehicle(vehicle{})                            # t = vehicle
MyCar:car = ProcessVehicle(car{NumDoors := 2})       # t = car
MyCar.NumDoors = 2                                   # Car-specific field
```

The `subtype(comparable)` constraint enables equality comparisons:

<!--versetest-->
<!-- 65 -->
```verse
# Can use = and <> operators on t
FindInArray(Items:[]t, Target:t where t:subtype(comparable))<decides>:[]int =
    for (Index -> Item : Items, Item = Target):
        Index

FindInArray[array{1, 2, 1}, 1] = array{0, 2}
```

Type parameters can reference each other in constraints:

<!--versetest-->
<!-- 66 -->
```verse
# u must be a subtype of t
Convert(Base:t, Derived:u where t:type, u:subtype(t)):t = Base
# This ensures type safety across related types
```

### Member Access

When using subtype constraints, you can access members that exist on the base type:

<!--versetest-->
<!-- 67 -->
```verse
entity := class:
    Name:string = "Entity"
    Health:int = 100

player := class(entity):
    Score:int = 0

# Can access entity members through type parameter
GetInfo(E:t where t:subtype(entity))<computes>:tuple(t, string, int) =
    (E, E.Name, E.Health)            # Can access Name and Health

P := player{Name := "Alice", Health := 100, Score := 1500}
Info := GetInfo(P)
Info(1) = "Alice"
Score:int = Info(0).Score            # Info(0) has type player, not entity
```

Method calls work too:

<!--versetest-->
<!-- 68 -->
```verse
entity := class:
    GetStatus():string = "Active"

# Call methods on parametrically-typed values
CheckStatus(E:t where t:subtype(entity)):string =
    E.GetStatus()  # Method call through type parameter

CheckStatus(entity{}) = "Active"
```

### Polarity and Variance

Type parameters must be used consistently according to variance rules. 
This ensures type safety when functions are used as values or passed as arguments.

The covariant positions, which are safe for return types, are:

- Function return types
- Tuple/array element types (as return)
- Map key types (as return)
- Map value types (as return)

The only contravariant position, safe for parameter types, is a
function parameter type.

The polarity check validates that type parameters appear
only in positions compatible with their intended use:

<!--versetest-->
<!-- 69 -->
```verse
# Valid: t appears covariantly (return type)
GetValue(X:t where t:type):t = X

# Valid: t appears contravariantly (parameter)
Consume(X:t where t:type):void = {}

# Valid: t appears in both positions (through function parameter and return)
Apply(F:type{_(:t):t}, X:t where t:type):t = F(X)
```

An invariant type causes an error:

<!--versetest
assert_semantic_error(3552):
    c(t:type) := class{var X:t}
    MakeContainer(X:t where t:type):c(t) = c(t){X := X}
<#
-->
<!-- 70 -->
```verse
# ERROR: Cannot return type that is invariant in t
c(t:type) := class{var X:t}  # Mutable field makes c invariant in t
MakeContainer(X:t where t:type):c(t) = c(t){X := X}
```
<!-- #>-->

The error occurs because `c(t)` contains a mutable field of type `t`,
making it invariant - neither covariant nor contravariant. Returning
such a type from a parametric function is unsafe.

Maps are covariant in both keys and values:

<!--versetest-->
<!-- 71 -->
```verse
# Valid: covariant key and value
ProcessMap(M:[t]u where t:subtype(comparable), u:type):[t]u = M
```

## Overloading

Function overloading allows you to define multiple functions with the
same name but different parameter types. The compiler selects the
correct version based on the types of the arguments provided at the
call site.

Define multiple functions with the same name but different parameter types:

<!--versetest-->
<!-- 72 -->
```verse
# Overload by parameter type
Process(Value:int):string = "Integer: {Value}"
Process(Value:float):string = "Float: {Value}"
Process(Value:string):string = "String: {Value}"

# Calls select the appropriate overload
Process(42) = "Integer: 42"
Process(3.14) = "Float: 3.140000"
Process("hello") = "String: hello"
```

The compiler determines which overload to call based on the argument
types. Each overload must have a distinct parameter type signature.

### Capture

You cannot take a reference to an overloaded function name:

<!--versetest
assert_semantic_error(3502):
    f77(x:int):void = {}
    f77(x:float):void = {}
    g77 := f77
-->
<!-- 73 -->
```verse
f(x:int):void = {}
f(x:float):void = {}

# g := f   # ERROR: which f?
```

This restriction exists because the compiler cannot determine which overload you mean without seeing the call site with arguments.

### Effects

You can overload functions with different effects, but only if the
parameter types are also different:

Different types with different effects are accepted:

<!--versetest-->
<!-- 74 -->
```verse
Process(x:float):float = x
Process(x:int)<transacts><decides>:int = x = 1

Process(3.0) = 3.0   # Non-failable
Process[1] = 1       # Failable
```

The same types with different effects are not:

<!--versetest
assert_semantic_error(3532):
    f(x:int):void = {}
    f(x:int)<transacts><decides>:void = {}
<#
-->
<!-- 75 -->
```verse
# ERROR: Same parameter type
f(x:int):void = {}
f(x:int)<transacts><decides>:void = {}  # ERROR
```
<!-- #>-->

Effects alone do not create distinctness - you need different parameter types.

### Overloads in Subclasses

Subclasses can add new overloads to methods:

<!--versetest-->
<!-- 76 -->
```verse
c0 := class:
    f(X:int):int = X

c1 := class(c0):
    # Add new overload for float
    f(X:float):float = X

c0{}.f(5) = 5       # int overload
c1{}.f(5) = 5       # inherited int overload
c1{}.f(5.0) = 5.0   # new float overload
```

When a subclass defines a method that shares a name with a parent
method, it must either:

1. Provide a **distinct parameter type** (different from all parent overloads)
2. **Override exactly one** parent overload using `<override>`

<!--versetest
assert_semantic_error(3532, 3532):
    c109 := class{}
    d109 := class(c109){}
    e109 := class:
        func(C:c109):c109 = C
        func(E:e109):e109 = E
    g109 := class(e109):
        func(D:d109):d109 = D
-->
<!-- 77 -->
```verse
c := class<allocates>{}
d := class<allocates>(c){}

# Parent class with overloads
e := class<allocates>:
    func(C:c):c = C
    func(E:e):e = E

# Valid: Overrides one parent overload
myf := class<allocates>(e):
    func<override>(C:c):d = d{}

# ERROR: d is subtype of c, overlaps but does not override
# g := class(e):
#     func(D:d):d = D  # ERROR - ambiguous with func(C:c)
```

### Interfaces with Overloaded Methods

Interfaces can declare overloaded methods:

<!--versetest-->
<!-- 78 -->
```verse
formatter := interface:
    Format(X:int):string = "{X}"
    Format(X:string):string = "{X}"

entity := class(formatter):
    Format<override>(X:int):string = "Entity-{X}"
    Format<override>(X:string):string = "Entity-{X}"

entity{}.Format(1) = "Entity-1"
entity{}.Format("a") = "Entity-a"
```

### Restrictions

A name cannot be both a function and a non-function value:

<!--versetest
assert_semantic_error(3532):
    f:int = 0
    f():void = {}
<#
-->
<!-- 79 -->
```verse
# ERROR: Cannot overload with a variable
f:int = 0
f():void = {}
```
<!-- #>-->

The bottom type (from `return` without a value) cannot be used for overload resolution:

<!--versetest
assert_semantic_error(3518):
    F(X:int):int = X
    F(X:float):float = X
    G():void =
        F(@ignore_unreachable return)
        0
<#
-->
<!-- 80 -->
```verse
F(X:int):int = X
F(X:float):float = X

G():void =
    F(@ignore_unreachable return)  # ERROR - which F?
    0
```
<!-- #>-->

### Overloading with `<suspends>`

You can mix suspending and non-suspending overloads if the parameter
types differ:

<!--versetest-->
<!-- 81 -->
```verse
f(x:int)<suspends>:void =
    Sleep(1.0)

f(x:float):void =
    Print("Non-suspending")

# Call non-suspending directly
f(1.0)

# Call suspending with spawn
spawn{f(1)}
```

A suspending overload cannot be called without `spawn`:

<!--versetest
assert_semantic_error(3512):
    f(x:int):void = {}
    f(x:float)<suspends>:void = {}
    g():void = f(1.0)
<#
-->
<!-- 82 -->
```verse
# ERROR: suspends version needs spawn context
f(x:int):void = {}
f(x:float)<suspends>:void = {}

g():void = f(1.0)  # ERROR - float version is suspends
```
<!-- #>-->


### Types 

Every function has a type that captures its parameters, effects, and
return value. The type syntax uses an underscore as a placeholder for
the function name:

<!--versetest-->
<!-- 83 -->
```verse
type{_(:int,:string)<decides>:float}
```

This represents any function that takes an integer and a string, might
fail, and returns a float when successful.

Multiple functions may share a name through overloading, as long as
their signatures do not create ambiguity. The compiler can distinguish
between overloads based on the argument types, as `Process` showed
above. However, overloading has strict limitations based on *type
distinctness*. Two types are considered "distinct" for overload
purposes only if there is no possible value that could match both
types. This restriction prevents ambiguity and ensures that function
calls can always be resolved unambiguously at compile time.

Verse uses precise rules to determine whether two parameter types are
distinct enough to allow overloading. Understanding these rules is
critical for designing clear APIs.

The following type pairs are **not distinct** and cannot be used to
overload functions:

**1. Optional and Logic.** `?t` and `logic` are not distinct because
both types include `false` as a value, creating overload ambiguity when
`false` is passed as an argument:

<!--versetest
assert_semantic_error(3532):
    F(:?any):void = {}
    F(:logic):void = {}
<#
-->
<!-- 84 -->
```verse
# ERROR: Not distinct
F(:?any):void = {}
F(:logic):void = {}
```
<!-- #>-->

Note that `?t` and `logic` are not equivalent types—`logic` contains
`true` and `false`, while `?t` contains `false` and option values like
`option{false}`. However, their shared `false` value means the compiler
cannot distinguish between them for overload resolution.

**2. Arrays and Maps.**  Arrays `[]t` and maps `[k]t` are not distinct:

<!--versetest
assert_semantic_error(3532):
    F(:[]int):void = {}
    F(:[string]int):void = {}
<#
-->
<!-- 85 -->
```verse
# ERROR: Not distinct
F(:[]int):void = {}
F(:[string]int):void = {}
```
<!-- #>-->

**3. Functions, Maps and Arrays.** Function types are distinct from
neither maps nor arrays, because an overloaded function could match
both:

<!--versetest
assert_semantic_error(3532, 3532):
    F1(:[string]int):void = {}
    F1(G(:string)<transacts><decides>:int):void = {}
    F2(:[]int):void = {}
    F2(G(:string)<transacts><decides>:int):void = {}
<#
-->
<!-- 86 -->
```verse
# ERROR: Not distinct
F1(:[string]int):void = {}
F1(G(:string)<transacts><decides>:int):void = {}

F2(:[]int):void = {}
F2(G(:string)<transacts><decides>:int):void = {}
```
<!-- #>-->

**4. Interfaces and Classes.** An interface and any class are never
distinct, even if the class does not implement the interface, because a
subtype of the class might:

<!--versetest
assert_semantic_error(3532):
    i := interface{}
    t := class{}
    f(:i):void = {}
    f(:t):void = {}
<#
-->
<!-- 87 -->
```verse
i := interface{}
t := class{}

# ERROR: Not distinct (subtype of t might implement i)
f(:i):void = {}
f(:t):void = {}
```
<!-- #>-->

**5. Functions with Different Effects or Signatures.** Functions are
not distinct based on effects alone; changing or removing effects does
not create a distinct overload. Neither do different parameter or
return types, because of function overloading:

<!--versetest
assert_semantic_error(3532, 3532):
    a := class{}
    b := class{}
    F1(G(:a)<transacts><decides>:b):void = {}
    F1(G(:a):b):void = {}
    F2(G(:b):b):void = {}
    F2(G(:a):b):void = {}
<#
-->
<!-- 88 -->
```verse
a := class{}
b := class{}

# ERROR: Not distinct, the effects differ
F1(G(:a)<transacts><decides>:b):void = {}
F1(G(:a):b):void = {}

# ERROR: Not distinct, the parameter types differ
F2(G(:b):b):void = {}
F2(G(:a):b):void = {}
```
<!-- #>-->

**6. void as Top Type.** `void` is treated as equivalent to the top
type (accepts `any`), so it is not distinct from any other type:

<!--versetest
assert_semantic_error(3532):
    F(:int):void = {}
    F(:void):void = {}
<#
-->
<!-- 89 -->
```verse
# ERROR: Not distinct
F(:int):void = {}
F(:void):void = {}
```
<!-- #>-->

**7. Subtype Relationships.** Classes with subtype relationships are
not distinct:

<!--versetest
assert_semantic_error(3532):
    a := class{}
    b := class(a){}
    F(:a):void = {}
    F(:b):void = {}
<#
-->
<!-- 90 -->
```verse
a := class{}
b := class(a){}

# ERROR: Not distinct
F(:a):void = {}
F(:b):void = {}
```
<!-- #>-->

**8. Tuple Distinctness Rules.**  Tuples have complex distinctness
rules. An empty tuple is not distinct from an array. A tuple and an
array are distinct only if the tuple element types are completely
distinct. A tuple is not distinct from a map with an `int` key, nor is
a singleton tuple distinct from the optional of the same element type
when that element is `int`:

<!--versetest
assert_semantic_error(3532, 3532, 3532, 3532):
    a := class{}
    b := class(a){}
    F1(:tuple(), :a):void = {}
    F1(:[]a, :a):void = {}
    F2(:tuple(a, b), :a):void = {}
    F2(:[]a, :a):void = {}
    F3(:tuple(a), :a):void = {}
    F3(:[int]a, :a):void = {}
    F4(:tuple(int), :a):void = {}
    F4(:?int, :a):void = {}
<#
-->
<!-- 91 -->
```verse
a := class{}
b := class(a){}

# ERROR: An empty tuple is an array
F1(:tuple(), :a):void = {}
F1(:[]a, :a):void = {}

# ERROR: b is a subtype of a, so the element types overlap
F2(:tuple(a, b), :a):void = {}
F2(:[]a, :a):void = {}

# ERROR: A tuple is a map keyed by int
F3(:tuple(a), :a):void = {}
F3(:[int]a, :a):void = {}

# ERROR: tuple(int) overlaps ?int
F4(:tuple(int), :a):void = {}
F4(:?int, :a):void = {}
```
<!-- #>-->

Change the key or element type away from `int` and both pairs become
distinct:

<!--versetest-->
<!-- 92 -->
```verse
a := class{}

# Valid: the map key is not int
F1(:tuple(a), :a):void = {}
F1(:[logic]a, :a):void = {}

# Valid: the option element is not int
F2(:tuple(a), :a):void = {}
F2(:?a, :a):void = {}
```

## Publishing Functions

Publishing a function is a promise of backwards compatibility between
the function and its clients. Consider this function:

<!--versetest-->
<!-- 93 -->
```verse
F1<public>(X:int):int = X + 1
```

The type annotation (`X:int):int`) tells us that this function promises that
given any integer it will always return an integer. That contract cannot be
broken in future versions of the code. Because it has the default effect, which
includes the `<reads>` effect, the implementation could change in the future,
perhaps to perform additional operations or optimizations, as long as it
maintains its signature.

Functions that do not have the `<reads>` effect are less flexible. Consider
this function:

<!--versetest-->
<!-- 94 -->
```verse
F2<public>(X:int)<computes>:int = X + 1
```

Because it has the `<computes>` effect specifier, it does not have the
`<reads>` effect. Within a given version, this guarantees referential
transparency: the function will always return the same result for the
same arguments. Across versions, this creates a stronger constraint:
since the compiler cannot verify that a modified body preserves the
same input-output mapping for all possible arguments, it
conservatively forbids any body changes. Thus, changing the body to
return `X + 2` in a future version would be rejected as backward
incompatible.

Functions such as `F1` and `F2` are sometimes called *opaque* as the return
type abstracts the function's body. Future version of Verse will support
*transparent* functions:

<!--NoCompile-->
<!-- 95 -->
```verse
F2<public>(X:int) := X + 1
```

A transparent function does not declare its return type, instead the
function's type is inferred from its body. This implies a very
different promise: a forever guarantee that the function's body will
remain exactly the same throughout the lifetime of the module code.
