# Access Specifiers

An access specifier controls where a definition can be referenced
from. Verse has five levels, plus one reserved for Epic-authored code.

The choice matters most for code you publish: making something
`<public>` is a commitment you cannot easily withdraw, because other
people's code may come to depend on it.

| Specifier | Visibility | Usage |
|-----------|------------|-------|
| `<public>` | Universally accessible | Members intended for external use |
| `<internal>` | Only within the module (default) | Module-private implementation |
| `<private>` | Only in immediate enclosing scope | Local to class/struct |
| `<protected>` | Current class and subtypes | Inheritance hierarchies |
| `<scoped>` | Current scope and enclosing scopes | Special use cases |
| `<epic_internal>` | Scopes with the /Verse.org, /UnrealEngine.com, and /Fortnite.com domains | `<epic_internal>` is only usable by Epic-authored code |

## Public

The `<public>` specifier represents the broadest level of access,
making an identifier universally accessible from any code that can
reference the containing module or type. When you mark something as
public, you are making a strong commitment about its availability and
stability:

<!--versetest
assert_semantic_error(3593, 3593):
    Game2 := module:
        PlayerManager2 := module:
            MaxPlayers2<public>:int = 100
    Outside2():int = Game2.PlayerManager2.MaxPlayers2
-->
<!-- 01 -->
```verse
Game := module:
    # Public reaches out of Game; without it PlayerManager would be
    # internal and unnameable from here
    PlayerManager<public> := module:
        MaxPlayers<public>:int = 100

        player<public> := class:
            Name<public>:string
            Level<public>:int = 1

Hero := Game.PlayerManager.player{Name := "Aldric"}
Hero.Level = 1
Game.PlayerManager.MaxPlayers = 100
```

Public members form the contract between your code and the outside
world. In the metaverse context, public declarations are particularly
significant because they represent guarantees that extend potentially
forever—once published, removing or incompatibly changing a public
member breaks the promise you've made to other developers who depend
on your code.

The public specifier can be applied to modules, classes, interfaces,
structs, enums, methods, and data members. When applied to a type
definition itself, it makes the type available for use outside its
defining module. When applied to members within a type, it makes those
members accessible to any code that has access to an instance of that
type.

## Protected

The `<protected>` specifier creates a middle ground between public and
private, allowing access within the defining class and any classes
that inherit from it. This level exists specifically to support
inheritance hierarchies while maintaining encapsulation:

<!--versetest
assert_semantic_error(3593):
    entity2 := class:
        var Health2<protected>:int = 100
    Outside2(E:entity2):int = E.Health2
-->
<!-- 02 -->
```verse
game_entity := class:
    var Health<protected>:int = 100

    Damage<protected>(Amount:int):void =
        set Health -= Amount
        OnHealthChanged()

    OnHealthChanged<protected>():void = {}  # Overridable by subclasses

player := class(game_entity):
    TakeHit():void =
        Damage(25)       # Can call a protected method
        set Health += 5  # Can modify a protected variable

    Report():int = Health

Hero := player{}
Hero.TakeHit()
Hero.Report() = 80
```

Protected access enables the template method pattern and other
inheritance-based designs while preventing external code from
accessing implementation details that should remain within the class
hierarchy. This is particularly valuable for game entities and other
hierarchical structures where parent classes need to share behavior
with children without exposing that behavior to the world.

## Private

The `<private>` specifier provides the strictest access control,
limiting visibility to the immediately enclosing scope. Private
members are truly internal implementation details that can be changed
freely without affecting any external code:

<!--versetest
assert_semantic_error(3593, 3593):
    bag2 := class:
        var Items2<private>:[]string = array{}
        HasRoom2<private>()<reads><decides>:void = Items2.Length < 2
    Outside2(B:bag2)<reads><decides>:void =
        B.HasRoom2[]
        B.Items2.Length = 0
-->
<!-- 03 -->
```verse
inventory := class:
    var Items<private>:[]string = array{}
    Capacity<private>:int = 2

    AddItem<public>(Name:string)<transacts><decides>:void =
        ValidateCapacity[]
        set Items += array{Name}

    ValidateCapacity<private>()<reads><decides>:void = Items.Length < Capacity

    Count<public>()<reads>:int = Items.Length

Bag := inventory{}
Bag.AddItem["sword"]
Bag.Count() = 1
```

Private members are the building blocks of encapsulation. They allow
you to maintain invariants, hide complexity, and create clean
abstractions. Changes to private members never break external code,
giving you the freedom to refactor and optimize implementation details
as needed.

## Internal

The `<internal>` specifier, which is the default access level when no
specifier is provided, makes members accessible within the defining
module but not outside it. This creates a natural boundary for
collaborative code that needs to share implementation details without
exposing them publicly:

<!--versetest
assert_semantic_error(3593):
    Physics2 := module:
        Fall2<internal>(V:float):float = V + 9.81
    Outside2():float = Physics2.Fall2(0.0)
-->
<!-- 04 -->
```verse
Physics := module:
    # No specifier, so internal to Physics
    GravityConstant:float = 9.81

    Fall<internal>(Velocity:float, DeltaTime:float):float =
        Velocity + GravityConstant * DeltaTime

    # The one step other modules are allowed to take
    Simulate<public>(Velocity:float):float = Fall(Velocity, 1.0)

Physics.Simulate(0.0) = 9.81
```

Internal access is ideal for module-wide utilities, shared
implementation details, and helper functions that multiple classes
within a module need but shouldn't be exposed to external code. It
provides a clean separation between the module's public interface and
its implementation machinery.

## Scoped

The `<scoped>` specifier creates custom access boundaries between
modules or code locations. Unlike the fixed visibility levels of
`public`, `internal`, and `private`, `scoped` access allows you to
explicitly grant access to particular modules while excluding all
others—creating a kind of "friend" relationship between program
entities.

### Scoped Definitions

A scoped access level is created using the `scoped{...}` expression,
which takes one or more module references:

<!-- 05 -->
```verse
Collaboration := module:
    # Create a scope that includes both ModuleA and ModuleB
    Shared<public> := scoped{ModuleA, ModuleB}

    # This class is only accessible within ModuleA and ModuleB
    shared_resource<Shared> := class:
        Data<public>:int = 42

ModuleA := module:
    using{Collaboration}
    Read<public>():int = shared_resource{}.Data

ModuleB := module{}

ModuleA.Read() = 42
```

The scoped definition creates an access level that can then be used as
a specifier on classes, functions, variables, and other
definitions. Code within any of the listed entities can access the
scoped member, while code outside those modules cannot—even if it can
see the containing scope.

### Cross-Module Collaboration

The most powerful use of scoped access is enabling controlled
collaboration between modules. A definition can be created in one
module but scoped to another, making it accessible where it is needed
while keeping it hidden elsewhere — the definition itself, not its
members; see [below](#scoping-a-definition-does-not-scope-its-members):

<!-- 06 -->
```verse
bounding_box := class{}

Graphics := module:
    # Define an interface scoped to the physics module. Its members need the
    # same scope, otherwise they stay internal to Graphics and cannot be
    # overridden from Physics.
    collidable_shape<scoped{Physics}> := interface:
        GetBounds<scoped{Physics}>():bounding_box

Physics := module:
    using{Graphics}

    # Physics can implement the interface even though it is defined in graphics
    sphere_collider := class<abstract>(collidable_shape):
        GetBounds<override>():bounding_box
```

This pattern allows graphics to define contracts that physics
implements without exposing those implementation details publicly. The
interface exists at the boundary between the two modules but is not
part of either module's public API.

You can scope a definition to multiple modules, creating a shared
private space for collaboration:

<!-- 07 -->
```verse
Gameplay := module:
    # This scope includes both the inventory and crafting modules
    SharedGameplayScope := scoped{Inventory, Crafting}

    # Items can be accessed by both inventory and crafting
    item<SharedGameplayScope> := class:
        ID<public>:int

    # Factory function available to both systems
    CreateItem<SharedGameplayScope>(TheID:int):item = item{ID := TheID}

Inventory := module:
    using{Gameplay}
    AddToInventory<public>(ItemID:int):int = CreateItem(ItemID).ID

Crafting := module:
    using{Gameplay}
    CraftItem<public>(Recipe:[]int)<decides>:int = CreateItem(Recipe[0]).ID

Inventory.AddToInventory(7) = 7
```

### Scoped Read or Write Access

Like other access specifiers, scoped can be applied separately to read
and write operations on variables:

<!--  BUG?  Or at least unhelpful error message

a:=class<computes>{}
F()<computes>:a= a{}
b := class{ G:a = F() }

Gives:
  Line 8: Verse compiler error V3582: Divergent calls (calls that might not complete) cannot be used to define data-members.
-->


<!--versetest
-->
<!-- 08 -->
```verse
Inventory := module{}
Crafting := module{}

state_manager := class:
    # Public read access, but only inventory and crafting can write
    var<scoped{Inventory, Crafting}> Phase<public>:int = 0

    # Only inventory and crafting can read or write this internal state
    var<scoped{Inventory, Crafting}> SyncCounter<scoped{Inventory, Crafting}>:int = 0

state_manager{}.Phase = 0
```

This pattern is particularly useful for shared state that multiple
modules need to coordinate on without exposing write access publicly.

### Visibility and Access Paths

An important subtlety of scoped access is that it grants access to a
specific member, but does not make intermediate types or modules
visible. To access a scoped member, you must be able to see the entire
path to it:

<!--versetest
assert_semantic_error(3593, 3593, 3593):
    Outer := module:
        # Internal to outer
        Inner := module:
            # Scoped to Target
            shared<scoped{Target}> := class{}

    Target := module:
        using{Outer}

        # ERROR: can't see Outer.Inner because Inner is internal to Outer,
        # even though shared is scoped to us
        UseShared():void = Inner.shared{}
<#
-->
<!-- 09 -->
```verse
Outer := module:
    # Internal to outer
    Inner := module:
        # Scoped to Target
        shared<scoped{Target}> := class{}

Target := module:
    using{Outer}

    # ERROR: can't see Outer.Inner because Inner is internal to Outer,
    # even though shared is scoped to us
    UseShared():void = Inner.shared{}
```
<!-- #> -->

For scoped access to work, either the containing scope must be
accessible (public or also scoped appropriately), or the scoped member
must be accessed through a public interface that exposes it.

A definition can only have one scoped access level—you cannot apply
multiple scoped specifiers:

<!--versetest
assert_semantic_error(3642):
    ModuleA := module{}
    ModuleB := module{}
    # ERROR: Cannot have multiple access level specifiers
    invalid_scope<scoped{ModuleA}><scoped{ModuleB}> := class{}
<#
-->
<!-- 10 -->
```verse
ModuleA := module{}
ModuleB := module{}
# ERROR: Cannot have multiple access level specifiers
invalid_scope<scoped{ModuleA}><scoped{ModuleB}> := class{}
```
<!-- #> -->

### Scoped Access and Inheritance

When a class member has scoped access, overriding members in
subclasses can maintain or narrow that access, following normal
inheritance rules:

<!-- 11 -->
```verse
ModuleA := module{}
ModuleB := module{}

base := class:
    # Accessible only in ModuleA and ModuleB
    ComputeValue<scoped{ModuleA, ModuleB}>():int = 42

derived := class(base):
    # Can override with same or more restrictive access
    ComputeValue<override>():int = 100  # Now internal to this module

derived{}.ComputeValue() = 100
```

#### Scoping a Definition Does Not Scope Its Members

A `<scoped>` grant applies only to the definition that carries it. The members
of that definition keep their own accessibility, which defaults to `internal`.
Granting `A<scoped{B}>` lets `B` name `A` but does not let `B` touch anything
*inside* `A`:

<!--versetest
assert_semantic_error(3593):
    Graphics := module:
        shape<scoped{Physics}> := class:
            Size:int = 1            # internal to Graphics

    Physics := module:
        using{Graphics}
        Report():int =
            S := shape{}
            S.Size                  # ERROR: Size is internal to Graphics
<#
-->
<!-- 12 -->
```verse
Graphics := module:
    shape<scoped{Physics}> := class:
        Size:int = 1            # internal to Graphics

Physics := module:
    using{Graphics}
    Report():int =
        S := shape{}
        S.Size                  # ERROR: Size is internal to Graphics
```
<!-- #> -->

To make a member reachable, mark the member too:

<!-- 13 -->
```verse
Graphics := module:
    shape<scoped{Physics}> := class:
        Size<scoped{Physics}>:int = 1

Physics := module:
    using{Graphics}
    Report<public>():int =
        S := shape{}
        S.Size

Physics.Report() = 1
```

The same applies at every level of nesting: reaching `A.B.C` from a granted
scope needs the grant on `A`, on `B`, and on `C`. A `<scoped>` container holding
an internal member is still an error.

This also governs interface implementation. An `<internal>` member of a
`<scoped>` interface cannot be overridden from the granted scope. Only members
that are themselves `<scoped{...}>` or `<public>` can be overridden:

<!--versetest
assert_semantic_error(3593, 3593):
    Graphics2 := module:
        collidable2<scoped{Physics2}> := interface:
            Reset():void
    Physics2 := module:
        using{Graphics2}
        sphere2 := class<abstract>(collidable2):
            Reset<override>():void = {}
-->
<!-- 14 -->
```verse
Graphics := module:
    collidable<scoped{Physics}> := interface:
        Describe<public>():void   # overridable from Physics
        Reset():void              # internal - NOT overridable

Physics := module:
    using{Graphics}
    sphere := class<abstract>(collidable):
        Describe<override>():void = {}
```

### Using Scoped for API Boundaries

Scoped access excels at creating controlled API boundaries where
certain functionality should be shared between specific modules but
not exposed as part of the public interface.

This creates an explicit architectural boundary—only the modules
listed in the scope can access the scoped primitives, while other
code must use higher-level public APIs.

### Design Considerations

Scoped access represents an architectural commitment between
modules. When using it effectively:

- Use scoped for legitimate cross-module collaboration that does not
  belong in the public API
- Keep scope definitions at the module level where they can be documented and maintained
- Prefer scoping to explicit modules rather than deeply nested scopes
- Consider whether protected or internal access might be simpler for your use case
- Document why particular modules are included in a scope

The scoped specifier fills a unique niche between internal and public
access, enabling sophisticated module architectures where multiple
components need to collaborate intimately without exposing those
implementation details to the wider codebase.

## Separating Read and Write Access

An innovative feature is the ability to apply different access
specifiers to reading and writing operations on the same
variable. This fine-grained control allows you to create variables
that are widely readable but narrowly writable, implementing common
patterns like read-only properties elegantly:

<!-- 15 -->
```verse
game_state := class:
    # Public read, protected write
    var<protected> Score<public>:int = 0

    # Public read, private write
    var<private> PlayerCount<public>:int = 0

    # Internal read, private write
    var<private> SessionID<internal>:string

State := game_state{SessionID := "s1"}
State.Score = 0
```

This dual-specifier system solves a common problem in object-oriented
programming where you want to expose state for reading without
allowing external modification. Rather than requiring getter methods
or property syntax, Verse makes this pattern a first-class language
feature.

The syntax places the write-access specifier on the `var` keyword and
the read-access specifier on the identifier itself. This visual
separation makes the access levels immediately clear when reading
code. The write specifier must be at least as restrictive as the read
specifier — you cannot write to a variable that is privately readable
but publicly writable, as this would violate basic encapsulation
principles.

## Best Practices

Understanding when to use each access level requires thinking about
your code's architecture and evolution. The principle of least
privilege suggests starting with the most restrictive access that
works and only broadening it when necessary.

For public  APIs, every public  member is a commitment.  Before making
something public, consider  whether it truly needs to be  part of your
module's contract or if it is  an implementation detail that happens to
be  needed elsewhere  temporarily.  Public members  should be  stable,
well-documented, and designed for longevity.

Protected access should be used thoughtfully in inheritance
hierarchies. Not everything in a base class needs to be protected—only
those members that form the inheritance contract between parent and
child classes. Overuse of protected access can create tight coupling
between classes in a hierarchy.

Private access is your default for implementation details. Most helper
functions, intermediate calculations, and state management should be
private. This gives you maximum flexibility to refactor and optimize
without breaking dependent code.

The dual-specifier pattern for variables is particularly powerful for
maintaining invariants. By making variables publicly readable but
privately or protectively writable, you can expose state for
observation while maintaining complete control over modifications:

<!--versetest
-->
<!-- 16 -->
```verse
resource_manager := class:
    var<private> Available<public>:int = 1000

    Allocate<public>(Amount:int)<transacts><decides>:void =
        Amount <= Available
        set Available -= Amount

Manager := resource_manager{}
Manager.Allocate[400]
Manager.Available = 600
```

## Annotations and Metadata

Verse provides an annotation system for attaching metadata to
definitions using the `@` prefix syntax. Annotations provide compiler
directives and metadata that affect how code is treated during
compilation and evolution.

### Built-in Annotations

#### @deprecated

!!! warning "Internal Feature"
    @deprecated attribute is currently an internal feature and cannot be used by end-users.

The `@deprecated` annotation marks definitions that should no longer
be used. When code references a deprecated definition, the compiler
produces a warning, alerting developers to update their code.

Deprecated definitions can use other deprecated definitions without
warnings, but non-deprecated code cannot use deprecated definitions
without triggering warnings. This allows gradual migration of
deprecated APIs:

<!-- 17 -->
```verse
# Mark a definition as deprecated
@deprecated
OldAPI():int = 42

# Valid: deprecated can call deprecated
@deprecated
MigrateOldAPI():int = OldAPI()

# Warning: non-deprecated calling deprecated
NewCode():int = OldAPI()

NewCode() = 42
```

`@deprecated` accepts two optional fields:

- `Message` — text shown alongside the deprecation warning. Passing `false`
  means "no message" and is accepted.
- `DiscontinuedAtFNVersion` — the version at which use stops being a warning and
  becomes a hard error.

The version comparison is `>=`: a package uploaded at **exactly** the cutoff
already counts as discontinued, not merely deprecated.

<!-- 18 -->
```verse
@deprecated{Message := "Use NewSpawn instead."}
OldSpawn():void = {}

@deprecated{Message := "Removed.", DiscontinuedAtFNVersion := 2000}
Older():void = {}
# A package uploaded at FN 20.00 or later gets an error, not a warning.
```

`@deprecated` may also be applied to a module, in which case it covers the
module's members.

The `@deprecated` annotation can be applied to:
- Functions and methods
- Classes, interfaces, structs, and enums
- Individual enum values
- Data members
- Modules

#### @experimental

!!! warning "Internal Feature"
    @experimental attribute is currently an internal feature and cannot be used by end-users.

The `@experimental` annotation marks features that are not yet stable
and may change or be removed in future versions. Experimental features
can only be used when the `AllowExperimental` package flag is enabled:

<!--versetest
# Mark a feature as experimental
@experimental
experimental_class := class:
    NewFeature:int

# Using experimental features requires the AllowExperimental package flag
UseExperimental(Obj:experimental_class):int = Obj.NewFeature
<#
-->
<!-- 19 -->
```verse
# Mark a feature as experimental
@experimental
experimental_class := class:
    NewFeature:int

# Using experimental features requires the AllowExperimental package flag
UseExperimental(Obj:experimental_class):int = Obj.NewFeature
```
<!-- #> -->

Experimental definitions behave similarly to deprecated
ones—experimental definitions can freely use other experimental
definitions, but stable code cannot use experimental definitions
unless the `AllowExperimental` flag is set.

The `@experimental` annotation cannot be applied to:
- Local variables
- Override methods (base method's experimental status is inherited)

#### @available

The `@available` annotation controls when a definition becomes
available based on version numbers. This enables gradual API rollout
and version-specific functionality:

<!--versetest
using { /Verse.org/Native }  # Required for @available

# Multiple definitions can coexist for different versions
@available{MinUploadedAtFNVersion := 2900}
OldImplementation():int = 42

@available{MinUploadedAtFNVersion := 3000}
NewImplementation():int = 100
<#
-->
<!-- 20 -->
```verse
using { /Verse.org/Native }  # Required for @available

# Multiple definitions can coexist for different versions
@available{MinUploadedAtFNVersion := 2900}
OldImplementation():int = 42

@available{MinUploadedAtFNVersion := 3000}
NewImplementation():int = 100
```
<!-- #> -->

The `@available` annotation can be applied to the same kinds of
definitions as `@deprecated`.

### Custom Attributes

!!! warning "Internal Feature"
    Custom attributes are currently an internal feature and cannot be created by end-users.

You can create custom attributes by inheriting from the special
`attribute` class. Custom attributes allow you to attach
domain-specific metadata to your code:

<!--versetest
# Define a custom attribute
@attribscope_class
gameplay_element := class<computes>(attribute):
    Category:string
    Priority:int

# Use the custom attribute
@gameplay_element{Category := "Combat", Priority := 1}
weapon_system := class:
    Damage:int
<#
-->
<!-- 21 -->
```verse
# Define a custom attribute
@attribscope_class
gameplay_element := class<computes>(attribute):
    Category:string
    Priority:int

# Use the custom attribute
@gameplay_element{Category := "Combat", Priority := 1}
weapon_system := class:
    Damage:int
```
<!-- #> -->

#### Attribute Scopes

When defining custom attributes, you must specify where they can be
applied using scope annotations:

- **@attribscope_class** - Can be applied to regular classes
- **@attribscope_attribclass** - Can be applied to attribute classes (classes that inherit from `attribute`)
- **@attribscope_enum** - Can be applied to enums
- **@attribscope_interface** - Can be applied to interfaces
- **@attribscope_function** - Can be applied to functions and methods
- **@attribscope_data** - Can be applied to data members

Example of scoped custom attributes:

<!--versetest
assert_semantic_error(3596):
    @attribscope_function
    perf2 := class<computes>(attribute):
        MaxMs:int
    @perf2{MaxMs := 16}
    thing2 := class{}

# Attribute that can only be applied to functions
@attribscope_function
performance_critical := class<computes>(attribute):
    MaxExecutionTimeMs:int

# Attribute that can only be applied to data members
@attribscope_data
serializable_field := class<computes>(attribute):
    SerializationKey:string

# Use them appropriately
entity := class<abstract>:
    @serializable_field{SerializationKey := "entity_id"}
    ID:int

    @performance_critical{MaxExecutionTimeMs := 16}
    Update():void
<#
-->
<!-- 22 -->
```verse
# Attribute that can only be applied to functions
@attribscope_function
performance_critical := class<computes>(attribute):
    MaxExecutionTimeMs:int

# Attribute that can only be applied to data members
@attribscope_data
serializable_field := class<computes>(attribute):
    SerializationKey:string

# Use them appropriately
entity := class<abstract>:
    @serializable_field{SerializationKey := "entity_id"}
    ID:int

    @performance_critical{MaxExecutionTimeMs := 16}
    Update():void
```
<!-- #> -->

Attempting to use an attribute in the wrong location produces a
compiler error. For example, a function-scoped attribute cannot be
applied to a class.

Custom attributes are currently metadata for
external tooling — the compiler, LSP, and the Unreal Editor can read
and act on them, but there is no Verse API to query attributes at
runtime. Attributes are used to apply rules, constraints, or extra
data that tools outside the language consume, such as serialization
hints, editor annotations, or performance directives.

### Getter and Setter Accessors

!!! warning "Internal Feature"
    Getter and setter accessors are currently an internal feature and cannot be used by end-users.

While not strictly annotations, the `<getter(...)>` and
`<setter(...)>` specifiers provide a related form of metadata for
controlling field access. These can be applied to both class and
interface fields to define custom access logic:

<!-- 23 -->
```verse
entity := class:
    # External field with custom accessors
    var Health<getter(GetHealth)><setter(SetHealth)>:int = external{}

    var InternalHealth:int = 100

    GetHealth(:accessor):int = InternalHealth

    SetHealth(:accessor, NewValue:int):void =
        if (NewValue >= 0, NewValue <= 100):
            set InternalHealth = NewValue
```

Constraints on accessors:

- Must include both `<getter(...)>` and `<setter(...)>` - cannot have only one
- The field must have `= external{}` or no default value (with archetype initialization required)
- Fields with accessors cannot be overridden in subclasses
- The field must be mutable (marked with `var`)
- Not all types are supported for accessor fields
- Accessor fields are currently only allowed in epic_internal scopes

For more details on accessor patterns, see [Fields with Accessors](10_classes_interfaces.md).

### Localization

The `<localizes>` specifier marks definitions as localizable messages
for internationalization. Localized messages use the `message` type
and can be extracted for translation into different languages:

<!--versetest
# Simple localized message
WelcomeMessage<localizes> : message = "Welcome to the game!"

# Call Localize to get the string
ShowWelcome():void =
    Print(Localize(WelcomeMessage))
assert:
    Localize(WelcomeMessage) = "Welcome to the game!"
<#
-->
<!-- 24 -->
```verse
# Simple localized message
WelcomeMessage<localizes> : message = "Welcome to the game!"

# Call Localize to get the string
ShowWelcome():void =
    Print(Localize(WelcomeMessage))
```
<!-- #> -->

#### Message Parameters

Localized messages can accept parameters for dynamic content interpolation.

Three parameter types are supported:
- `string` - Text values
- `int` - Integer values (formatted with comma separators)
- `float` - Floating-point values

The interpolation syntax is minimal:
- Use `{ParameterName}` to insert parameter values
- Parameters can be used multiple times or not at all
- Only parameter names and Unicode code points allowed in braces

<!--versetest
# Message with parameter interpolation
GreetPlayer<localizes>(PlayerName:string) : message = "Hello, {PlayerName}!"

# Multiple parameters, some repeated
ScoreMessage<localizes>(Player:string, Score:int) : message =
    "Congratulations {Player}! Your score is {Score}. Great job, {Player}!"

# Not all parameters required in message text
OptionalParam<localizes>(Name:string, Score:int) : message =
    "Thanks for playing!"  # Score parameter ignored
assert:
    Localize(GreetPlayer("Aldric")) = "Hello, Aldric!"
    Localize(ScoreMessage("Alice", 1500)) =
        "Congratulations Alice! Your score is 1,500. Great job, Alice!"
    Localize(OptionalParam("Bob", 3)) = "Thanks for playing!"
<#
-->
<!-- 25 -->
```verse
# Message with parameter interpolation
GreetPlayer<localizes>(PlayerName:string) : message = "Hello, {PlayerName}!"

# Multiple parameters, some repeated
ScoreMessage<localizes>(Player:string, Score:int) : message =
    "Congratulations {Player}! Your score is {Score}. Great job, {Player}!"

# Not all parameters required in message text
OptionalParam<localizes>(Name:string, Score:int) : message =
    "Thanks for playing!"  # Score parameter ignored
```
<!-- #> -->

#### Integer Formatting

Integer parameters are automatically formatted with comma separators for readability:

<!--versetest
HighScore<localizes>(Points:int) : message = "New record: {Points} points!"

assert:
    Localize(HighScore(190091)) = "New record: 190,091 points!"
<#
-->
<!-- 26 -->
```verse
HighScore<localizes>(Points:int) : message = "New record: {Points} points!"

Localize(HighScore(190091)) = "New record: 190,091 points!"
```
<!-- #> -->

#### Named and Default Parameters

Localized messages support named parameters and default values:

<!--versetest
ConfigMessage<localizes>(?MaxPlayers:int = 8, ?TimeLimit:int = 300):message =
    "Game settings: {MaxPlayers} players, {TimeLimit} seconds"

assert:
    # Can be called with any combination
    Localize(ConfigMessage()) = "Game settings: 8 players, 300 seconds"
    Localize(ConfigMessage(?MaxPlayers := 16)) = "Game settings: 16 players, 300 seconds"
<#
-->
<!-- 27 -->
```verse
ConfigMessage<localizes>(?MaxPlayers:int = 8, ?TimeLimit:int = 300):message =
    "Game settings: {MaxPlayers} players, {TimeLimit} seconds"

# Can be called with any combination
Localize(ConfigMessage()) = "Game settings: 8 players, 300 seconds"
Localize(ConfigMessage(?MaxPlayers := 16)) = "Game settings: 16 players, 300 seconds"
```
<!-- #> -->

#### Tuple Parameters

Messages can accept tuple parameters, which are destructured in the parameter list:

<!--versetest
LocationMessage<localizes>(Player:string, (X:int, Y:int)) : message =
    "{Player} is at position ({X}, {Y})"

assert:
    # Call with tuple
    Localize(LocationMessage("Hero", (10, 20))) = "Hero is at position (10, 20)"
<#
-->
<!-- 28 -->
```verse
LocationMessage<localizes>(Player:string, (X:int, Y:int)) : message =
    "{Player} is at position ({X}, {Y})"

# Call with tuple
Localize(LocationMessage("Hero", (10, 20))) = "Hero is at position (10, 20)"
```
<!-- #>-->

#### String Escaping and Unicode

A message literal may carry a Unicode code point, escaped braces to show
literal braces, and the usual backslash escapes; whitespace and comments are
allowed inside an interpolation. Escaping only suppresses interpolation for a
name that is *not* a parameter — `\{Name\}` still substitutes when `Name` is
one:

<!--versetest
UnicodeMessage<localizes> : message = "The letter is {0u004d}"

EscapedMessage<localizes>(Name:string) : message =
    "Braces \{ and \} around {Name}"

SpecialChars<localizes> : message =
    "Supports: \\r\\n\\t\\\"\\'\\#\\<\\>\\&\\~"

SpacedParam<localizes>(Name:string) : message = "Hello { Name }"
CommentedParam<localizes>(Name:string) : message = "Hello {<# comment #>Name}"
assert:
    Localize(UnicodeMessage) = "The letter is M"
    Localize(EscapedMessage("value")) = "Braces \{ and \} around value"
    Localize(SpacedParam("Aldric")) = "Hello Aldric"
    Localize(CommentedParam("Aldric")) = "Hello Aldric"
<#
-->
<!-- 29 -->
```verse
UnicodeMessage<localizes> : message = "The letter is {0u004d}"

EscapedMessage<localizes>(Name:string) : message =
    "Braces \{ and \} around {Name}"

SpecialChars<localizes> : message =
    "Supports: \\r\\n\\t\\\"\\'\\#\\<\\>\\&\\~"

SpacedParam<localizes>(Name:string) : message = "Hello { Name }"
CommentedParam<localizes>(Name:string) : message = "Hello {<# comment #>Name}"
```
<!-- #> -->

#### Scope Requirements

Localized messages **must be defined at module or snippet scope**. They cannot be defined inside functions:

<!--versetest
# Valid: module scope
MyModule := module:
    ModuleMessage<localizes> : message = "Valid"

# Valid: snippet scope
TopLevelMessage<localizes> : message = "Valid"

assert_semantic_error(3506, 3506, 3651):
    BadFunction():void =
        LocalMessage<localizes> : message = "Invalid"  # ERROR
<#
-->
<!-- 30 -->
```verse
# Valid: module scope
MyModule := module:
    ModuleMessage<localizes> : message = "Valid"

# Valid: snippet scope
TopLevelMessage<localizes> : message = "Valid"

BadFunction():void =
    LocalMessage<localizes> : message = "Invalid"  # ERROR
```
<!-- #> -->

#### Inheritance and Override

Localized messages can be overridden in class hierarchies:

<!-- 31 -->
```verse
base_ui := class:
    Title<localizes>:message = "Base Title"
    Description<localizes>:message = "Base description"

derived_ui := class(base_ui):
    # Override the title message
    Title<localizes><override>:message = "Derived Title"
    # Inherits Description from base

Localize(derived_ui{}.Title) = "Derived Title"
Localize(derived_ui{}.Description) = "Base description"
```

Localized messages can also be abstract:

<!-- 32 -->
```verse
quest_base := class<abstract>:
    # Abstract message - must be implemented by subclasses
    TaskDescription<localizes><public> : message
    # Concrete message with default
    CompletionMessage<localizes><protected> : message = "Quest complete!"

fetch_quest := class<final>(quest_base):
    TaskDescription<localizes><override> : message = "Collect 10 items"

Localize(fetch_quest{}.TaskDescription) = "Collect 10 items"
```

#### Restrictions and Errors

The type annotation `: message` is required; implicit typing is not
supported. The right-hand side must be a string literal, not an
expression. Not all types are supported as parameters. And only
parameter names and Unicode code points are allowed inside `{}`. Each
of these four definitions is rejected:

<!--versetest
assert_semantic_error(3639, 3560):
    BadMessage<localizes> := "Text"                                # no `: message`
assert_semantic_error(3638, 3560):
    InvalidMessage<localizes> : message = "A" + "B"                # not a literal
assert_semantic_error(3506, 3506):
    OptionalMsg<localizes>(Player:?string) : message = "{Player}"  # optional type
assert_semantic_error(3506, 3506):
    my_class2 := class{Value:int}
    ClassMsg<localizes>(Obj:my_class2) : message = "{Obj}"         # class type
assert_semantic_error(3652, 3506, 3506):
    ExprMessage<localizes>(Name:string) : message = "{"Hello"}"    # expression
<#
-->
<!-- 33 -->
```verse
BadMessage<localizes> := "Text"                                # no `: message`
InvalidMessage<localizes> : message = "A" + "B"                # not a literal
OptionalMsg<localizes>(Player:?string) : message = "{Player}"  # optional type
my_class2 := class{Value:int}
ClassMsg<localizes>(Obj:my_class2) : message = "{Obj}"         # class type
ExprMessage<localizes>(Name:string) : message = "{"Hello"}"    # expression
```
<!-- #> -->

If you reference an identifier that is not a parameter, it gets escaped in the output:

<!--versetest
GlobalName:string = "World"

RefMessage<localizes>(Greeting:string) : message =
    "{Greeting} to {GlobalName}"

assert:
    # GlobalName is escaped because it is not a parameter
    Localize(RefMessage("Hello")) = "Hello to \{GlobalName\}"
<#
-->
<!-- 34 -->
```verse
GlobalName:string = "World"

RefMessage<localizes>(Greeting:string) : message =
    "{Greeting} to {GlobalName}"

# GlobalName is escaped because it is not a parameter
Localize(RefMessage("Hello")) = "Hello to \{GlobalName\}"
```
<!-- #> -->

#### Access Specifiers

Localized messages support standard access specifiers:

<!-- 35 -->
```verse
MyModule := module:
    PublicMessage<localizes><public> : message = "Public message"
    InternalMessage<localizes> : message = "Internal message"

    some_class := class:
        PrivateMessage<localizes><private> : message = "Private message"

Localize(MyModule.PublicMessage) = "Public message"
```

#### Best Practices

Keep messages translatable:

- Use complete sentences, not fragments that might be concatenated
- Avoid gender or number assumptions that do not translate well
- Provide context through parameter names

Design for different languages:

- Don't assume word order - let translators rearrange parameter positions
- Allow repeated parameter use for languages that need it
- Keep formatting codes (like comma separators) automated

Organization:

- Group related messages in the same module
- Use descriptive names that indicate message purpose
- Consider using abstract base classes for message families

<!--versetest
# Good: Clear, complete, flexible
PlayerJoined<localizes>(PlayerName:string, TeamName:string) : message =
    "{PlayerName} joined team {TeamName}"

# Avoid: Fragments that might be concatenated
# PlayerPrefix<localizes>(Name:string) : message = "Player {Name}"
# JoinedSuffix<localizes>(Team:string) : message = "joined {Team}"
<#
-->
<!-- 36 -->
```verse
# Good: Clear, complete, flexible
PlayerJoined<localizes>(PlayerName:string, TeamName:string) : message =
    "{PlayerName} joined team {TeamName}"

# Avoid: Fragments that might be concatenated
# PlayerPrefix<localizes>(Name:string) : message = "Player {Name}"
# JoinedSuffix<localizes>(Team:string) : message = "joined {Team}"
```
<!-- #> -->

## Evolution

Access specifiers play a crucial role in code evolution. Changing
access levels after publication can break compatibility:

- Narrowing access (public to private) breaks external code that
  depends on the member
- Widening access (private to public) is generally safe but creates
  new commitments
- Changing protected members affects the inheritance contract

The `<castable>` specifier on classes has special compatibility
requirements—once published, it cannot be added or removed, as this
would affect the safety of dynamic casts throughout the codebase.

When designing for long-term evolution, consider using internal access
for members that might eventually become public. This allows you to
test and refine APIs within your module before committing to public
exposure.
