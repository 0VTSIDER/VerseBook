# Structs and Enums

Structs and enums are Verse's value types. A struct groups related data with no methods and no inheritance; its fields are public and immutable by default. An enum defines a fixed set of named values, which `case` can match exhaustively.

Both are more limited than classes by design. Reach for them when you need data rather than behaviour.

## Structs

Structs provide lightweight data containers without the object-oriented features of classes. They're value types optimized for simple data aggregation, making them perfect for mathematical types, data transfer objects, and any scenario where you need a simple bundle of related values without behavior.

Structs group related data with minimal overhead:

<!-- 01 -->
```verse
damage_type := enum:
    Physical
    Fire

vector2 := struct:
    X : float = 0.0
    Y : float = 0.0

damage_info := struct:
    Amount : int = 0
    Type : damage_type = damage_type.Physical
    IsCritical : logic = false
```

All struct fields are public and immutable by default. Structs cannot have methods, constructors, or participate in inheritance hierarchies. This simplicity makes them efficient and predictable.

### Construction

Creating struct instances uses the same archetype syntax as classes:

<!--versetest
vector2 := struct:
    X : float = 0.0
    Y : float = 0.0
-->
<!-- 02 -->
```verse
Origin := vector2{}                           # every field takes its default
PlayerPos := vector2{X := 100.0, Y := 250.0}

Origin.X = 0.0
PlayerPos.Y = 250.0
```

Since structs are value types, assigning a struct to a variable creates a copy of all its data. This differs from classes, which use reference semantics. The `<computes>` specifier below is what lets the fields of a mutable struct variable be assigned; see the [Mutability](05_mutability.md) chapter for the details.

<!--versetest
position := struct<computes>:
    X : float = 0.0

counter := class:
    var Hits : int = 0
-->
<!-- 03 -->
```verse
var Pos:position = position{X := 100.0}
Snapshot := Pos          # copies the fields
set Pos.X = 0.0
Snapshot.X = 100.0       # the copy kept the old value

Tally := counter{}
Alias := Tally           # binds the same object
set Tally.Hits = 7
Alias.Hits = 7           # the alias sees the change
```

### Comparison

Structs with all comparable fields support equality comparison:

<!--versetest
vector2 := struct:
    X : float = 0.0
    Y : float = 0.0
-->
<!-- 04 -->
```verse
Origin := vector2{}
UnitX := vector2{X := 1.0}

Origin = vector2{}   # succeeds - every field matches
Origin <> UnitX      # succeeds - the X fields differ
```

Comparison happens field by field, succeeding only if all corresponding fields are equal.

### Persistable Structs

Structs can be marked as persistable for use with Verse's persistence system:

<!--versetest
player := class<concrete><unique>{}
-->
<!-- 05 -->
```verse
player_stats := struct<persistable>:
    HighScore : int = 0
    GamesPlayed : int = 0
    WinRate : float = 0.0

# can be used in persistent storage
var PlayerData : weak_map(player, player_stats) = map{}
```

Once published, persistable structs cannot be modified, ensuring data compatibility across game updates.

### Parametric Structs

Like classes, structs can be parametric (generic). A parametric struct declares one or more type parameters, allowing the same struct definition to work with different types. This is useful when you want a lightweight value type that is reusable across different data types without defining a full class.

A parametric struct takes type parameters in its definition, just like a parametric class. The type parameter `t` can be used anywhere a concrete type would appear in field declarations, and when creating instances you provide the concrete type:

<!-- 06 -->
```verse
# a wrapper that can hold a value of any type
wrapper(t:type) := struct:
    Value : t

IntWrapped := wrapper(int){Value := 42}
StringWrapped := wrapper(string){Value := "hello"}

IntWrapped.Value = 42
StringWrapped.Value = "hello"
```

Parametric structs work naturally with parametric functions. A function can accept any instantiation of a parametric struct by using a `where` clause to capture the type parameter. Since the type parameter is preserved through instantiation, parametric structs can also be nested — here a `wrapper` holds another `wrapper` as its value:

<!--versetest
wrapper(t:type) := struct:
    Value : t
-->
<!-- 07 -->
```verse
Unwrap(W:wrapper(t) where t:type):t = W.Value

Unwrap(wrapper(int){Value := 10}) = 10
Unwrap(wrapper(float){Value := 2.0}) = 2.0

Nested := wrapper(wrapper(int)){Value := wrapper(int){Value := 11}}
Unwrap(Unwrap(Nested)) = 11
```

Parametric structs retain all the characteristics of regular structs — they are value types with public, immutable fields and no methods or inheritance. The only addition is the ability to parameterize field types. Note that parametric structs cannot be marked `<persistable>` — persistence requires concrete, fixed types that can be serialized reliably across game updates.

## Enums

Enums define types with a fixed set of named values, perfect for representing states, types, or any concept with a known, finite set of alternatives. They make code more readable by replacing magic numbers with meaningful names and provide compile-time safety by restricting values to the defined set.

An enum lists all possible values for a type:

<!-- 08 -->
```verse
game_state := enum:
    MainMenu
    Playing
    Paused
    GameOver

placeholder := enum{}  # valid but rarely useful
```

Each value in the enum becomes a named constant of that enum type. The compiler ensures that variables of an enum type can only hold one of these defined values. Enums can even be empty, as `placeholder` shows.

Enums introduce both a type and a set of values, and it is crucial to distinguish between them:

<!--versetest
assert_semantic_error(3509):
    status09 := enum:
        Active
        Inactive
    BadAssignment09:status09 = status09
-->
<!-- 09 -->
```verse
status := enum:
    Active
    Inactive

# status is the TYPE; status.Active and status.Inactive are VALUES
var CurrentStatus:status = status.Active
set CurrentStatus = status.Inactive
CurrentStatus = status.Inactive

# BadAssignment:status = status  # ERROR: cannot use a type as a value
# set CurrentStatus = status     # ERROR: cannot use a type as a value
```

You cannot use the enum type where a value is expected. This distinction prevents confusion and ensures type safety. The enum type defines what values are possible, while enum values are the actual constants you use in your code.

### Restrictions

Enums have specific syntactic requirements that keep their usage clear and unambiguous. An enum must be the direct right-hand side of a definition, and that definition must sit at module or class level rather than inside a function:

<!--versetest
assert_semantic_error(3606):
    Result10 := -enum{A, B}
assert_semantic_error(3606, 3547):
    Value10 := enum{X, Y} + 1
assert_semantic_error(3502):
    Process10():void =
        LocalEnum10 := enum{A, B}
-->
<!-- 10 -->
```verse
priority := enum:
    Low
    Medium
    High

# Result := -enum{A, B}    # ERROR: enums cannot appear inside an expression
# Value := enum{X, Y} + 1  # ERROR: same

Rank(P:priority):int =
    # LocalEnum := enum{A, B}  # ERROR: no local enum definitions
    case (P):
        priority.Low => 0
        priority.Medium => 1
        priority.High => 2

Rank(priority.High) = 2
```

These restrictions ensure enums remain stable, referenceable definitions throughout your codebase rather than ephemeral local values.

### Using Enums

Enums provide type-safe alternatives to error-prone string or integer constants:

<!--versetest
game_state := enum:
    MainMenu
    Playing
    Paused
    GameOver
-->
<!-- 11 -->
```verse
var CurrentState:game_state = game_state.MainMenu

ProcessInput(Input:string):void =
    case (CurrentState):
        game_state.MainMenu =>
            if (Input = "Start"):
                set CurrentState = game_state.Playing
        game_state.Playing =>
            if (Input = "Pause"):
                set CurrentState = game_state.Paused
        game_state.Paused =>
            if (Input = "Resume"):
                set CurrentState = game_state.Playing
        game_state.GameOver =>
            if (Input = "Restart"):
                set CurrentState = game_state.MainMenu

ProcessInput("Start")
CurrentState = game_state.Playing
ProcessInput("Pause")
CurrentState = game_state.Paused
```

The `case` expression with enums provides powerful pattern matching with exhaustiveness checking that ensures you handle all possible values correctly.

### Open vs Closed Enums

Enums can be marked as open or closed, fundamentally affecting how they can evolve and how they interact with pattern matching:

<!-- 12 -->
```verse
# closed enum - cannot add values after publication
direction := enum<closed>:  # <closed> is the default
    North
    East
    South
    West

# open enum - can add new values after publication
weapon_type := enum<open>:
    Sword
    Bow
    # Staff, Wand, Dagger, etc. can be added in updates
```

Closed enums, the default, commit to a fixed set of values forever. This allows the compiler to verify that case expressions handle all possibilities exhaustively. Use closed enums for truly fixed sets: days of the week, cardinal directions, fundamental game states.

Open enums allow new values to be added in future versions. This flexibility comes at a cost: case expressions cannot be exhaustive since future values might exist. Use open enums for extensible sets: item types, enemy types, damage types, or any content that may grow.

### Exhaustiveness

The interaction between enum types and case expressions follows sophisticated rules that prevent bugs while enabling both safety and flexibility. Understanding these rules is essential for working with enums effectively.

#### Closed Enums with Full Coverage

When your case expression handles every value in a closed enum, no wildcard is needed. Adding one anyway triggers an unreachable code warning:

<!-- 13 -->
```verse
day := enum:
    Monday
    Tuesday
    Wednesday

# exhaustive - all values covered, so no wildcard is needed
GetDayType(D:day):string =
    case (D):
        day.Monday => "Weekday"
        day.Tuesday => "Weekday"
        day.Wednesday => "Weekday"

GetDayTypeWarn(D:day):string =
    case (D):
        day.Monday => "Weekday"
        day.Tuesday => "Weekday"
        day.Wednesday => "Weekday"
        _ => "Unknown"  # WARNING: unreachable - all values already matched

GetDayType(day.Tuesday) = "Weekday"
```

#### Closed Enums with Partial Coverage

If you do not match all values, you must either provide a wildcard or be in a `<decides>` context:

<!--versetest
day := enum:
    Monday
    Tuesday
    Wednesday
assert_semantic_error(3512):
    day14 := enum:
        Monday
        Tuesday
    GetWeekStart14(D:day14):string =
        case (D):
            day14.Monday => "Week start"
-->
<!-- 14 -->
```verse
# with a wildcard - OK
GetWeekStart(D:day):string =
    case (D):
        day.Monday => "Week start"
        _ => "Mid-week"

# without a wildcard but in a <decides> context - OK
GetWeekStartOrFail(D:day)<transacts><decides>:string =
    case (D):
        day.Monday => "Week start"
        # missing other days causes failure

# GetWeekStartBad(D:day):string =  # ERROR: missing cases and no wildcard
#     case (D):
#         day.Monday => "Week start"

GetWeekStart(day.Tuesday) = "Mid-week"
GetWeekStartOrFail[day.Monday] = "Week start"
not GetWeekStartOrFail[day.Tuesday]
```

#### Open Enums Always Require a Wildcard or `<decides>`

Open enums can have new values added after publication, so they can never be exhaustive.\
This is to ensure backwards compatibility of functions using them (see also [Publishing Functions](06_functions.md#publishing-functions)):

<!--versetest
assert_semantic_error(3512):
    weapon15 := enum<open>:
        Sword
        Bow
    GetClass15(W:weapon15):string =
        case (W):
            weapon15.Sword => "Melee"
            weapon15.Bow => "Ranged"
-->
<!-- 15 -->
```verse
weapon := enum<open>:
    Sword
    Bow

# must have a wildcard - OK
GetWeaponClass(W:weapon):string =
    case (W):
        weapon.Sword => "Melee"
        weapon.Bow => "Ranged"
        _ => "Unknown"  # REQUIRED - future values may exist

# in a <decides> context without a wildcard - OK
GetWeaponClassOrFail(W:weapon)<transacts><decides>:string =
    case (W):
        weapon.Sword => "Melee"
        weapon.Bow => "Ranged"
        # can fail for unknown (future) values

# without either it is a COMPILE ERROR: open enum needs a wildcard or <decides>

GetWeaponClass(weapon.Bow) = "Ranged"
GetWeaponClassOrFail[weapon.Sword] = "Melee"
```

Even if you match all currently defined values in an open enum, you still need a wildcard or `<decides>` context because new values might be added in future versions.

#### Summary of Exhaustiveness Rules

| Enum Type | Case Coverage | Wildcard | Context | Result |
|-----------|---------------|----------|---------|--------|
| Closed | Full | No | Any | ✓ Valid - exhaustive |
| Closed | Full | Yes | Any | ⚠ Warning - unreachable wildcard |
| Closed | Partial | Yes | Any | ✓ Valid |
| Closed | Partial | No | `<decides>` | ✓ Valid - unmatched values fail |
| Closed | Partial | No | Non-`<decides>` | ✗ Error - missing cases |
| Open | Any | Yes | Any | ✓ Valid |
| Open | Any | No | `<decides>` | ✓ Valid - unmatched values fail |
| Open | Any | No | Non-`<decides>` | ✗ Error - open enum needs wildcard |

These rules ensure that closed enums provide safety through exhaustiveness while open enums require explicit handling of unknown values.

### Unreachable Case Detection

The compiler actively detects unreachable cases in case expressions, helping you identify dead code and logic errors. Duplicate cases are flagged as unreachable, and so is any case that follows a wildcard:

<!--versetest
assert_semantic_error(3616):
    status16 := enum:
        Active
        Inactive
        Pending
    GetCode16(S:status16):int =
        case (S):
            status16.Active => 1
            status16.Inactive => 2
            status16.Pending => 3
            status16.Pending => 4
assert_semantic_error(3616):
    other16 := enum:
        Active
        Inactive
    First16(S:other16):int =
        case (S):
            other16.Active => 1
            _ => 0
            other16.Inactive => 2
-->
<!-- 16 -->
```verse
status := enum:
    Active
    Inactive
    Pending

GetStatusCode(S:status):int =
    case (S):
        status.Active => 1
        status.Inactive => 2
        status.Pending => 3
        # status.Pending => 4  # ERROR: unreachable - already matched above

FirstOnly(S:status):int =
    case (S):
        status.Active => 1
        _ => 0                     # the wildcard matches everything
        # status.Inactive => 2  # ERROR: unreachable - the wildcard matched first

GetStatusCode(status.Pending) = 3
FirstOnly(status.Inactive) = 0
```

These errors prevent logic bugs where you think you are handling specific cases but the code will never execute.

### The `@ignore_unreachable` Attribute

Sometimes you intentionally want unreachable cases—for testing, migration, or defensive programming. The `@ignore_unreachable` attribute suppresses unreachable warnings and errors for specific cases. It only affects cases it is applied to; other unreachable cases without the attribute still produce errors:

<!--versetest
status := enum:
    Active
    Inactive
assert_semantic_error(3616):
    status17 := enum:
        Active
        Inactive
    Process17(S:status17):int =
        case (S):
            status17.Active => 1
            status17.Inactive => 2
            @ignore_unreachable status17.Inactive => 3
            status17.Active => 4
-->
<!-- 17 -->
```verse
ProcessStatus(S:status):int =
    case (S):
        status.Active => 1
        status.Inactive => 2
        @ignore_unreachable status.Inactive => 3  # suppressed, no error
        @ignore_unreachable _ => 0                # no unreachable warning
        # status.Active => 4  # ERROR: still unreachable without the attribute

ProcessStatus(status.Inactive) = 2
```

Use `@ignore_unreachable` sparingly, primarily during refactoring or when maintaining multiple code paths for testing purposes.

### Explicit Qualification

Enumerators can collide with identifiers in parent scopes. When this happens, you can use explicit qualification to disambiguate:

<!-- 18 -->
```verse
# top level 'Start'
Start:int = 0

# the enum wants to use 'Start' as an enumerator
game_state := enum:
    (game_state:)Start  # explicit qualification avoids the collision
    Playing
    Paused

# now both are accessible
Start = 0                           # references the int
StateStart:game_state = game_state.Start  # references the enum value
StateStart <> game_state.Playing
```

The syntax `(enum_name:)enumerator` explicitly qualifies the enumerator, preventing conflicts with outer-scope symbols.

Qualification also allows you to use reserved words and keywords as enum values, which would otherwise cause errors, and you can even use the enum's own name as a value when qualified:

<!--versetest
assert_semantic_error(3532):
    bad_enum19 := enum:
        public
        Regular
assert_semantic_error(3532):
    bad_recursive19 := enum:
        bad_recursive19
        OtherValue
-->
<!-- 19 -->
```verse
keyword_enum := enum:
    (keyword_enum:)public        # OK: reserved word qualified
    (keyword_enum:)for           # OK: keyword qualified
    (keyword_enum:)keyword_enum  # OK: qualified with the enum's own name
    Regular                      # normal enum value

# without qualification each of those three is an error

keyword_enum.Regular <> keyword_enum.public
```

This is particularly useful when modeling language constructs, access levels, or any domain where reserved words make natural value names.

### Comparison

Enum values are fully comparable, meaning they support both equality (`=`) and inequality (`<>`) operators. This makes them ideal for state tracking and conditional logic. Enum values from the same enum type can be compared, while values from different enum types are always unequal:

<!--versetest
weapon_type := enum:
    Sword
    Bow

game_state := enum:
    MainMenu
    Playing
    Paused
-->
<!-- 20 -->
```verse
CurrentWeapon := weapon_type.Sword
CurrentWeapon = weapon_type.Sword     # succeeds - same value
CurrentWeapon <> weapon_type.Bow      # succeeds - different values

CurrentState := game_state.Paused
PreviousState := game_state.Playing
CurrentState <> PreviousState

CurrentState <> weapon_type.Sword     # succeeds - different enum types
```

Because enums are comparable, they can be used as map keys, stored in sets, and used with generic functions that require comparable types:

<!--versetest
game_state := enum:
    Menu
    Playing
    Paused
-->
<!-- 21 -->
```verse
# enums as map keys
StateIDs:[game_state]int = map{
    game_state.Menu => 0,
    game_state.Playing => 1,
    game_state.Paused => 2
}

# in generic functions
FindStateID(States:[]game_state, Target:game_state):int =
    for (
        State : States, State = Target,
        ID := StateIDs[State]
    ):
        return ID
    -1 # return -1 if the state is not found

FindStateID(array{game_state.Menu, game_state.Paused}, game_state.Paused) = 2
FindStateID(array{game_state.Menu}, game_state.Playing) = -1
```
