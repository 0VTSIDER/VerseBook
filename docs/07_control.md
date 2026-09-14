# Control Flow

Control flow in Verse is built from expressions rather than
statements: `if`, `case`, `loop`, `for`, `first`, and `block` all
produce values, so any of them can be used where a value is expected.
This chapter covers each of those, along with `return` and `defer`.

## Blocks

A code block is a fundamental organizational unit, it groups related
expressions together and creates a new scope for variables and
constants. Unlike many languages where blocks are merely syntactic
conveniences, blocks are expressions themselves, meaning they produce
values just like any other expression.

The concept of scope is crucial to understanding code blocks. When you
create a variable or constant within a block, it exists only within
that block's context. This containment ensures that your code remains
organized and that names do not accidentally conflict across different
parts of your program. Consider this function, it is body is a code
block that contains one if-then-else expression, itself
composed of three different code blocks.

<!--versetest-->
<!-- 01 -->
```verse
CalculateReward(PlayerLevel:int)<reads>:int =
    if:
        PlayerLevel > 10
        Multiplier := 2.0  # Only exists within this if block
        Base := 100
        Result := Floor[(Base+PlayerLevel) * Multiplier] # Fails on infinity
    then:
        Result  # This block extends the scope of the if
    else:
        50      # Different branch, different scope
                # Multiplier and Result do not exist here
```
<!-- CalculateReward(11) = 222 -->

Verse has a flexible syntax with three equivalent formats for
writing blocks. The spaced format is the most common, using a colon to
introduce the block and indentation to show structure:

<!--versetest
IsPlayerReady()<decides><transacts>:void = {}
StartMatch()<transacts>:void = {}
BeginCountdown()<transacts>:void = {}
-->
<!-- 02 -->
```verse
if (IsPlayerReady[]):
    StartMatch()
    BeginCountdown()
```

The multi-line braced format offers familiarity for programmers coming
from C-style languages:

<!--versetest
IsPlayerReady()<decides><transacts>:void = {}
StartMatch()<transacts>:void = {}
BeginCountdown()<transacts>:void = {}
-->
<!-- 03 -->
```verse
if (IsPlayerReady[]) {
    StartMatch()
    BeginCountdown()
}
```

For simple operations, the single-line dot format keeps code concise:

<!--versetest
HasPowerup()<computes><decides>:void={}
ApplyBoost():void={}
-->
<!-- 04 -->
```verse
if (HasPowerup[]). ApplyBoost()
```

Since everything is an expression, blocks themselves have values. The
value of a block is given by the last expression executed within
it. This enables elegant patterns where complex computations can be
encapsulated in blocks that seamlessly integrate with surrounding
code:

<!--versetest
CalculateScore()<computes>:int = 100
CalculateBonus(Time:float)<computes>:int = 50
CompletionTime:float = 10.0
AccuracyValue:float = 0.95
-->
<!-- 05 -->
```verse
FinalScore := block:              # The variable has the block's value
    Base := CalculateScore()
    Bonus := CalculateBonus(CompletionTime)
    Accuracy := Floor[AccuracyValue * 100.0]
    Base + Bonus + Accuracy       # This becomes the block's value

FinalScore = 245
```


## If Expressions

The `if` expression uses success and failure to drive decisions (see
[Failure](08_failure.md) for details). When an expression in the
condition succeeds, the corresponding branch executes:

<!--versetest
player := class:
   CanJump()<computes><decides>:void={}
   Jump()<computes>:void={}
   GetEquippedWeapon()<computes><decides>:weapon=weapon{}
   Idle()<computes>:void={}

weapon:=class<computes>{
   Fire():void={}
}
ConsumeAmmo():void={}
PlayJumpSound():void={}
-->
<!-- 06 -->
```verse
HandlePlayerAction(Player:player, Action:string):void =
    if (Action = "jump", Player.CanJump[]):
        Player.Jump()
        PlayJumpSound()
    else if (Action = "attack", Weapon := Player.GetEquippedWeapon[]):
        Weapon.Fire()
        ConsumeAmmo()
    else:
        # Default action
        Player.Idle()
```

This approach allows you to chain conditions that might fail without
explicit error handling at each step.

An alternative syntax uses `then:` and `else:` keywords to explicitly
label branches:

<!--versetest-->
<!-- 07 -->
```verse
ProcessValue(Value:int):string =
    if:
        Value > 0
        Value < 100
    then:
        "Valid"
    else:
        "Out of range"

ProcessValue(50) = "Valid"
```

This syntax can improve readability when you have multiple conditions
or want to emphasize the condition-action separation. 

The condition in an `if` must contain at least one expression that can
fail. This requirement ensures `if` is used for its intended
purpose, handling uncertain outcomes:

<!--versetest
Items:[]int = array{1, 2, 3}
Process(X:int):void = {}
assert_semantic_error(3513):
    DoSomething():void = {}
    NoFallibleCondition():void =
        if (1 + 1):
            DoSomething()
assert:
    if (FirstItem := Items[0]):
        Process(FirstItem)
<#
-->
<!-- 08 -->
```verse
# Error: condition cannot fail
if (1 + 1):
    DoSomething()

# Valid: array access can fail
if (FirstItem := Items[0]):
    Process(FirstItem)
```
<!-- #> -->

Empty conditions are also not allowed: every `if` must test something.

If any expression in the condition fails, control flow proceeds to the
`else` branch if present. Any effects performed while evaluating the
condition are automatically rolled back (see
[Failure](08_failure.md#speculative-execution) for details):

<!--versetest-->
<!-- 09 -->
```verse
var Attempts:int = 0

TryScore(Score:int)<transacts>:logic =
    if:
        set Attempts += 1  # Provisional change
        Score > 100        # Might fail
    then:
        true
    else:
        false

TryScore(200)?      # Condition succeeded
Attempts = 1        # The increment was kept
not TryScore(50)?   # Condition failed
Attempts = 1        # The increment was rolled back - undone!
```

This speculative execution makes conditional logic safer. You can
perform operations optimistically, knowing they'll be reversed if
subsequent conditions fail.

Variables defined in the condition are available in the `then` branch
but not in the `else` branch:

<!--versetest
assert_semantic_error(3506):
    FindPlayer(N:string)<computes><decides>:int = 1
    AwardBonus(P:int):void = {}
    Penalize(P:int):void = {}
    ElseCannotSeeBinding(Name:string):void =
        if:
            Player := FindPlayer[Name]  # Define Player
        then:
            AwardBonus(Player)  # OK - Player available
        else:
            Penalize(Player)  # Compile error
<#
-->
<!-- 10 -->
```verse
if:
    Player := FindPlayer[Name]  # Define Player
then:
    AwardBonus(Player)  # OK - Player available
else:
    Penalize(Player)  # Compile error
```
<!-- #> -->

This scoping reflects the logical flow: in the `else` branch, the
condition failed, so any variables bound during the condition might
not have meaningful values.

Since `if` is an expression, it produces a value. When all branches
return compatible types, the `if` can be used anywhere a value is
expected:

<!--versetest
IsCritical:logic = true
BaseDamage:int = 10
Health:int = 100
-->
<!-- 11 -->
```verse
Damage := if (IsCritical?):
    BaseDamage * 2
else:
    BaseDamage
Damage = 20

# Ternary-style
Status := if (Health > 50). "Healthy" else. "Wounded"
Status = "Healthy"
```

When branches have incompatible types, the result is widened to `any`:

<!--versetest
UseNumber:logic=false
-->
<!-- 12 -->
```verse
# Different types in branches yields any
Result:any = if (UseNumber?) then 42 else "text"
```

All branches must produce a value for the `if` to be used as an
expression.

### Handling Only Failures

A common pattern is to handle only the failure case of a `<decides>`
expression, letting success continue without additional logic. The
idiomatic way to express this is with `if (Condition): else:`:

<!--versetest-->
<!-- 13 -->
```verse
var Attempts:int = 0

ProcessData()<decides><transacts>:void =
    set Attempts += 1

if (ProcessData[]):
    # Success - no additional logic needed
else:
    # Handle the failure case
    Print("Processing failed")

Attempts = 1  # Effect preserved
```

When the condition succeeds, execution continues after the `if`
statement. When it fails, the `else` block handles the error. This
pattern is clearer than alternatives that might seem equivalent but
behave differently.

A tempting but sometimes incorrect
pattern is to use `not` to check for failure:

<!--versetest-->
<!-- 14 -->
```verse
var Attempts:int = 0

ProcessData()<decides><transacts>:void =
    set Attempts += 1

# Causes unwanted rollback
if (not ProcessData[]):
    Print("Processing failed")

Attempts = 0  # The successful increment was undone
```

This fails because when `ProcessData[]` succeeds, `not true` fails,
causing the outer `if` to fail and roll back any transactional effects
from `ProcessData`. The other safe pattern converts the failure into a
boolean with `logic{}`:

<!--versetest-->
<!-- 15 -->
```verse
var Attempts:int = 0

ProcessData()<decides><transacts>:void =
    set Attempts += 1

Succeeded := logic{ProcessData[]}  # Bound before the if
if (not Succeeded?):
    Print("Processing failed")

Attempts = 1  # Effect preserved
```

The `logic{}` conversion has to be bound before the `if`. Inlining it
into the condition puts it back inside a condition that fails, so the
effect is rolled back after all.

## Case Expressions

When you need to make decisions based on multiple possible values, the
`case` expression provides clear, readable branching:

<!--versetest-->
<!-- 16 -->
```verse
GetWeaponDamage(WeaponType:string):float =
    case(WeaponType):
        "sword"  => 50.0
        "bow"    => 35.0
        "staff"  => 40.0
        "dagger" => 25.0
        _        => 10.0  # Default damage for unknown weapons

GetWeaponDamage("sword") = 50.0
```

The `case` expression is used when you have discrete values to match
against, making your intent clearer than a series of `if-else`
conditions.

Case expressions work with specific types that support direct value
comparison:

- **Primitives**: `int`, `logic`, `char`
- **Strings**: `string`
- **Enums**: Both open and closed enums
- **Refinement types**: Custom types with constraints

They do not work on `float`, objects and tuples due to implementation
limitations.

### Exhaustiveness Checking with Enums

Case expressions over enums are checked for exhaustiveness.  For closed
enums where all values are known, the compiler verifies you've handled
all cases:

<!--versetest
direction := enum:
    North
    South
    East
    West
-->
<!-- 17 -->
```verse
# Exhaustive - no wildcard needed
GetVector(Dir:direction):tuple(int, int) =
    case (Dir):
        direction.North => (0, 1)
        direction.South => (0, -1)
        direction.East => (1, 0)
        direction.West => (-1, 0)

GetVector(direction.North) = (0, 1)
```

If you add a wildcard when all cases are covered, you'll get a warning
that the wildcard is unreachable:

<!--versetest
coin := enum{ Heads, Tails }
-->
<!-- 18 -->
```verse
Score(C:coin):int =
    case (C):
        coin.Heads => 1
        coin.Tails => 0
        _ => -1  # Warning: all cases already covered

Score(coin.Heads) = 1
```

Incomplete case coverage is allowed in a `<decides>` context:

<!--versetest
direction := enum{ North, South, East, West }
-->
<!-- 19 -->
```verse
# Without wildcard in <decides> context - OK
PrimaryDirection(Dir:direction)<transacts><decides>:string =
    case (Dir):
        direction.North => "Primary"
        # Other directions cause function to fail

PrimaryDirection[direction.North] = "Primary"
not PrimaryDirection[direction.South]
```

Open enums can have values added after publication, so they can never
be exhaustive. They always require either a wildcard or a `<decides>`
context.

## Loop Expressions

The `loop` expression creates an infinite loop that continues until
explicitly broken:

<!--versetest
UpdatePlayerPositions()<transacts>:void={}
CheckCollisions()<transacts>:void={}
RenderFrame()<transacts>:void={}
GameOver()<decides><transacts>:void={}
-->
<!-- 20 -->
```verse
GameLoop():void =
    loop:
        UpdatePlayerPositions()
        CheckCollisions()
        RenderFrame()
        if (GameOver[]). break
```

The `break` expression exits the loop entirely, terminating iteration.
`break` has "bottom" type, a type that represents a computation that
never returns normally. Since the bottom type is a subtype of all
other types, `break` can be used in any type context:

<!--versetest-->
<!-- 21 -->
```verse
NumberOfBits(X:int):int =
    var B:int = 1
    var C:int = 0
    loop:
        set B = if (B > X) { break } else { 2*B }
        set C = C+1
    C

NumberOfBits(8) = 4
NumberOfBits(0) = 0
```

This demonstrates bottom type: `break` unifies with `int` (from `2*B`)
in the if-expression. The assignment `set B = ...` uses the value of
the if-expression, showing that `break` is compatible in any type context.

The loop expression itself produces a value of type
`true`, regardless of what expressions appear in its body.
This return value is rarely useful in practice; loops are typically used for
their side effects.

When `break` appears in nested loops, it exits only the innermost
enclosing loop:

<!--versetest-->
<!-- 22 -->
```verse
var Outer:int = 0
loop:
    set Outer += 1
    var Inner:int = 0
    loop:
        set Inner += 1
        if (Inner = 5):
            break        # Exits inner loop
    if (Outer = 10):
        break            # Exits outer loop
Outer = 10
```

The following restrictions apply. The `break` statement must appear in
a code block, not as part of a complex expression.  A loop must
contain at least one non-break statement. Finally, using `break`
outside a `loop` produces an error:

<!--versetest
assert_semantic_error(3581):
    ShouldStop()<computes><decides>:void={}
    ProcessData():void =
        if (ShouldStop[]):
            break      # Error
<#
-->
<!-- 23 -->
```verse
ProcessData():void =
    if (ShouldStop[]):
        break      # Error
```
<!-- #> -->

## For Expressions

The `for` expression iterates over collections, ranges, and other
iterable types, providing a more structured approach to repetition:

<!--versetest
player:=class{}
GetScore(P:player)<transacts>:int=100
-->
<!-- 24 -->
```verse
CalculateTotalScore(Players:[]player)<transacts>:int =
    var Total:int = 0
    for (Player : Players):
        PlayerScore := GetScore(Player)
        set Total += PlayerScore
    Total

CalculateTotalScore(array{player{}, player{}}) = 200
```

While it may look familiar from earlier imperative languages, `for` is
best thought of as a functional construct that combines iteration,
filtering with speculative execution, and construction of a collection
of results.

<!--versetest-->
<!-- 25 -->
```verse
Values:[]float= array{1.0, 10.1, 100.2}
Result := 
   for:
      V : Values
      V >= 10.0
      R := Floor[V]
   do:
      R*2.0

Result = array{20.0, 200.0}
```

The above is written with an alternative multi-clause syntax using the
`do:` keyword to  separate the iteration specification  from the body.
The `for` iterates  over the `Values` array,  discarding values smaller
than 10  and rounding down  numbers. It  returns an array  of floats.
The `Floor` function is defined as `decides` --if it were to fail that
iteration would be discarded.

There is another alternative syntax: the single-line dot syntax for
simple operations:

<!--versetest
Values:[]int = array{1, 2, 3}
DoSomething(V:int):void = {}
-->
<!-- 26 -->
```verse
# Single-line dot style
for (V : Values). DoSomething(V)
```

### Index and Value Pairs

When iterating arrays or maps, you can access both the index/key and the value
using the pair syntax `Index -> Value` or `Key -> Value`:

<!--versetest
player:=struct{ Name:string }
-->
<!-- 27 -->
```verse
Roster(Players:[]player):[]string =
    for (Index -> Player : Players):
        "Player {Index}: {Player.Name}"

Roster(array{player{Name:="Ada"}, player{Name:="Bo"}}) =
    array{"Player 0: Ada", "Player 1: Bo"}
```

The index is zero-based, matching Verse's array indexing convention.

### Defining Variables in For Clauses

The for loop allows you to define intermediate variables that can be
used in subsequent filters or the loop body:

<!--versetest-->
<!-- 28 -->
```verse
# Define Y based on X
Doubled := for (X := 1..5, Y := X * 2):
    Y
Doubled = array{2, 4, 6, 8, 10}

# Combine with filtering
SafeDivision := for (X := -3..3, X <> 0, Y := Floor[10.0 / (X*1.0)]):
    Y  # Skips X=0
SafeDivision = array{-4, -5, -10, 10, 5, 3}
```

These intermediate variables are scoped to the iteration and can
reference earlier variables in the same clause.

### Multiple Filters

You can chain multiple filter conditions using comma-separated or
semicolon-separated expressions. Each filter must be failable, and if any fails, that
iteration is skipped:

<!--versetest-->
<!-- 29 -->
```verse
Filtered := for (X := 1..10; X <> 3; X <> 7):
    X
Filtered = array{1, 2, 4, 5, 6, 8, 9, 10}
```

Each filter condition is evaluated in order, and iteration continues
only if all conditions succeed. The two separators cannot be mixed
within one clause list.

### Iterating Over Maps

Maps can be iterated over in two ways: values only, or key-value pairs
using the pair syntax:

<!--versetest-->
<!-- 30 -->
```verse
# Iterate over values only
Scores:[int]int = map{1 => 100, 2 => 200, 3 => 150}
for (Score : Scores) { Score } = array{100, 200, 150}

# Iterate over key-value pairs
Ranking:[string]int = map{"Alice" => 100, "Bob" => 200}
for (Name -> Score : Ranking) { "{Name} scored {Score}" } =
    array{"Alice scored 100", "Bob scored 200"}
```

Maps preserve insertion order, so iteration order matches the order in
which keys were added to the map.

### String Iteration

Strings can be iterated character by character:

<!--versetest-->
<!-- 31 -->
```verse
CountVowels(Text:string):int =
    var Count:int = 0
    for (Char : Text, Char = 'a' or Char = 'e' or Char = 'i' or Char = 'o' or Char = 'u'):
        set Count += 1
    Count

CountVowels("education") = 5
```

### Nested Iteration

Multiple iteration sources create nested loops, producing the cartesian product:

<!--versetest-->
<!-- 32 -->
```verse
Cells := for (X := 1..3, Y := 1..3):
    X*10 + Y
Cells = array{11, 12, 13, 21, 22, 23, 31, 32, 33}
```

### Filtering with Failure

Verse's `for` expressions are particularly powerful when they leverage
failure contexts, as they can naturally filter:

<!--versetest
player:=struct{ Name:string, Score:int }
-->
<!-- 33 -->
```verse
GetHighScorers(Players:[]player):[]player =
    for (Player : Players, Player.Score > 1000):
        Player  # Only players with score > 1000 are included

Best := GetHighScorers(array{player{Name:="Ada", Score:=2000},
                             player{Name:="Bo", Score:=100}})
for (P : Best) { P.Name } = array{"Ada"}
```

When any expression in the iteration header fails, that iteration is
skipped. This allows elegant filtering without explicit `if`
statements.

### For as an Expression

Like other control flow constructs, `for` is an expression. When the body produces values, `for` collects them into an array:

<!--versetest
player:=struct{Name:string}
-->
<!-- 34 -->
```verse
# Collect player names
GetNames(Players:[]player):[]string =
    for (Player : Players):
        Player.Name  # Each iteration produces a string

GetNames(array{player{Name:="Ada"}, player{Name:="Bo"}}) = array{"Ada", "Bo"}
```

This makes `for` a powerful tool for transforming collections without
explicit accumulator variables.

The `break` statement cannot exit `for` loops early. If you need only the
first matching result from an iteration, use `first` instead of `for`
(see [First Expressions](#first-expressions) below).

Unlike many languages, Verse does not currently support a `continue`
statement to skip to the next iteration. Instead, use conditional
logic or failure-based filtering to achieve similar results:

<!--versetest
item:=struct{IsValid:logic}
ProcessItem(I:item):void={}
-->
<!-- 35 -->
```verse
# Instead of continue, use conditional blocks
ProcessItems(Items:[]item):void =
    for (Item : Items):
        if (Item.IsValid?):
            ProcessItem(Item)
        # No continue needed - just structure with conditions

# Or use failure-based filtering in the header
ProcessValidItems(Items:[]item):void =
    for (Item : Items, Item.IsValid?):
        ProcessItem(Item)  # Only valid items reach here
```


### Range Iteration

The range operator `..` provides numeric
iteration over integer sequences. Ranges are inclusive on both ends:

<!--versetest-->
<!-- 36 -->
```verse
for (N := 1..5)   { N } = array{1, 2, 3, 4, 5}  # Both bounds included
for (N := 42..42) { N } = array{42}             # Single element range
for (N := 5..1)   { N } = array{}               # Start > end: no iterations
```

The `..` operator is always inclusive. There is no exclusive range
syntax.

Range bounds are evaluated in a specific order, and side effects occur
predictably:

1. **Left bound evaluated first**, then right bound
2. **Both bounds always evaluated**, even if the range is empty
3. **Side effects happen in order**, regardless of whether iterations occur

While you cannot store ranges as values, you can create arrays using
for expressions:

<!--versetest-->
<!-- 37 -->
```verse
# This works because for produces an array, not because ranges are storable
Squares:[]int = for (X := 1..5){ X * X }
Squares = array{1, 4, 9, 16, 25}
```

The range exists only during the for expression evaluation; the
resulting array is what gets stored.

### Restrictions

The for loop has several important restrictions:

1. **Iteration source must be iterable:** Only ranges (`1..10`),
   arrays, maps, and strings can be iterated. 

2. **Filters must be failable:** Filter conditions must contain at
   least one expression that can fail. 

3. **Cannot redefine iteration variables:** You cannot redefine the
   iteration variable in the same clause.

4. **Cannot define mutable variables:** Using `var` to declare
   variables in the for clause is not allowed.

The range operator `..` has strict limitations that distinguish it
from other iterable types. Ranges are *not first-class values*. They
are expressions that iteratively yield each integer in the range as a
separate value. Ranges cannot be used in some contexts where you
might expect them to work:

<!--versetest
assert_semantic_error(3552):
    StoreRange():void =
        MyRange := 1..10
assert_semantic_error(3552, 3509):
    PassRange():void =
        ProcessRange(X:int):void = {}
        ProcessRange(1..10)
assert_semantic_error(3552):
    RangeInArray():void =
        Ranges := array{1..10}
<#
-->
<!-- 38 -->
```verse
# ERROR: Cannot store a range in a variable
MyRange := 1..10

# ERROR: Cannot pass a range to a function
ProcessRange(1..10)

# ERROR: Cannot put a range in an array
Ranges := array{1..10}
```
<!-- #> -->

Every one of these reports the same error 3552: ranges are only
supported as the iterated expression of `for`, `sync`, `rush`, or
`race`. Indexing a range or reading a member off one fails the same
way.

Ranges work exclusively with the `int` type. Other numeric types,
booleans, types, or objects are not supported.

### For Without a Generator

A `for` domain does not have to contain a generator. If it contains only
failable expressions, the `for` behaves like the equivalent `if (X := Y)` chain:
the body runs **at most once**, and if any domain expression fails the body does
not run at all. The result is therefore an empty or single-element array.

<!--versetest-->
<!-- 39 -->
```verse
Some:?int = option{7}
for(Some?) { 1 } = array{1}   # Filter succeeded, body ran once

None:?int = false
for(None?) { 1 } = array{}    # Filter failed, body never ran
```

### Failable Filters Before a Generator

A failable filter or binding may also precede a generator. A binding made this
way is visible to the generator that follows it, and if the binding fails the
generator is never evaluated:

<!--versetest
GetThing()<transacts><decides>:int = 2
PassesFilter()<transacts><decides>:void = {}
-->
<!-- 40 -->
```verse
# A failable call used purely as a guard
for(PassesFilter[], N:=1..3) { N } = array{1,2,3}

# A failable binding that feeds the generator
for(Thing := GetThing[], N:=Thing..Thing+2) { Thing*10+N } = array{22,23,24}
```

## First Expressions

The `first` expression is similar to `for`, but instead of evaluating
the body for every iteration of the domain clause, it evaluates only
the **first** iteration of the domain clause that succeeds. Instead
of yielding an array as `for` does, it yields the value of the body
for that single iteration. If no iteration reaches the body, `first`
fails, so it requires a `<decides>` context.

<!--versetest
player:=struct{ Name:string, Score:int }
GetScore(P:player)<computes><decides>:int = P.Score
-->
<!-- 41 -->
```verse
# Find the first player with a score above the threshold
FindTopScorer(Players:[]player, Threshold:int)<transacts><decides>:player =
    first (Player : Players; GetScore[Player] > Threshold):
        Player

Roster := array{player{Name:="Ada", Score:=10}, player{Name:="Bo", Score:=99}}
FindTopScorer[Roster, 50].Name = "Bo"
not FindTopScorer[Roster, 100]
```

Like `for`, the `first` expression supports three syntax forms.
The block form uses `do:` to separate the iteration clauses from
the body:

<!--versetest
Collection:[]int = array{1, 2, 3}
Predicate(X:int)<computes><decides>:void = { X > 1 }
Process(X:int)<computes>:int = X * 10
-->
<!-- 42 -->
```verse
# Block form with do:
FirstMatch := first:
    X : Collection
    Predicate[X]
do:
    Process(X)
FirstMatch = 20

# Braces form
first(X : Collection; Predicate[X]){ Process(X) } = 20

# Dot form for single expressions
first(X : Collection; Predicate[X]). Process(X) = 20
```

The `first` expression uses the same binding syntax as `for`. You
can iterate arrays, maps, strings, and ranges. You can use index-value
pairs with the `->` syntax, chain multiple filters, and nest multiple
iteration sources:

<!--versetest-->
<!-- 43 -->
```verse
# Find the index of an element using index -> value binding
IndexOf(Arr:[]int, Target:int)<transacts><decides>:int =
    first(I -> V : Arr, V = Target). I

IndexOf[array{5, 6, 7}, 7] = 2
not IndexOf[array{5, 6, 7}, 9]
```

Note that `first` yields the value of the **body** expression, not the
iteration variable. This is what makes it possible to search for one
thing and yield another: finding an index by matching a
value.

Here is how the two constructs compare:

| | `for` | `first` |
|-|-------|---------|
| Yields | Array of all results | First result only |
| On no match | Empty array | **Fails** (requires `<decides>`) |
| Stops | After all iterations | After the first iteration |

Since `first` requires `<decides>`, a common way to use it is to wrap
it in an `if` or an `option` to handle the case where no match is found:

<!--versetest-->
<!-- 44 -->
```verse
# Find with fallback using if
FindOrDefault(Arr:[]int, Target:int)<transacts>:int =
    if (Index := first(I -> V : Arr, V = Target). I):
        Index
    else:
        -1

# Find with fallback using option
FindOptional(Arr:[]int, Target:int)<transacts>:?int =
    option:
        first(I -> V : Arr, V = Target). I

FindOrDefault(array{5, 6, 7}, 9) = -1
FindOptional(array{5, 6, 7}, 7)? = 2
```

### First With Failable Filters

`first` accepts the same failable filters and bindings before a generator. The
difference is the outcome when a binding fails: `for` yields an empty array,
whereas `first` *fails*.

<!--versetest
GetThing()<transacts><decides>:int = 2
GetNoThing()<transacts><decides>:int =
    0 = 1
    0
-->
<!-- 45 -->
```verse
# Binding succeeds - first yields the first body value
first(Thing := GetThing[], N:=Thing..Thing+2) { Thing*10+N } = 22

# Binding fails - the whole `first` fails
not first(Thing := GetNoThing[]; N:=Thing..Thing+2) { Thing*10+N }
```

## Return Statements

The `return` statement provides explicit early exits from functions,
allowing you to terminate execution and return a value before reaching
the end of the function body:

<!--versetest-->
<!-- 46 -->
```verse
ValidateInput(Value:int):string =
    if (Value < 0):
        return "Error: Negative value"

    if (Value > 1000):
        return "Error: Value too large"

    "Valid"     # Implicit return

ValidateInput(-1) = "Error: Negative value"
ValidateInput(5000) = "Error: Value too large"
ValidateInput(50) = "Valid"
```

Return statements can only appear in specific positions within your
code. They must be in "tail position," meaning they must be the last
operation performed before control exits a scope. This restriction
ensures predictable control flow:

<!--versetest
GetOrder(:int)<transacts><decides>:order=order{}
order := class<allocates>{ IsValid()<decides><transacts>:void={} }
-->
<!-- 47 -->
```verse
# Valid: return is last operation
ProcessOrder(OrderId:int)<transacts>:string =
    if (Order := GetOrder[OrderId]):
        if (Order.IsValid[]):
            return "Processed"
    "Invalid order"

# Valid: return in both branches
GetStatus(Value:int):string =
    if (Value > 0):
        return "Positive"
    else:
        return "Non-positive"

ProcessOrder(1) = "Processed"
GetStatus(-1) = "Non-positive"
```

Verse functions implicitly return the value of their last expression,
so `return` is only needed for early exits.

The `return` statement allows you to provide successful values from early
exits, while still allowing other paths to fail:

<!--versetest
config:=struct{MaxRetries:int}
GetConfig()<transacts><decides>:config=config{MaxRetries:=3}
AttemptOperation(Retry:int)<computes><decides>:string="success"
-->
<!-- 48 -->
```verse
RetryableOperation()<transacts>:string =
    if (Config := GetConfig[]):
        for (Retry := 1..Config.MaxRetries):
            if (Result := AttemptOperation[Retry]):
                return Result  # Success - exit immediately
    "Failed" # All retries exhausted

RetryableOperation() = "success"
```

This pattern is common for search operations where you want to return
immediately upon finding a match, but fail if no match is found.

## Defer Statements

The `defer` statement schedules code to run when the enclosing scope
exits. This makes it invaluable for cleanup operations like closing
files, releasing resources, or logging.

Defer is **scope-based**, not function-based. A `defer` block executes
when leaving the scope that directly contains it, including:

- **Function bodies** — runs when the function returns
- **`for` loops** — the `for` body runs each iteration in its own
  scope; the `for` domain also introduces a lexical scope
- **Each iteration of `loop` blocks** — runs at the end of each
  iteration (including on `break`)
- **`if`/`then`/`else` clauses** — runs when leaving the chosen branch
- **`block` scopes** — runs when leaving the block
- **`not` expressions** — `not e` evaluates `e` in a new lexical scope
- **`or` expressions** — `e0 or e1` evaluates `e0` in a new lexical
  scope
- **`and` expressions** — `e0 and e1` evaluates the entire expression
  in a new lexical scope
- **`option` and `logic` expressions** — `option{e}` and `logic{e}`
  evaluate `e` in a new lexical scope
- **`case` expressions** — `case(e0){e1=>e2, e3=>e4}` creates a
  lexical scope for the whole `case`, and then for each result
  expression (`e2`, `e4`)
- **Archetype instantiation** — `my_class{...}` introduces a lexical
  scope for the body
- **`defer` blocks themselves** — nested defers run when the outer
  defer completes
- **Structured concurrency macros** (`race`, `rush`, `branch`) —
  each arm runs in its own lexical scope
- **`spawn`, `await`, and `batch` expressions** — `spawn{e}`,
  `await{e}`, and `batch{e}` evaluate `e` in a new lexical scope
- **`live` bindings** — `live Name : e0 = e1` creates a new lexical
  scope for `e1`
- **Cancelled concurrent scopes** — runs during cancellation
  unwinding (see [Concurrency](14_concurrency.md#cleanup-and-resource-management))

Here is a basic example:

<!--versetest
OpenFile(P:string)<computes>:?int=option{1}
CloseFile(P:int)<computes>:void={}
ReadFile(P:int)<computes>:?string=option{"data"}
ProcessContents(P:string)<computes><decides>:void={}
SaveResults()<computes><decides>:void={}
-->
<!-- 49 -->
```verse
ProcessFile(FileName:string)<transacts><decides>:void =
    File := OpenFile(FileName)?
    defer:
        CloseFile(File)  # Runs on success or early exit

    Contents := ReadFile(File)?
    ProcessContents[Contents]
    SaveResults[]

ProcessFile["save.dat"]
```

Deferred code executes when the scope exits successfully or through
explicit control flow like `return`:

<!--versetest-->
<!-- 50 -->
```verse
var Closed:logic = false

Lookup(Values:[]int, Target:int)<transacts>:string =
    defer:
        set Closed = true  # Cleanup always needed

    for (Index -> V : Values):
        if (V = Target):
            return "found"  # defer executes after return being called

    "missing"  # defer executes before leaving the function scope on success

Lookup(array{1, 2, 3}, 2) = "found"
Closed?
```

This is a subtle but crucial point: if a function fails due to
speculative execution, deferred code does **not** execute. This is
because failure triggers a rollback that undoes all effects, including
the scheduling of defer blocks:

<!--versetest
AcquireResource()<transacts><decides>:int=0
ReleaseResource(Id:int)<transacts>:void={}
RiskyOperation(Id:int)<transacts><decides>:void={}
-->
<!-- 51 -->
```verse
ExampleWithFailure()<transacts><decides>:void =
    ResourceId := AcquireResource[]
    defer:
        ReleaseResource(ResourceId) # Scheduled...

    RiskyOperation[ResourceId] # This fails!
    # defer does NOT run - entire scope was speculative and rolled back
```

When the `RiskyOperation` fails, the entire function also fails, and
speculative execution undoes everything, including the defer
registration. The resource cleanup never happens because the resource
acquisition itself is rolled back.

This behavior ensures consistency: if a function fails, it is as if it
never ran, including any cleanup code that was scheduled.

When multiple `defer`s exist in the same scope, they execute in
reverse order of definition (last-in, first-out), mimicking the
stack-based cleanup of nested resources:

<!--versetest-->
<!-- 52 -->
```verse
DeferOrder()<transacts>:[]string =
    var Order:[]string = array{}
    block:
        defer:
            set Order += array{"outer"}   # Declared first, executes second
        defer:
            set Order += array{"inner"}   # Declared second, executes first
    Order

DeferOrder() = array{"inner", "outer"}
```

Deferred code also executes when async operations are cancelled, such
as when a `race` completes or a `spawn` is interrupted:

<!--versetest
AcquireResource()<transacts>:int=0
ReleaseResource(Resource:int)<transacts>:void={}
LongRunningTask(Resource:int)<suspends><transacts>:void={}
-->
<!-- 53 -->
```verse
ProcessWithTimeout()<suspends><transacts>:void =
    race:
        block:
            Resource := AcquireResource()
            defer:
                ReleaseResource(Resource)  # Runs if cancelled

            LongRunningTask(Resource)

        block:
            Sleep(10.0)  # Timeout
    # If timeout wins, first block is cancelled and defer runs
```

This ensures cleanup happens even when concurrency control interrupts your code.

Defer statements can be nested within other defer blocks, creating a
cascade of cleanup operations:

<!--versetest-->
<!-- 54 -->
```verse
var Trace:string = ""

Log(S:string)<transacts>:void =
    set Trace += S

ProcessWithCleanup()<transacts>:void =
    Log("A")
    defer:
        Log("B")
        defer:
            Log("inner")  # Runs after B
        Log("C")
    Log("D")

ProcessWithCleanup()
Trace = "ADBCinner"
```

The execution order follows the LIFO principle at each nesting
level: inner defers execute after the outer defer's code, maintaining
the stack-like cleanup order.

Defers work correctly within all control flow constructs:

<!--versetest
Log(S:string)<transacts>:void={}
-->
<!-- 55 -->
```verse
ProcessLoop()<transacts>:int =
    var Cleanups:int = 0
    for (N := 0..2):
        Log("Start")
        defer:
            set Cleanups += 1  # Runs at the end of each iteration
        Log("End")
    Cleanups

ProcessWithIf(Condition:logic):void =
    if (Condition?):
        defer:
            Log("Then cleanup")
        Log("Then body")
    else:
        defer:
            Log("Else cleanup")
        Log("Else body")

ProcessLoop() = 3
```

Each control flow path executes its own defers independently.

The defer statement has important restrictions
to ensure predictable behavior:

1. **Cannot be empty:** Defer blocks must contain at least one
   expression:

2. **Cannot be used as expression:** Defer cannot be used in positions
   where a value is expected.

3. **Cannot cross boundaries:** Defer blocks cannot contain `return`,
   `break`, or other control flow that would exit the defer's scope.

4. **Cannot fail:** Expressions in defer blocks cannot fail.

5. **Cannot suspend directly:** Defer blocks cannot contain suspend
   expressions, but they can use `spawn` for fire-and-forget async
   operations.

For how `defer` interacts with async cancellation and concurrency
constructs like `race` and `spawn`, see
[Cleanup and Resource Management](14_concurrency.md#cleanup-and-resource-management).

## Profiling

Understanding how your code performs is crucial for optimization, and
the `profile` expression measures execution time:

<!--versetest-->
<!-- 56 -->
```verse
OptimizedCalculation():float =
    profile("Complex Math"):
        var Result:float = 0.0
        for (I := 1..1000000):
            set Result += Sin(I*1.0) * Cos(I*1.0)
        Result
```

The profile expression wraps around the code you want to measure,
logging the execution time to the output. You can add descriptive tags
to organize your profiling output, making it easier to identify
bottlenecks in complex systems.

Profile expressions pass through their results transparently, meaning
you can wrap them around any expression without changing the program's
behavior:

<!--versetest
BaseDamage:float = 50.0
GetMultiplier()<computes>:float = 1.5
GetCriticalBonus()<computes>:float = 2.0
-->
<!-- 57 -->
```verse
PlayerDamage := profile("Damage Calculation"):
    BaseDamage * GetMultiplier() * GetCriticalBonus()
```
