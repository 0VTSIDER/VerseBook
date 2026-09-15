# Modules

A module groups related definitions under a name and controls what the
rest of the world can see of them. You might keep inventory handling in
one module, combat in another, and UI in a third, each exposing only
what its callers need.

Modules also give every published definition a unique, permanent path
in a global namespace. Together with the compatibility rules in
[Code Evolution](18_evolution.md), that is what allows code to be
published once and depended on by others afterwards.

Each module is intrinsically linked to the file system structure of
your project. When you create a folder in your Verse project, that
folder automatically becomes a module. The module's name is simply the
folder's name, making the relationship between your file organization
and your code organization completely transparent.

All `.verse` files within the same folder are considered part of that
module and share the same namespace. This means that if you have three
files - `player.verse`, `inventory.verse`, and `equipment.verse` - all
in a folder called `PlayerSystems`, they all contribute to the
`PlayerSystems` module and can reference each other's definitions
without any import statements. This automatic grouping makes it easy
to split large modules across multiple files for better organization
while maintaining the logical unity of the module.

## Paths

Paths are the addressing system that makes Verse's vision of a shared,
persistent Metaverse possible. Just as every website on the internet
has a unique URL, every module has a unique path that identifies it
globally. This path system is more than just a naming convention -
it is a fundamental part of how Verse manages code distribution,
versioning, and dependencies.

Paths borrow conceptually from web domains with adaptations for the
needs of a programming language. A path starts with a forward slash
`/` and typically includes a domain-like identifier followed by one or
more path segments. This creates a hierarchical namespace that is both
human-readable and globally unique.

The format `/domain/path/to/module` serves several important purposes:

- **Persistent and unique identification**: Once a module is published
  at a particular path, that path belongs to it forever. No other
  module can ever claim the same path, ensuring that dependencies
  always resolve to the correct code.

- **Ownership and authority**: The domain portion of the path (like
  `Fortnite.com` or `Verse.org`) indicates who owns and maintains the
  module. This helps developers understand the source and
  trustworthiness of the code they are using.

- **Discoverability**: Because paths follow a predictable pattern,
  developers can often guess or easily find the modules they
  need. Documentation and tooling can also leverage this structure to
  provide better discovery experiences.

- **Hierarchical organization**: The path structure naturally supports
  organizing related modules together. For example, all UI-related
  modules might live under `/YourGame.com/UI/`, making them easy to
  find and understand as a group.

Epic Games provides several standard modules that are commonly used:

- `/Verse.org/Verse` - Core language features and standard library functions
- `/Verse.org/Random` - Random number generation utilities
- `/Verse.org/Simulation` - Simulation and timing utilities
- `/Fortnite.com/Devices` - Integration with Fortnite Creative devices
- `/UnrealEngine.com/Temporary/Diagnostics` - Debugging and diagnostic tools
- `/UnrealEngine.com/Temporary/SpatialMath` - 3D math and spatial operations

The use of "Temporary" in some paths indicates that these modules are
provisional and may be reorganized in future versions of Verse. This
naming convention helps set expectations about the stability of the
API.

When you create your own modules, they can exist at various levels of
the path hierarchy:

- `/YourGame/` - Top-level module for your game
- `/YourGame/Player/` - Player-related functionality
- `/YourGame/Player/Inventory/` - Specific inventory management
- `/pizlonator@fn.com/NightDeath/` - Personal or experimental modules

The ability to include email-like identifiers (such as
`pizlonator@fn.com`) allows individual developers to claim their own
namespace without needing to own a domain. This democratizes the
module system while still maintaining uniqueness guarantees.

## Creating Modules

A module can contain:

- Constants and variables
- Functions
- Classes, interfaces, and structs
- Enums
- Other module definitions
- Type definitions

When you create a subfolder in a Verse project, a module is
automatically created for that folder. The file structure directly
maps to the module hierarchy.

You can create modules within a `.verse` file using the following syntax:

<!-- 01 -->
```verse
# Colon syntax
inventory := module:
    Capacity<public>:int = 20

    slot<public> := class:
        Item<public>:string = ""

# Bracket syntax (also supported)
crafting := module { Recipes<public>:int = 8 }
```
<!--versetest
inventory.Capacity = 20
crafting.Recipes = 8
-->

Modules can contain other modules, creating a hierarchy. The file
structure `ModuleFolder/BaseModule/Submodule` is equivalent to:

<!-- 02 -->
```verse
ModuleFolder := module:
    BaseModule<public> := module:
        Submodule<public> := module:
            submodule_class<public> := class:
                Value<public>:int = 100
```
<!--versetest
ModuleFolder.BaseModule.Submodule.submodule_class{}.Value = 100
-->

### Restrictions

Module bodies have strict requirements about what they can
contain. Understanding these restrictions helps avoid common errors
when defining modules.

A module body can only contain definition statements—declarations that
bind names to values. You cannot include arbitrary expressions or
executable statements. All data definitions at module scope must also
explicitly specify their type; type inference with `:=` alone is not
allowed:

<!--versetest
assert_semantic_error(3560):
    Bad1 := module:
        MaxValue<public>:int = 100
        1 + 2
assert_semantic_error(3547):
    Bad2 := module:
        Limit := 100
-->
<!-- 03 -->
```verse
Config := module:
    MaxValue<public>:int = 100
    DefaultName<public>:string = "Player"

    Score<public>(Base:int)<computes>:int = Base * 10

    # 1 + 2          # ERROR: not a definition
    # Limit := 100   # ERROR: must specify a type domain
```
<!--versetest
Config.Score(10) = 100
-->

The first restriction ensures that module initialization is
deterministic and does not execute arbitrary code when the module is
loaded. The second makes module interfaces explicit and helps with
separate compilation and module evolution.

Modules can contain these categories of definitions:

<!-- 04 -->
```verse
Utilities := module:
    # Constants with explicit types
    Version<public>:int = 1
    AppName<public>:string = "MyApp"

    # Functions
    Calculate<public>(X:int)<computes>:int = X * 2

    # Classes, interfaces, structs
    data_class<public> := class:
        Value<public>:int

    data_interface<public> := interface:
        GetValue<public>()<computes>:int

    data_struct<public> := struct:
        X:float
        Y:float

    # Enums
    status<public> := enum:
        Active
        Inactive

    # Nested modules
    Nested<public> := module:
        Label<public>:string = "nested"

    # Type aliases
    coordinate<public> := tuple(float, float)

    # Refinement types
    positive_int<public> := type{X:int where X > 0}
```
<!--versetest
Utilities.Calculate(21) = 42
Utilities.Nested.Label = "nested"
-->

Unlike functions, classes, or data values, modules are not first-class
citizens in Verse. You cannot treat modules as values that can be
stored, passed, or manipulated at runtime. A module name cannot be
bound to a variable, passed as an argument, or collected into a tuple:

<!--versetest
assert_semantic_error(3502, 3547, 3502):
    MyModule := module:
        Value<public>:int = 42
    M:MyModule = MyModule
assert_semantic_error(3502):
    Process(M:module):void = {}
assert_semantic_error(3502, 3502, 3547):
    ModA := module:
        Value<public>:int = 1
    Modules := (ModA, ModA)
-->
<!-- 05 -->
```verse
MyModule := module:
    Value<public>:int = 42

# M:MyModule = MyModule             # ERROR: a module is not a value
# Process(M:module):void = {}       # ERROR: there is no module type
# Modules := (MyModule, MyModule)   # ERROR: no collections of modules
```
<!--versetest
MyModule.Value = 42
-->

Modules exist purely as namespaces and organizational constructs at
compile time. The module identifier `MyModule` can only be used in
specific contexts, and there is no `module` type that can be used in
function signatures.

## Importing Modules

The import system is designed to be explicit and predictable. Unlike
some languages that automatically import commonly used modules or
search multiple locations for dependencies, Verse requires you to
explicitly declare every external module you want to use. This
explicitness helps prevent naming conflicts and makes dependencies
clear.

The `using` statement is the primary mechanism for importing modules
into your Verse code. It usually is placed at the top of your file, before
any other code definitions, and makes the contents of the specified module
available in your current scope.

The basic syntax is straightforward - the keyword `using` followed by
the module path in curly braces:

<!--NoCompile-->
<!-- 06 -->
```verse
using { /Verse.org/Random }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
```

When you import a module, all its public members become available in
your code. However, you still need to qualify them with the module
name unless the names are unambiguous. This qualification requirement
helps maintain code clarity and prevents accidental use of the wrong
definition when multiple modules define similar names.

The `using` directive is a statement-level declaration that must
appear at the top level of your code. You cannot use it as an
expression or embed it in other expressions. Besides the file level,
which is the most common placement, the other legal home for a `using`
is the body of a module definition:

<!--versetest
assert_semantic_error(3669):
    M11 := module:
        Gain<public>:int = 2
    Mix11():void = using{M11}
assert_semantic_error(3537):
    M11b := module:
        Gain<public>:int = 2
    mixer11 := class:
        using{M11b}
        Field:int
-->
<!-- 07 -->
```verse
audio := module:
    Gain<public>:int = 2

mixer := module:
    using { audio }
    Doubled<public>:int = Gain * 2

# Invalid: using in an expression context
# Mix():void = using{audio}   # ERROR: not an expression

# Invalid: using in a class, struct or interface body
# mixer_class := class:
#     using{audio}            # ERROR: not allowed in a class body
#     Field:int
```
<!--versetest
mixer.Doubled = 4
-->

Module `using` statements must appear at the file or module level, not
nested within other constructs. This ensures that imports are visible
and consistent throughout the scope where they are declared.

While module imports with paths are not allowed in function bodies,
Verse does support local scope `using` with local variables and
parameters. See [Local Scope Using](#local-scope-using) below for
details.

### Import Resolution

When Verse encounters a `using` statement, it follows a specific resolution process:

1. **Absolute paths** (starting with `/`) are resolved from the global module registry
2. **Relative paths** (without leading `/`) are resolved relative to the current module's location
3. **Nested modules** can be accessed through their parent modules

This resolution process happens at compile time, meaning that all
imports must be resolvable when your code is compiled. There's no
runtime module loading or dynamic imports in Verse.

### Local and Relative Imports

For modules within your own project, you have flexibility in how you reference them:

<!--NoCompile-->
<!-- 08 -->
```verse
# Absolute import from your project root
using { /MyGameProject/Systems/Combat }

# Import from a sibling folder
using { ../UI/MainMenu }

# Import from the same directory
using { PlayerController }

# Import from a subdirectory
using { Subsystems/WeaponSystem }
```

The choice between absolute and relative imports often depends on your
project structure and whether you plan to reorganize your
modules. Absolute imports are more stable when refactoring, while
relative imports can make module groups more portable.

### Nested Imports

Nested modules present special considerations for importing. The order
in which you import modules matters, and there are multiple valid
approaches:

<!--versetest
assert_semantic_error(3506, 3506):
    GS2 := module:
        Inv2<public> := module:
            Slots<public>:int = 8
    Bad2 := module:
        using { Inv2 }
        Total<public>:int = Slots
-->
<!-- 09 -->
```verse
GameSystems := module:
    Inventory<public> := module:
        Slots<public>:int = 8

Loadout := module:
    # Method 1: import parent first, then child
    using { GameSystems }
    using { Inventory }
    Total<public>:int = Slots * 2

Storage := module:
    # Method 2: direct path to the nested module
    using { GameSystems.Inventory }
    Total<public>:int = Slots * 3

Vault := module:
    # Method 3: import the parent and qualify the child
    using { GameSystems }
    Total<public>:int = Inventory.Slots * 4

    # Reversing method 1 is an error: `using { Inventory }` before
    # `using { GameSystems }` cannot resolve Inventory
```
<!--versetest
Loadout.Total = 16
Storage.Total = 24
Vault.Total = 32
-->

The restriction on import order exists because Verse resolves imports
sequentially. When you import a nested module directly, Verse needs to
know about its parent module first. This is why importing the parent
before the child always works, while the reverse order fails.

### Using a Value

`using` also accepts an expression that evaluates to a class instance. Its
members become directly nameable for the remainder of the enclosing block,
which is useful for cutting repetition when working against one object:

<!-- 10 -->
```verse
settings := class:
    Volume<public>:int = 3

Describe()<transacts>:int =
    Config := settings{}
    using { Config }
    Volume              # resolves to Config.Volume
```
<!--versetest
Describe() = 3
-->

A local `using` is captured like any other local, so the names stay valid inside
a concurrent body such as the arms of a `branch`.

### Module Aliases with import

The `import` expression creates a local alias for a module, binding
its path to a name. Unlike `using`, which brings a module's public
members directly into scope, `import` lets you access them through
the alias with dot notation. Like `using`, it may only appear at
module scope:

<!-- 11 -->
```verse
# using: members are available directly
sampler := module:
    using { /Verse.org/Random }
    Roll<public>(Sides:int)<transacts>:int = GetRandomInt(1, Sides)

# import: members are reached through an alias
dice := module:
    Rand := import(/Verse.org/Random)
    using { Rand }    # optional: also brings the members into scope
    Roll<public>(Sides:int)<transacts>:int = Rand.GetRandomInt(1, Sides)
```
<!--versetest
sampler.Roll(6) >= 1
dice.Roll(6) >= 1
-->

This is useful when you want to avoid name collisions, or when you
need to make the origin of a definition explicit in your code: with a
physics module and a graphics module aliased as `Physics` and
`Graphics`, `Physics.Transform` and `Graphics.Transform` can never be
confused.

Module aliases created with `import` are visible across all snippets
within the same module. As the `dice` module shows, an `import` can
also be combined with `using` to both alias a module and bring its
members into scope.

Note that `import` only works with module paths. Attempting to import
a path that resolves to a class or other non-module definition is an
error.

### Scope and Visibility

Imports have file scope - they only affect the file in which they
appear. If you have multiple `.verse` files in the same module, each
file needs its own import statements for external modules. However,
files within the same module can see each other's definitions without
imports:

<!-- 12 -->
```verse
# File: player_module/health.verse
health_component := class:
    CurrentHealth:float = 100.0

# File: player_module/armor.verse
# No import needed for health_component since it is in the same module
armor_component := class:
    HealthComp:health_component = health_component{}
```
<!--versetest
armor_component{}.HealthComp.CurrentHealth = 100.0
-->

### Import Conflicts

When two imported modules define members with the same name, you need to disambiguate:

<!--versetest
assert_semantic_error(3588, 3532, 3532):
    melee13 := module:
        Bonus<public>:int = 2
    spell13 := module:
        Bonus<public>:int = 3
    using { melee13 }
    using { spell13 }
    X:int = Bonus
-->
<!-- 13 -->
```verse
melee := module:
    Bonus<public>:int = 2

spell := module:
    Bonus<public>:int = 3

# Dot notation is never ambiguous
Total()<computes>:int = melee.Bonus + spell.Bonus

# using both modules is what creates the clash:
# using { melee }
# using { spell }
# X:int = Bonus          # ERROR: ambiguous identifier
```
<!--versetest
Total() = 5
-->

### Qualified Names

After importing, you can refer to module contents using qualified
names. Verse provides two forms of qualification: standard dot
notation for most cases, and special qualified access syntax for
disambiguation.

When you need to disambiguate between identifiers with the same name
from different modules, or when you want to explicitly specify the
scope of an identifier, use a qualified access expression using
parentheses and a colon:

<!-- 14 -->
```verse
audio := module:
    Volume<public>:int = 5

mixer := module:
    using { audio }

    Mix<public>()<computes>:int =
        (local:)Volume:int = 1
        (local:)Volume + (audio:)Volume   # 1 + 5
```
<!--versetest
mixer.Mix() = 6
-->

This comes up in practice when a name you define collides with one added to the
standard library. If your module defines `Last` and the array extension `Last`
is also in scope, `MyModule.Last(X)` becomes ambiguous and must be written
`MyModule.(MyModule:)Last(X)` to select yours.


<!-- BUG? Or bad error message?

m := module{ item<public> := class{} }

x := module{
item := class{}
F():void =
    A := (local:)item{} 
    B := (m:)item{}
}


LogVerseBuild: Error: C:/VerseBook/Book/verse/16_modules/17.versetest(8,10, 8,22): Script Error 3506: Unknown identifier `item`. Did you mean any of:
InventoryModule.item
item
LogVerseBuild: Error: C:/VerseBook/Book/verse/16_modules/17.versetest(9,10, 9,33): Script Error 3506: Unknown identifier `item`. Did you mean any of:
InventoryModule.item

-->

The qualified access expression `(module:)identifier` is particularly useful in several scenarios:

1. **Resolving naming conflicts**: When multiple imported modules export the same identifier
2. **Explicit scoping**: When you want to make it clear which module an identifier comes from for readability
3. **Accessing shadowed names**: When a local definition shadows a module member
4. **Generic programming**: When working with parametric types where the qualifier might be computed

## Module-Scoped Variables

Variables defined at module scope are global to any game instance where the variable is in scope.

Restrictions on module-scoped definitions:

- Direct `var` declarations of simple types (like `var X:int = 0`) are not allowed at module scope
- Instances of `<unique>` classes with `<allocates>` can be created at module scope, as long as their construction does not actually allocate mutable memory
- For persistent mutable state, use `weak_map` with appropriate key types (see below)

Use `weak_map(session, t)` for variables that persist for the duration of a game session:

<!--versetest
session := class<unique>{}
GetSession()<transacts>:session = session{}
-->
<!-- 15 -->
```verse
var GlobalCounter:weak_map(session, int) = map{}

IncrementCounter()<transacts>:void =
    CurrentValue := if (Value := GlobalCounter[GetSession()]) then Value + 1 else 0
    if (set GlobalCounter[GetSession()] = CurrentValue) {}
```

Use `weak_map(player, t)` for data that persists across game sessions:

<!--versetest
player := class<unique><persistent><module_scoped_var_weak_map_key>{}
var PlayerSaveData:weak_map(player, player_data) = map{}

player_data := class<final><persistable>:
    Level:int = 1
    Experience:int = 0
    UnlockedItems:[]string = array{}

SavePlayerProgress(Player:player, NewData:player_data)<decides>:void =
    set PlayerSaveData[Player] = NewData
<#
-->
<!-- 16 -->
```verse
var PlayerSaveData:weak_map(player, player_data) = map{}

player_data := class<final><persistable>:
    Level:int = 1
    Experience:int = 0
    UnlockedItems:[]string = array{}

SavePlayerProgress(Player:player, NewData:player_data)<decides>:void =
    set PlayerSaveData[Player] = NewData
```
<!-- #> -->

## Metaverse and Publishing

When you publish a module to the Metaverse, the module path becomes
globally accessible, its public members become part of the module's
API, and from that point the module must maintain backward
compatibility.

The following example of shows how evolution works:

<!--NoCompile-->
<!-- 17 -->
```verse
# Initial publication
Thing<public>:rational = 1/3

# Valid updates: change the value, or narrow the type to a subtype
Thing<public>:rational = 10/3
Thing<public>:int = 20

# Invalid updates: removing the member, or changing to an
# incompatible type such as Thing<public>:string = "hello"
```

## Local Qualifiers

The `(local:)` qualifier can disambiguate identifiers within
functions. This is critical for evolution compatibility—when external
modules add new public definitions after your code is published,
`(local:)` ensures your local definitions take precedence.

<!--versetest
assert_semantic_error(3588, 3532):
    Ext18<public> := module:
        ShadowX<public>:int = 10
    Mine18 := module:
        using{Ext18}
        Foo<public>()<computes>:float =
            ShadowX:float = 0.0
            ShadowX
-->
<!-- 18 -->
```verse
ExternalModule := module:
    # ShadowX is added after your code is published
    ShadowX<public>:int = 10

MyModule := module:
    using{ExternalModule}

    # Without (local:), `ShadowX:float = 0.0` conflicts with
    # ExternalModule.ShadowX

    # With (local:) the intent is unambiguous
    Foo<public>()<computes>:float =
        (local:)ShadowX:float = 0.0   # local definition
        (local:)ShadowX               # returns 0.0, not 10
```
<!--versetest
MyModule.Foo() = 0.0
-->

The qualifier applies to function parameters, data definitions in a
function body, `for` loop variables, `if` conditions, block scopes and
class blocks:

<!-- 19 -->
```verse
qualifiers := module:
    # Parameters and function body data definitions
    Scale<public>((local:)Factor:int)<computes>:int =
        (local:)Base:int = 10
        (local:)Base * (local:)Factor

    # For loop variables
    SumTo<public>((local:)Limit:int)<transacts>:int =
        var Total:int = 0
        for ((local:)Index := 0..(local:)Limit):
            set Total += (local:)Index
        Total

    # Block scopes and if conditions
    Clamp<public>((local:)X:int)<computes>:int =
        block:
            (local:)Max:int = 5
            if ((local:)X > (local:)Max) then (local:)Max else (local:)X

# Class blocks
counter := class:
    var Value<public>:int = 0
    block:
        (local:)Start:int = 42
        set (counter:)Value = (local:)Start
```
<!--versetest
qualifiers.Scale(3) = 30
qualifiers.SumTo(3) = 6
qualifiers.Clamp(9) = 5
counter{}.Value = 42
-->

The one place `(local:)` does not help is a nested redefinition: you
currently cannot redefine a `(local:)` qualified identifier in a
nested block.

<!--versetest
assert_semantic_error(3532):
    Bad20((local:)X:int)<computes>:int =
        block:
            (local:)X:float = 5.5
        (local:)X
-->
<!-- 20 -->
```verse
Scale((local:)X:int)<computes>:int =
    block:
        (local:)Factor:int = 2   # a fresh name is fine
        (local:)X * (local:)Factor
    # (local:)X:float = 5.5      # ERROR: X is already defined
```
<!--versetest
Scale(5) = 10
-->

This limitation may be lifted in future versions to support more complex scoping patterns.

## Automatic Qualification

!!! warning "Unreleased Feature"
    Automatic qualification has not yet been fully implemented. This section documents planned functionality that is not currently available. The behavior described here, particularly regarding how the compiler transforms identifiers in published code, should not be relied upon until officially released.

When you write Verse code, you use simple, unqualified identifiers for
clarity and readability. However, the Verse compiler will internally
transform all identifiers into fully-qualified forms that explicitly
specify their scope and origin. This process, called *automatic
qualification*, will ensure that every identifier is unambiguous and can
be resolved to exactly one definition.

Understanding automatic qualification will help you understand how Verse
will resolve names, why certain errors occur, and how the module system
will maintain correctness even in complex codebases with many modules and
overlapping names.

The compiler will qualify several categories of identifiers:

1. **Top-level definitions** - Functions, variables, classes, modules at package scope
2. **Type references** - All types, including built-in types like `int` and `string`
3. **Function parameters** - Local parameters get the `(local:)` qualifier
4. **Class and interface members** - Methods, fields, nested within composite types
5. **Module members** - Public and internal definitions within modules
6. **Nested scopes** - References within nested modules, classes, and functions

Verse uses several patterns to qualify identifiers based on their
scope. Definitions at the root of a package are qualified with the
package path, and function parameters and local variables are marked
with `(local:)`:

<!--NoCompile-->
<!-- 21 -->
```verse
# What you write:
ProcessValue(Input:int, Multiplier:int):int =
    Input * Multiplier

# How the compiler sees it:
(/YourPackage:)ProcessValue((local:)Input:(/Verse.org/Verse:)int, (local:)Multiplier:(/Verse.org/Verse:)int):(/Verse.org/Verse:)int =
    (local:)Input * (local:)Multiplier
```

The package path `/YourPackage` becomes the qualifier for
`ProcessValue`, while the parameters get the special `(local:)`
qualifier, and the built-in type `int` is qualified with its standard
library path `/Verse.org/Verse`.

Members within classes, interfaces, or modules get qualified with their container's path:

<!--NoCompile-->
<!-- 22 -->
```verse
# What you write:
player_class := class:
    Health:float = 100.0

    TakeDamage(Amount:float):void =
        set Health = Health - Amount

# How the compiler sees it:
(/YourPackage:)player_class := class:
    (/YourPackage/player_class:)Health:(/Verse.org/Verse:)float = 100.0

    (/YourPackage/player_class:)TakeDamage((local:)Amount:(/Verse.org/Verse:)float):(/Verse.org/Verse:)void =
        set (/YourPackage/player_class:)Health = (/YourPackage/player_class:)Health - (local:)Amount
```

Notice how `Health` and `TakeDamage` are qualified with `/YourPackage/player_class` to indicate they are members of the class.

Definitions within modules are qualified with the module path, and a
nested module extends that path by one more segment. All built-in
types are qualified with their standard library paths. This makes it
explicit where these types come from and maintains consistency with
user-defined types:

```
int       → (/Verse.org/Verse:)int
float     → (/Verse.org/Verse:)float
string    → (/Verse.org/Verse:)string
logic     → (/Verse.org/Verse:)logic
message   → (/Verse.org/Verse:)message
```

When you write `X:int`, the compiler expands it to `X:(/Verse.org/Verse:)int`, making the type's origin explicit.

### Example

Here's a more realistic example showing how qualification would work across multiple scopes:

<!--NoCompile-->
<!-- 23 -->
```verse
# What you write:
GameSystem := module:
    BaseValue:int = 42

    Calculator := module:
        Multiplier:int = 2

        Calculate(Input:int):int =
            Input * Multiplier + BaseValue

# How the compiler will see it (when implemented):
(/YourGame:)GameSystem := module:
    (/YourGame/GameSystem:)BaseValue:(/Verse.org/Verse:)int = 42

    (/YourGame/GameSystem:)Calculator := module:
        (/YourGame/GameSystem/Calculator:)Multiplier:(/Verse.org/Verse:)int = 2

        (/YourGame/GameSystem/Calculator:)Calculate((local:)Input:(/Verse.org/Verse:)int):(/Verse.org/Verse:)int =
            (local:)Input * (/YourGame/GameSystem/Calculator:)Multiplier + (/YourGame/GameSystem:)BaseValue
```

Notice how:

- The parameter `Input` is `(local:)`
- `Multiplier` is qualified with its containing module path
- `BaseValue` is qualified with the outer module path
- All type references are qualified with the Verse standard library path

Automatic qualification will only apply to published code, not your
source code. Verse currently enforces strict anti-shadowing rules to
prevent confusion and maintain code clarity. For example, a nested
module may not reuse the name of an enclosing one:

<!--versetest
assert_semantic_error(3532):
    Thing24 := module:
        Thing24 := module:
            Potato := module{}
-->
<!-- 24 -->
```verse
Thing := module:
    Potato<public> := module:
        Value<public>:int = 1

# Thing := module:
#     Thing := module{}   # ERROR: cannot shadow the outer Thing
```
<!--versetest
Thing.Potato.Value = 1
-->

Even with automatic qualification, nested definitions cannot shadow outer definitions with the same name. If you want to intentionally shadow something, you must use explicit qualifiers to make your intent clear. This strict approach helps prevent bugs and makes code evolution safer.

### Qualification with Using

When you import modules with `using`, the compiler still qualifies all identifiers, but it can resolve unqualified names to the imported modules:

<!-- NoCompile-->
<!-- 25 -->
```verse
# What you write:
using { /Verse.org/Random }

GenerateRandomValue():float =
    GetRandomFloat(0.0, 1.0)

# How the compiler sees it:
using { /Verse.org/Random }

(/YourGame:)GenerateRandomValue():(/Verse.org/Verse:)float =
    (/Verse.org/Random:)GetRandomFloat(0.0, 1.0)
```

The compiler resolves `GetRandomFloat` to `(/Verse.org/Random:)GetRandomFloat` based on the `using` statement.

### When It Matters

Once implemented, you will rarely need to think about automatic or manual qualification during normal
development, as the compiler will handle it transparently. However,
understanding it will help in several situations.

When the compiler reports ambiguous or unresolved identifiers,
understanding qualification helps you see why. If two imported modules
both define `Calculate`, the compiler cannot automatically qualify a
bare `Calculate` - it could be either `(/ModuleA:)Calculate` or
`(/ModuleB:)Calculate`. The same happens on a smaller scale when a
local variable has the same name as a module member: qualification is
what distinguishes `(/MyModule:)Value` from `(local:)Value`.

Compiler error messages sometimes show qualified names to precisely
identify which definition is involved:

```
Error: Cannot assign (/Verse.org/Verse:)string to (/Verse.org/Verse:)int at line 42
```

This makes it clear that the error involves the built-in `string` and
`int` types, not user-defined types with the same names.

Tools that generate Verse code or analyze code structure work with the
qualified form, so understanding it helps when working with such
tools.

### Explicit Qualification

While the compiler automatically qualifies identifiers, you can also
explicitly qualify them using the qualified access syntax
`(qualifier:)identifier`. This is useful when you want to override
automatic resolution or make your intent explicit:

<!-- 26 -->
```verse
GameSystem := module:
    Value<public>:int = 100

    # Explicitly qualify to avoid any ambiguity
    GetValue<public>()<computes>:int = (GameSystem:)Value

    # Use the local qualifier for parameters
    Scale<public>((local:)Value:int)<computes>:int =
        (GameSystem:)Value * (local:)Value
```
<!--versetest
GameSystem.GetValue() = 100
GameSystem.Scale(2) = 200
-->

Explicit qualification is particularly valuable when:

- Resolving naming conflicts between imported modules
- Making code more self-documenting
- Overriding shadowing behavior
- Working with dynamic or computed qualifiers

## Local Scope Using

While module-level `using` imports modules by their paths, Verse also
supports local scope `using` within function bodies to enable
member access inference from local variables and parameters. This
feature makes code cleaner when working with objects that have many
member accesses.

Local scope `using` takes a local variable or parameter identifier
(not a module path) and makes its members accessible without explicit
qualification:

<!-- 27 -->
```verse
entity := class:
    Name<public>:string = "Entity"
    var Health<public>:int = 100

    UpdateHealth<public>(Amount:int):void =
        set Health = Health + Amount

ProcessEntity(E:entity):void =
    # Explicit member access
    Print(E.Name)
    E.UpdateHealth(-10)

    # With local using - inferred member access
    using{E}
    Print(Name)         # Inferred as: E.Name
    UpdateHealth(-10)   # Inferred as: E.UpdateHealth(-10)
```
<!--versetest
Goblin := entity{}
ProcessEntity(Goblin)
Goblin.Health = 80
-->

The `using{E}` expression makes all members of `E` accessible without
the `E.` prefix within the current scope, and it works just as well
with a variable defined in the same function as with a parameter.

### Block Scoping

The `using` scope is limited to the block where it appears and any nested blocks:

<!-- 28 -->
```verse
record := class:
    Value<public>:int = 7
    Bump<public>(By:int)<computes>:int = Value + By

Scoped()<transacts>:int =
    Data := record{}
    Outer := block:
        using{Data}    # Data comes from the enclosing scope
        Bump(Value)    # Inferred as: Data.Bump(Data.Value)

    using{Data}        # Applies to this block and nested blocks
    Inner := block:
        Bump(Value)    # Inner block inherits the outer using

    Outer + Inner
```
<!--versetest
Scoped() = 28
-->

### Order

Member inference only works after the `using` expression is encountered:

<!--versetest
record := class:
    Value<public>:int = 7
assert_semantic_error(3506):
    r2 := class:
        Value<public>:int = 7
    Early(Data:r2)<computes>:int =
        Value
assert_semantic_error(3506):
    r3 := class:
        Value<public>:int = 7
    Late(Data:r3)<computes>:int =
        block:
            using{Data}
            Value
        Value
-->
<!-- 29 -->
```verse
ProcessData(Data:record)<computes>:int =
    # Value        # ERROR: inference is not retroactive
    Inner := block:
        using{Data}
        Value      # OK - within the using scope
    # Value        # ERROR: the using scope ended with the block
    Inner
```
<!--versetest
ProcessData(record{}) = 7
-->

The `using` statement acts as a declaration point - inference is not retroactive.

### Conflict Resolution

You can have multiple `using` expressions in the same scope, but conflicting member names must be explicitly qualified:

<!--versetest
assert_semantic_error(3588):
    ps30 := class:
        Health<public>:int = 100
        Mana<public>:int = 50
    es30 := class:
        Health<public>:int = 80
        Armor<public>:int = 20
    Report30(P:ps30, E:es30)<computes>:int =
        using{P}
        using{E}
        Health
-->
<!-- 30 -->
```verse
player_stats := class:
    Health<public>:int = 100
    Mana<public>:int = 50

enemy_stats := class:
    Health<public>:int = 80
    Armor<public>:int = 20

Report(Player:player_stats, Enemy:enemy_stats)<computes>:string =
    using{Player}
    Print("{Mana}")     # Player.Mana (no conflict)

    using{Enemy}
    Print("{Armor}")    # Enemy.Armor (no conflict with Player)

    # Print("{Health}") # ERROR: both classes have Health

    # Conflicting members must be qualified
    "{Player.Health} {Enemy.Health}"
```
<!--versetest
Report(player_stats{}, enemy_stats{}) = "100 80"
-->

When members exist in multiple `using` contexts, you must explicitly qualify to disambiguate.

### Mutable Member

Local `using` works with mutable fields through the `set` keyword:

<!-- 31 -->
```verse
config := class:
    var Volume<public>:float = 1.0
    var Quality<public>:int = 2

UpdateSettings(Settings:config):void =
    using{Settings}

    # Mutable field access
    set Volume = 0.8     # Inferred as: set Settings.Volume = 0.8
    set Quality = 3      # Inferred as: set Settings.Quality = 3
```
<!--versetest
C := config{}
UpdateSettings(C)
C.Quality = 3
-->

## Troubleshooting

When working with modules, you may encounter various issues. Understanding these common problems and their solutions will help you debug module-related errors more efficiently.

### Module Not Found Errors

The compiler reports that a module cannot be found when you try to
import it. There are three common causes.

The path may simply be wrong. Double-check the module path in your
`using` statement, and remember that paths are case-sensitive:

<!--versetest
assert_semantic_error(3587):
    using { /verse.org/random }
-->
<!-- 32 -->
```verse
roller := module:
    # using { /verse.org/random }  # ERROR: module not found
    using { /Verse.org/Random }    # correct case

    Roll<public>()<transacts>:int = GetRandomInt(1, 6)
```
<!--versetest
roller.Roll() >= 1
-->

A parent module import may be missing. When importing nested modules,
ensure the parent is imported first, as described under
[Nested Imports](#nested-imports).

Finally, the file location may not match the module structure. If you
have a folder named `PlayerSystems`, all files in that folder are part
of the `PlayerSystems` module.

### Access Denied Errors

You can't access a member of an imported module. Members without the
`<public>` specifier are internal by default, so nothing outside the
defining module can see them:

<!--versetest
assert_semantic_error(3506):
    Y:int = ModuleA.SecretValue
-->
<!-- 33 -->
```verse
ModuleA := module:
    SecretValue:int = 42            # internal by default
    PublicValue<public>:int = 100   # explicitly public

# From another module:
# X:int = ModuleA.SecretValue   # ERROR: not accessible
# Y:int = ModuleA.PublicValue   # works
```
<!--versetest
ModuleA.PublicValue = 100
-->

The same applies inside classes: `<private>` and `<protected>` members
are not accessible outside their defining scope, while `<public>` ones
are.

### Circular Dependency Errors

Two modules try to import each other, creating a circular
dependency. Restructure your code to avoid it:

1. **Extract common code**: Move shared definitions to a third module that both can import.
2. **Use interfaces**: Define interfaces in a separate module to break the dependency cycle.
3. **Reconsider architecture**: Circular dependencies often indicate a design issue that needs rethinking.

### Name Collision Errors

Two imported modules define members with the same name. Use fully
qualified names to disambiguate: where a bare `CalculateDamage(10.0)`
is ambiguous, `(/GameA/Combat:)CalculateDamage(10.0)` and
`(/GameB/Combat:)CalculateDamage(10.0)` each name exactly one
function, as shown under [Import Conflicts](#import-conflicts).

### Persistence Issues

Module-scoped variables are not persisting as expected. There are
three common causes.

1. **Wrong type used**: Ensure you are using `weak_map(player, t)` for player persistence.
2. **Type not persistable**: Check that your custom types have the `<persistable>` specifier.
3. **Initialization timing**: Make sure you are initializing persistent data at the right time in the game lifecycle.

### Local Qualifier Conflicts

Shadowing errors occur when local identifiers conflict with module
members. Use the `(local:)` qualifier to disambiguate, pairing it with
an explicit module qualifier such as `(ModuleX:)Value` when you need
to reach the module member too, as shown under
[Explicit Qualification](#explicit-qualification).
