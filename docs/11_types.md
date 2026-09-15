# Types

Every value has a type. Types determine what operations are permitted
and where a value can be used, and they are checked at compile time.
Types are also values in Verse, which is what makes generic code
possible.

The types form a lattice rather than a tree, so a type can have several
supertypes. At the top sits `any`, the supertype from which all other
types descend. At the bottom lies `false`, the empty type that contains
no values at all. Everything else sits between them, each type with its
own capabilities and constraints.

## Understanding Subtyping

Subtyping is the foundation of the type hierarchy. When we say that
type A is a subtype of type B, we mean that every value of type A can
be used wherever a value of type B is expected. This relationship
creates a natural ordering among types, from the most specific to the
most general.

Consider the relationship between `rational` and `int`. Every
integer is a rational number, but not every rational is an integer.
Therefore, `int` is a subtype of `rational`. This means you can
pass an `int` to any function expecting a `rational`, but not vice versa:

<!--versetest
assert_semantic_error(3509):
    _GetInt(X:int):void = {}
    _Pass(R:rational):void = _GetInt(R)
-->
<!-- 01 -->
```verse
GetInt(X:int):void = Print("Integer: {X}")
GetRat(X:rational):void = Print("Rational")

MyRat:rational = 1/3
MyInt:int = -10

GetRat(MyInt)    # OK -- int is a subtype of rational
# GetInt(MyRat)  # Compile error - rational is not a subtype of int
```

Composite types have their own subtyping rules. Arrays, options and
tuples are covariant in their elements, so `[]int` is a subtype of
`[]rational` and `tuple(int, int)` is a subtype of `tuple(rational,
rational)`.

Maps are covariant in both parts: `[K1]V1` is a subtype of `[K2]V2`
when `K1` is a subtype of `K2` and `V1` is a subtype of `V2`. See
[Variance](03_containers.md#variance) for why iteration forces keys to
be covariant rather than contravariant.

Classes and interfaces introduce nominal subtyping through
inheritance. When a class inherits from another class or implements an
interface, it explicitly declares a subtyping relationship:

<!--versetest-->
<!-- 02 -->
```verse
vehicle := class:
    Speed:float = 0.0

car := class(vehicle):  # car is a subtype of vehicle
    NumDoors:int = 4

sports_car := class(car):  # sports_car is a subtype of car (and vehicle)
    Turbo:logic = true
```

This inheritance hierarchy means that a `sports_car` can be used
anywhere a `car` or `vehicle` is expected, but not the reverse. The
subtype inherits all fields and methods from its supertypes while
potentially adding new ones or overriding existing ones.

## Numeric and String Conversions

All type conversions must be explicit, a design choice that eliminates
entire categories of bugs while making the programmer's intent
clear. Converting between numeric types illustrates this principle
clearly. To convert an integer to a float, you multiply by 1.0:

<!--versetest-->
<!-- 03 -->
```verse
MyI:int   = 42
MyF:float = MyI * 1.0  # Explicit conversion to float
```

!!! note 
    The strongest reason for disallowing implicit conversions is that
	they can cause code to break when new overloadings to a function
	are added. Imagine a call to function `f` that takes a float such
	as `f(1)`, if the integer argument was implicitly converted to a 
	float and, in some future library release, an overload `f(:int)` 
	was added, the call would silently invoke that new function
	and potentially change the result of the computation.

The reverse conversion, from float to integer, requires choosing a
rounding strategy:

<!--versetest-->
<!-- 04 -->
```verse
MyF:float = 3.7

Down:int    = Floor[MyF]
Up:int      = Ceil[MyF]
Nearest:int = Round[MyF]

Down = 3
Up = 4
Nearest = 4
```

These conversion functions are failable - they have the `<decides>`
effect and will fail if passed non-finite values like `NaN` or
`Inf`. The explicit failure forces you to handle edge cases:

<!--versetest-->
<!-- 05 -->
```verse
SafeConvert(Value:float):int =
    if:
       Value <> NaN
       Value <> Inf
       Result:= Floor[Value]
    then:
       Result
    else:
       0  # Assuming zero is a safe fallback
```
<!--versetest
SafeConvert(3.7) = 3
SafeConvert(NaN) = 0
-->

String conversions follow similar principles. The `ToString()`
function converts various types to their string representations, while
string interpolation provides a convenient syntax for embedding values
in strings:

<!--versetest-->
<!-- 06 -->
```verse
Score:int  = 1500
Msg:string = "Your score: {Score}"  # Implicit ToString() call

Msg = "Your score: 1500"
```

## Type `any`

<!-- TODO add a link to the builtin types -->

Type `any` is at the top of the type hierarchy it is the universal
supertype that can hold a value of any type. Every type in Verse is a
subtype of `any`, making it the most permissive type.  It serves as an
escape hatch when you genuinely need to work with values of unknown or
varying types.

Once a value is typed as `any`, you've effectively told the compiler
"I do not know what this is," and the compiler responds by preventing
most operations. This is by design—without knowing the actual type,
the compiler cannot verify that operations are safe.

You can explicitly coerce any value to `any` using function call
syntax, `any(42)`. 

Verse automatically coerces values to `any` when their types would
otherwise be incompatible. Understanding these rules help when working
with heterogeneous data.

Mixed-type arrays and maps automatically coerces to the most specific shared
type, if no common type is found, the array coerces to `any`:

<!--versetest
SomeFunction():void={}
assert_semantic_error(3509):
    _F():void={}
    Cfg:[string]comparable = map{"count"=>42, "process"=>_F, "name"=>"Player"}
-->
<!-- 07 -->
```verse
MixedArray := array{42, "hello", true, 3.14}
MixedMap   := map{0=>"zero", 1=>1, 2=>2.0}
ConfigMap  := map{"count"=>42, "process"=>SomeFunction, "name"=>"Player"}

# The types the compiler inferred
Arr:[]comparable   = MixedArray
Mp:[int]comparable = MixedMap
Cfg:[string]any    = ConfigMap
```

A function value is not comparable, so `ConfigMap` cannot be narrowed
any further: annotating it `[string]comparable` is a compile error.

Conditional expressions with disjoint branch types produce `any`:

<!--versetest-->
<!-- 08 -->
```verse
# If branches return different types
GetValue(UseString:logic):any =
    if (UseString?):
        "text result"
    else:
        42
```

Logical OR with disjoint types coerces to `any`:

<!--versetest-->
<!-- 09 -->
```verse
# Yields either the int or the string
OneOf(MaybeI:?int, S:string):any =
    MaybeI? or S
```

The `any` type has restrictions that reflect its role as a generic
container:

- You cannot use equality operators with `any`
- Because `any` is not comparable, it cannot be used as a map key type
- Because `any` is not castable, it is a sticky type.

### Generic Functions and Type Preservation

Generic functions with `where t:type` constraints behave fundamentally differently from functions that accept `any`. Understanding this difference is crucial for writing type-safe code.

When you pass a value to a function with parameter type `any`, the type information is lost:

<!--versetest
assert_semantic_error(3509):
    _AcceptAny(X:any):any = X
    _Use(M:[int]string):void =
        R := _AcceptAny(M)
        if (M = R) {}
-->
<!-- 10 -->
```verse
AcceptAny(X:any):any = X

MyMap:[int]string = map{1 => "one"}
Result := AcceptAny(MyMap)  # Result has type any - type info lost
# MyMap = Result            # Compile error: any is not comparable
```

In contrast, generic functions preserve exact types:

<!--versetest-->
<!-- 11 -->
```verse
Identity(X:t where t:type):t = X

MyMap:[int]string = map{1 => "one"}
Result := Identity(MyMap)  # Result has type [int]string - type preserved
MyMap = Result  # Succeeds - same type
```

This preservation extends to all container types, including arrays, maps, tuples, and structs. The generic type parameter captures the complete type, including:

- Map key and value types
- Array element types
- Tuple component types
- Struct field types

The practical implication is not that the container changes shape —
nothing happens to the value itself — but that its type stays known to
the compiler, so every operation that type allows still works on the
result:

<!--versetest-->
<!-- 12 -->
```verse
Identity(X:t where t:type):t = X

# Even a compound key type survives the round trip
TupleMap:[tuple(int, string)]int = map{(1, "a") => 100}
TupleMap = Identity(TupleMap)  # Same type

# Iteration and lookup work as expected
for (Key->Value : TupleMap):
    Identity(TupleMap)[Key] = Value  # All lookups succeed
```

This makes generic functions the preferred approach when you need to write reusable code that works with containers while maintaining type safety.

## Class and Interface Casting

Verse provides two distinct casting mechanisms for classes and
interfaces: fallible casts for runtime type checking, and infallible
casts for compile-time verified conversions. All classes and interfaces
support dynamic casting regardless of whether they are marked with the
`<castable>` attribute—`<castable>` is only required for using the
`castable_subtype` type constraint.

Fallible casts use square bracket syntax `TargetType[value]` to
perform runtime type checks. These casts succeed and return the
casted value (`TargetType`), failing if the value is not of
a valid target type or a subtype:

<!--versetest-->
<!-- 13 -->
```verse
component := class<castable>:
    Name:string = "Component"

physics_component := class<castable>(component):
    Velocity:float = 0.0

render_component := class<castable>(component):
    Material:string = "default"

Describe(Comp:component)<computes>:string =
    if (PhysicsComp := physics_component[Comp]):
        # Successfully cast - PhysicsComp is physics_component
        "physics"
    else if (RenderComp := render_component[Comp]):
        # Different type - RenderComp is render_component
        RenderComp.Material
    else:
        # Neither type matched
        Comp.Name

Describe(physics_component{}) = "physics"
Describe(render_component{}) = "default"
Describe(component{})        = "Component"
```

The cast expression fails if the runtime type does not
match, allowing you to use it directly in conditionals. The optional
binding pattern `(Variable := Expression)` both performs the cast and
binds the result to a variable when successful.

For classes marked `<unique>`, fallible casts preserve identity—a
successful cast returns the same instance, not a copy:

<!--versetest-->
<!-- 14 -->
```verse
entity := class<unique><castable>:
    ID:int

player := class<unique>(entity):
    Name:string

P := player{ID := 1, Name := "Alice"}

# Cast to base type
E := entity[P]
E = P  # Succeeds - the cast returned the very same instance
```

Fallible casts work **only with class and interface types**. You
cannot dynamically cast from or to primitive types, structs, arrays,
or other value types:

<!--versetest
assert_semantic_error(3512, 3509, 3547):
    component := class<castable>{}
    FromInt := component[42]

assert_semantic_error(3512, 3509, 3547):
    component := class<castable>{}
    FromArray := component[array{1, 2}]

assert_semantic_error(3512, 3509, 3547, 3512):
    component := class<castable>{}
    ToInt := int[component{}]

assert_semantic_error(3512, 3552, 3547, 3512):
    component := class<castable>{}
    ToOption := (?int)[component{}]
<#
-->
<!-- 15 -->
```verse
component := class<castable>{}

# Error: cannot cast a non-class value to a class
FromInt   := component[42]
FromArray := component[array{1, 2}]

# Error: cannot cast a class to a non-class type
ToInt    := int[component{}]
ToOption := (?int)[component{}]
```
<!-- #>-->

The restriction exists because fallible casts rely on runtime type
information that only classes and interfaces maintain. Value types
like integers and structs do not have runtime type tags.

*Infallible* casts use parenthesis syntax `TargetType(value)` for
conversions that the compiler can verify will always succeed. These
casts require the source type to be a compile-time subtype of the
target type:

<!--versetest-->
<!-- 16 -->
```verse
component := class<castable>:
    Name:string = "Component"

physics_component := class<castable>(component):
    Velocity:float = 0.0

# Upcasting: always safe, always succeeds
Base:physics_component = physics_component{Velocity := 10.0}

BaseComp:component = component(Base) # upcast during expression
# or
AlsoBaseComp:component = Base # upcast during assignment

# Both still refer to the original instance
physics_component[BaseComp].Velocity = 10.0
physics_component[AlsoBaseComp].Velocity = 10.0
```

Any type can be infallibly cast to `void`, which discards the value:

<!--versetest
component:=class{}
-->
<!-- 17 -->
```verse
void(42)           # Discard an integer
void("result")     # Discard a string
void(component{})  # Discard an object
```

This implicitly happens when you call a function for its side effects
and want to ignore its return value.

### Dynamic Type-Based Casting

Types in Verse are first-class values, which means you can store types
in variables and use them dynamically for casting. This enables
powerful patterns for runtime polymorphism:

<!--versetest-->
<!-- 18 -->
```verse
# Type hierarchy
component := class<castable>{}
physics_component := class<castable>(component){}
render_component := class<castable>(component){}

# Store a type as a value
ComponentType:castable_subtype(component) = physics_component

# Cast using the stored type
IsType(Comp:component, ExpectedType:castable_subtype(component))<computes>:logic =
    if (ExpectedType[Comp]):
        true  # Component matches expected type
    else:
        false

P := physics_component{}
IsType(P, ComponentType)?
not IsType(P, render_component)?
```

This pattern is particularly powerful when the type to check is not
known until runtime:

<!--versetest
entity:=class{}
component := class<castable>:
    Owner:entity
physics_component := class<castable>(component){}
render_component := class<castable>(component){}
LoadedConfig:string="physics"
-->
<!-- 19 -->
```verse
# Select type based on configuration
GetComponentType(Config:string)<computes>:castable_subtype(component) =
    if (Config = "physics"):
        physics_component
    else if (Config = "render"):
        render_component
    else:
        component

Components:[]component = array{
    physics_component{Owner := entity{}},
    render_component{Owner := entity{}}}

# Use the dynamically selected type
RequiredType := GetComponentType(LoadedConfig)
Selected := for (Comp : Components, Specific := RequiredType[Comp]):
    Specific

Selected.Length = 1  # Only the physics component matched
```

This bridges compile-time type safety with runtime flexibility,
allowing type decisions to be made based on program state while
maintaining type correctness.

## Where Clauses

Where clauses are the mechanism for constraining type parameters in
generic code. They appear after type parameters and specify
requirements that types must satisfy to be valid arguments. This
creates a powerful system for writing generic code that is both
flexible and type-safe.

<!--versetest-->
<!-- 20 -->
```verse
# Simple subtype constraint
Process(Value:t where t:subtype(comparable)):void =
    if (Value = Value):  # We know it supports equality
        Print("Value equals itself")
```

Using the same type in multiple constraints is not yet supported, when
implemented, it will allow to write code such as:

<!--versetest
assert_semantic_error(3588, 3588, 3503, 3503, 3532):
    printable := interface:
        PrintIt():void

    # Multiple constraints on the same type - not supported
    F(In:t where t:subtype(comparable), t:subtype(printable)):t =
        In
<#
-->
<!-- 21 -->
```verse
printable := interface:
    PrintIt():void

# Multiple constraints on the same type - not supported
F(In:t where t:subtype(comparable), t:subtype(printable)):t =
    In
```
<!-- #> -->

Where clauses become more powerful when working with multiple type parameters:

<!--versetest-->
<!-- 22 -->
```verse
# Independent constraints on different parameters
Combine(A:t1, B:t2 where t1:type, t2:type):tuple(t1, t2) =
    (A, B)

# Related constraints
Convert(From:t1, Converter:type{_(:t1):t2} where t1:type, t2:type):t2 =
    Converter(From)
```

Where clauses can express sophisticated relationships between types:

<!--versetest
Contains(Arr:[]t, Item:t where t:type)<decides><computes>:logic = false
-->
<!-- 23 -->
```verse
# Constraint that ensures compatible types for an operation
Merge(Container1:[]t, Container2:[]t where t:subtype(comparable)):[]t =
    var Result:[]t = Container1
    for (Element : Container2, not Contains[Result, Element]):
        set Result += array{Element}
    Result

# Function type constraints
ApplyTwice(F:type{_(:t):t}, Value:t where t:type):t =
    F(F(Value))
```

Where clauses enable sophisticated generic programming patterns:

<!--versetest-->
<!-- 24 -->
```verse
MapFunction(F:type{_(:a):b}, Container:[]a where a:type, b:type):[]b =
    for (Element : Container):
        F(Element)
```

## Refinement Types

While `where` clauses constrain type parameters in generic code,
**refinement types** use `where` to constrain the *values* a type can
hold. This creates subtypes that only accept values satisfying
specific conditions, enabling domain-specific constraints enforced by
the type system.

A natural question is: why fail on out-of-range values when you could
just clamp? The answer is that clamping silently propagates wrong
values, which is acceptable for some domains (UI opacity) but
dangerous in others. In algorithms where exact values matter — bit
manipulation, hashing, Unicode code point operations, coordinate
system math — silently clamping an out-of-range value produces
incorrect results that are extremely hard to track down. Refinement
types make the constraint explicit and force the caller to handle
violations, catching bugs at their source rather than letting them
propagate.

In practice, type aliases like `positive_int` or `zero_to_one_float`
make refinement types convenient to reuse across a codebase without
repeating the constraint expression each time.

A refinement type defines a constrained subtype using value predicates:

<!--versetest
assert_semantic_error(3509):
    _percent := type{_X:float where 0.0 <= _X, _X <= 1.0}
    BadPercent:_percent = 1.5
-->
<!-- 25 -->
```verse
# Percentages: floats between 0.0 and 1.0
percent := type{_X:float where 0.0 <= _X, _X <= 1.0}

Opacity:percent = 0.5
Alpha:percent   = 1.0

# BadPercent:percent = 1.5  # Rejected: outside the range
```

Because the bound and the initializer are both literals, that last line
is rejected by the compiler rather than at run time. A value that is
only known at run time is checked with a fallible cast instead, as
described below.

### Syntax Structure

<!--NoCompile-->
<!-- 26 -->
```verse
TypeName := type{_Variable:BaseType where Constraint1, Constraint2, ...}
```

- `_Variable` is a placeholder for the value being constrained
- `BaseType` is `int` or `float`
- Constraints are comparison expressions using `<=`, `<`, `>=`, or `>`

Integer refinements restrict int values to specific ranges:

<!--versetest-->
<!-- 27 -->
```verse
# Age between 0 and 120
age := type{_X:int where 0 <= _X, _X <= 120}

ValidAge:age = 25
not age[150]      # 150 is outside the range
```

Float refinements handle continuous ranges with IEEE 754 semantics,
and a bound may be any float literal, including a negative one:

<!--versetest-->
<!-- 28 -->
```verse
# Temperature in Celsius, above absolute zero
celsius := type{_X:float where _X >= -273.15}

Freezing:celsius = 0.0
not celsius[-300.0]
```

The special values `Inf` and `-Inf` are float literals too, so a
refinement can exclude them and so describe exactly the finite floats:

<!--versetest-->
<!-- 29 -->
```verse
# Finite values only (no ±Inf)
finite := type{_X:float where -Inf < _X, _X < Inf}

# Maximum and minimum finite IEEE 754 doubles
MaxFinite:finite = 1.7976931348623157e+308
MinFinite:finite = -1.7976931348623157e+308

not finite[Inf]
```

### IEEE 754 Edge Cases

#### Negative and Positive Zero

IEEE 754 distinguishes between `+0.0` and `-0.0`. In verse Zero is just Zero,
with no distinction between positve or negative.

When any expression evaluates to Zero, the sign is discarded:

<!--versetest-->
<!-- 30 -->
```verse
# Integer Zero (type{0})
Value1 := -0
Value2 := +0

Value1 = Value2 # Succeeds
-0 = +0         # Succeeds

# Float Zero (type{0.0})
Value3 := -0.0
Value4 := +0.0

Value3 = Value4 # Succeeds
-0.0 = +0.0     # Succeeds
```

#### Floating-Point Precision

Constraints respect exact IEEE 754 representations:

<!--versetest-->
<!-- 31 -->
```verse
# Values strictly less than 0.1
small_float := type{_X:float where _X < 0.1}

# Valid: the largest float below 0.1
Tiny:small_float = 0.09999999999999999167332731531132594682276248931884765625

# 0.1 itself is not below its own stored representation
not small_float[0.1]
```

The decimal `0.1` cannot be represented exactly in binary
floating-point, so the actual stored value is slightly above the
mathematical 0.1.

### Constraint Expression Restrictions

Refinement type constraints have strict limitations on what
expressions are allowed.

#### Only Literal Values

Constraints must use literal numbers, not variables or expressions:

<!--versetest
assert_semantic_error(3502):
    Limit:float = 100.0
    bad_type := type{_X:float where _X < Limit}

assert_semantic_error(3512, 3502):
    GetMax():float = 100.0
    bad_type := type{_X:float where _X < GetMax()}
-->
<!-- 32 -->
```verse
# Valid: literal float
bounded := type{_X:float where _X < 100.0}

# Invalid: a bound may not be a variable
# Limit:float = 100.0
# bad_type := type{_X:float where _X < Limit}

# Invalid: nor a function call
# GetMax():float = 100.0
# bad_type := type{_X:float where _X < GetMax()}
```

This ensures constraints are statically known at compile time.

#### Float Literals Required for Float Types

When constraining floats, bounds must be float literals, written with
a decimal point:

<!--versetest
assert_semantic_error(3502):
    bad_float := type{_X:float where _X <= 142}

assert_semantic_error(3502):
    nan_type := type{_X:float where _X <= NaN}
-->
<!-- 33 -->
```verse
# Invalid: integer literal in float constraint
# bad_float := type{_X:float where _X <= 142}  # ERROR

# Valid: float literal
good_float := type{_X:float where _X <= 142.0}
```

#### NaN Not Allowed

Not a Number cannot appear in constraints, in any spelling: `_X <=
NaN`, `NaN <= _X` and `_X <= 0.0/0.0` are all rejected. Since `NaN`
comparisons are always false, such constraints would be meaningless.

The literal forms a constraint does allow are these:

- Float literals: `1.0`, `3.14`, `-2.5`, `1.7976931348623157e+308`
- Integer literals: `0`, `42`, `-100` (for int refinements)
- Special float values: `Inf`, `-Inf`

### Fallible Casts

Refinement types are checked at assignment and through fallible casts:

<!--versetest
GetInputFromUser()<computes>:float = 50.0
ProcessPercent(P:float):void = {}
ShowError(Msg:string):void = {}
-->
<!-- 34 -->
```verse
percent := type{_X:float where 0.0 <= _X, _X <= 1.0}

# Direct assignment (compile-time known)
Valid:percent = 0.5

# Runtime check with fallible cast
UserInput:float = GetInputFromUser()
if (Value := percent[UserInput]):
    # UserInput was in [0.0, 1.0]
    ProcessPercent(Value)
else:
    # Out of range
    ShowError("out of range")

percent[0.25] = 0.25  # The cast returns the value itself
not percent[1.5]
```

The cast `percent[UserInput]` returns `percent` succeeding if the
value satisfies the constraint, or failing otherwise.

### Examples

Refinement types work as parameter and return types:

<!--versetest
assert_semantic_error(3509):
    _finite := type{_X:float where -Inf < _X, _X < Inf}
    _Half(X:_finite):float = X
    _G():void = _Half(Inf)
-->
<!-- 35 -->
```verse
finite := type{_X:float where -Inf < _X, _X < Inf}

# Parameter with constraint
Half(X:finite)<computes>:float = X / 2.0

Half(100.0) = 50.0
Half(1.0)   = 0.5

# Cannot pass infinity
# Half(Inf)  # ERROR: Inf not in finite
```

A refinement type also survives negation: the compiler negates the
bounds along with the value, so a `percent` becomes a
`negative_percent`.

<!--versetest-->
<!-- 36 -->
```verse
percent := type{_X:float where 0.0 <= _X, _X <= 1.0}
negative_percent := type{_X:float where _X <= 0.0, _X >= -1.0}

MakePercent()<computes>:percent = 0.5

NegValue:negative_percent = -MakePercent()
NegValue = -0.5

# Repeated negation folds before the constraint is checked
NegValue2:negative_percent = ---0.7
NegValue2 = -0.7
```

### Overloading Restrictions

Overlapping refinement types cannot be used for function
overloading—they are ambiguous:

<!--versetest
assert_semantic_error(3532):
    percent := type{_X:float where 0.0 <= _X, _X <= 1.0}
    not_infinity := type{_X:float where Inf > _X}
    F(X:percent):float = 0.0
    F(X:not_infinity):float = X
-->
<!-- 37 -->
```verse
percent := type{_X:float where 0.0 <= _X, _X <= 1.0}
not_infinity := type{_X:float where Inf > _X}

# ERROR: cannot distinguish - percent is contained in not_infinity,
# so a call such as F(0.5) would match both overloads
# F(X:percent):float = 0.0
# F(X:not_infinity):float = X
```

However, **disjoint** refinement types can overload:

<!--versetest-->
<!-- 38 -->
```verse
positive := type{_X:float where _X > 0.0}
negative := type{_X:float where _X < 0.0}

# Valid: ranges do not overlap (zero excluded from both)
F(X:positive)<computes>:float = X
F(X:negative)<computes>:float = X + 1.0

F(1.0)  = 1.0   # positive overload
F(-1.0) = 0.0   # negative overload
# F(0.0)        # Would fail - neither overload matches
```

## Comparable and Equality

The `comparable` type represents a special subset of types that
support equality comparison. Not all types can be compared for
equality - this is a deliberate design choice that prevents
meaningless comparisons and ensures that equality has well-defined
semantics.

A type is comparable if its values can be meaningfully tested for
equality. The basic scalar types are all comparable: `int`, `float`,
`rational`, `logic`, `char`, and `char32`. Compound types are
comparable if all their components are comparable. This means arrays
of integers are comparable, tuples of floats and strings are
comparable, and maps with comparable keys and values are comparable.

The equality operators `=` and `<>` are defined in terms of the
comparable type:

<!--NoCompile-->
<!-- 39 -->
```verse
operator'='(X:t, Y:t where t:subtype(comparable))<decides>:t
operator'<>'(X:t, Y:t where t:subtype(comparable))<decides>:t
```

The signatures require that both operands be subtypes of comparable
and the return type is the least upper bound of their types.

<!--versetest-->
<!-- 40 -->
```verse
0 = 0            # Succeeds - both are int
0.0 = 0.0        # Succeeds - both are float
not (0 = 0.0)    # Fails - there is no implicit conversion from int to float
```

Note that `0 = 0.0` is not rejected by the compiler. Both operands are
subtypes of `comparable`, so the comparison type-checks; it simply
never succeeds, because an `int` and a `float` are never the same
value.

How the return type of `=` is computed:

<!--versetest-->
<!-- 41 -->
```verse
# The declared return types are what `=` actually produces, so these
# signatures type-check; both comparisons then fail at runtime
CompareToRational(I:int, R:rational)<computes><decides>:rational = I = R
CompareToString(I:int, S:string)<computes><decides>:comparable = I = S

not CompareToRational[1, 1/3]
not CompareToString[1, "hi"]
```

Comparing an `int` with a `rational` could yield either `rational` or
`comparable`, and the least upper bound, `rational`, is the one chosen.
For an `int` and a `string` the only common type is `comparable`.


Classes require special handling for comparability. By default, class
instances are not comparable because there's no universal way to
define equality for user-defined types. However, you can make a class
comparable using the `unique` specifier:

<!--versetest-->
<!-- 42 -->
```verse
entity := class<unique>:
    ID:int
    Name:string

Player1 := entity{ID := 1, Name := "Alice"}
Player2 := entity{ID := 1, Name := "Alice"}
Player3 := Player1

not (Player1 = Player2)  # Different instances, equal fields
Player1 = Player3        # Same instance
```

With the `unique` specifier, instances are only equal to themselves
(identity equality), not to other instances with the same field values
(structural equality). This provides a clear, predictable semantics
for class equality.

### Comparable as a Generic Constraint

The `comparable` type is commonly used as a constraint in generic
functions to ensure operations like equality testing are available:

<!--versetest-->
<!-- 43 -->
```verse
Find(Items:[]t, Target:t where t:subtype(comparable))<decides>:int =
    Results := for (Index->Item:Items, Item = Target):
        Index
    Results[0]

# Works with any comparable type
Position := Find[array{"apple", "banana", "cherry"}, "banana"]
Position = 1
```

### Array-Tuple Comparison

A notable feature of Verse's equality system is that arrays and tuples
of comparable elements can be compared with each other:

<!--versetest-->
<!-- 44 -->
```verse
# Arrays can equal tuples
array{1, 2, 3} = (1, 2, 3)       # Succeeds
(4, 5, 6) = array{4, 5, 6}       # Succeeds - bidirectional

# Inequality also works
array{1, 2, 3} <> (1, 2, 4)      # Succeeds - different values
```

This comparison works structurally - the sequences must have the same
length and corresponding elements must be equal. This feature allows
functions expecting arrays to accept tuples, increasing flexibility.

### Overload Distinctness with Comparable

You cannot create overloads where one parameter is a specific comparable type and another is the general `comparable` type, as this creates ambiguity:

<!--versetest
assert_semantic_error(3532):
    F(X:int):void = {}
    F(X:comparable):void = {}

assert_semantic_error(3532):
    unique_class := class<unique>{}
    G(X:unique_class):void = {}
    G(X:comparable):void = {}
<#
-->
<!-- 45 -->
```verse
# Not allowed - ambiguous overloads
F(X:int):void = {}
F(X:comparable):void = {}  # ERROR: int is already comparable

# Not allowed with unique classes either
unique_class := class<unique>{}
G(X:unique_class):void = {}
G(X:comparable):void = {}  # ERROR: unique_class is comparable
```
<!-- #> -->

However, you can overload with non-comparable types:

<!--versetest-->
<!-- 46 -->
```verse
# This is allowed
regular_class := class{}  # Not comparable
H(X:regular_class):void = {}
H(X:comparable):void = {}  # OK: no ambiguity
```

### Dynamic Comparable Values

When working with heterogeneous collections, you may need to box
comparable values into the `comparable` type explicitly. These boxed
values maintain their equality semantics:

<!--versetest-->
<!-- 47 -->
```verse
AsComparable(X:comparable):comparable = X

# Boxed values compare correctly with both boxed and unboxed
array{AsComparable(1)} = array{1}              # Succeeds
array{AsComparable(1)} = array{AsComparable(1)} # Succeeds
array{AsComparable(1)} <> array{2}             # Succeeds

# With direct upcasting:
comparable(15) = comparable(15)     # Succeeds
comparable("Hello") = "Hello"       # Succeeds
```

This allows you to create collections that mix different comparable
types by boxing them all to `comparable`.

### Map Keys and Comparable

Map keys must be comparable types. Most comparable types can be used
as map keys, including:

- All numeric types: `int`, `float`, `rational`
- Character types: `char`, `char32`
- Text: `string`
- Enumerations
- `<unique>` classes
- Optionals of comparable types: `?t` where `t` is comparable
- Arrays of comparable types: `[]t` where `t` is comparable
- Tuples of comparable types
- Maps with comparable keys and values: `[k]v`
- Structs with comparable fields

Note that while `float` can be used as a map key, floating-point
special values have specific equality semantics (see [Map
documentation](02_primitives.md#floats) for details on
`NaN` and zero handling).

There is currently no way to make a regular class comparable by
writing a custom comparison method. Only the `<unique>` specifier
enables class comparability through identity equality.

## Type `void`

Unlike `any`, which erases type information, `void` serves as a
"discard" type indicating that a value's specific type does not matter.

`void` also participates in a wider unification with `true`, `tuple()` and the
`false` literal — see
[void, true, tuple() and false](02_primitives.md#void-true-tuple-and-false).

Functions with `void` return type can return any value, which is then
discarded by the type system:

<!--versetest
WriteToFile(:string)<transacts>:void = {}
-->
<!-- 48 -->
```verse
LogEvent(Message:string)<transacts>:void =
    WriteToFile(Message)
    42                   # Returns int, but typed as void

F():void = 1             # Valid - returns int, typed as void
F()                      # Result is void
```

Despite being typed as `void`, these functions still produce their
computed values—the values are simply not accessible through the type
system. This ensures side effects and computations occur even when the
return value is discarded:

<!--versetest-->
<!-- 49 -->
```verse
MakePair(X:string, Y:string):void = (X, Y)

# Function computes the pair even though return type is void
MakePair("hello", "world")  # Still creates ("hello", "world")
```

Functions with `void` parameters accept any argument type:

<!--versetest-->
<!-- 50 -->
```verse
Discard(X:void):int = 42

Discard(0)               # int → void 
Discard(1.5)             # float → void 
Discard("test")          # string → void 
```

Class fields can be typed as `void`, accepting any initialization
value:

<!--versetest-->
<!-- 51 -->
```verse
config := class:
    Setting:void = array{1, 2}  # Default with array
```

In function types, `void` participates in variance:

<!--versetest-->
<!-- 52 -->
```verse
IntIdentity(X:int):int = X

# Covariant return: subtype allowed in return position
F:int->void = IntIdentity  # int->int → int->void ✓
# void is supertype of int, so this works

AcceptVoid(X:void):int = 19

# Contravariant parameter: supertype in parameter position
G:int->int = AcceptVoid    # void->int → int->int ✓
# Can use function accepting void where function accepting int expected
```

However, `void` in parameter position does NOT allow conversion the
other way:

<!--versetest
assert_semantic_error(3509):
    IntFunction(X:int):int = X
    F:void->int = IntFunction
-->
<!-- 53 -->
```verse
IntFunction(X:int):int = X

# F:void->int = IntFunction  # ERROR
# Cannot convert an int parameter to a void parameter in a function type
```

### `void` and `false`

The `false` type is the empty, or bottom, type: an uninhabited type
with no values at all. It is the opposite of `void`:

- **`void`**: Universal supertype - all types are subtypes of void, contains all values
- **`false`**: Bottom type - subtype of all types, contains zero values

Between the universal supertypes (`any`, `void`) and the bottom type
(`false`), types form natural groupings. The numeric types (`int`,
`float`, `rational`) share common arithmetic operations but do not form
a single hierarchy - they are siblings rather than ancestors and
descendants. The container types (arrays, maps, tuples, options) each
have their own subtyping rules based on their element types.

Understanding variance is crucial for working with generic
containers. Arrays and options are covariant in their element type -
if A is a subtype of B, then `[]A` is a subtype of `[]B` and `?A` is a
subtype of `?B`. This allows natural code like:


<!--versetest
RationalPrinter(X:rational):string=""
-->
<!-- 54 -->
```verse
ProcessNumbers(Nums:[]rational):void =
    for (N : Nums):
        Print("{RationalPrinter(N)}")

IntArray:[]int = array{1, 2, 3}
ProcessNumbers(IntArray)  # Works due to covariance
```

Functions exhibit more complex variance. They're contravariant in
their parameter types and covariant in their return types. A function
type `(T1)->R1` is a subtype of `(T2)->R2` if T2 is a subtype of T1
(contravariance) and R1 is a subtype of R2 (covariance). This ensures
that function subtyping preserves type safety:

<!--versetest-->
<!-- 55 -->
```verse
function_type1 := type{_(:any):int}
function_type2 := type{_(:int):any}

# function_type1 is a subtype of function_type2: it accepts more
# general input (any vs int) and returns more specific output (int vs any)
ConcreteFunc(Input:any):int = 42

UseFunction(F:function_type2, Value:int):void =
    Result:any = F(Value)

UseFunction(ConcreteFunc, 5)  # Works: function_type1 <: function_type2
```

## Type Aliases

Type aliases allow you to create alternative names for types, making
complex type signatures more readable and maintainable. They're
particularly valuable for function types, parametric types, and
frequently-used type combinations.

A type alias is created using simple assignment syntax at module scope:

<!--versetest-->
<!-- 56 -->
```verse
entity := struct{}

# Simple type aliases
coordinate := tuple(float, float, float)
entity_map := [string]entity
player_id := int

# Function type aliases
update_handler := type{_(:float):void}
validator := int -> logic

Origin:coordinate = (0.0, 0.0, 0.0)
Registry:entity_map = map{"hero" => entity{}}
```

Type aliases are compile-time only - they create no runtime overhead
and are purely for programmer convenience and code clarity.

A type alias is an alternative name, not a new type. Aliases do not
create distinct types the way `newtype` does in some languages. Values
of the alias and the original type are completely interchangeable:

<!--versetest-->
<!-- 57 -->
```verse
player_id := int
game_id := int

ProcessPlayer(ID:player_id):void = {}
ProcessGame(ID:game_id):void = {}

PID:player_id = 42
GID:game_id = 42

# These all work - aliases are just names
ProcessPlayer(PID)      # OK
ProcessPlayer(GID)      # OK - game_id is also int
ProcessPlayer(42)       # OK - int literal works too
ProcessGame(PID)        # OK - player_id is also int
```

Type aliases can have access specifiers that control their visibility across modules:

<!--versetest
assert_semantic_error(3594):
    ProtectedAlias<protected> := float
# Public alias - accessible from other modules
PublicAlias<public> := int

# Internal alias - only accessible within defining module
InternalAlias<internal> := string
<#
-->
<!-- 58 -->
```verse
# Public alias - accessible from other modules
PublicAlias<public> := int

# Internal alias - only accessible within defining module
InternalAlias<internal> := string
```
<!-- #> -->

Only `<public>` and `<internal>` are available here. Writing
`ProtectedAlias<protected> := float` at module scope is an error,
because `protected` and `private` are meaningful only inside a class
or an interface.

A type alias cannot be more public than the type it aliases:

<!--versetest
private_class := class{}

InternalToInternal<internal> := private_class
InternalAlias := private_class  # Defaults to internal

assert_semantic_error(3593):
    M<public> := module:
        internal_class := class{}
        PublicToInternal<public> := internal_class
<#
-->
<!-- 59 -->
```verse
private_class := class{}      # No specifier = internal scope

# INVALID: public alias to an internal type
# PublicToPrivate<public> := private_class

# VALID: same or less visibility
InternalToInternal<internal> := private_class
InternalAlias := private_class  # Defaults to internal
```
<!-- #> -->

#### Requirements

- Type aliases can only be defined at module scope. They cannot be
defined inside classes, functions, or any nested scope.
This restriction ensures type aliases have consistent visibility and
prevents scope-dependent type interpretations.

- Type aliases must be defined before they are used. Forward
references are not allowed.

- Type aliases are not first-class values and cannot be used as such.

## Metatypes

Verse provides advanced type constructors that allow you to work with
types as values, enabling powerful patterns for runtime polymorphism
and generic instantiation. These metatypes—`subtype`,
`concrete_subtype`, and `castable_subtype`—bridge the gap between
compile-time type safety and runtime flexibility.

### subtype

The `subtype(T)` type constructor represents runtime type values that
are subtypes of `T`. Unlike `concrete_subtype` and `castable_subtype`,
which are specialized for classes and interfaces, `subtype(T)` works
with **any type** in Verse, including primitives, enums, collections,
and function types.

<!--versetest-->
<!-- 60 -->
```verse
animal := class {}
dog := class(animal) {}

registry := class:
    # Can hold animal, dog, or any subtype of animal
    var AnimalType:subtype(animal) = animal

    SetToDog()<transacts>:void = set AnimalType = dog

    # A type value can also arrive as a parameter
    SetTo(ClassArg:subtype(animal))<transacts>:void = set AnimalType = ClassArg
```

The key capability of `subtype(T)` is holding type values at runtime
while maintaining type safety through the subtype relationship.

Unlike the other metatypes, `subtype(T)` accepts any type as its parameter:

<!--versetest
assert_semantic_error(3549):
    ArrayType:subtype([]int) = []int
-->
<!-- 61 -->
```verse
my_enum      := enum { A, B, C }
my_interface := interface {}
int_array    := []int
void_fn      := type{_():void}

IntType:subtype(int)                = int
EnumType:subtype(my_enum)           = my_enum
InterfaceType:subtype(my_interface) = my_interface
ArrayType:subtype(int_array)        = int_array
FuncType:subtype(void_fn)           = void_fn
```

Collection and function types have to be named by an alias first. The
compound type may not be written inline in the annotation of a
definition, because `ArrayType:subtype([]int) = []int` is parsed as an
indexing expression on the left-hand side and rejected. Naming the
type sidesteps the ambiguity; there is no restriction on the metatype
itself.

This universality makes `subtype(T)` the most flexible of the metatypes, suitable for any scenario where you need to store or pass type values.

#### Subtyping Relationship

The `subtype` constructor preserves the subtyping relationship:
`subtype(T) <: subtype(U)` if and only if `T <: U`. This means you can
assign a more specific subtype to a less specific one:

<!--versetest-->
<!-- 62 -->
```verse
super_class := class{}
sub_class := class(super_class) {}

# Covariance: sub_class <: super_class
SubtypeVar:subtype(sub_class) = sub_class
SupertypeVar:subtype(super_class) = SubtypeVar  # Valid

# Reverse fails - super_class is not <: sub_class
# SubtypeVar2:subtype(sub_class) = super_class
```

This also applies to interfaces:

<!--versetest-->
<!-- 63 -->
```verse
super_interface := interface{}
sub_interface := interface(super_interface) {}

class_impl := class(sub_interface) {}

# Covariance through interface hierarchy
SpecificType:subtype(sub_interface) = class_impl
GeneralType:subtype(super_interface) = SpecificType  # Valid
```

#### Using with Interfaces

When working with interfaces, `subtype(T)` can hold any class that implements the interface:

<!--versetest-->
<!-- 64 -->
```verse
printable := interface:
    PrintIt():void

document := class(printable):
    PrintIt<override>():void = {}

# Can hold any type implementing printable
DocumentType:subtype(printable) = document
```

#### Relationship to `type`

Both `subtype(T)` and `castable_subtype(T)` are subtypes of `type`, meaning they can be used where `type` is expected:

<!--versetest-->
<!-- 65 -->
```verse
c := class:
    f(C:subtype(c)):type = return(C)  # Valid: subtype(c) <: type

t := interface {}
g(x:subtype(t)):type = x  # Valid: subtype(t) <: type
```

#### Restrictions

While `subtype(T)` is flexible, it has important restrictions. It is a
type constructor, not a value, so you cannot use `subtype(T)` itself
as a value. It requires exactly one type argument. And it cannot be
used with classes that inherit from `attribute`.

### concrete_subtype

The `concrete_subtype(t)` type constructor creates a type that
represents concrete (instantiable) subclasses of `t`. A concrete class
is one that can be instantiated directly—it has the `<concrete>`
specifier and provides default values for all fields:

<!--versetest-->
<!-- 66 -->
```verse
# Abstract base class
entity := class<abstract>:
    Name:string
    GetDescription():string

# Concrete implementations
player := class<concrete>(entity):
    Name<override>:string = "Player"
    GetDescription<override>():string = "A player character"

enemy := class<concrete>(entity):
    Name<override>:string = "Enemy"
    GetDescription<override>():string = "An enemy creature"

# Class that stores a type and can instantiate it
spawner := class:
    EntityType:concrete_subtype(entity)

    Spawn():entity =
        # Instantiate using the stored type
        EntityType{}

NewEntity := spawner{EntityType := player}.Spawn()
NewEntity.Name = "Player"
spawner{EntityType := enemy}.Spawn().Name = "Enemy"
```

The key feature of `concrete_subtype` is that it ensures the stored type can be instantiated. Without this constraint, you couldn't safely call `EntityType{}` because abstract classes cannot be instantiated.

#### Requirements

A type can be used with `concrete_subtype` only if it is a class or
interface type. Additionally, the actual type value assigned must be a
concrete class—one marked with `<concrete>` and having all fields with
defaults:

<!--versetest
assert_semantic_error(3509):
    abstract_base := class<abstract>:
        Value:int
    BaseType:concrete_subtype(abstract_base) = abstract_base
-->
<!-- 67 -->
```verse
# Valid: concrete class with all defaults
config := class<concrete>:
    MaxPlayers:int = 8
    TimeLimit:float = 300.0

ConfigType:concrete_subtype(config) = config

# Invalid: an abstract class is not a concrete_subtype
abstract_base := class<abstract>:
    Value:int

# BaseType:concrete_subtype(abstract_base) = abstract_base
```

When you have a `concrete_subtype`, you can instantiate it with the
empty archetype `{}`, but you cannot provide field initializers—the
concrete class must provide all necessary defaults:

<!--versetest
assert_semantic_error(3552):
    entity_base := class<abstract>:
        Health:int
    warrior := class<concrete>(entity_base):
        Health<override>:int = 100
    holder := class:
        EntityType:concrete_subtype(entity_base)
        Bad():entity_base = EntityType{Health := 150}
-->
<!-- 68 -->
```verse
entity_base := class<abstract>:
    Health:int

warrior := class<concrete>(entity_base):
    Health<override>:int = 100

spawner := class:
    EntityType:concrete_subtype(entity_base)

    # Valid: the empty archetype uses the concrete class's defaults
    Spawn():entity_base = EntityType{}

    # Invalid: cannot initialize fields through the metatype
    # Spawn2():entity_base = EntityType{Health := 150}

spawner{EntityType := warrior}.Spawn().Health = 100
```

### castable_subtype

The `castable_subtype(t)` type constructor represents types that are
subtypes of `t` and marked with the `<castable>` specifier. This
constraint is required when you want to use types as first-class
values—storing them in variables, passing them as parameters, or
returning them from functions—and then use those type values to perform
casts. Note that the `<castable>` specifier is not required for basic
dynamic casting; all classes and interfaces support the `Type[value]`
cast syntax regardless of `<castable>`:

<!--versetest
entity:=class{}
vector3:=class{}
-->
<!-- 69 -->
```verse
# Castable base class
component := class<abstract><castable>:
    Owner:entity

# Castable subtypes
physics_component := class<castable>(component):
    Velocity:vector3

render_component := class<castable>(component):
    Material:string

# Function accepting castable subtype
ProcessComponent(CompType:castable_subtype(component), Comp:component):void =
    # Can use CompType to perform type-safe casts
    if (Specific := CompType[Comp]):
        # Comp is now known to be of type CompType
```

### final_super and Type Queries

The `castable_subtype` works with the `<final_super>` specifier and
`GetCastableFinalSuperClass` function to enable sophisticated runtime
type queries. This combination provides a powerful mechanism for
component systems and polymorphic architectures.

The `<final_super>` specifier marks classes as stable anchor points in
inheritance hierarchies. These "final super classes" act as canonical
representatives for families of related types:

<!--versetest
entity:=class{}
vector3:=class{}
-->
<!-- 70 -->
```verse
component := class<castable>:
    Owner:entity

# Stable anchor for the physics component family
physics_component := class<final_super>(component):
    Velocity:vector3

# Specific implementations inherit from the anchor
rigid_body := class(physics_component):
    Mass:float

soft_body := class(physics_component):
    SpringConstant:float
```

By marking `physics_component` as `<final_super>`, you declare it as the canonical representative for all physics-related components. Even though `rigid_body` and `soft_body` are distinct types, they both belong to the "physics_component family" anchored at `physics_component`.

#### GetCastableFinalSuperClass

The `GetCastableFinalSuperClass` function queries the type hierarchy to find the `<final_super>` class between a base type and a derived type. Two variants exist:

<!--NoCompile-->
<!-- 71 -->
```verse
# Takes an instance
GetCastableFinalSuperClass(BaseType, instance)<decides>:castable_subtype(BaseType)

# Takes a type
GetCastableFinalSuperClassFromType(BaseType, Type)<decides>:castable_subtype(BaseType)
```

Both return a `castable_subtype` representing the least specific `<final_super>` class that:

1. Directly inherits from the specified base type
2. Is in the inheritance chain of the instance/type

The function fails if no appropriate `<final_super>` class exists.

Consider this hierarchy:


<!--versetest
vector3:=class{}
-->
<!-- 72 -->
```verse
component := class<castable>:
    ID:int

# Direct final_super subclass of component
physics_component := class<final_super>(component):
    Velocity:vector3

# Descendants of physics_component
rigid_body := class(physics_component):
    Mass:float

character_body := class(rigid_body):
    Health:int
```

Query results:


<!--versetest
vector3 := class{}
component := class<castable>:
    ID:int
physics_component := class<final_super>(component):
    Velocity:vector3
rigid_body := class(physics_component):
    Mass:float
character_body := class(rigid_body):
    Health:int
-->
<!-- 73 -->
```verse
# All instances in the physics_component family return physics_component
Body := character_body{ID:=1, Velocity:=vector3{}, Mass:=10.0, Health:=100}

if (Family := GetCastableFinalSuperClass[component, Body]):
    # Family = physics_component (the final_super anchor), even though
    # Body is a character_body
    Family[Body]
else:
    false  # Never taken - the query succeeds
```

The function "walks up" the inheritance chain from `character_body` → `rigid_body` → `physics_component` and stops at `physics_component` because:

1. It has `<final_super>`
2. It directly inherits from the queried base (`component`)

#### When Queries Succeed and Fail

A query succeeds when a `<final_super>` class directly inherits from
the base type and the instance or type inherits from that
`<final_super>` class:

<!--versetest-->
<!-- 74 -->
```verse
base := class<castable>:
    Value:int = 0

anchor := class<final_super>(base):
    Extra:string = ""

derived := class(anchor):
    More:string = ""

# Valid: anchor is final_super of base, derived inherits from anchor
if (GetCastableFinalSuperClass[base, derived{}]) {} else { false }
if (GetCastableFinalSuperClass[base, anchor{}])  {} else { false }
```

It fails when no `<final_super>` class exists between base and
instance, when the queried type is itself the instance type, so that
there is no level to walk up from, or when the instance is not a
subtype of the base.


#### Multiple Final Supers

You can have multiple `<final_super>` classes at different levels. The
function returns the one directly inheriting from the queried base:

<!--versetest-->
<!-- 75 -->
```verse
base := class<castable>:
    ID:int = 0

first_anchor := class<final_super>(base):
    Category:string = ""

second_anchor := class<final_super>(first_anchor):
    Subcategory:string = ""

leaf := class(second_anchor):
    Specific:string = ""

# Query from base returns first_anchor
if (GetCastableFinalSuperClass[base, leaf{}]) {} else { false }

# Query from first_anchor returns second_anchor
if (GetCastableFinalSuperClass[first_anchor, leaf{}]) {} else { false }
```


This layered approach allows hierarchical categorization where
different levels represent different granularities of type families.

#### GetCastableFinalSuperClassFromType

The type-based variant works identically but takes a type instead of instance:

<!--versetest
component := class<castable>{}
physics_component := class<final_super>(component){}
rigid_body := class(physics_component){}
-->
<!-- 76 -->
```verse
# Same behaviour, different argument: both return physics_component
TypeFamily := GetCastableFinalSuperClassFromType[component, rigid_body]
if (GetCastableFinalSuperClass[component, rigid_body{}]) {} else { false }
```

This is useful when working with type values directly rather than instances.

### castable_concrete_subtype

The `castable_concrete_subtype(t)` type constructor combines the requirements of both `castable_subtype` and `concrete_subtype`, representing types that are:
- Subtypes of `t`
- Marked with `<castable>` (enabling runtime type queries)
- Marked with `<concrete>` (enabling instantiation)

This is useful when you need a stored type to be both castable and concrete:

<!--versetest
entity := class{}
-->
<!-- 77 -->
```verse
component := class<abstract><castable>:
    Owner:entity = entity{}

physics_component := class<castable><concrete>(component):
    Velocity:float = 0.0

factory := class:
    # Must be both castable (for type queries) and concrete (to instantiate)
    CompType:castable_concrete_subtype(component)

    CreateAndCast():component =
        # Can instantiate because CompType is <concrete>
        Instance := CompType{}
        # Can cast because CompType is <castable>
        if (Specific := CompType[Instance]):
            Specific
        else:
            Instance

Made := factory{CompType := physics_component}.CreateAndCast()
physics_component[Made].Velocity = 0.0
```

The type value has to be held in a class *field*, as it is here. A
`concrete_subtype` or `castable_concrete_subtype` that arrives as a
function *parameter* cannot be instantiated: writing `CompType{}` on a
parameter is rejected with "CompType is not a macro". Casting with a
parameter, as in the `castable_subtype` example above, works fine; it
is only the archetype syntax that is restricted to fields.

### classifiable_subset

Building on the concept of runtime type queries introduced by
`castable_subtype`, Verse provides `classifiable_subset`—a
sophisticated mechanism for maintaining sets of runtime types. Where
`castable_subtype` represents a single type value,
`classifiable_subset` represents a collection of types, tracking which
classes are present in a system and supporting queries based on type
hierarchies.

This feature is particularly valuable for component-based
architectures, where you need to track which component types an entity
possesses, query for specific capabilities, or filter operations based
on type compatibility. Rather than maintaining separate boolean flags
or type tags, `classifiable_subset` provides a type-safe,
hierarchy-aware registry of runtime types.

Three related types work together to provide both immutable and
mutable type sets:

**`classifiable_subset(t)`** represents an immutable set of runtime
types, where `t` must be a `<castable>` base type. Once created, the
set cannot be modified, making it suitable for configuration,
capability descriptions, or any scenario where the type set should
remain stable.

**`classifiable_subset_var(t)`** provides a mutable variant with
`Read()` and `Write()` operations, enabling dynamic type sets that
change during program execution. This is essential for runtime systems
where component types are added or removed as entities evolve.

**`classifiable_subset_key(t)`** represents keys used to identify
specific instances when adding them to a mutable set. These keys
enable removal of specific instances later, supporting lifecycle
management of registered types.

Unlike ordinary classes, `classifiable_subset` types cannot be
directly instantiated. You must use the constructor functions
`MakeClassifiableSubset()` and `MakeClassifiableSubsetVar()`:

<!--versetest
component:=class<castable>{}
physics_component := class<final_super>(component){}
rigid_body := class(physics_component){}
render_component := class<castable>(component){}
-->
<!-- 78 -->
```verse
# Immutable set, initially empty
EmptySet:classifiable_subset(component) = MakeClassifiableSubset()

# Immutable set with initial instances
InitialSet:classifiable_subset(component) =
    MakeClassifiableSubset(array{physics_component{}, render_component{}})

# Mutable set
DynamicSet:classifiable_subset_var(component) = MakeClassifiableSubsetVar()
```

The base type `t` must be `<castable>`, ensuring runtime type queries
are possible. This restriction is enforced at compile time:

<!--versetest-->
<!-- 79 -->
```verse
component := class<castable>{}
ComponentSet:classifiable_subset(component) = MakeClassifiableSubset()

# Invalid: non-castable types cannot be used
regular_class := class:
    Value:int

# BadSet:classifiable_subset(regular_class) = MakeClassifiableSubset()
```

You cannot subclass these types or create instances through ordinary
construction syntax. This ensures that all sets use the proper
internal representation for efficient type queries.

#### Type Hierarchy Semantics

The crucial insight of `classifiable_subset` is that it tracks runtime
types, not individual instances. When you add an instance to the set,
the system records that instance's actual runtime type. More
importantly, type queries respect the inheritance hierarchy:


<!--versetest
entity:=class{}
vector3:=class{}
component := class<castable>{}
physics_component := class<castable>(component):
    Velocity:vector3=vector3{}

rigid_body_component := class<castable>(physics_component):
    Mass:float=0.0
-->
<!-- 80 -->
```verse
# Add a rigid body instance
Set:classifiable_subset(component) =
    MakeClassifiableSubset(array{rigid_body_component{}})

# Query results respect hierarchy
Set.Contains[component]             # true - rigid_body is a component
Set.Contains[physics_component]     # true - rigid_body is a physics_component
Set.Contains[rigid_body_component]  # true - directly present
```

This hierarchy awareness makes `classifiable_subset` fundamentally
different from a simple set of type tags. The `Contains` operation
asks "does this set contain any type that is-a T?" rather than "does
this set contain exactly T?".

When you add instances of different types, each distinct runtime type
is tracked separately:

<!--versetest
component := class<castable>{}
physics_component := class<castable>(component){}
rigid_body_component := class<castable>(physics_component){ }
render_component := class<castable>(component){}
audio_component := class<castable>(component){}
-->
<!-- 81 -->
```verse
# Add multiple different types
TheSet:classifiable_subset_var(component) = MakeClassifiableSubsetVar()
Key1 := TheSet.Add(physics_component{})
Key2 := TheSet.Add(render_component{})
Key3 := TheSet.Add(audio_component{})

TheSet.Contains[component]          # succeeds - all three are components
TheSet.Contains[physics_component]  # succeeds - physics_component present
TheSet.Contains[render_component]   # succeeds - render_component present
```

The set remembers each distinct type that was added. When you remove an instance by its key, that specific type is removed only if it was the last instance of that type:

<!--versetest
component := class<castable>{}
physics_component := class<castable>(component){}
rigid_body_component := class<castable>(physics_component){ }
-->
<!-- 82 -->
```verse
# Add multiple instances of same type
TheSet:classifiable_subset_var(component) = MakeClassifiableSubsetVar()
Key1 := TheSet.Add(physics_component{})
Key2 := TheSet.Add(physics_component{})

TheSet.Contains[physics_component]  # succeeds

TheSet.Remove[Key1]
TheSet.Contains[physics_component]  # still succeeds - Key2 remains

TheSet.Remove[Key2]
not TheSet.Contains[physics_component]  # fails - last instance removed
```

#### Core Operations

The `classifiable_subset` types provide several operations for
querying and manipulating type sets.

##### Contains

`Contains` checks whether any type in the set matches or is a
subtype of the queried type:

<!--versetest
component := class<castable>{}
physics_component := class<castable>(component){}
render_component := class<castable>(component){}
-->
<!-- 83 -->
```verse
TheSet:classifiable_subset(component) =
    MakeClassifiableSubset(array{physics_component{}})

TheSet.Contains[component]             # a physics_component is a component
not TheSet.Contains[render_component]  # no render component was added
```

##### ContainsAll

`ContainsAll` verifies that all types in an array are present in the set:

<!--versetest
component := class<castable>{}
physics_component := class<castable>(component){}
render_component := class<castable>(component){}
-->
<!-- 84 -->
```verse
TheSet:classifiable_subset(component) =
    MakeClassifiableSubset(array{physics_component{}})

TheSet.ContainsAll[array{physics_component, component}]
not TheSet.ContainsAll[array{physics_component, render_component}]
```

##### ContainsAny

`ContainsAny` checks whether at least one type from an array is present:

<!--versetest
component := class<castable>{}
physics_component := class<castable>(component){}
audio_component := class<castable>(component){}
-->
<!-- 85 -->
```verse
TheSet:classifiable_subset(component) =
    MakeClassifiableSubset(array{physics_component{}})

# Physics is present, audio is not, so at least one matches
TheSet.ContainsAny[array{physics_component, audio_component}]
```

##### Add and Remove

`Add`, on mutable sets only, adds an instance and returns a key for
later removal. `Remove`, also on mutable sets only, takes such a key
and removes the instance it identifies. It fails if the key is not
present, either because it was never added or because it has already
been removed:

<!--versetest
component := class<castable>{}
physics_component := class<castable>(component){}
-->
<!-- 86 -->
```verse
TheSet:classifiable_subset_var(component) = MakeClassifiableSubsetVar()

Key := TheSet.Add(physics_component{})
TheSet.Remove[Key]      # Succeeds
not TheSet.Remove[Key]  # Fails - the key is already spent
```

##### FilterByType

`FilterByType` creates a new set containing only types that are compatible (assignable to or from) the specified type:

<!--versetest
component := class<castable>{}
physics_component := class<castable>(component){}
render_component := class<castable>(component){}
audio_component := class<castable>(component){}
-->
<!-- 87 -->
```verse
TheSet:classifiable_subset(component) = MakeClassifiableSubset(array{
    physics_component{}, render_component{}, audio_component{}})

# Filter to physics-related types
PhysicsSet := TheSet.FilterByType(physics_component)
PhysicsSet.Contains[physics_component]
not PhysicsSet.Contains[render_component]  # unrelated sibling
PhysicsSet.Contains[component]             # base type is compatible
```

The filtering respects both upward and downward compatibility in the
type hierarchy, keeping types that could be assigned to or from the
filter type.

##### Union

Two sets are combined with the `+` operator:

<!--versetest
component := class<castable>{}
physics_component := class<castable>(component){}
render_component := class<castable>(component){}
audio_component := class<castable>(component){}
entity := class{}
-->
<!-- 88 -->
```verse
Set1:classifiable_subset(component) =
    MakeClassifiableSubset(array{physics_component{}})
Set2:classifiable_subset(component) =
    MakeClassifiableSubset(array{render_component{}})

Combined := Set1 + Set2
Combined.Contains[physics_component]  # true
Combined.Contains[render_component]   # true
```

For mutable sets, the Read/Write operations enable copying and updating:

<!--versetest
component := class<castable>{}
physics_component := class<castable>(component){}
render_component := class<castable>(component){}
audio_component := class<castable>(component){}
-->
<!-- 89 -->
```verse
Set1:classifiable_subset_var(component) = MakeClassifiableSubsetVar()
Set1.Add(physics_component{})

Set2:classifiable_subset_var(component) = MakeClassifiableSubsetVar()
Set2.Write(Set1.Read())  # Copy Set1's contents to Set2
```

#### Design Considerations

Several important constraints govern `classifiable_subset` usage:

The base type must be `<castable>` to enable runtime type
queries. This requirement ensures that type checks can be performed
efficiently.

You cannot subclass `classifiable_subset` types or create instances
except through the designated constructor functions. This restriction
maintains internal invariants required for correct type tracking.

Keys from one set cannot be used with a different set—they are bound to
the specific set instance where the element was added.

The type parameter must be consistent across operations. You cannot
add a `physics_component` to a `classifiable_subset(render_component)`
even if both inherit from `component`:

<!--versetest
component := class<castable>{}
physics_component := class<castable>(component){}
render_component := class<castable>(component){}
audio_component := class<castable>(component){}
-->
<!-- 90 -->
```verse
render_set:classifiable_subset(render_component) = MakeClassifiableSubset()
physics_comp:physics_component = physics_component{}

# This would be a type error - physics_component is not a render_component
# render_set.Add(physics_comp)
```

Mutable sets require careful lifetime management. Keys become invalid
when their corresponding instances are removed, and attempting to
remove an already-removed key triggers a failure.

Performance characteristics matter for large type sets. While
`Contains` queries are efficient due to the internal representation,
operations like `FilterByType` may need to examine each type in the
set.

When designing systems with `classifiable_subset`, consider whether
immutable or mutable sets better fit your needs. Immutable sets
provide stronger guarantees and work well for configuration, while
mutable sets support dynamic systems where component types change
frequently.

The hierarchy-aware semantics mean that adding a derived type makes
queries for base types succeed. This is usually desirable but requires
awareness—if you only want exact type matches, `classifiable_subset`
may not be the right tool.
