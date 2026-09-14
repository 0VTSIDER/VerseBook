# Persistable Types

Persistable types allow you to store data that persists beyond the
current game session. This is essential for saving player progress,
preferences, and other game state that should be maintained across
multiple play sessions.

Persistable data is stored using module-scoped `weak_map(player, t)`
variables, where `t` is any persistable type. When a player joins a
game, their previously saved data is automatically loaded into all
module-scoped variables of type `weak_map(player, t)`. The examples in
this chapter use `persistent_key` rather than `player`, because it is
the key type available outside a Fortnite island; everything shown
applies unchanged to `weak_map(player, t)`.

<!-- 01 -->
```verse
progress := module:
    # Persistent storage is a module-scoped var weak_map
    var Levels:weak_map(persistent_key, int) = map{}

    # A player with nothing saved yet gets the default
    GetLevel(Key:persistent_key)<transacts>:int =
        if (Level := Levels[Key]) then Level else 1

    # Writing one entry saves it for the next session
    SetLevel(Key:persistent_key, Level:int)<transacts><decides>:void =
        set Levels[Key] = Level
```

## Built-in Persistable Types

The following primitive types are persistable by default:

- Numeric Types:

   - `logic` - Boolean values (true/false)
   - `int` - Integer values (must fit in 64-bit signed range for persistence)
   - `float` - Floating-point numbers

- Character Types:

   - `string` - Text values
   - `char` - Single UTF-8 character
   - `char32` - Single UTF-32 character

- Container Types:

   - `array` - Persistable if element type is persistable
   - `map` - Persistable if both key and value types are persistable
   - `option` - Persistable if the wrapped type is persistable
   - `tuple` - Persistable if all element types are persistable

!!! warning
    Persistence stores integers as 64-bit values. Serializing an integer outside
    that range fails at runtime (`IntegerBoundsExceeded` on VerseVM), even
    though VerseVM itself can represent it. Do not persist values produced by
    arbitrary-precision arithmetic without range-checking them first.

## Custom Persistable Types

You can create custom persistable types using the `<persistable>`
specifier with classes, structs, and enums.

Classes must meet specific requirements to be persistable:

<!--versetest
assert_semantic_error(3663):
    not_final := class<persistable>:
        XP:int = 0
assert_semantic_error(3664):
    is_unique := class<final><unique><persistable>:
        XP:int = 0
assert_semantic_error(3665):
    some_base := class:
        XP:int = 0
    has_super := class<final><persistable>(some_base){}
assert_semantic_error(3665):
    some_marker := interface{}
    has_interface := class<final><persistable>(some_marker):
        XP:int = 0
assert_semantic_error(3502):
    is_parametric(t:type) := class<final><persistable>:
        XP:int = 0
assert_semantic_error(3662):
    has_var := class<final><persistable>:
        var XP:int = 0
assert_semantic_error(3582):
    StartingXP():int = 0
    calls_function := class<final><persistable>:
        XP:int = StartingXP()
-->
<!-- 02 -->
```verse
player_profile := class<final><persistable>:
    Version:int = 1
    Title:string = ""
    Unlocked:[]string = array{}
    BestTimes:[string]float = map{}
    LastScore:?int = false
```

Requirements for persistable classes:

- Must have the `<persistable>` specifier
- Must be `<final>` (no subclasses allowed)
- Cannot be `<unique>`
- Cannot have a superclass (including interfaces)
- Cannot be parametric (generic)
- Can only contain persistable field types
- Cannot have variable members (`var` fields)
- Field initializers cannot call functions

Two of those rules are less separate than they look. A `var` field is
rejected not on its own account but because a mutable member's type is
never persistable, so it reports the same diagnostic as any other
unpersistable field. And the restriction on initializers is not about
effects: the compiler rejects every call in a data-member initializer,
effect-free ones included and in ordinary classes as much as persistable
ones, because it cannot prove the call terminates. Initializers are
limited to literals and constants.

Structs are ideal for simple data structures that will not change after
publication:

<!--versetest
assert_semantic_error(3502):
    parametric_pair(t:type) := struct<persistable>:
        Value:int
assert_semantic_error(3607, 3662):
    mutable_point := struct<persistable>:
        var X:float = 0.0
-->
<!-- 03 -->
```verse
coordinates := struct<persistable>:
    X:float = 0.0
    Y:float = 0.0
```

Requirements for persistable structs:

- Must have the `<persistable>` specifier
- Cannot be parametric (generic)
- Can only contain persistable field types (see Prohibited Field Types below)
- Field initializers cannot call functions
- Cannot be modified after island publication

Enums represent a fixed set of named values:

<!-- 04 -->
```verse
# A closed enum's set of values is fixed once published
difficulty := enum<persistable><closed>:
    Easy
    Normal
    Hard

# An open enum can gain new values in a later release
achievement := enum<persistable><open>:
    FirstWin
```

Important notes:

- `<closed>` persistable enums cannot be changed to open after publication
- Only `<open>` persistable enums can have new values added after publication

## Prohibited Field Types

Persistable types have strict restrictions on what field types they
can contain. The following types cannot be used as fields in
persistable classes or structs:

- Abstract and Dynamic Types:

   - `any` - Cannot be persisted (too dynamic)
   - `comparable` - Abstract interface type
   - `type` - Type values cannot be persisted

- Non-Serializable Types:

   - `rational` - Exact rational numbers (not persistable)
   - Function types (e.g., `int -> int`) - Functions cannot be serialized
   - `weak_map` - Weak references are not persistable
   - Interface types - Abstract interfaces cannot be persisted

- Non-Persistable User Types

   - Non-persistable enums - Enums without `<persistable>` specifier cannot be used
   - Non-persistable classes - Classes without `<persistable>` specifier cannot be used
   - Non-persistable structs - Structs without `<persistable>` specifier cannot be used

Every one of these produces the same diagnostic: the data member of a
persistable type must itself be persistable.

<!--versetest
assert_semantic_error(3662):
    f_any := class<final><persistable>:
        Anything:any
assert_semantic_error(3662):
    f_comparable := class<final><persistable>:
        Key:comparable
assert_semantic_error(3662):
    f_type := class<final><persistable>:
        Shape:type
assert_semantic_error(3662):
    f_rational := class<final><persistable>:
        Exact:rational
assert_semantic_error(3662):
    f_function := class<final><persistable>:
        Scale:type{_(:int):int}
assert_semantic_error(3662):
    f_weak_map := class<final><persistable>:
        Cache:weak_map(int, int)
assert_semantic_error(3662):
    marker := interface{}
    f_interface := class<final><persistable>:
        Plugin:marker
assert_semantic_error(3662):
    plain_enum := enum:
        Solo
    f_enum := class<final><persistable>:
        Mode:plain_enum
assert_semantic_error(3662):
    plain_class := class:
        Value:int = 0
    f_class := class<final><persistable>:
        Owner:plain_class
assert_semantic_error(3662):
    plain_struct := struct:
        Value:int = 0
    f_struct := class<final><persistable>:
        Point:plain_struct
-->
<!-- 05 -->
```verse
save_slot := class<final><persistable>:
    Label:string = ""
    Scores:[]int = array{}

    # ERROR: Anything:any              - too dynamic to serialize
    # ERROR: Key:comparable            - abstract interface type
    # ERROR: Shape:type                - type values cannot be persisted
    # ERROR: Exact:rational            - not serializable
    # ERROR: Scale:type{_(:int):int}   - functions cannot be serialized
    # ERROR: Cache:weak_map(int, int)  - weak references are not persistable
    # ERROR: Plugin:marker             - interface types are abstract
    # ERROR: Mode:plain_enum           - enum without <persistable>
    # ERROR: Owner:plain_class         - class without <persistable>
    # ERROR: Point:plain_struct        - struct without <persistable>
```

## Example

Putting the pieces together, here is a persistable struct behind a
module that reads and updates one player's saved progress. Because a
persistable type has no `var` fields, an update replaces the whole
stored value rather than assigning into it:

<!-- 06 -->
```verse
player_stats := struct<persistable>:
    Level:int = 1
    Experience:int = 0

progress_tracker := module:
    var Stats:weak_map(persistent_key, player_stats) = map{}

    # A player with nothing saved yet gets the struct's defaults
    GetStats(Key:persistent_key)<transacts>:player_stats =
        if (Existing := Stats[Key]) then Existing else player_stats{}

    AddExperience(Key:persistent_key, Points:int)<transacts><decides>:void =
        Current := GetStats(Key)
        set Stats[Key] = player_stats:
            Level := Current.Level
            Experience := Current.Experience + Points
```

## JSON Serialization

!!! note "Unreleased Feature"
    JSON Serialization have not yet been released and is not publicly available.

Verse provides JSON serialization functions for persistable types,
enabling manual serialization and deserialization of data. While the
primary persistence mechanism uses `weak_map(player, t)` for automatic
player data, JSON serialization can be useful for debugging, data
migration, or integration with external systems.

`ToJson` converts a persistable value to a JSON string, and `FromJson`
deserializes a JSON string back to a typed value:

<!--versetest
player_data := class<final><persistable>:
    Level:int = 1
    Score:int = 100
PersistenceModule := module{
    ToJson<public>(Data:player_data)<decides>:string = ""
    FromJson<public>(JsonStr:string, T:type)<transacts><decides>:player_data =
        false?
        player_data{}
}
-->
<!-- 07 -->
```verse
Data := player_data{Level := 5, Score := 250}
Json := PersistenceModule.ToJson[Data]
# {"$package_name":"/...", "$class_name":"player_data", "x_Level":5, "x_Score":250}

if (Restored := PersistenceModule.FromJson[Json, player_data]):
    Restored.Level = 5
```

All serialized persistable objects include metadata fields:

```json
{
  "$package_name": "/SolIdeDataSources/_Verse",
  "$class_name": "player_data",
  "x_Level": 5,
  "x_Score": 250
}
```

Of these, `$package_name` is the package path of the type and
`$class_name` is the qualified class or struct name. Field names are
prefixed with `x_` in the current format; an older format used mangled
names like `i___verse_0x123_FieldName`.

### Type-Specific Serialization

Each persistable type has its own JSON encoding:

| Field                                | JSON                                                   |
| ------------------------------------ | ------------------------------------------------------ |
| `Value:int = 42`                     | `"x_Value":42`                                         |
| `Value:?int = false`                 | `"x_Value":false`                                      |
| `Value:?int = option{42}`            | `"x_Value":{"":42}`                                    |
| `Pair:tuple(int, int) = (4, 5)`      | `"x_Pair":[4,5]`                                       |
| `Empty:tuple() = ()`                 | `"x_Empty":[]`                                         |
| `Values:[]int = array{1, 2, 3}`      | `"x_Values":[1,2,3]`                                   |
| `Lookup:[string]int = map{"a" => 1}` | `"x_Lookup":[{"k":{"":"a"},"v":{"":1}}]`               |
| `Mode:difficulty = difficulty.Easy`  | `"x_Mode":"difficulty::Easy"`                          |

A primitive becomes the corresponding JSON scalar. An `option` is
`false` when empty and an object with a single empty key when present.
Tuples and arrays become JSON arrays, a map becomes an array of
key/value pairs, and an enum becomes its qualified name as a string.

### Default Value Handling

When deserializing, missing fields are automatically filled with their default values:

<!--versetest
versioned_data := class<final><persistable>:
    Version:int = 1
    NewField:int = 0
PersistenceModule := module{
    FromJson<public>(JsonStr:string, T:type)<transacts><decides>:versioned_data =
        false?
        versioned_data{}
}
-->
<!-- 08 -->
```verse
# Old JSON, written before NewField existed, carries no x_NewField
OldJson := "\{\"x_Version\":1\}"

if (Data := PersistenceModule.FromJson[OldJson, versioned_data]):
    Data.Version = 1
    Data.NewField = 0   # filled in from the field's default
```

This enables forward-compatible schema evolution - new fields with
defaults can be added without breaking old saved data.

### Block Clauses During Deserialization

Block clauses do not execute when deserializing from JSON:

<!--versetest
PersistenceModule := module{
    FromJson<public>(JsonStr:string, T:type)<transacts><decides>:audited =
        false?
        audited{}
}
-->
<!-- 09 -->
```verse
audited := class<final><persistable>:
    Value:int = 0
    block:
        Print("constructed")

# Normal construction runs the block clause
Instance := audited{Value := 1}

# Deserialization does not: nothing is printed here
if (Loaded := PersistenceModule.FromJson["{}", audited]):
    Loaded.Value = 0
```

Block clauses are only executed during normal construction, not during
deserialization. This means initialization logic in blocks will not run
for loaded data.

### Integer Range Limitations

Verse protects against integer overflow during serialization. Integers
that exceed the safe serialization range cause runtime errors, so a
field holding a value produced by arbitrary-precision arithmetic can
serialize correctly in testing and fail in the field.

This prevents silent precision loss that could occur with
floating-point representation of large integers.

## Best Practices

- Design your persistable types carefully for schema stability, as
they cannot be easily changed after publication. Consider versioning
strategies for future updates.

- For data that will not need inheritance or complex behavior, prefer
persistable structs over classes.

- Always check if data exists for a player before accessing it, and
provide appropriate defaults for missing data.

- When updating persistent data, create new instances rather than
trying to modify existing ones (Verse uses immutable data structures),
which makes every update atomic.

- Persistent data is loaded for all players when they join, so be
mindful of the memory used by the amount of data stored per player.
