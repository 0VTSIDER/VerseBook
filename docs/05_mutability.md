# Mutability

Values in Verse are immutable by default: once created, a value never changes. Mutation is available but opt-in and visible. You declare a variable with `var`, change it with `set`, and the effect system records both in the signature of any function that does so.

The distinction reaches further than whether a value can change. It also determines how data is shared between functions, which is why structs and classes behave differently when you mutate them.

## The Pure Foundation

In Verse's pure fragment, computation happens without side effects. Values are created but never modified. Functions transform inputs into outputs without changing anything along the way. This is not a limitation — it is a powerful foundation that makes code predictable and composable.

<!--versetest-->
<!-- 01 -->
```verse
point := struct<computes>:
    X:float = 0.0
    Y:float = 0.0

# These values are eternal - Origin will always be (0, 0)
Origin := point{}
UnitX := point{X := 1.0}
UnitY := point{Y := 1.0}

Distance(P1:point, P2:point)<reads>:float =
    DX := P2.X - P1.X
    DY := P2.Y - P1.Y
    Sqrt(DX * DX + DY * DY)

Distance(Origin, UnitX) = 1.0
```

In this pure world, equality means structural equality — two values are equal if they have the same shape and content. For primitive types and structs, this happens automatically. For classes, which have identity beyond their content, equality requires more careful consideration.

<!--versetest-->
<!-- 02 -->
```verse
# A recursive class needs an explicit structural comparison
linked_list := class:
    Value:int = 0
    Next:?linked_list = false

    # Custom equality check for structural comparison
    Equals(Other:linked_list)<computes><decides>:void =
        Self.Value = Other.Value
        # Both have no next, or both have next and those are equal
        if (Self.Next?):
            Tmp := Self.Next?
            OtherNext := Other.Next?
            Tmp.Equals[OtherNext]
        else:
            not Other.Next?

List1 := linked_list{Value := 1, Next := option{linked_list{Value := 2}}}
List2 := linked_list{Value := 1, Next := option{linked_list{Value := 2}}}

List1.Equals[List2]                        # Same shape and content
not List1.Equals[linked_list{Value := 1}]  # A shorter list is not equal
```

A function marked `<computes>` always produces the same output for the same input, with no hidden dependencies. That is what makes it safe to cache, reorder, or run in parallel.

## Introducing Mutation

Mutation enters through two keywords: `var` and `set`. The `var` annotation declares that a variable can be reassigned. The `set` keyword performs that reassignment. Together, they provide controlled mutation with clear visibility.

<!--versetest-->
<!-- 03 -->
```verse
Score:int = 100            # Immutable: cannot be reassigned
var Health:float = 100.0   # Mutable: the type annotation is required
set Health = 75.0
Health = 75.0
```

Every use of `var` and `set` has implications for effects. Reading from a `var` variable requires the `<reads>` effect. Using `set` requires both `<reads>` and `<writes>` effects. This is not bureaucracy — it is transparency. The effects make mutation visible in function signatures, so callers know when functions might observe or modify state.

### Requirements for var Declarations

Mutable variable declarations have strict requirements that prevent common errors:

<!--versetest
assert_semantic_error(3515, 3601, 3502, 3549):
    NoType()<transacts>:void =
        var A := 0
    NoValue()<transacts>:void =
        var B:int
    NoTypeNoValue()<transacts>:void =
        var C
    NestedVar()<transacts>:void =
        var (var D):int = 0
-->
<!-- 04 -->
```verse
var Health:float = 100.0    # A var needs both an explicit type and a value

# var Health := 100.0       # ERROR: := cannot be used with var
# var Health:float          # ERROR: no initial value in a local scope
# var Health                # ERROR: neither a type nor a value
# var (var Health):int = 0  # ERROR: var cannot be nested inside var
Health = 100.0
```

The type inference syntax `:=` cannot be used with `var`. You must explicitly declare the type.

In local scopes (functions, control flow blocks), every `var` declaration requires an initial value. However, when declaring mutable fields in classes or interfaces, the initial value can be omitted and provided during instantiation (see the Classes and Interfaces chapter for details).

A declaration that supplies neither a type nor a value is not a declaration at all, and the `var` keyword cannot be nested within itself.

### var Declarations as Expressions

Variable declarations with `var` can be used as expressions, evaluating to their initial value:

<!--versetest
assert_semantic_error(3509):
    SetOnDeclaration()<transacts>:void =
        set (var Z:int = 0) = 1
-->
<!-- 05 -->
```verse
X := (var Y:int = 42)      # X is 42, and Y is declared and mutable
X = 42
set Y = 43
Y = 43

# set (var Z:int = 0) = 1  # ERROR: cannot use set on a value
```

A `var` declaration cannot be the target of `set`. Since `var` declarations return their initial value as an expression result, you cannot use `set` on them - `set` requires a mutable variable, not a value.

### set with Block Expressions

The `set` statement can use block expressions, which allows complex computations and side effects:

<!--versetest-->
<!-- 06 -->
```verse
var X:int = 0
var Y:int = 1

set X = block:
    set Y = X      # Side effect: Y becomes 0
    2              # Block result: X becomes 2

X = 2 and Y = 0
```

This pattern is useful when the new value requires intermediate computations or when you need multiple side effects during assignment.

Verse evaluates the left-hand side of `set` before the block executes, and assigns the block's return value. This can lead to confusing behavior in certain cases:

<!--versetest-->
<!-- 07 -->
```verse
# Confusing: Setting the same variable inside the block
var X:int = 0
set X = block:
    set X = 5  # X temporarily becomes 5
    2          # But X will be set to 2 (the block result)
X = 2          # The inner set was overwritten!

# Confusing: Modifying index variables used in array access
var Xs:[]int = array{10, 20, 30}
var Index:int = 1
set Xs[Index] = block:
    set Index = 2  # Index changes, but does not affect which element is set
    99
Xs[1] = 99         # Element at original Index (1) was modified, not Xs[2]
Index = 2          # Index is now 2, but too late to affect the assignment
```

To avoid confusion, it is best to avoid modifying the target variable or any variables used in the target expression inside the block.

### Scope and Redeclaration Restrictions

Verse does not allow variable shadowing. Once an identifier is declared, you cannot redeclare it with `:=` anywhere in the same scope or any nested scope. This is more restrictive than many languages that allow inner scopes to shadow outer scope variables.

<!--versetest
SomeCondition:logic = false
assert_semantic_error(3653, 3653, 3532):
    SameScope()<transacts>:void =
        var Count:int = 0
        Count := 1
    NestedScope()<transacts>:void =
        var Count:int = 0
        if (false?):
            Count := 2
    NestedVarScope()<transacts>:void =
        var Count:int = 0
        if (false?):
            var Count:int = 2
-->
<!-- 08 -->
```verse
var Count:int = 0
Step:int = 1

# Count := 1             # ERROR: Count exists; write `set Count = 1` instead
# Count := Step          # ERROR: the same, though it looks like an assignment

if (SomeCondition?):
    set Count += Step
    # Count := 2         # ERROR: no shadowing, not even in a nested scope
    # var Count:int = 2  # ERROR: nor with a nested var declaration
Count = 0
```

Use `set Count = Step` to assign to an existing mutable variable. If you need multiple identifiers with similar purposes, use descriptive names (e.g., `InitialHealth`, `CurrentHealth`) or use qualified names to create separate scopes (see the [Modules and Paths](16_modules.md) chapter for details on qualified names and disambiguation).

## Deep vs Shallow Mutability

Verse's approach to mutability differs significantly between structs and classes, reflecting their different roles in the language.

### Struct Mutability: Deep and Structural

When you declare a struct variable with `var`, you are declaring the entire structure as mutable — the variable itself and all its nested fields, recursively. This deep mutability means you can modify any part of the structure tree.

<!--versetest
point := struct<computes>{X:float = 0.0, Y:float = 0.0}
assert_semantic_error(3509):
    stats15 := struct<computes>{Level:int = 1}
    ImmutableStruct()<transacts>:void =
        Stats:stats15 = stats15{}
        set Stats.Level = 2
-->
<!-- 09 -->
```verse
player_stats := struct<computes>:
    Level:int = 1
    Position:point = point{}
    Inventory:[]string = array{}

# Immutable struct variable - nothing can change
Stats1:player_stats = player_stats{}
# set Stats1.Level = 2  # ERROR: cannot modify an immutable struct

# Mutable struct variable - everything can change, however deeply nested
var Stats2:player_stats = player_stats{}
set Stats2.Level = 2
set Stats2.Position.X = 100.0
set Stats2.Inventory += array{"Sword"}

Stats2.Level = 2
Stats2.Position.X = 100.0
Stats2.Inventory = array{"Sword"}
```

When you assign one struct variable to another, Verse performs a deep copy. The two variables become independent, each with their own copy of the data. Changes to one do not affect the other.

<!--versetest
point:=struct<computes>{}
player_stats := struct<computes>:
    Level:int = 1
    Position:point = point{}
    Inventory:[]string = array{}

-->
<!-- 10 -->
```verse
var Original:player_stats = player_stats{Level := 5}
var Copy:player_stats = Original

set Copy.Level = 10
Original.Level = 5   # unchanged, they are independent copies
```

This deep-copy semantics extends to all value types: structs, arrays, maps, and tuples. When you pass a struct to a function, the function receives its own copy. When you store a struct in a container, the container holds a copy. This prevents aliasing and makes reasoning about struct mutations local and predictable.

<!--versetest-->
<!-- 11 -->
```verse
# Arrays also have value semantics - assignments create copies
var Original:[]int = array{1, 2, 3}
var Copy:[]int = Original

set Copy[0] = 999
Original[0] = 1  # unchanged, they are independent copies
Copy[0] = 999
```

### Class Mutability: Reference Semantics

Classes behave differently. They have reference semantics — when you assign a class instance, you are sharing a reference to the same object, not creating a copy. The `var` annotation on a class variable only affects whether that variable can be reassigned to reference a different object. It does not affect the mutability of the object's fields.

<!--versetest
assert_semantic_error(3509, 3509):
    gc18 := class:
        var Health:float = 100.0
        MaxHealth:float = 100.0
    ReassignNonVar()<transacts>:void =
        Player:gc18 = gc18{}
        set Player = gc18{}
    SetNonVarField()<transacts>:void =
        var Player:gc18 = gc18{}
        set Player.MaxHealth = 200.0
-->
<!-- 12 -->
```verse
game_character := class:
    Name:string = "Hero"
    var Health:float = 100.0  # This field is always mutable
    MaxHealth:float = 100.0   # This field is always immutable

# Immutable variable, but mutable fields can still change
Player1:game_character = game_character{}
# set Player1 = game_character{}  # ERROR: cannot reassign a non-var variable
set Player1.Health = 50.0

# Mutable variable allows reassignment, but not more field mutation
var Player2:game_character = Player1  # Same object
set Player2 = game_character{Name := "Villain"}
set Player2.Health = 75.0
# set Player2.MaxHealth = 200.0   # ERROR: MaxHealth is still not var

Player2.Name = "Villain"
Player2.Health = 75.0
Player1.Health = 50.0   # Untouched: Player2 now refers to another object
```

The key insight: for classes, the class definition determines field mutability at definition time, not at variable declaration time. A `var` field is always mutable, regardless of how you access it. A non-`var` field is always immutable, even if accessed through a `var` variable.

### Collection Mutability: Arrays and Maps

Arrays and maps follow struct semantics—they are values, not references. When you copy a collection, you get an independent copy. Mutations to one copy do not affect the other.

#### Basic Array Mutation

Mutable arrays allow element replacement:

<!--versetest-->
<!-- 13 -->
```verse
var Nums:[]int = array{0, 1}

set Nums[0] = 42
Nums[0] = 42
Nums[1] = 1  # Unchanged
```

You cannot add elements beyond the array's current length:

<!--versetest-->
<!-- 14 -->
```verse
var A:[]int = array{0}
not (set A[1] = 1)  # Fails - index out of bounds
# Must use concatenation: set A = A + array{1}
```

#### Basic Map Mutation

Mutable maps allow both updating existing keys and adding new keys:

<!--versetest-->
<!-- 15 -->
```verse
var Scores:[string]int = map{"Alice" => 1}

set Scores["Alice"] = 42   # Updates the existing key
set Scores["Bob"] = 100    # Adds a new key
Scores = map{"Alice" => 42, "Bob" => 100}
```

Looking up a non-existent key does not add it:

<!--versetest-->
<!-- 16 -->
```verse
M:[int]int = map{}
not (M[0] = 0)  # Key does not exist, comparison fails
M = map{}       # M is still empty, the lookup did not add the key
```

#### Deleting Keys from Maps

Verse does not have a direct "delete" or "remove" operation for maps. To remove keys, create a new map that excludes the unwanted keys by iterating over the original map:

<!--versetest-->
<!-- 17 -->
```verse
var Scores:[string]int = map{"Alice" => 100, "Bob" => 85, "Charlie" => 92}

# Remove "Bob" by creating a new map without that key
var NewScores:[string]int = map{}
for (Name->Score:Scores):
    if (Name <> "Bob"):
        set NewScores[Name] = Score

set Scores = NewScores

# Scores now only contains Alice and Charlie
Scores["Alice"] = 100
Scores["Charlie"] = 92
```

This pattern can be wrapped in a helper function for reusability. See the [Control Flow](07_control.md) chapter for more details on `for` loops.

#### Nested Collection Mutation

Collections can be nested, and `set` works through multiple levels:

<!--versetest-->
<!-- 18 -->
```verse
# A map of arrays
var Data:[int][]int = map{}
set Data[666] = array{42}      # Sets a whole array as the value of a key
set Data[666][0] = 1234        # Reaches into the nested array
Data = map{666 => array{1234}}

# An array of maps
var Grid:[][int]int = array{map{}}
set Grid[0][1234] = 4321       # Adds a key to the nested map
Grid[0] = map{1234 => 4321}

# An array of arrays
var Matrix:[][]int = array{array{1234}}
set Matrix[0][0] = 42
Matrix = array{array{42}}
```

All nested levels should exist to use `set`, if any of the higher levels do not exist, the entire set will fail.

<!--versetest-->
<!-- 19 -->
```verse
var Grid:[string][]int = map{"apples" => array{1, 2, 3, 4}}

set Grid["bananas"] = array{}      # OK - no nesting, just adds a new key
set Grid["apples"][2] = 7          # OK - changes nested element 3 to 7
not (set Grid["oranges"][0] = 10)  # Fails - the "oranges" key does not exist

Grid["apples"] = array{1, 2, 7, 4}
```

#### Value Semantics for Collections

Extracting a value from a mutable collection creates an independent copy:

<!--versetest-->
<!-- 20 -->
```verse
var X:[][int]int = array{map{42 => 1122}}

# Y gets a copy of the map, not a reference
Y := X[0]

set X[0][0] = 111
X[0] = map{42 => 1122, 0 => 111}
Y = map{42 => 1122}    # Unchanged

set X[0] = map{42 => 4242}  # Replacing the element does not affect Y either
Y = map{42 => 1122}
```

This is different from class reference semantics—collections copy, classes share.

#### Collections with Mutable Values

When collections contain classes or structs with mutable fields, you can mutate through the collection:

<!--versetest
my_class := class:
    var X:[]int = array{0}
-->
<!-- 21 -->
```verse
C := my_class{}
set C.X[0] = 42        # Through a var field that is itself a collection
C.X[0] = 42

var M:[int]my_class = map{0 => C}
set M[0].X[0] = 99     # Through a collection, into a var field
C.X[0] = 99            # The map holds the same object, not a copy of it
```

A map of a value type behaves differently: constructed from a `var`, it does not track changes to the source variable:

<!--versetest-->
<!-- 22 -->
```verse
var I:int = 42
M:[int]int = map{0 => I}
M[0] = 42

set I = 0
M[0] = 42  # Still 42! Map has a copy of the value
```

### Arrays of Structs: Independent Copies

When you store structs in an array, each element is an independent copy:

<!--versetest
my_struct := struct<computes>:
    I:int = 10
-->
<!-- 23 -->
```verse
S := my_struct{I := 88}
var A:[]my_struct = array{S, S}   # All three start out at 88

# Mutating one does not affect the others
set A[0].I = 99
A[0].I = 99  # Changed
A[1].I = 88  # Unchanged
S.I = 88     # Unchanged
```

### Arrays of Classes: Shared References

Arrays of classes behave very differently—all references to the same object share mutations:

<!--versetest
my_class := class:
    var I:int = 20
-->
<!-- 24 -->
```verse
C := my_class{}
var A:[]my_class = array{C, C}   # Both elements reference the same object

# Mutating through one affects every reference
set A[0].I = 30
A[1].I = 30  # Changed!
C.I = 30     # Changed here too

# Replacing an element breaks the sharing for that element
set A[1] = my_class{}
A[0].I = 30  # Still the original object
A[1].I = 20  # A new object with the default value
```

This is a critical distinction: **structs in collections are copies, classes in collections are shared references**.

### Compound Assignment Operators

Verse supports compound assignment operators that combine arithmetic with mutation:

<!--versetest
my_struct:= struct<computes>:
    A:int = 10
-->
<!-- 25 -->
```verse
var S:my_struct = my_struct{}

set S.A += 10
S.A = 20

set S.A -= 3
S.A = 17

set S.A *= 4
S.A = 68
```

Available compound operators:

- `set += ` - Addition assignment (int, float, string, array)
- `set -= ` - Subtraction assignment (int, float)
- `set *= ` - Multiplication assignment (int, float)
- `set /= ` - Division assignment (float only)

Do note that `set /=` does not work with integers because integer division is failable.

Compound assignments work anywhere regular assignment does:

<!--versetest-->
<!-- 26 -->
```verse
var Score:int = 100
set Score += 50
set Score *= 2
Score = 300

var Data:[]int = array{1, 2, 3}
set Data += array{4, 5}  # Array concatenation
Data = array{1, 2, 3, 4, 5}

var Nums:[][]int = array{array{1}}
set Nums[0][0] *= 42
Nums[0][0] = 42
```

Array concatenation with `+=` works on struct fields, nested fields,
and collection values, just like regular `set` does:

<!--versetest-->
<!-- 27 -->
```verse
my_struct := struct<computes>:
    X:[]int = array{}

my_nested := struct<computes>:
    Inner:my_struct = my_struct{}

# Append to a struct field
var S:my_struct = my_struct{}
set S.X += array{1, 2, 3}
S.X = array{1, 2, 3}

# Append to a nested struct field
var N:my_nested = my_nested{}
set N.Inner.X += array{10, 20}
N.Inner.X = array{10, 20}

# Append to a map value
var M:[int][]int = map{}
set M[42] = array{}
set M[42] += array{1}
set M[42] += array{2}
M[42] = array{1, 2}
```

### Mutating Parametric Containers

Compound assignment works when the element type is a class type parameter, so
generic containers can be written without special-casing:

<!--versetest-->
<!-- 28 -->
```verse
queue(t:type) := class:
    var Contents<private>:[]t = ()

    Push<public>(Arg:t)<transacts>:void =
        set Contents += array. Arg          # polymorphic +=

    Pop<public>()<transacts><decides>:t =
        Result := Contents[Contents.Length - 1]
        set Contents = for (Key->Val:Contents; Key <> Contents.Length - 1). Val
        Result

Q := queue(int){}
Q.Push(1)
Q.Push(2)
Q.Pop[] = 2
Q.Pop[] = 1
not Q.Pop[]   # the queue is empty again
```

Assignment into an element of a parametric container also works:
`set X.Contents[0] = ...`.

### Tuple Mutability: Replacement Only

Tuples can be replaced entirely but individual elements cannot be mutated:

<!--versetest
assert_semantic_error(3509):
    MutateTupleElement()<transacts>:void =
        var T:tuple(int, int) = (10, 20)
        set T(0) = 70
-->
<!-- 29 -->
```verse
var T:tuple(int, int) = (10, 20)

# The whole tuple can be replaced
set T = (30, 40)
T(0) = 30
T(1) = 40

# set T(0) = 70  # ERROR: tuple elements cannot be mutated
```

This restriction applies even when the tuple is mutable. You must replace the entire tuple to change its contents.

### Map Ordering and Mutation

Maps preserve **insertion order**, and this order is maintained through mutations:

#### New Keys Append to End

<!--versetest-->
<!-- 30 -->
```verse
var M:[int]int = map{2 => 2}

set M[1] = 1  # Appends to end
set M[0] = 0  # Appends to end

# Iteration follows insertion order, not key order
Keys := for (Key->Value : M). Key
Keys = array{2, 1, 0}
```

#### Updating Existing Keys Preserves Position

Map equality considers both keys/values **and order**, which is what makes the
position of an updated key observable:

<!--versetest-->
<!-- 31 -->
```verse
var M:[string]int = map{"a" => 3, "b" => 1, "c" => 2}

# Mutating a value keeps the key in place
set M["a"] = 0
M = map{"a" => 0, "b" => 1, "c" => 2}   # Same keys, values and order: equal

# The same pairs in another order are a different map
M <> map{"b" => 1, "c" => 2, "a" => 0}
```

## Critical Mutability Restrictions

Verse imposes several important restrictions on where and how mutation can occur. These are not arbitrary—they prevent unsound behaviors and maintain type safety.

### Cannot Mutate Immutable Class Fields

Classes might contain unique pointers or other resources that cannot be safely cloned. Therefore, you cannot mutate immutable fields of a class instance:

<!--versetest
assert_semantic_error(3509):
    classX := class{X:int = 20}
    MutateImmutableField()<transacts>:void =
        var C:classX = classX{}
        set C.X = 30
-->
<!-- 32 -->
```verse
classX := class:
    X:int = 20         # No var, so immutable for the life of the object

var C:classX = classX{}
set C = classX{}       # OK: the variable can be pointed at another instance
# set C.X = 30         # ERROR: the field itself still cannot be mutated
C.X = 20
```

This restriction applies even when the class instance itself is mutable. Only `var` fields of classes can be mutated.

### Only <computes> Structs Allow Field Mutation

Only structs marked `<computes>` (pure structs) allow field mutation through a variable:

<!--versetest
assert_semantic_error(3509):
    effectful_struct := struct{M:int = 0}
    MutateEffectfulStruct()<transacts>:void =
        var S:effectful_struct = effectful_struct{}
        set S.M = 1
-->
<!-- 33 -->
```verse
my_mutable_struct := struct<computes>{M:int = 0, J:float = 3.0}
# my_mutable_struct := struct{M:int = 0}  # ERROR on the set below: not <computes>

var S:my_mutable_struct = my_mutable_struct{}
Old := S      # Makes a copy of the struct

set S.M = 1   # Makes a copy of the struct, but updates `M` in the process

S.M = 1
not (Old = S) # Structs do not pass as references
```

When a new struct is constructed, Verse assigns it the updated value and copies other fields.
If there are other places referencing the old struct, they will not have the updated values (unlike classes).

This restriction ensures that only predictable, effect-free structs can be mutated.

### Cannot Mutate Through Immutable Class Fields

When mutating nested structures, you cannot mutate through an immutable field of a class (a field not declared with `var`):

<!--versetest
assert_semantic_error(3509):
    inner46 := struct<computes>{Value:int = 0}
    locked46 := class{Data:inner46 = inner46{}}
    box46 := struct<computes>{L:locked46}
    MutateThroughImmutableField()<transacts>:void =
        var B:box46 = box46{L := locked46{}}
        set B.L.Data.Value = 10
-->
<!-- 34 -->
```verse
inner := struct<computes>{Value:int = 0}
locked := class{Data:inner = inner{}}        # Immutable field
unlocked := class{var Data:inner = inner{}}  # Mutable field
box := struct<computes>{L:locked, U:unlocked}

var B:box = box{L := locked{}, U := unlocked{}}
set B.U.Data.Value = 10       # OK: the path runs through a var field
# set B.L.Data.Value = 10     # ERROR: L.Data is not declared with var
B.U.Data.Value = 10
```

The error occurs because `L.Data` is an immutable field (not declared with `var`). The mutation path must be `var` all the way down, however deeply nested it is.

Mutability of the index is a separate matter, and does not help: it is the array that must be `var` to allow element mutation.

<!--versetest
assert_semantic_error(3509):
    MutateImmutableArray()<transacts><decides>:void =
        var I:int = 2
        A:[]int = array{5, 6, 7}
        set A[I] = 2
-->
<!-- 35 -->
```verse
var I:int = 2                 # A mutable index changes nothing
var A:[]int = array{5, 6, 7}
set A[I] = 42
A[2] = 42

# B:[]int = array{5, 6, 7}
# set B[I] = 42  # ERROR: B is not var, so no element of it can be mutated
```

## Identity and Uniqueness

The `<unique>` specifier gives classes identity-based equality. Without it, classes can't be compared for equality at all (you'd need to write custom comparison methods). With it, equality means identity — two references are equal only if they refer to the exact same object.

<!--versetest-->
<!-- 36 -->
```verse
unique_item := class<unique>:
    var Count:int = 0

Item1:unique_item = unique_item{}
Item2:unique_item = Item1          # Same object
Item3:unique_item = unique_item{}  # Different object, identical contents

Item1 = Item2
not (Item1 = Item3)
```

This identity-based equality is crucial for game objects that need distinct identities even when their data is identical. Two monsters might have the same stats, but they are still different monsters.
