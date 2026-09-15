# Effects

An effect specifier states what a function does besides returning a
value: whether it reads or writes mutable state, allocates, might
fail, or might suspend. Effects are part of the signature, so the
declaration alone tells you what the function is permitted to do.

Compare the two. `UpdateScore(Player, Points)` says nothing about
whether it touches the heap, writes a log, or blocks for a frame.
`UpdateScore(Player, Points)<writes>` says it modifies state, and the
compiler holds it to that.

This explicitness might seem like extra work at first, but it
fundamentally changes how you reason about code. When you see
`<reads>` on a function, you know it observes mutable state. When you
see `<writes>`, you know it modifies that state. When you see
`<decides>`, you know it might fail. These are not comments or
documentation that might be wrong; they are compiler-enforced
contracts that must be accurate.

## Understanding Effects

Effects represent observable interactions between your code and the
world around it. Reading a player's health, updating a score, spawning
a particle effect, waiting for an animation to complete: all these
operations have effects that ripple beyond simple computation. Verse's
effect system captures these interactions, making them visible and
verifiable.

Consider this simple function that greets a player:

<!-- 01 -->
```verse
var CurrentGreeting:string = ""

GreetPlayer()<transacts>:void =
    set CurrentGreeting = "Hello, adventurer!"

GreetPlayer()
CurrentGreeting = "Hello, adventurer!"
```

The `<transacts>` effect tells you immediately that this function
modifies mutable state. You do not need to read the implementation to
know that calling `GreetPlayer()` will change something in your
program's memory. The effect is a promise about behavior, checked and
enforced by the compiler.

Effects compose naturally through function calls. If function A calls
function B, and B has certain effects, then A must declare at least
those same effects (with some exceptions we'll explore). This
propagation ensures that effects can't be hidden or laundered through
intermediate functions, so the true nature of an operation is always
visible at every level of the call stack.

#### Why Effects Matter

Making effects explicit serves both human understanding and compiler
optimization. For developers, effects act as documentation that can't
lie. When you are debugging why a value changed unexpectedly, you can
trace through the call chain looking only at functions with
`<writes>`. When you are trying to understand why a function might
fail, you look for `<decides>`. None of this is guesswork; it is guaranteed
by the type system.

For the compiler, explicit effects enable powerful optimizations and
safety guarantees. Pure functions marked `<computes>` can be memoized,
their results cached because they'll always return the same output for
the same input. Functions without `<writes>` can be safely executed in
parallel without locks. Functions without `<decides>` can be called
without failure handling.

The effect system also enforces architectural decisions. Want to
ensure your math library remains pure? Mark its functions
`<computes>`. Building a predictive client system that must run on
players' machines? Use `<predicts>` to ensure no server-only
operations sneak in. These are not conventions but
compiler-enforced guarantees.

## Effect Families and Specifiers

Verse organizes effects into families, each tracking a specific aspect
of computation. Each family contains fundamental effects, and effect
specifiers declare which effects a function may perform.

The six effect families are:

* **Cardinality**: Whether and how a function returns
* **Heap**: Access to mutable memory
* **Suspension**: Whether a function may suspend execution
* **Divergence**: Whether a function may run forever
* **Prediction**: Where a function runs
* **Internal**: Reserved for internal use

Some effects have no specifier, while some specifiers imply multiple
effects. For instance, `<transacts>` implies `reads`, `writes` and
`allocates`, and belongs to the Heap family.

Effect specifiers can be further divided into *exclusive* specifiers
(`<converges>`, `<computes>`, `<transacts>`) and *additive* specifiers
(`<suspends>`, `<decides>`, `<reads>`, `<writes>`, `<allocates>`). A
function may have at most one exclusive specifier but can combine
multiple additive ones. For example, `<computes><decides>` is valid
(pure computation that may fail), but `<computes><transacts>` is an
error (cannot have two exclusive effects).

|Fundamental Effect|Effect Specifier|Effect Family|Effects implied by Specifier | Notes |
| -----        | -----------    | -------     | ----- | ---- |
| **succeeds** |                | Cardinality |                  | *No specifier; Must Succeed* |
| **fails**    |                | Cardinality |                  | *No specifier; Can Fail* |
|              | `<decides>`    | Cardinality | `{succeeds, fails}` | *Cannot combine with `<suspends>`* |
| **reads**    | `<reads>`      | Heap        | `{reads}`        | *Allows reading mutable states* |
| **writes**   | `<writes>`     | Heap        | `{writes}`       | *Allows writing mutable states* |
| **allocates**| `<allocates>`  | Heap        | `{allocates}`    | *Allows allocation of mutable memory* |
|              | `<transacts>`  | Heap        | `{reads, writes, allocates}` | *Exclusive; default* |
|              | `<computes>`   | Heap        | `{}`             | *Exclusive; Pure computation* |
| **suspends** | `<suspends>`   | Suspension  | `{suspends}`     | *Cannot combine with `<decides>`* |
| **diverges** |                | Divergence  | `{diverges}`     | *No specifier; May run forever* |
|              | `<converges>`  | Divergence  | `{}`             | *Exclusive; Native functions, abstract methods, type signatures* |
| **dictates** |                | Prediction  | `{dictates}`     | *No specifier; Server Authority* |
|              | `<predicts>`   | Prediction  | `{}`             | *Allows Client Prediction* |
| **no_rollback** |             | Internal    | `{no_rollback}`  | *To be deprecated; Transactions disallowed* |

The following restrictions are in effect:

- `<suspends>` and `<decides>` cannot be combined on the same function,
- `<converges>` is only allowed on `<native>` functions, abstract methods, and type signatures,
- duplicate specifiers (e.g., `<computes><computes>`) are errors.

## How Effects Compose

Think of effect specifiers as setting bits in a bit vector: one bit
per fundamental effect. Without any annotation, a function such as
`GameUpdate` has the following effects:

<!-- 02 -->
```verse
GameUpdate():void = {}  # No explicit effects specified
```

| dictates | suspends | reads | writes | allocates | succeeds | fails |
| :---:    | :---:    | :---: | :---:  | :---:     | :---:    | :---: |
| ✔️       | ❌      | ✔️    | ✔️    | ✔️        | ✔️      | ❌    |

This means it has effects `dictates`, `reads`, `writes`, `allocates`
and `succeeds`. It's almost like writing `<dictates><transacts>`
except we lack a way to say the function cannot fail.

As an aside: the absence of specifiers for `fails` and `succeeds` can
be explained by the fact that a specifier like `<fails>` means the
function always fails, never returns a value, and cannot have
observable side effects (they would be undone by failure).  The
`succeeds` effect is implicit.

Annotating a function only affects the bits in that specifier's
family. For example, function `CheckPlayerStatus` with the `<reads>`
and `<predicts>` specifier:

<!-- 03 -->
```verse
CheckPlayerStatus()<reads><predicts>:string = "Ready"
```

has the following effects:

| dictates | suspends | reads | writes | allocates | succeeds | fails |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| ❌ | ❌ | ✔️ | ❌ | ❌ | ✔️ | ❌ |

Specifying `<reads>` clears the `writes` and `allocates` bits, and
`<predicts>` clears the `dictates` bit, everything else is unchanged.

## Effect Families in Detail

### Cardinality effects

The cardinality family deals with whether functions return values
successfully. Every function either succeeds (returning its declared
type) or fails (producing no value). Most functions always succeed:
they are deterministic transformations that always produce output. But
functions marked with `<decides>` can fail, turning failure into a
control flow mechanism.

<!-- 04 -->
```verse
ValidateHealth(Health:float)<transacts><decides>:void =
    Health > 0.0      # Fails if health is zero or negative
    Health <= 100.0   # Fails if health exceeds maximum

# The check itself is the branch
if (ValidateHealth[50.0]):
    Print("Combat starts")

not ValidateHealth[0.0]
not ValidateHealth[150.0]
```

The beauty of the decides effect is that it unifies validation with
control flow. You do not check conditions and then act on them; the
check itself drives the program's path.

### Heap effects

The heap family governs access to mutable memory. This is perhaps the
most important family for understanding program behavior, as it
determines whether functions can observe or modify state.

The `<computes>` specifier marks pure functions, those that neither
read nor write mutable state. These functions are deterministic: given
the same inputs, they always produce the same outputs. They're the
mathematical ideal of computation, transforming data without side
effects.

<!--versetest-->
<!-- 05 -->
```verse
CalculateDamage(BaseDamage:float, Multiplier:float)<computes>:float =
    BaseDamage * Multiplier
```

The `<reads>` effect allows functions to observe mutable state. They
can see the current values of variables and mutable fields, but cannot
modify them. This is useful for queries and calculations based on
current game state.

<!-- 06 -->
```verse
player := class:
    Name:string
    var Health:float = 100.0

GetPlayerStatus(P:player)<reads>:string =
    if (P.Health > 50.0):
        "Healthy"
    else if (P.Health > 0.0):
        "Injured"
    else:
        "Defeated"

GetPlayerStatus(player{Name := "Ana"}) = "Healthy"
GetPlayerStatus(player{Name := "Bo", Health := 10.0}) = "Injured"
GetPlayerStatus(player{Name := "Cy", Health := 0.0}) = "Defeated"
```

The `<writes>` effect permits modification of mutable state. Functions
with this effect can use `set` to update variables and mutable
fields. `<writes>` often requires `<reads>` as well, for instance when
modification involves reading the current value.

In fact, the `set` instruction is by default `<transacts>` due to the
addition of *live variables* to the language. A live variable is
variable whose value depends on other variables; when one of those
variables is updated by a `set` the live variable will be evaluated
with potentially some `reads` and `allocates`.

<!--versetest
player := class:
    Name:string
    var Health:float = 100.0
-->
<!-- 07 -->
```verse
HealPlayer(P:player, Amount:float)<transacts>:void =
    NewHealth := P.Health + Amount
    set P.Health = Min(NewHealth, 100.0)

Hurt := player{Name := "Ana", Health := 50.0}
HealPlayer(Hurt, 30.0)
Hurt.Health = 80.0

HealPlayer(Hurt, 50.0)   # Min caps the result at the maximum
Hurt.Health = 100.0
```

The `<allocates>` effect indicates functions that create observably
unique values: either objects marked `<unique>` or values containing
mutable fields. Each call to such a function returns a distinct value,
even if the inputs are identical.

<!--versetest
vector3 := struct:
    X:float
    Y:float
    Z:float
-->
<!-- 08 -->
```verse
game_entity := class<unique><allocates>:
    Name:string
    var Position:vector3

CreateEntity(N:string, Pos:vector3)<allocates>:game_entity =
    game_entity{Name := N, Position := Pos}

# Identical arguments, yet two distinguishable entities
Origin := vector3{X := 0.0, Y := 0.0, Z := 0.0}
First := CreateEntity("goblin", Origin)
Second := CreateEntity("goblin", Origin)
not First = Second
```

The `<transacts>` is the default for functions. 

### Suspension effects

The suspension family contains a single effect:
`<suspends>`. Functions with this effect can pause their execution and
resume later, potentially across multiple game frames. This is
essential for operations that take time: animations, cooldowns,
waiting for player input, or any multi-frame behavior.

<!--versetest
PlayAnimation(Name:string):void = {}
PlaySound(Name:string):void = {}
ShowRewardsScreen():void = {}
-->
<!-- 09 -->
```verse
PlayVictorySequence()<suspends>:void =
    PlayAnimation("VictoryDance")
    Sleep(2.0)  # Wait 2 seconds
    PlaySound("VictoryFanfare")
    Sleep(1.0)
    ShowRewardsScreen()
```

The `suspends` effect is viral: any function that calls a suspending
function must itself be marked `<suspends>`. This ensures you always
know which functions might take time to complete.

While `<suspends>` and `<decides>` cannot be combined on the same
function, they have specific rules for how they interact across
function calls. A `<suspends>` function can call a `<decides>`
function, but *only within a failure context* using the square bracket
`[]` syntax -- this ensures that the failure is handled locally and
does not propagate as a failure effect:

<!--versetest
DoAsyncWork():void={}
assert_semantic_error(3511):
    Validate10(Value:int)<decides><computes>:void =
        Value > 0
    G10():void =
        Validate10(5)
-->
<!-- 10 -->
```verse
ValidateInput(Value:int)<decides><computes>:void =
    Value > 0
    Value < 100

ProcessAsync(Value:int)<suspends>:void =
    # Valid: calling decides function in failure context
    if (ValidateInput[Value]):
        # Process valid input
        DoAsyncWork()

# Invalid: calling decides function outside failure context
# ProcessAsync(Value:int)<suspends>:void =
#     ValidateInput(Value)  # ERROR: must use [] syntax
```

A `<suspends>` function can call another `<suspends>` function, but *must not use failure-handling syntax* like `?`:

<!--versetest
assert_semantic_error(3512):
    AsyncOp11()<suspends>:?int = false
    CallAsync11()<suspends>:void =
        if (Value := AsyncOp11()?):
            Value
-->
<!-- 11 -->
```verse
AsyncOp()<suspends>:?int = false

CallAsync()<suspends>:void =
    # Valid: calling suspends function normally
    X := AsyncOp()

    # Invalid: cannot use ? with suspends in suspends context
    # if (Value := AsyncOp()?):
```

The asymmetry exists because `<suspends>` and `<decides>` represent
fundamentally different control flow mechanisms. Suspension is about
time, while failure is about whether an expression produces a value. Mixing their syntactic
forms creates ambiguity about what's being handled.

### Internal effects

The internal family exists for the compiler's own use. Its single
effect, `no_rollback`, marks code in which transactions are disallowed.
It has no specifier of its own and is being deprecated.

#### Prediction effects

!!! note "Unreleased Feature"
    The `<predicts>` effect is not yet released.

The prediction family determines where code runs in a client-server
architecture. By default, functions have the `dictates` effect,
meaning they run authoritatively on the server. The `<predicts>`
specifier allows functions to run predictively on clients for
responsiveness, with the server later validating and potentially
correcting the results.

<!--versetest
StartJumpAnimation()<predicts>:void = {}
PlayJumpSound()<predicts>:void = {}
ApplyJumpVelocity()<predicts>:void = {}
-->
<!-- 12 -->
```verse
HandleJumpInput()<predicts>:void =
    # Runs immediately on the client for responsiveness
    StartJumpAnimation()
    PlayJumpSound()
    ApplyJumpVelocity()
```

This enables responsive gameplay even with network latency, as players
see immediate feedback for their actions while the server maintains
authoritative state.

Because `<predicts>` clears the `dictates` bit rather than adding to
it, the effect propagates downwards: everything a predicting function
calls must itself predict. A server-authoritative function cannot be
invoked from one, so the client-side path has to be built out of
predicting pieces all the way down.

#### Divergence effects

Currently in planning, the divergence family will track whether
functions are guaranteed to terminate. The `<converges>` specifier
marks functions that provably complete in finite time, while
functions without it might run forever. This is particularly important
for constructors and initialization code.

The `<converges>` specifier can be used on:

- `<native>` functions that are guaranteed to terminate
- Abstract method signatures in classes and interfaces
- Function signatures in type expressions

Regular function implementations cannot use `<converges>`; it is allowed only on declarations in abstract contexts and on native functions.


<!-- TODO: write more -->

## Effect Composition

Effects generally propagate up the call chain: a function must
declare all the effects of the functions it calls. However, certain
language constructs can hide specific effects, preventing them from
propagating further.

An `if` expression hides `fails` effects in its failure context, thus
failure failure in a condition does not propagate to the enclosing
function:

<!--versetest-->
<!-- 13 -->
```verse
SafeMod(A:int, B:int)<computes>:int =
    if (V:= Mod[A,B])  then V else 0
```

The `spawn` expression hides the `suspends` effect, allowing immediate
functions to start asynchronous operations that continue
independently:

<!--versetest
GetNextTrack():int=0
PlayTrack(:int)<suspends>:void={}
-->
<!-- 14 -->
```verse
Play()<suspends>:void =
        loop:
            PlayTrack(GetNextTrack())
            Sleep(180.0)  

StartBackgroundMusic():void =  # No <suspends>
    spawn:
        Play() # Suspends effect hidden by spawn
```

As mentioned above failure is not allowed within `<suspends>` code
including `spawn`. One way around this restriction is to use the
`option` expression to convert failure into an optional value,
transforming the `fails` effect into a regular value that can be
handled without `<decides>`:

<!--versetest
item:=struct{}
-->
<!-- 15 -->
```verse
TryGetItem(Items:[]item, Index:int):?item =
    option{Items[Index]}  # Array access might fail, option catches it
```

The `defer` expression provides cleanup code that runs when exiting a
scope, but has strict effect limitations:

- Cannot contain `<suspends>` operations, because deferred code must execute synchronously
- Cannot contain `<decides>` operations, because deferred code must always succeed

<!--versetest
resource:=class{}
DoAsyncWork():void={}
GetResource()<transacts>:resource=resource{}
-->
<!-- 16 -->
```verse
AcquireResource()<transacts>:resource = GetResource()
ReleaseResource(R:resource)<transacts>:void = {}

ProcessResource()<suspends>:void =
    R := AcquireResource()
    defer:
        ReleaseResource(R)  # Valid: transacts allowed in defer

    # Process resource with async operations
    DoAsyncWork()
```

These constraints ensure that cleanup code executes predictably and
completely, without the possibility of suspension or failure that
could leave resources in an inconsistent state.

## Subtyping and Type Compatibility

Effect annotations create a subtyping relationship between function
types. Understanding how effects interact with type compatibility is
essential when storing functions in variables, passing them as
parameters, or choosing between different implementations.

A function with **fewer effects** can be used where a function with
**more effects** is expected. This is effect subtyping: a function that
does less is compatible with a context that allows more:

<!-- 17 -->
```verse
# Pure function with only computes
PureAdd(X:int)<computes>:int = X + 1

# Assignable to any type that permits at least as much
F1:type{_(:int)<computes><decides>:int} = PureAdd
F2:type{_(:int)<transacts>:int} = PureAdd
F3:type{_(:int)<reads>:int} = PureAdd

F1[5] = 6   # Must use [] since this type has <decides>
F2(5) = 6
F3(5) = 6
```

In this example, `PureAdd` has only `<computes>`, but it can be
assigned to a variable expecting `<computes><decides>`. The pure
function is a valid implementation of the failable interface; it simply
never exercises the failure capability. The same principle applies to
all effects, which is why the assignments to the `<transacts>` and
`<reads>` types are equally valid: `PureAdd` does less than what any of
them allows.

When deciding subtyping, effects have the following impact:

- `<computes>` is a subtype of `<reads>`, `<transacts>`, and any combination with `<decides>`
- `<reads>` is a subtype of `<transacts>`
- Functions without `<decides>` are subtypes of functions with `<decides>`
- Functions without `<suspends>` are subtypes of functions with `<suspends>` (when compatible)

While you can add effects through subtyping, you **cannot remove**
effects that a function actually has:

<!--versetest
assert_semantic_error(3509):
    Validate20(X:int)<computes><decides>:int =
        X > 0
        X
    F20:type{_(:int)<computes>:int} = Validate20
-->
<!-- 18 -->
```verse
Validate(X:int)<computes><decides>:int =
    X > 0
    X

# ERROR: Cannot assign to type without <decides>
# F:type{_(:int)<computes>:int} = Validate
# The function CAN fail, but the type does not allow it
```

Similarly, functions with heap effects cannot be assigned to pure types:

<!--versetest
assert_semantic_error(3509):
    c20 := class:
        var Count:int = 0
    Increment20(C:c20)<transacts>:int =
        set C.Count = C.Count + 1
        C.Count
    F20:type{_(:c20)<computes>:int} = Increment20
-->
<!-- 19 -->
```verse
counter := class:
    var Count:int = 0

Increment(C:counter)<transacts>:int =
    set C.Count = C.Count + 1
    C.Count

Tally := counter{}
Increment(Tally) = 1
Increment(Tally) = 2

# ERROR: F:type{_(:counter)<computes>:int} = Increment
# The function writes state, the type does not permit it
```

This restriction ensures type safety: the type signature is a promise
about what effects the function might perform, and the actual function
must honor that promise.

When you conditionally select between functions with different
effects, the resulting expression has the union of all possible
effects. This is *effect joining*: the compiler conservatively assumes
the result might perform any effect that any branch could perform:

<!-- 20 -->
```verse
Identity(X:int)<computes>:int = X

DecidesIdentity(X:int)<computes><decides>:int =
    X > 0
    X

TransactsIdentity(X:int)<transacts>:int = X

# Joining <computes> and <computes><decides> gives <computes><decides>
F1:type{_(:int)<computes><decides>:int} =
    if (true?) then Identity else DecidesIdentity

# Joining <computes><decides> and <transacts> gives both
F2:type{_(:int)<decides><transacts>:int} =
    if (true?) then DecidesIdentity else TransactsIdentity

# Both must be called with [] because each joined type has <decides>
F1[5] = 5
F2[5] = 5
```

The selected function might fail, if the branch taken was the failable
one, or might not, so the type has to include `<decides>` either way.
Effect joining applies to all control flow that selects between
functions, not just `if`.


Effect subtyping enables flexible function parameters:

<!-- 21 -->
```verse
# Accepts any function that does not exceed <transacts><decides>
ProcessValues(
    Data:[]int,
    Transform(:int)<transacts><decides>:int
):[]int =
    for (Value:Data, Result := Transform[Value]):
        Result

Double(X:int)<computes>:int = X * 2
Positive(X:int)<computes><decides>:int =
    X > 0
    X

ProcessValues(array{1, 2, 3}, Double) = array{2, 4, 6}

# A failing Transform simply drops that element from the result
ProcessValues(array{-1, 2, 3}, Positive) = array{2, 3}
```

Effect subtyping makes function composition work naturally:

<!-- 22 -->
```verse
PureFunction(X:int)<computes>:int = X + 1
FailableFunction(X:int)<computes><decides>:int =
    X > 0
    X * 10

ComposeFlexible(
    F(:int)<transacts><decides>:int,
    G(:int)<transacts><decides>:int
):type{_(:int)<transacts><decides>:int} =
    Local(X:int)<transacts><decides>:int = G[F[X]]
    Local

# Both arguments have fewer effects than the parameter types allow
H := ComposeFlexible(PureFunction, FailableFunction)
H[4] = 50

# Failure propagates out of the composition
not H[-1]
```

The following table summarize the interaction of effects and types:

| Scenario | Valid? | Explanation |
|----------|--------|-------------|
| Assign `<computes>` to `<computes><decides>` type | ✓ | Adding effects via subtyping |
| Assign `<computes>` to `<transacts>` type | ✓ | Pure is subtype of transactional |
| Assign `<reads>` to `<transacts>` type | ✓  | Reads is subtype of transactional |
| Assign `<computes><decides>` to `<computes>` type | ✗  | Cannot remove `<decides>` |
| Assign `<transacts>` to `<computes>` type | ✗  | Cannot remove heap effects |
| Select between `<computes>` and `<decides>` | Result: `<computes><decides>` | Effect joining |
| Select between `<reads>` and `<transacts>` | Result: `<transacts>` | Effect joining |

These rules ensure that effect annotations remain trustworthy
contracts: functions can do less than declared (subtyping), but never
more, and conditional selection conservatively accounts for all
possibilities (joining).

## Effects on Data Types

Classes, structs, and interfaces can be annotated with effect
specifiers, which apply to their constructors. This is particularly
useful for ensuring that creating certain objects remains pure or has
limited effects:

<!--versetest-->
<!-- 23 -->
```verse
# Pure data structure - constructor has no effects
vector3 := struct<computes>:
    X:float = 0.0
    Y:float = 0.0
    Z:float = 0.0

# Entity that requires allocation due to unique identity
monster := class<unique><allocates>:
    Name:string
    var Health:float = 100.0
```

Classes, interfaces, and structs **cannot** be marked with `<suspends>` or `<decides>`:

<!--versetest
assert_semantic_error(3512):
    invalid_class29 := class<suspends>{}
assert_semantic_error(3512):
    invalid_interface29 := interface<decides>{}
assert_semantic_error(3512):
    invalid_struct29 := struct<decides>{}
-->
<!-- 24 -->
```verse
# Valid effect specifiers for classes/interfaces/structs:
valid_class := class<computes>{}
valid_interface := interface<computes>{}
valid_struct := struct<transacts>{}

# Invalid: async and failable effects not allowed
# invalid_class := class<suspends>{}      # ERROR
# invalid_interface := interface<decides>{}  # ERROR
# invalid_struct := struct<decides>{}     # ERROR
```

This restriction applies to the class/struct **declaration** itself.
The archetype constructor `my_class{...}` cannot be failable or
suspending. However, **constructor functions** can use `<decides>`:

<!-- 25 -->
```verse
# The class declaration cannot be <decides>
my_class := class:
    Value:int

# But a constructor function CAN be <decides>
MakeMyClass<constructor>(V:int)<transacts><decides> := my_class:
    Value := block:
        V > 0      # Fails if V <= 0
        V < 100    # Fails if V >= 100
        V

MakeMyClass[42].Value = 42
not MakeMyClass[0]
not MakeMyClass[100]
```

This provides failable construction when needed: the object either
exists fully formed or the constructor function fails and no object
is created.

Field default values and block clauses in classes have strict effect requirements:

<!--versetest
assert_semantic_error(3582):
    Helper30()<transacts>:int = 42
    bad_class30 := class:
        Value:int = Helper30()
assert_semantic_error(3512, 3512):
    bad_class30b := class<computes>:
        var Counter:int = 0
        block:
            set Counter = 1
-->
<!-- 26 -->
```verse
# Field initializers must use pure functions
HelperFunction()<transacts>:int = 42

# Invalid: field initializers cannot call transacts functions
# bad_class := class:
#     Value:int = HelperFunction()  # ERROR

# Block clauses must respect class effects
valid_class := class<transacts>:
    var Counter:int = 0
    block:
        set Counter = 1  # Valid: class has transacts

# Invalid: block effect exceeds class effect
# bad_class := class<computes>:
#     var Counter:int = 0
#     block:
#         set Counter = 1  # ERROR: computes class cannot write
```

Class member initializers and block clauses are implicitly restricted
to have no more effects than what the class declares. This ensures
that constructing an instance of the class respects the class's effect
contract.

Limiting constructor effects helps maintain architectural
boundaries. Data transfer objects can be kept pure with `<computes>`,
ensuring they are just data carriers. Game entities might require
`<allocates>` for unique identity, while service objects might need
full `<transacts>` to initialize their state.

### Interface Construction Effect Constraints

When classes or interfaces inherit from interfaces with construction effects, they must declare at least the same construction effects:

<!--versetest
assert_semantic_error(3512):
    transacting31 := interface<transacts>{}
    invalid31 := class<computes>(transacting31){}
-->
<!-- 27 -->
```verse
# Interface with transacts effect
transacting_interface := interface<transacts>{}

# Valid: class has at least transacts
valid_class := class<transacts>(transacting_interface){}

# Invalid: class has less effects than interface requires
# invalid_class := class<computes>(transacting_interface){}  # ERROR
```

Interface field initializers must also respect the interface's declared construction effects:

<!--versetest
assert_semantic_error(3512):
    tc32 := class<transacts>{}
    invalid_interface32 := interface<computes>:
        Instance:tc32 = tc32{}
-->
<!-- 28 -->
```verse
transacting_class := class<transacts>{}

# Valid: interface has transacts, field initializer has transacts
valid_interface := interface<transacts>:
    Instance:transacting_class = transacting_class{}

# Invalid: interface has computes, but field initializer has transacts
# invalid_interface := interface<computes>:
#     Instance:transacting_class = transacting_class{}  # ERROR
```

These constraints ensure that construction effects flow correctly through inheritance hierarchies. A class inheriting an interface must be able to construct all interface fields, which requires having at least the same construction effects.

## Working with Effects

When designing functions, start with the minimal effects needed and
expand only when necessary. Pure functions with `<computes>` are the
easiest to test, reason about, and compose. Add `<reads>` when you
need to observe state, `<writes>` when you need to modify it, and
`<decides>` when you need failure-based control flow.

Effects are part of your API contract. Once published, removing
effects is a backwards-compatible change (your function does less than
before), but adding effects is breaking (your function now does more
than callers might expect). Design your effect signatures
thoughtfully, as they become promises to your users.

Remember that over-specifying effects is allowed and sometimes
beneficial. A function marked `<reads>` can be implemented as pure
`<computes>` internally. This provides flexibility for future changes
without breaking existing callers.

<!--versetest
weapon:=struct<computes>{Type:weapon_type,Damage:int}
weapon_type:=enum:
    Sword
-->
<!-- 29 -->
```verse
# API promises it might read state
GetDefaultWeapon()<reads>:weapon =
    # But current implementation is pure
    weapon{Type := weapon_type.Sword, Damage := 10}

GetDefaultWeapon().Damage = 10
```

Effect over-specification can future-proof APIs and avoid breaking
changes later. For example, marking a currently pure function as
`<reads>` allows you to add state observation in the future without
breaking compatibility.

## Backwards Compatibility

The effects of a function are part of what is checked for backwards
compatibility. When updating a function that is part of a published
API, the new version can have "fewer bits" but not more. So, a
function that was marked as `<reads>` in a previous version cannot be
changed to `<transacts>`, but it can be refined to `<computes>`.

Effects transform side effects from hidden gotchas into visible,
verifiable contracts. By making the implicit explicit, Verse helps you
write more predictable, maintainable, and correct code. The effect
system lets you state your intent explicitly and have the compiler verify that your implementation matches
that intent.
