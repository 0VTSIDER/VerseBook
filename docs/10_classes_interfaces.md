# Classes and Interfaces

A class has fields and methods and supports single inheritance. An
interface specifies data and behaviour without implementing it, and a
class may implement several.

The two express different relationships: class inheritance gives
*is-a*, interface implementation gives *can-do*.

## Classes

A class is a type that bundles data (fields) with operations
(methods). Class definitions must occur at module scope—you cannot
define a class inside another class, struct, interface, or function:

<!--versetest
assert_semantic_error(3502):
    outer := class:
        inner := class:
            Value:int
-->
<!-- 001 -->
```verse
# Valid: class at module scope
MyModule := module:
    entity := class:
        ID:int

# Invalid: class inside another class
# outer := class:
#     inner := class:  # ERROR: classes must be at module scope
#         Value:int
```

<!--versetest-->
<!-- 002 -->
```verse
character := class:
    Name : string
    var Health : int = 100
    var Level : int = 1
    MaxHealth : int = 100
```

Fields without `var` are immutable after construction. Fields with
`var` are mutable (see [Mutability](05_mutability.md)). Default values
enable convenient construction while ensuring valid initial states.

### Object Construction

Creating instances of a class involves specifying values for its
fields through an archetype expression:

<!--versetest
character := class:
    Name : string
    var Health : int = 100
    var Level : int = 1
    MaxHealth : int = 100
	
Ignore:int=1
-->
<!-- 003 -->
```verse
Hero := character{Name := "Aldric", Health := 100, Level := 5}
Villager := character{Name := "Martha"}  # default values for unspecified fields
```

Named parameters can appear in any order. Fields with defaults may be
omitted. Fields without defaults must be specified.

### Methods

<!--versetest-->
<!-- 004 -->
```verse
character := class:
    Name : string
    var Health : int = 100
    var Level : int = 1
    var MaxHealth : int = 100

    TakeDamage(Amount : int) : void =
        set Health = Max(0, Health - Amount)

    Heal(Amount : int) : void =
        set Health = Min(MaxHealth, Health + Amount)

    IsAlive()<decides>:void= Health > 0

    LevelUp() : void =
        set Level += 1
        set MaxHealth = 100 + (Level * 10)
        set Health = MaxHealth  # Full heal on level up
```

Methods have access to all fields of the class and can modify mutable
fields. They encapsulate the logic for how objects of the class should
behave, ensuring that state changes happen in controlled, predictable
ways.

All methods in non-abstract classes must have implementations. Unlike
interfaces (which can declare abstract methods), a concrete class
method declaration without an implementation is an error:

<!--versetest
assert_semantic_error(3591):
    invalid_class := class:
        Compute():int
-->
<!-- 005 -->
```verse
# Valid: method with implementation
valid_class := class:
    Compute():int = 42

# Invalid: method without implementation in concrete class
# invalid_class := class:
#     Compute():int  # ERROR: needs implementation
```

### Blocks for Initialization

Classes can include `block` clauses that execute when an instance is
created:

<!--versetest-->
<!-- 006 -->
```verse
logged_entity := class:
    ID:int
    var Label:string = ""

    block:
        # This executes when an instance is created
        Print("Creating entity with ID: {ID}")
        set Label = "entity-{ID}"

Entity := logged_entity{ID := 42}
Entity.Label = "entity-42"
```

Block clauses have access to all fields of the class, including
`Self`, and can modify mutable fields. They execute in the order they
appear in the class definition:

<!--versetest-->
<!-- 007 -->
```verse
multi_step_init := class:
    var Step1:int = 0
    var Step2:int = 0

    block:
        set Step1 = 10

    var Step3:int = 0

    block:
        set Step2 = Step1 + 5  # Can access earlier fields
        set Step3 = Step2 * 2

Instance := multi_step_init{}
Instance.Step1 = 10 and Instance.Step2 = 15 and Instance.Step3 = 30
```

When a class hierarchy is involved, the order in which blocks run is
not portable: the Verse VM runs the subclass block first, while
Blueprint runs the superclass block first. Code that has to work on
both should not depend on that order.

Blocks exist alongside constructor functions because they can see
`Self`, which a constructor function cannot. Reach for a block
whenever the initialization needs to refer to the object being
constructed.

A block is also the place to put initialization that has to call
another function. A field default value may not call anything at all,
not even a harmless-looking helper that merely allocates: the compiler
reports "divergent calls cannot define data-members", and it reports it
whatever effects the helper carries. Give the field a cheap default and
move the real work into a block:

<!--versetest
foo := class{}
MakeFoo()<transacts>:foo = foo{}

assert_semantic_error(3582):
    priv_foo := class{}
    PrivMakeFoo()<transacts>:priv_foo = priv_foo{}
    priv_bar := class:
        var Foo:priv_foo = PrivMakeFoo()
-->
<!-- 008 -->
```verse
# ERROR: a field default value may not call MakeFoo
# bar := class:
#     var Foo:foo = MakeFoo()

bar := class:
    var Foo:foo = foo{}      # cheap default

    block:
        set Foo = MakeFoo()  # the block does the real work
```

A block runs inside the transaction that constructs the object, so
what it may call is limited in turn. `MakeFoo` above has to be
`<transacts>`; had it been left with the default effect set, the call
would be rejected with "this invocation calls a function that has the
`no_rollback` effect, which is not allowed by its context". Blocks are
restricted in a few other ways:

- Blocks cannot contain failure (`<decides>`) operations
- Blocks cannot call suspending (`<suspends>`) functions
- Blocks can use `defer` statements, which execute when the block exits
- Block clauses are only allowed in classes, not in interfaces,
  structs, or modules

Block clauses are particularly useful for:

- Logging object creation
- Computing derived values during initialization
- Registering objects with global systems
- Performing initialization that requires `Self` or a function call

### Let Clauses in Archetypes

Archetype expressions (used to construct class and struct instances)
can include `let` clauses that introduce local bindings.
These are useful for computing intermediate values used by multiple
field initializers, avoiding repetition:

<!--versetest
assert_semantic_error(3506, 3552):
    priv_box := class:
        var X:int = 0
    PrivMake()<transacts>:priv_box = priv_box:
        set X += 3
-->
<!-- 009 -->
```verse
rect := class:
    Width:int
    Height:int
    Area:int

Square := rect:
    let:
        S:int = 4    # computed once, used by three initializers
    Width := S
    Height := S
    Area := S * S

Square.Area = 16
```

The `let` clause introduces bindings visible to subsequent field
initializers. Unlike `block`, `let` permits only 
declarations.

#### Restrictions Inside Archetype Bodies

An archetype body initializes fields; it is not a general statement
block. Mutating assignment is rejected outright: a body that says
`set X += 3` does not see `X` as a name it can read, so the compiler
reports both "unknown identifier `X`", and "unsupported
argument to archetype instantiation". Initialize each field once, with
`:=`, and mutate afterwards through a method or a `block` clause.

Calling a `<constructor>` function of the class being instantiated is
*not* a restriction, despite what the shape of an archetype body might
suggest: that call is exactly how delegating constructors work, and it
is legal both inside another constructor and in a plain archetype
expression. Delegation is covered later in this chapter.

### Self

Within class methods, `Self` refers to the current instance:

<!--versetest
LogCharacterAction(:character, :string)<computes>:void={}
-->
<!-- 010 -->
```verse
character := class:
    var Name : string
    var Title : string = ""

    Announce()<computes>:void =
        LogCharacterAction(Self, "announced")  # pass the whole object along

    WithTitle(NewTitle:string)<transacts>:character =
        set Title = NewTitle
        Self                             # return this instance, for chaining

    SetName(NewName:string)<transacts>:void =
        set Self.Name = NewName          # set a field of this instance
        Self.Announce()                  # call a method of this instance

Hero := character{Name := "Aldric"}
Hero.WithTitle("Knight").Title = "Knight"
```

You can capture `Self` when creating nested objects:

<!--versetest-->
<!-- 011 -->
```verse
container := class:
    ID:int

    CreateChild():child_with_parent =
        child_with_parent{Parent := Self}  # capture this instance

child_with_parent := class:
    Parent:container

C := container{ID := 42}
C.CreateChild().Parent.ID = 42   # the child holds a reference to C
```

### Inheritance

Classes support single inheritance:

<!--versetest
vector3:=struct{}
-->
<!-- 012 -->
```verse
entity := class:
    var Position : vector3 = vector3{}
    var IsActive : logic = true

    Activate() : void = set IsActive = true
    Deactivate() : void = set IsActive = false

character := class(entity):  # character inherits from entity
    Name : string
    var Health : int = 100

    TakeDamage(Amount : int) : void =
        set Health = Max(0, Health - Amount)
        if (Health = 0):
            Deactivate()  # Can call inherited methods

player := class(character):  # player inherits from character
    var Score : int = 0
    var Lives : int = 3

    AddScore(Points : int) : void =
        set Score += Points

P := player{Name := "Aldric"}
P.TakeDamage(100)
P.Health = 0 and P.IsActive = false   # inherited field, set by inherited method
```

A `player` is a `character`, and a `character` is an `entity`. You can
use a subclass wherever a superclass is expected.

Three constraints govern what a subclass may do:

1. **Single class inheritance only:** A class can inherit from at most
   one class, but can implement multiple interfaces.

2. **No shadowing of data members:** Subclasses cannot declare fields
   with the same name as parent fields

3. **No method signature changes:** Overriding requires the exact same
   signature

To override a method, use the `<override>` specifier with the matching signature.

### Super

Within a subclass, `super` refers to the superclass, and it appears in
two forms that are easy to confuse. `(super:)` is a qualifier on a
call: it invokes the superclass's implementation of a method on the
object you are already in. `super{...}` is an archetype instantiation:
`super` names the superclass as a *type*, so the braces build a brand
new instance of it.

The qualifier is what an overriding method almost always wants. It
reaches the parent's version of the very method being overridden,
letting the subclass add to that behavior rather than replace it:

<!--versetest-->
<!-- 013 -->
```verse
base := class:
    Describe()<computes>:string = "base"

derived := class(base):
    Describe<override>()<computes>:string =
        # Call the parent implementation, then add to it
        "{(super:)Describe()} + derived"

derived{}.Describe() = "base + derived"
```

`super{...}` is not a way to call up, even though it can be arranged
to look like one. Because it constructs a separate object, the parent
method runs against that new instance and cannot see the state of the
one you are in. When the superclass holds mutable state the two forms
give different answers:

<!--versetest-->
<!-- 014 -->
```verse
tagged := class:
    var Tag:string = "original"
    Describe()<transacts>:string = "[{Tag}]"

call_parent := class(tagged):
    Describe<override>()<transacts>:string = "call {(super:)Describe()}"

build_parent := class(tagged):
    Describe<override>()<transacts>:string = "build {super{}.Describe()}"

A := call_parent{}
set A.Tag = "updated"
A.Describe() = "call [updated]"    # the parent's method, on this object

B := build_parent{}
set B.Tag = "updated"
B.Describe() = "build [original]"  # a different object entirely
```

Both methods above are `<transacts>` for a reason. Constructing a
class that holds mutable state is a transaction, so the `super{}` form
needs that effect, while `(super:)` on its own is content with
`<reads>`. Since an overriding method may not widen the effects it
inherits, a `<reads>` parent method cannot be overridden by a
`<transacts>` one at all — the compiler no longer treats it as an
override and reports that it could not find a parent function to
override. The `super{...}` form is therefore unavailable in any
hierarchy whose parent method is `<reads>` or narrower, and the only
way to admit it is to loosen the parent. Write `super{...}` only when
you genuinely want a fresh instance of the superclass, which is the
same object `tagged{...}` would have given you, named without
repeating the parent's name.

#### Virtual Dispatch Through Parent Methods

When parent methods call other methods, virtual dispatch still applies
based on the actual object type. This means `Self` binds to the
derived instance even when calling through `(super:)`:

<!--versetest-->
<!-- 015 -->
```verse
base := class:
    # Virtual method that can be overridden
    GetValue()<computes>:int = 10

    # Parent method that uses GetValue
    ComputeDouble()<computes>:int =
        2 * GetValue()  # Calls derived GetValue if overridden

derived := class(base):
    # Override GetValue to return different value
    GetValue<override>()<computes>:int = 20

    # Override ComputeDouble to call parent, but GetValue dispatch is virtual
    ComputeDouble<override>()<computes>:int =
        # Calls base.ComputeDouble, which calls derived.GetValue!
        (super:)ComputeDouble()

derived{}.ComputeDouble() = 40   # not 20
```

In this example, even though `ComputeDouble` calls the parent
implementation, the `GetValue()` call inside the parent uses virtual
dispatch and calls the derived version.

### Method Overriding

Subclasses can override methods defined in their superclasses to provide specialized behavior:

<!--versetest
character:=class:
    IsAlive()<decides><transacts>:void={}
MoveToward(:?character)<transacts>:void={}
Patrol()<transacts>:void={}
ScanForTargets()<transacts>:void={}
-->
<!-- 016 -->
```verse
entity := class:
    OnUpdate<public>()<transacts>:void = {}  # Default no-op implementation

enemy := class(entity):
    var Target : ?character = false

    OnUpdate<override>()<transacts> : void =
        if (Target?.IsAlive[]):
            MoveToward(Target)
        else:
            Patrol()

turret := class(entity):
    var Rotation:int = 0

    OnUpdate<override>()<transacts>: void =
        if (V := Mod[Rotation + 90, 360]):
            set Rotation = V
        ScanForTargets()

T := turret{}
Squad:[]entity = array{enemy{}, T}
for (U : Squad):
    U.OnUpdate()          # called through an entity reference
T.Rotation = 90           # ...but the turret's own override is what ran
```

The loop knows only that its elements are entities, yet each object
runs its own `OnUpdate`. That is the whole point of overriding: the
implementation is chosen by the actual type of the object, not by the
type of the variable holding it.

An overriding method does not have to return exactly what the parent
returned. It may narrow the result to a subtype, which is called a
*covariant* return type. The override can call the parent through
`(super:)` and then refine what comes back:

<!--versetest
assert_semantic_error(3532, 3523, 3532):
    b2 := class:
        Tag:int = 0
    d2 := class(b2):
        Extra:int = 0
    p2 := class:
        Create()<transacts>:d2 = d2{}
    s2 := class(p2):
        Create<override>()<transacts>:b2 = b2{}
-->
<!-- 017 -->
```verse
base_type := class:
    Name:string

derived_type := class(base_type):
    Value:int = 0

producer := class:
    Create()<transacts>:base_type = base_type{Name := "base"}

sub_producer := class(producer):
    # Override with a more specific return type
    Create<override>()<transacts>:derived_type =
        derived_type{Name := "{(super:)Create().Name} refined", Value := 42}

# A caller that knows the subclass sees the narrower type
sub_producer{}.Create().Value = 42

# Through a superclass reference, dispatch still reaches the override
P:producer = sub_producer{}
P.Create().Name = "base refined"
```

Narrowing is the only direction allowed, and the reason is
substitutability: anyone holding a `producer` was promised a
`base_type`, and a `derived_type` honors that promise. Going the other
way would not, so the compiler does not merely complain about the
return type — it stops treating the method as an override at all and
then reports the leftover definition as clashing with the inherited
one.

### Constructor Functions

Classes do not have traditional constructor methods like you might find
in other object-oriented languages. Instead, Verse provides three
approaches to object construction, each suited to different needs:

- **Archetype expressions** — direct field initialization for simple
  cases. Straightforward and requires no extra definitions.
- **Block clauses** — initialization code in the class body that runs
  on every construction. Has access to `Self` and all fields,
  making it ideal for registering the object, computing derived
  values, or calling divergent functions that can't appear in field
  defaults.
- **Constructor functions** — annotated with `<constructor>`, these
  are first-class functions that can validate inputs, delegate to
  other constructors (including parent class constructors), be
  overloaded, and be passed around as values. They are the most
  powerful option and essential for inheritance hierarchies where
  subclass constructors need to initialize superclass fields.

These approaches compose: a constructor function returns an archetype
expression, which can contain `let` and `block` clauses, and the
class body can also have its own `block` clauses that execute
regardless of which constructor was used.

For simple cases where you just need to set field values, use
archetype expressions directly:

<!--versetest-->
<!-- 018 -->
```verse
player := class:
    Name:string
    var Health:int = 100
    Level:int = 1

Hero := player{Name := "Aldric", Health := 150, Level := 5}
Hero.Health = 150
```

When you need validation, computation, or complex initialization
logic, use constructor functions annotated with `<constructor>`:

<!--versetest
player := class:
    Name:string
    var Health:int = 100
    Level:int = 1

MaxLevel:int = 99
-->
<!-- 019 -->
```verse
MakePlayer<constructor>(InName:string, InLevel:int)<transacts> := player:
    Name := InName
    Level := InLevel
    Health := InLevel * 100

Hero := MakePlayer("Aldric", 5)   # call it by name
Hero.Health = 500
```

Constructor functions are regular functions that return class
instances, but the `<constructor>` annotation enables special
capabilities like delegating to other constructors. When calling a
constructor function from normal code, use just the function name—the
`<constructor>` annotation only appears in the definition.

Constructor functions can have effects that control their
behavior. Common effects include `<computes>`, `<allocates>`, and
`<transacts>`. A particularly useful effect is `<decides>`, which
allows constructors to fail if preconditions are not met:

<!--versetest
player := class:
    Name:string
    var Health:int = 100
    Level:int = 1

MaxLevel:int = 99
-->
<!-- 020 -->
```verse
MakeValidPlayer<constructor>(InName:string, InLevel:int)<transacts><decides> := player:
    Name := InName
    Level := block:
        InLevel > 0
        InLevel <= MaxLevel
        InLevel
    Health := InLevel * 100

MakeValidPlayer["Aldric", 5].Health = 500
not MakeValidPlayer["Aldric", 0]   # the level check fails, so the call fails
```

Constructor functions cannot use the `<suspends>` effect. Construction
must complete synchronously to maintain object consistency.

### Overloading Constructors

You can provide multiple constructor functions with different
parameter signatures, allowing flexible object creation:

<!--versetest
vector3:=class<final>{ X:float=0.0; Y:float=0.0; Z:float=0.0 }
-->
<!-- 021 -->
```verse
entity := class:
    Name:string
    var Health:int = 100
    Position:vector3

# Constructor with all parameters
MakeEntity<constructor>(Name:string, Health:int, Position:vector3) := entity:
    Name := Name
    Health := Health
    Position := Position

# Constructor with defaults
MakeEntity<constructor>(Name:string, Position:vector3) := entity:
    Name := Name
    Health := 100
    Position := Position

# Constructor for origin placement
MakeEntity<constructor>(Name:string) := entity:
    Name := Name
    Health := 100
    Position := vector3{X := 0.0, Y := 0.0, Z := 0.0}

# The overload is chosen by the argument list
SpawnPoint := vector3{X := 10.0, Y := 0.0, Z := 0.0}
MakeEntity("Goblin", 50, SpawnPoint).Health = 50
MakeEntity("Guard", SpawnPoint).Health = 100
MakeEntity("Shopkeeper").Position.X = 0.0
```

### Delegating Constructors

Constructor functions can delegate to other constructors, enabling
code reuse and constructor chaining. This is particularly important
for inheritance hierarchies where subclass constructors need to
initialize superclass fields.

When delegating to a parent class constructor from a subclass, you
must initialize the subclass fields first, then call the parent
constructor using the qualified `<constructor>` syntax within the
archetype:

<!--versetest
entity := class:
    Name:string
    var Health:int

MakeEntity<constructor>(Name:string, Health:int) := entity:
    Name := Name
    Health := Health

character := class(entity):
    Class:string
    Level:int

# Subclass constructor delegates to parent constructor
MakeCharacter<constructor>(Name:string, Class:string, Level:int) := character:
    # Initialize subclass fields first
    Class := Class
    Level := Level
    # Then delegate to parent constructor
    MakeEntity<constructor>(Name, Level * 100)

assert:
    Hero := MakeCharacter("Aldric", "Warrior", 5)
    Hero.Health = 500 and Hero.Name = "Aldric"
<#
-->
<!-- 022 -->
```verse
entity := class:
    Name:string
    var Health:int

MakeEntity<constructor>(Name:string, Health:int) := entity:
    Name := Name
    Health := Health

character := class(entity):
    Class:string
    Level:int

# Subclass constructor delegates to parent constructor
MakeCharacter<constructor>(Name:string, Class:string, Level:int) := character:
    # Initialize subclass fields first
    Class := Class
    Level := Level
    # Then delegate to parent constructor
    MakeEntity<constructor>(Name, Level * 100)

Hero := MakeCharacter("Aldric", "Warrior", 5)
Hero.Health = 500 and Hero.Name = "Aldric"
```
<!-- #>-->

Constructor functions can also forward to other constructors of the same class:

<!--versetest
player := class:
    Name:string
    var Score:int

# Primary constructor
MakePlayer<constructor>(Name:string, Score:int) := player:
    Name := Name
    Score := Score

# Convenience constructor forwards to primary
MakeNewPlayer<constructor>(Name:string) := player:
    # Delegate to another constructor of the same class
    MakePlayer<constructor>(Name, 0)

assert:
    MakeNewPlayer("Aldric").Score = 0
<#
-->
<!-- 023 -->
```verse
player := class:
    Name:string
    var Score:int

# Primary constructor
MakePlayer<constructor>(Name:string, Score:int) := player:
    Name := Name
    Score := Score

# Convenience constructor forwards to primary
MakeNewPlayer<constructor>(Name:string) := player:
    # Delegate to another constructor of the same class
    MakePlayer<constructor>(Name, 0)

MakeNewPlayer("Aldric").Score = 0
```
<!-- #>-->

When delegating to a constructor of the same class, the delegation
replaces all field initialization—any fields you initialize before the
delegation are ignored. When delegating to a parent class constructor,
your subclass field initializations are preserved, and the parent
constructor initializes the parent fields.

### Order of Execution

Understanding execution order is crucial for correct initialization:

1. **Archetype expression:** Field initializers execute in the order
   they are written in the archetype
2. **Delegating constructor:** Subclass fields are initialized first,
   then the parent constructor runs
3. **Class body blocks:** When using direct archetype construction,
   blocks in the class definition execute before field initialization

For delegating constructors to parent classes:

<!--versetest
base := class:
    BaseValue:int

MakeBase<constructor>(Value:int) := base:
    block:
        Print("Base constructor")
    BaseValue := Value

derived := class(base):
    DerivedValue:int

MakeDerived<constructor>(Base:int, Derived:int) := derived:
    # This executes first
    DerivedValue := Derived
    # Then parent constructor executes
    MakeBase<constructor>(Base)

assert:
    Instance := MakeDerived(10, 20)
    Instance.BaseValue = 10 and Instance.DerivedValue = 20
<#
-->
<!-- 024 -->
```verse
base := class:
    BaseValue:int

MakeBase<constructor>(Value:int) := base:
    block:
        Print("Base constructor")
    BaseValue := Value

derived := class(base):
    DerivedValue:int

MakeDerived<constructor>(Base:int, Derived:int) := derived:
    # This executes first
    DerivedValue := Derived
    # Then parent constructor executes
    MakeBase<constructor>(Base)

Instance := MakeDerived(10, 20)          # prints "Base constructor"
Instance.BaseValue = 10 and Instance.DerivedValue = 20
```
<!-- #>-->

For classes with mutable fields, initialization sets starting values
that can change during the object's lifetime. Immutable fields must be
initialized during construction and cannot be modified afterward. This
distinction makes the construction phase critical for establishing
invariants that will hold throughout the object's existence.

## Shadowing and Qualification

Verse has strict rules about name shadowing to prevent ambiguity and
maintain code clarity. Understanding these rules and the qualification
syntax is essential for working with inheritance hierarchies, multiple
interfaces, and nested modules.

In most contexts, you **cannot redefine names** that already exist in
an enclosing scope. This applies to functions, variables, classes,
interfaces, and modules:

<!--versetest
assert_semantic_error(3532):
    F(X:int):int = X + 1
    c := class:
        F(X:int):int = X + 2
-->
<!-- 025 -->
```verse
# ERROR: the class method shadows the module-level F
# F(X:int):int = X + 1
# c := class:
#     F(X:int):int = X + 2
```

The same prohibition reaches across every kind of definition. Each of
the four pairs below is rejected the same way:

<!--versetest
assert_semantic_error(3532):
    priv_something := class {}
    PrivM := module:
        priv_something := class {}

assert_semantic_error(3532):
    PrivValue:int = 1
    PrivN := module:
        PrivValue:int = 2

assert_semantic_error(3532):
    priv_c := class { PrivA:int }
    PrivA():void = {}

assert_semantic_error(3532):
    PrivId():void = {}
    PrivId := module {}
-->
<!-- 026 -->
```verse
# something := class {}
# M := module:
#     something := class {}   # a nested module cannot shadow a class

# Value:int = 1
# N := module:
#     Value:int = 2           # nor a binding

# c := class { A:int }
# A():void = {}               # nor collide with a data member

# Id():void = {}
# Id := module {}             # a module and a function cannot share a name
```

The prohibition holds regardless of definition order: it does not
matter whether the outer name is defined before or after the inner
scope. The third pair above shows this — the class comes first there,
and moving the function ahead of it changes nothing.

To define methods with the same name in different contexts, use
**qualified names** with the syntax `(ClassName:)MethodName`:

<!--versetest-->
<!-- 027 -->
```verse
# Class with a qualified method of the same name
c := class:
   (c:)F(X:int):int = X + 2

# Module-level function
F(X:int):int = X + 1

F(10) = 11              # the module-level function
c{}.F(10) = 12          # the class method
c{}.(c:)F(10) = 12      # explicit qualification, optional here
```

The `(c:)` qualifier indicates this `F` is defined specifically in
the `c` class context, distinguishing it from the module-level
`F`. This allows the same name to coexist without shadowing errors.

### Methods with Same Name

Using qualifiers, you can define *new methods* with the same name as
inherited methods, creating multiple distinct methods in the same
class:

<!--versetest
assert_semantic_error(3518):
    c58 := class<abstract> { F(X:int):int }
    d58 := class(c58):
        F<override>(X:int):int = X + 1
    e58 := class(d58):
        (e58:)F(X:int):int = X + 2
    Ambiguous58(E:e58):int = E.F(10)
-->
<!-- 028 -->
```verse
c := class<abstract> { F(X:int):int }

d := class(c):
    F<override>(X:int):int = X + 1

e := class(d):
    (e:)F(X:int):int = X + 2 # NEW method with same name, not an override

# e now contains BOTH methods
E := e{}
E.(c:)F(10) = 11   # inherited from c, overridden in d
E.(e:)F(10) = 12   # newly defined in e

# ERROR: neither one wins - the unqualified call matches both
# E.F(10)
```

Key distinction:

- `F<override>` without qualifier: Overrides the inherited `F`
- `(e:)F` without `<override>`: Defines a **new** `F` specific to `e`

Once both methods exist, the qualifier is no longer optional. There is
no rule that the nearer or the more derived definition wins: an
unqualified `E.F(10)` matches both and the compiler reports that
multiple overloads match the arguments. This is the difference from the
`(c:)F` above, where the qualifier could be dropped because only one
`F` was a member of the class. So a class can carry several methods of
the same name, each serving a different purpose in the hierarchy, but
every call to them has to say which one it means.

### `(super:)` Qualified

The `(super:)` qualifier works with qualified method names to call the
parent class's implementation:

<!--versetest-->
<!-- 029 -->
```verse
i := interface { F(X:int):int }

ci := class(i):
    (i:)F<override>(X:int):int = X + 1
    (ci:)F(X:int):int = X + 2

dci := class(ci):
    # Override both inherited methods, calling super implementations
    (i:)F<override>(X:int):int = 100 + (super:)F(X)
    (ci:)F<override>(X:int):int = 200 + (super:)F(X)

DCI := dci{}
DCI.(i:)F(10) = 111
DCI.(ci:)F(10) = 212
```

`(super:)F(X)` within the qualified method calls the parent class's
implementation of that same qualified method. This enables you to
extend behavior for multiple method variants independently.

### Interface Collisions

When implementing multiple interfaces with methods of the same name,
qualifiers disambiguate which interface's method you are implementing:


<!--versetest-->
<!-- 030 -->
```verse
i := interface:
    B(X:int):int

j := interface:
    B(X:int):int

collision := class(i, j):
    # Implement both B methods separately
    (i:)B<override>(X:int):int = 20 + X
    (j:)B<override>(X:int):int = 30 + X

Obj := collision{}
Obj.(i:)B(1) = 21
Obj.(j:)B(1) = 31
```

Without qualifiers, the compiler cannot determine which interface's
method you are implementing.

The same qualifiers untangle deeper hierarchies, where one interface
inherits from another and redefines a method it has already inherited:

<!--versetest-->
<!-- 031 -->
```verse
i := interface:
    C(X:int):int

j := interface(i):
    A(X:int):int

k := interface(i):
    B(X:int):int
    (k:)C(X:int):int  # k redefines C

multi := class(j, k):
    A<override>(X:int):int = 10 + X
    B<override>(X:int):int = 20 + X
    # Must implement C from both inheritance paths
    (i:)C<override>(X:int):int = 30 + X
    (k:)C<override>(X:int):int = 40 + X

Obj := multi{}
Obj.(i:)C(1) = 31
Obj.(k:)C(1) = 41
```

When an interface redefines a method from a parent interface using
qualification `(k:)C`, implementing classes must provide
separate implementations for both variants.

### Nested Module Qualification

Modules can be nested, and deeply qualified names reference members
through the entire hierarchy:

<!--versetest
assert_semantic_error(3506):
    Top59 := module:
        (Top59:)M<public> := module:
            (Top59.M:)F<public>(X:int):int = X + 10
    Use59():int = (Top59.M:)F(0)
-->
<!-- 032 -->
```verse
Top := module:
    (Top:)M<public> := module:
        (Top.M:)Value<public>:int = 1
        (Top.M:)F<public>(X:int):int = X + 10

        (Top.M:)M<public> := module:
            (Top.M.M:)Value<public>:int = 3
            (Top.M.M:)F<public>(X:int):int = X + 100

client := module:
    using { Top.M }
    using { Top.M.M }

    # Both F's are in scope here; full qualification tells them apart
    (client:)Check<public>()<decides>:void =
        (Top.M:)F(0) = 10
        (Top.M.M:)F(0) = 100

client.Check[]

# Or reach them by path, which needs no `using` at all
Top.M.F(1) = 11
Top.M.M.F(1) = 101
```

Nested modules can have the same simple name — both of these are
called `M` — and stay distinct because their full paths differ, which
is what lets a hierarchy grow without naming conflicts.

The two `using` declarations are doing more work than they appear to.
A qualifier only says which `F` is meant among the ones already in
scope; it does not itself bring anything into scope. Drop the `using`
declarations and `(Top.M:)F(0)` does not become ambiguous, it becomes
an unknown identifier. The dotted path is the form that stands alone:
`Top.M.F(1)` needs no `using`, because the path names the module and
the member in one go. Note also where the `using` declarations sit.
They are module-scope declarations, so they belong inside `client`
rather than beside the calls; a `using` of a module written in an
ordinary expression context is rejected.

### Restrictions

Local variables cannot shadow class members. A local binding that
reuses a field's name is rejected by the same rule that
governs every other shadowing case:

<!--versetest
assert_semantic_error(3532):
    priv_a := class:
        I:int
        F(X:int):void =
            I:int = 5
-->
<!-- 033 -->
```verse
# a := class:
#     I:int
#     F(X:int):void =
#         I:int = 5   # ERROR: shadows member I
```

Currently, there is no `(local:)` qualifier to disambiguate, so this
pattern is not supported. You must use different names for local
variables and members.

## Parametric Classes

Parametric classes, also known as generic classes, allow you to define
classes that work with any type. Rather than writing separate
container classes for integers, strings, players, and every other
type, you write one parametric class that accepts a type parameter.

A parametric class takes one or more type parameters in its definition:

<!--versetest-->
<!-- 034 -->
```verse
# Simple container that holds a single value
container(t:type) := class:
    Value:t

# More than one type parameter is allowed
pair(t:type, u:type) := class:
    First:t
    Second:u

Coordinate := pair(int, string){First := 10, Second := "north"}
Coordinate.First = 10 and Coordinate.Second = "north"
```

The syntax `container(t:type)` parameterizes the class by type `t`,
which can be used in field declarations, method signatures, and return
types. A type parameter is in scope throughout the body, so methods can
take it as an argument type, return it, and nest it inside other types:

<!--versetest-->
<!-- 035 -->
```verse
optional_container(t:type) := class:
    var MaybeValue:?t = false

    Set(Value:t)<transacts>:void =
        set MaybeValue = option{Value}

    Get()<reads><decides>:t =
        MaybeValue?

    Clear()<transacts>:void =
        set MaybeValue = false

Box := optional_container(string){}
not Box.Get[]
Box.Set("hello")
Box.Get[] = "hello"
Box.Clear()
not Box.Get[]
```

### Instantiation and Identity

Multiple instantiations with the same type arguments produce the same
type:

<!--versetest-->
<!-- 036 -->
```verse
container(t:type) := class:
    Value:t

# These name one type, not two copies of it
Type1 := container(int)
Type2 := container(int)

C1:Type1 = container(int){Value := 1}
C2:Type2 = C1              # accepted: Type1 and Type2 are the same type
C2.Value = 1
```

The instantiation process is **deterministic and memoized**. The first
time you write `container(int)`, Verse generates a concrete
type. Every subsequent use of `container(int)` refers to that same
type, not a new copy.

This matters for:

- **Type compatibility**: Two values of `container(int)` can be used interchangeably
- **Memory efficiency**: Not creating duplicate type definitions
- **Semantic correctness**: Same type arguments always mean the same type

While the same type arguments always produce the same type, different
type arguments produce distinct, incompatible types:

<!--versetest
assert_semantic_error(3510):
    cont(t:type) := class:
        Value:t
    Mix(A:cont(int)):cont(string) = A
-->
<!-- 037 -->
```verse
container(t:type) := class:
    Value:t

IntContainer := container(int){Value := 42}
StringContainer := container(string){Value := "text"}

IntContainer.Value = 42
StringContainer.Value = "text"

# ERROR: the two instantiations are unrelated types
# Mix(A:container(int)):container(string) = A
```

`container(int)` and `container(string)` are completely different
types, with no subtype relationship. They happen to share the same
structure (both defined from `container`), but that does not make them
compatible.

While different instantiations of a parametric class are distinct
types, Verse allows certain instantiations to be used in place of
others based on **variance**. Variance determines when
`parametric_class(subtype)` can be used where
`parametric_class(supertype)` is expected (or vice versa).

The variance of a parametric type depends on how the type parameter is
used within the class definition. The four cases below all use this
pair of classes:

<!--versetest-->
<!-- 038 -->
```verse
entity := class:
    ID:int

player := class(entity):
    Name:string
```

#### Covariant

When a type parameter appears only in **return positions** (method
return types, field types being read), the parametric class is
**covariant** in that parameter (see
[Types](11_types.md#understanding-subtyping) for details on
variance). This means instantiations follow the same subtyping
direction as their type arguments:

<!--versetest
entity := class:
    ID:int
player := class(entity):
    Name:string
-->
<!-- 039 -->
```verse
producer(t:type) := class:
    Value:t

    Get():t = Value  # Returns t - covariant position

ProcessProducer(P:producer(entity)):int = P.Get().ID

PlayerProducer:producer(player) = producer(player){Value := player{ID := 1, Name := "Alice"}}
EntityProducer:producer(entity) = PlayerProducer   # Valid: player is an entity
ProcessProducer(PlayerProducer) = 1                # so this works too
```

This is safe because a `player` has everything an `entity` has. If you
expect to get an `entity` out of a producer, receiving a `player`
instead is always acceptable.

#### Contravariant

When a type parameter appears only in **parameter positions** (method
parameters being consumed), the parametric class is **contravariant**
in that parameter (see [Types](11_types.md#understanding-subtyping)
for details on variance). This means instantiations follow the
**opposite** subtyping direction:


<!--versetest
entity := class:
    ID:int
player := class(entity):
    Name:string
-->
<!-- 040 -->
```verse
consumer(t:type) := class:
    Process(Item:t):void = {}  # Accepts t - contravariant position

ProcessPlayers(C:consumer(player)):void =
    C.Process(player{ID := 1, Name := "Bob"})

# Contravariance allows supertype -> subtype
EntityConsumer:consumer(entity) = consumer(entity){}
PlayerConsumer:consumer(player) = EntityConsumer  # Valid!
ProcessPlayers(EntityConsumer)                    # Works!
```

The direction reverses because a `consumer(entity)` accepts everything
a `consumer(player)` accepts, and more. Anything able to handle any
`entity` can certainly handle a `player`.

#### Invariant

When a type parameter appears in **both parameter and return
positions**, the parametric class is **invariant** in that
parameter. No subtyping relationship exists between different
instantiations:

<!--versetest
entity := class:
    ID:int

player := class(entity):
    Name:string

assert_semantic_error(3509):
    ent := class:
        ID:int
    pl := class(ent):
        Name:string
    tr(t:type) := class:
        Transform(Input:t):t = Input
    G():void =
        PT:tr(pl) = tr(pl){}
        X:tr(ent) = PT
-->
<!-- 041 -->
```verse
# Type parameter in both positions, so no variance either way
transformer(t:type) := class:
    Transform(Input:t):t = Input

EntityTransformer:transformer(entity) = transformer(entity){}
PlayerTransformer:transformer(player) = transformer(player){}

# ERROR: neither of these conversions is allowed
# X:transformer(entity) = PlayerTransformer
# Y:transformer(player) = EntityTransformer
```

Neither direction is safe. If a `transformer(player)` were usable as a
`transformer(entity)`, you could hand any `entity` to a `Transform`
that expects a `player`.

#### Bivariant

When a type parameter is not used in any member signature, neither in the
type's own members nor in any member it inherits, the parametric class is
**bivariant**. Any instantiation can be converted to any other:

<!--versetest
entity := class:
    ID:int

player := class(entity):
    Name:string
-->
<!-- 042 -->
```verse
# Type parameter not used in the public interface
container(t:type) := class:
    DoSomething():void = {}  # Doesn't use t at all

EntityContainer:container(entity) = container(entity){}
PlayerContainer:container(player) = container(player){}

# Both directions work
X:container(entity) = PlayerContainer
Y:container(player) = EntityContainer
```

The type parameter does not affect observable behaviour, so the
instantiations are interchangeable.

#### Inherited Members Constrain Variance

Variance is computed over a type's full member set, including members inherited
from a parametric base. A derived type with an empty body is *not* automatically
bivariant:

<!--versetest
assert_semantic_error(3510):
    holder(t:type) := interface:
        Value:t
    derived(t:type) := interface(holder(t)) {}
    F(X:derived(int)):derived(float) = X
<#
-->
<!-- 043 -->
```verse
holder(t:type) := interface:
    Value:t                          # covariant use of t

# Empty body, but inherits Value:t - so `derived` is covariant, not bivariant
derived(t:type) := interface(holder(t)) {}

# Invalid: covariance only allows the subtype -> supertype direction
# F(X:derived(int)):derived(float) = X   # ERROR
```
<!-- #> -->

### Recursive Parametric Types

Parametric classes can reference themselves in their field types,
enabling recursive generic data structures like linked lists, trees,
and graphs. The key requirement is that the self-reference uses
**the same type parameter** — this is the only form of recursion
Verse allows. It works because the compiler can resolve the type
structure in a single pass: `list_node(int)` contains a
`?list_node(int)`, which contains a `?list_node(int)`, and so on.
The optional (`?`) provides the base case that terminates the
recursion at runtime.

Here is a generic linked list built as a recursive parametric class:

<!--versetest-->
<!-- 044 -->
```verse
# Linked list node
list_node(t:type) := class:
    Value:t
    Next:?list_node(t)  # Same type parameter 't'

# Helper to create lists
Cons(Head:t, Tail:?list_node(t) where t:type)<transacts>:list_node(t) =
    list_node(t){Value := Head, Next := Tail}

# Sum a linked list
SumList(List:?list_node(int))<transacts>:int =
    if (Head := List?):
        Head.Value + SumList(Head.Next)
    else:
        0

IntList := Cons(1, option{Cons(2, false)})
SumList(option{IntList}) = 3
```

#### Disallowed: Direct Type Alias Recursion

You cannot define a parametric type that directly aliases to a
structural type containing itself:

<!--versetest
assert_semantic_error(3502):
    t1(u:type) := []t1(u)
-->
<!-- 045 -->
```verse
# Invalid: Direct array recursion
# t(u:type) := []t(u)  # ERROR

# Invalid: Direct map recursion
# t(u:type) := [int]t(u)  # ERROR

# Invalid: Direct optional recursion
# t(u:type) := ?t(u)  # ERROR

# Invalid: Direct function recursion
# t(u:type) := u->t(u)  # ERROR
# t(u:type) := t(u)->u  # ERROR
```

These fail because they create infinite type expansion—the compiler
cannot determine the actual structure of the type.

The way round this is to wrap the recursive reference in a class. A
tree where each node holds a list of children is a recursive
parametric type — each `nested_list(t)` contains an array of
`nested_list(t)` — and it is accepted, because the class gives the
compiler a name to stop at:

<!--versetest-->
<!-- 046 -->
```verse
nested_list(t:type) := class:
    Items:[]nested_list(t)  # OK - wrapped in class

Tree := nested_list(int){
    Items := array{
        nested_list(int){Items := array{}},
        nested_list(int){Items := array{}}
    }
}
Tree.Items.Length = 2
```

#### Disallowed: Polymorphic Recursion

Polymorphic recursion occurs when a parametric type references itself
with a **different type argument**:

<!--versetest
assert_semantic_error(3509):
    my_type(t:type) := class:
        Next:my_type(?t)
assert_semantic_error(3509):
    bi_list(t:type, u:type) := class:
        Value:t
        Next:?bi_list(u, t)
-->
<!-- 047 -->
```verse
# Invalid: Type parameter changes
# my_type(t:type) := class:
#     Next:my_type(?t)  # ERROR - ?t is different from t

# Invalid: Alternating type parameters
# bi_list(t:type, u:type) := class:
#     Value:t
#     Next:?bi_list(u, t)  # ERROR - parameters swapped
```

Polymorphic recursion makes type inference undecidable: instantiating
`my_type(int)` would need `my_type(?int)`, which needs `my_type(??int)`,
and so on without end. It is sound in some type systems, but Verse does
not support it, to keep type checking tractable.

#### Disallowed: Mutual Recursion

Mutual recursion between multiple parametric types is not supported
either; each of the two definitions below is rejected on its own:

<!--versetest
assert_semantic_error(3509, 3509):
    priv_t1(t:type) := class:
        Next:?priv_t2(t)
    priv_t2(t:type) := class:
        Next:?priv_t1(t)
-->
<!-- 048 -->
```verse
# ERROR: circular dependency the compiler cannot resolve
# t1(t:type) := class:
#     Next:?t2(t)  # References t2
#
# t2(t:type) := class:
#     Next:?t1(t)  # References t1
```

Mutual recursion raises the same problem, creating circular
dependencies the compiler cannot resolve.

Combine them into a single type instead, and tag each node with an
enum to recover the case distinction the two types were carrying:

<!--versetest-->
<!-- 049 -->
```verse
node_type := enum:
    TypeA
    TypeB

combined_node(t:type) := class:
    Type:node_type
    Value:t
    Next:?combined_node(t)

Node := combined_node(int){Type := node_type.TypeA, Value := 1, Next := false}
Node.Value = 1
```

#### Disallowed: Inheritance Recursion

You cannot inherit from a type variable or create recursive
inheritance through parametric types; both are rejected:

<!--versetest
assert_semantic_error(3590):
    priv_self(u:type) := class(priv_self(u)){}

assert_semantic_error(3590):
    priv_from_var(t:type) := class(t){}
-->
<!-- 050 -->
```verse
# ERROR: inheriting from the parametric type being defined
# t(u:type) := class(t(u)){}

# ERROR: inheriting from a type variable
# inherits_from_variable(t:type) := class(t){}
```

Inheritance requires knowing the parent's structure, but under
parametric recursion that structure would be self-referential before it
is defined.


### Parametric Interfaces

While parametric classes get most of the attention, interfaces can
also be parametric, enabling abstract contracts that work with any
type:

<!--versetest-->
<!-- 051 -->
```verse
# Generic equality interface
equivalence(t:type, u:type) := interface:
    Equal(Left:t, Right:u)<transacts><decides>:t

# Generic collection interface
collection_ifc(t:type) := interface:
    AddItem(Item:t)<transacts>:void
    RemoveItem(Item:t)<transacts><decides>:void
    Has(Item:t)<reads>:logic
```

Classes implement parametric interfaces by providing concrete types
for the parameters:

<!--versetest
equivalence(t:type, u:type) := interface:
    Equal(Left:t, Right:u)<transacts><decides>:t

# Implement with specific types
int_equivalence := class(equivalence(int, comparable)):
    Equal<override>(Left:int, Right:comparable)<transacts><decides>:int =
        Left = Right

# Or with type parameters matching the class
comparable_equivalence(t:subtype(comparable)) := class(equivalence(t, comparable)):
    Equal<override>(Left:t, Right:comparable)<transacts><decides>:t =
        Left = Right

assert:
    Eq := comparable_equivalence(int){}
    Eq.Equal[5, 5] = 5
<#
-->
<!-- 052 -->
```verse
equivalence(t:type, u:type) := interface:
    Equal(Left:t, Right:u)<transacts><decides>:t

# Implement with specific types
int_equivalence := class(equivalence(int, comparable)):
    Equal<override>(Left:int, Right:comparable)<transacts><decides>:int =
        Left = Right

# Or with type parameters matching the class
comparable_equivalence(t:subtype(comparable)) := class(equivalence(t, comparable)):
    Equal<override>(Left:t, Right:comparable)<transacts><decides>:t =
        Left = Right

Eq := comparable_equivalence(int){}
Eq.Equal[5, 5] = 5
```
<!-- #> -->

Parametric interfaces follow the same variance rules as parametric classes:

<!--versetest-->
<!-- 053 -->
```verse
entity := class:
    ID:int

player := class(entity):
    Name:string

# Covariant interface - returns t
producer_interface(t:type) := interface:
    Produce():t

player_producer := class(producer_interface(player)):
    Produce<override>():player = player{ID := 1, Name := "Test"}

# Covariant subtyping works
EntityProducer:producer_interface(entity) = player_producer{}
EntityProducer.Produce().ID = 1
```

You can create specialized (non-parametric) interfaces from parametric
ones. That matters for casting, because a cast target has to be a
non-parametric type:

<!--versetest-->
<!-- 054 -->
```verse
generic_handler(t:type) := interface:
    Handle(Item:t):void

# Specialize to a concrete type
int_handler := interface(generic_handler(int)):
    # Inherits Handle(Item:int):void
    # Can add more methods here

int_processor := class(int_handler):
    Handle<override>(Item:int):void =
        Print("Handling: {Item}")

# The specialized interface can be a cast target
Base := int_processor{}
if (Handler := int_handler[Base]):
    Handler.Handle(42)
```

#### Multiple Type Parameters

Interfaces can have multiple type parameters with independent variance:

<!--versetest-->
<!-- 055 -->
```verse
converter_interface(input:type, output:type) := interface:
    Convert(In:input):output
    # input is contravariant, output is covariant

entity := class:
    ID:int

player := class(entity):
    Name:string

# Implement with specific types
player_to_entity := class(converter_interface(player, entity)):
    Convert<override>(In:player):entity = entity{ID := In.ID}

# Variance allows flexible usage
C:converter_interface(player, entity) = player_to_entity{}
C.Convert(player{ID := 7, Name := "Ann"}).ID = 7
```

### Advanced Parametric Types

#### Effects

Parametric types can have effect specifiers that apply to all instantiations:

<!--versetest
assert_semantic_error(3512):
    eff_decides(t:type) := class<decides>:
        P:t

assert_semantic_error(3512):
    eff_suspends(t:type) := class<suspends>:
        P:t

assert_semantic_error(3565):
    eff_converges(t:type) := class<converges>:
        P:t

assert_semantic_error(3565):
    eff_plain := class<converges>:
        P:int
-->
<!-- 056 -->
```verse
# Parametric class with effects
async_container(t:type) := class<computes>:
    Property:t

transactional_container(t:type) := class<transacts>:
    Property:t

# Every instantiation inherits the effect
X:async_container(int) = async_container(int){Property := 1}
Y:transactional_container(int) = transactional_container(int){Property := 2}
X.Property + Y.Property = 3
```

The effects a parametric class may carry are `<computes>`, which allows
non-terminating computation, `<transacts>`, which makes instantiation
participate in a transaction, `<reads>` and `<writes>`, which touch mutable
state, and `<allocates>`, which allocates. The failure and suspension
effects are rejected outright. `<decides>` would mean that the effect
declaration itself might fail, which would require a failure context around
the class definition, and `<suspends>` would likewise require a context that
can block; neither exists at the point where a type is declared, so both
are rejected.

An effect on the class becomes part of its contract: it propagates to every
construction site, so a function that builds an instance has to declare it
as well.

<!--versetest-->
<!-- 057 -->
```verse
my_type(t:type) := class<computes>:
    Property:t

# This requires <computes> in the context
CreateInstance()<computes>:my_type(int) =
    my_type(int){Property := 1}

CreateInstance().Property = 1
```

#### Aliases

You can create type aliases that simplify complex parametric type expressions:

<!--versetest-->
<!-- 058 -->
```verse
# Alias for map type
string_map(t:type) := [string]t

# Use the alias
PlayerScores:string_map(int) = map{
    "Alice" => 100,
    "Bob" => 95
}

# Alias for optional array
optional_array(t:type) := []?t

# Simplifies type signatures
FilterValid(Items:optional_array(int)):[]int =
    for (Item : Items; Value := Item?):
        Value
```

Aliases are not restricted to named types. Function types and tuple types
can be given names in exactly the same way:

<!--versetest-->
<!-- 059 -->
```verse
# Function type aliases
transformer(input:type, output:type) := input -> output
predicate(t:type) := t -> logic

# Tuple type aliases
pair(t:type, u:type) := tuple(t, u)
triple(t:type) := tuple(t, t, t)

# Use in signatures
ApplyTransform(T:transformer(int, string), Value:int):string =
    T(Value)

CheckCondition(P:predicate(int), Value:int):logic =
    P(Value)
```

Type aliases improve readability and maintainability for complex generic types.

#### Advanced Type Constraints

Beyond basic `subtype` constraints, parametric types support specialized constraints:

A `subtype` constraint restricts the argument to classes that derive from a
given class, which in turn lets the body of the parametric class use that
class's members:

<!--versetest
entity := class{ID:int = 0}
player := class(entity){}

# Constrain to subtype of a class
bounded_container(t:subtype(entity)) := class:
    Value:t

    GetID():int = Value.ID  # Can access entity members

assert:
    # Valid: player is a subtype of entity
    PlayerContainer := bounded_container(player){Value := player{}}
    PlayerContainer.GetID() = 0

assert_semantic_error(3509):
    c_entity := class{ID:int = 0}
    c_bounded(t:subtype(c_entity)) := class:
        Value:t
    Bad(X:c_bounded(int)):void = {}
<#
-->
<!-- 060 -->
```verse
entity := class{ID:int = 0}
player := class(entity){}

# Constrain to subtype of a class
bounded_container(t:subtype(entity)) := class:
    Value:t

    GetID():int = Value.ID  # Can access entity members

# Valid: player is a subtype of entity
PlayerContainer := bounded_container(player){Value := player{}}

# ERROR: int is not a subtype of entity
# IntContainer := bounded_container(int){Value := 0}
```
<!-- #>-->

A `castable_subtype` constraint goes further: it requires an argument that
can be used as the target of a runtime cast, so the parametric class can
test values against `t` with `t[Item]`:

<!--versetest
component := class<castable>{}
warrior := class(component){Power:int}
ProcessTyped(:component)<computes>:void = {}

# t must be usable as the target of a cast
dynamic_handler(t:castable_subtype(component)) := class:
    Handle(Item:component):void =
        if (Typed := t[Item]):
            # Typed has the specific subtype
            ProcessTyped(Typed)

# warrior satisfies the constraint
HandleAsWarrior(Item:component):void =
    dynamic_handler(warrior){}.Handle(Item)
<#
-->
<!-- 061 -->
```verse
component := class<castable>{}
warrior := class(component){Power:int}

# t must be usable as the target of a cast
dynamic_handler(t:castable_subtype(component)) := class:
    Handle(Item:component):void =
        if (Typed := t[Item]):
            # Typed has the specific subtype
            ProcessTyped(Typed)

# warrior satisfies the constraint
HandleAsWarrior(Item:component):void =
    dynamic_handler(warrior){}.Handle(Item)
```
<!-- #> -->

A constraint on a parametric class also tells the compiler what the body may
do with `t`. The `comparable` constraint below is what makes `=` legal on a
field of type `t`. A function that takes such a class has to repeat the
constraint in a `where` clause; dropping it is an error, because the
function would be promising less about `t` than the class demands:

<!--versetest
# The constraint is what makes `=` legal on Data
wrapper(t:subtype(comparable)) := class:
    Data:t

# A function taking a wrapper must repeat the constraint
Same(W:wrapper(t), Other:t where t:subtype(comparable))<computes><decides>:void =
    W.Data = Other

assert:
    Same[wrapper(int){Data := 5}, 5]
    not Same[wrapper(string){Data := "a"}, "b"]

assert_semantic_error(3509):
    w_priv(t:subtype(comparable)) := class:
        Data:t
    SamePriv(W:w_priv(t), Other:t where t:type)<computes><decides>:void =
        W.Data = Other
<#
-->
<!-- 062 -->
```verse
# The constraint is what makes `=` legal on Data
wrapper(t:subtype(comparable)) := class:
    Data:t

# A function taking a wrapper must repeat the constraint
Same(W:wrapper(t), Other:t where t:subtype(comparable))<computes><decides>:void =
    W.Data = Other

Same[wrapper(int){Data := 5}, 5]

# ERROR: `where t:type` promises less than the class requires
# SameLoose(W:wrapper(t), Other:t where t:type)<computes><decides>:void =
#     W.Data = Other
```
<!-- #> -->

## Class Attributes

Classes can be annotated with attributes that modify their behavior,
visibility, and capabilities. These attributes apply to all classes,
not just parametric ones.

### Access Specifiers

Classes support fine-grained control over member visibility through
access specifiers:

<!--versetest-->
<!-- 063 -->
```verse
game_state := class:
    Score<public> : int = 0                    # Anyone can read
    var Lives<private> : int = 3               # Only this class can access
    var Shield<protected> : float = 100.0      # This class and subclasses
    DebugInfo<internal> : string = ""          # Same module only

    # Public method - anyone can call
    GetLives<public>() : int = Lives

    # Protected method - subclasses can override
    OnLifeLost<protected>() : void = {}

    # Private helper - only this class
    ValidateState<private>() : void = {}
```

Default visibility is `internal` (same module only).

### Concrete

The `<concrete>` specifier enforces that all fields have default
values, allowing construction with an empty archetype:

<!--versetest-->
<!-- 064 -->
```verse
config := class<concrete>:
    MaxPlayers : int = 8
    TimeLimit : float = 300.0
    FriendlyFire : logic = false

# Can construct with empty archetype
DefaultConfig := config{}
```

A concrete class C can be constructed with C{}. A concrete class may have
subclasses that are not concrete.

A `<concrete>` class must supply a value for every data member, including
members inherited from an interface. Re-declaring the member with `<override>`
does not satisfy the requirement — it still needs an initializer. This applies
to `var` members and to members of function type as well:

<!--versetest
assert_semantic_error(3519):
    has_field := interface { Field:int }
    thing := class<concrete>(has_field) {}

assert_semantic_error(3519):
    has_field2 := interface { Field:int }
    thing2 := class<concrete>(has_field2) { Field<override>:int }

assert_semantic_error(3519):
    has_var := interface { var Field:int }
    thing3 := class<concrete>(has_var) {}
<#
-->
<!-- 065 -->
```verse
has_field := interface:
    Field:int

# ERROR - Field has no value
# thing := class<concrete>(has_field) {}

# ERROR - re-declaring without a value does not help
# thing := class<concrete>(has_field) { Field<override>:int }

# OK
thing := class<concrete>(has_field):
    Field<override>:int = 0
```
<!-- #> -->

### Unique

The `<unique>` specifier creates classes and interfaces with reference
semantics where each instance has a distinct identity. When a class or
interface is marked as `<unique>`, instances become comparable using
the equality operators (= and <>), with equality based on object
identity rather than field values.

Classes marked with `<unique>` compare by identity, not by value:

<!--versetest-->
<!-- 066 -->
```verse
entity := class<unique>:
    Name : string
    Level : int

E1 := entity{Name := "Guard", Level := 3}
E2 := entity{Name := "Guard", Level := 3}
E3 := E1

E1 <> E2  # distinct instances, despite identical field values
E1 = E3   # the same instance
```

Without `<unique>`, class instances cannot be compared for equality at
all—the language prevents meaningless comparisons. With `<unique>`,
you gain the ability to use instances as map keys, store them in sets,
and perform identity checks, essential for tracking specific objects
throughout their lifetime.

#### Interfaces

Interfaces can also be marked with `<unique>`, which makes all
instances of classes implementing that interface comparable by
identity:

<!--versetest-->
<!-- 067 -->
```verse
component := interface<unique>:
    Update():void
    Render():void

physics_component := class(component):
    Update<override>():void = {}
    Render<override>():void = {}

# Instances are comparable because component is unique
P1 := physics_component{}
P2 := physics_component{}

P1 <> P2  # different instances
P1 = P1   # the same instance
```

The `<unique>` property propagates through interface inheritance. If a
parent interface is marked `<unique>`, all child interfaces and
classes implementing those interfaces automatically become comparable:

<!--versetest-->
<!-- 068 -->
```verse
base_component := interface<unique>:
    Update():void

# Child interface inherits <unique> from parent
advanced_component := interface(base_component):
    AdvancedUpdate():void

# Classes implementing any interface in the hierarchy become comparable
player_component := class(advanced_component):
    Update<override>():void = {}
    AdvancedUpdate<override>():void = {}

C1 := player_component{}
C2 := player_component{}
C1 <> C2  # comparable because base_component is unique
```

When a class implements multiple interfaces, comparability is
determined by whether ANY of the inherited interfaces is `<unique>`:

<!--versetest-->
<!-- 069 -->
```verse
updateable := interface:  # Not unique
    Update():void

renderable := interface<unique>:  # Unique
    Render():void

game_object := class(updateable, renderable):
    Update<override>():void = {}
    Render<override>():void = {}

# game_object is comparable because renderable is unique
G1 := game_object{}
G2 := game_object{}
G1 <> G2
```

Even if most interfaces are non-unique, a single `<unique>` interface
in the hierarchy makes the entire class comparable.

#### Unique in Default Values

When a `<unique>` class appears in a field's default value, each
containing object receives its own distinct instance. This guarantee
applies even when the unique class is nested within complex parametric
types:

<!--versetest-->
<!-- 070 -->
```verse
token := class<unique>:
    ID:int = 0

container := class:
    MyToken:token = token{}

C1 := container{}
C2 := container{}
C1.MyToken <> C2.MyToken  # each container gets its own token
```

This behavior extends to `<unique>` instances within arrays,
optionals, tuples, and maps:

<!--versetest-->
<!-- 071 -->
```verse
item := class<unique>{}

# Each class instantiation creates fresh unique instances in default values
with_array := class:
    Items:[]item = array{item{}}

with_optional := class:
    MaybeItem:?item = option{item{}}

with_map := class:
    ItemMap:[int]item = map{0 => item{}}

A := with_array{}
B := with_array{}
A.Items[0] <> B.Items[0]  # different unique instances

C := with_optional{}
D := with_optional{}
ItemC := C.MaybeItem?
ItemD := D.MaybeItem?
ItemC <> ItemD

E := with_map{}
F := with_map{}
E.ItemMap[0] <> F.ItemMap[0]
```

The same principle applies when parametric classes contain unique
instances in their fields:

<!--versetest-->
<!-- 072 -->
```verse
entity := class<unique>{}

registry(t:type) := class:
    DefaultEntity:entity = entity{}
    Data:t

R1 := registry(int){Data := 1}
R2 := registry(int){Data := 2}
R1.DefaultEntity <> R2.DefaultEntity

R3 := registry(string){Data := "hi"}
R3.DefaultEntity <> R1.DefaultEntity  # even across different type parameters
```

This guarantee ensures that identity-based operations remain
reliable. If you store objects in maps keyed by unique instances, or
maintain sets of unique objects, each container genuinely owns
distinct instances rather than sharing references. The language
prevents subtle bugs where multiple objects might unexpectedly share
the same identity.

#### Overload Resolution

Types marked with `<unique>` are subtypes of the built-in `comparable`
type. This can create overload ambiguity:

<!--versetest
# Valid: non-unique interface does not conflict with comparable
regular_interface := interface:
    Method():void

Process(A:comparable, B:comparable):void = {}
Process(A:regular_interface, B:regular_interface):void = {}  # OK - no conflict

# Invalid: unique interface conflicts with comparable
assert_semantic_error(3532):
    my_unique_interface := interface<unique>:
        Method():void

    Handle(A:comparable, B:comparable):void = {}
    Handle(A:my_unique_interface, B:my_unique_interface):void = {}  # ERROR - ambiguous!
<#
-->
<!-- 073 -->
```verse
# Valid: non-unique interface does not conflict with comparable
regular_interface := interface:
    Method():void

Process(A:comparable, B:comparable):void = {}
Process(A:regular_interface, B:regular_interface):void = {}  # OK - no conflict

# Invalid: unique interface conflicts with comparable
unique_interface := interface<unique>:
    Method():void

Handle(A:comparable, B:comparable):void = {}
# Handle(A:unique_interface, B:unique_interface):void = {}  # ERROR - ambiguous!
```
<!-- #>-->

Since `unique_interface` is a subtype of `comparable`, both overloads
could match when called with `unique_interface` arguments, causing a
compilation error. When designing overloaded functions, be aware that
`<unique>` types participate in the `comparable` type hierarchy.

#### Use Cases

The `<unique>` specifier suits anything whose identity matters more than its
current field values: game entities that must stay distinguishable as their
health and position change, session objects that outlive any particular
connection state, and resource handles that name one specific instance
rather than an equivalent value. What all of these have in common is that
they want to be map keys, and only a `<unique>` type can be one, because a
map key has to be `comparable`. The same applies to `<unique>` interfaces,
so a component registry can be keyed by an interface reference.

<!--versetest-->
<!-- 074 -->
```verse
vector3 := class<final>{X:float = 0.0; Y:float = 0.0; Z:float = 0.0}

# Each entity stays distinguishable however its state changes
entity := class<unique>:
    var Health:int = 100
    var Position:vector3 = vector3{}

# A unique type can be a map key
E1 := entity{}
E2 := entity{}
Sessions := map{E1 => "alice", E2 => "bob"}
Sessions[E2] = "bob"
```

The specifier is what provides identity-based equality, and with it the
ability to maintain sets of unique objects and to tell two instances apart
even when their data is identical.

### Abstract

The `<abstract>` specifier marks classes that cannot be instantiated
directly — they exist solely as base classes for inheritance. When you
declare a class with `<abstract>`, you are creating a template that
defines structure and behavior for subclasses to inherit and
implement.

Abstract classes serve as architectural foundations in a type
hierarchy. They define contracts through abstract methods that
subclasses must implement, while potentially providing concrete
methods and fields that subclasses inherit. This creates a powerful
pattern for code reuse and polymorphic behavior.

<!-- versetest-->
<!-- 075 -->
```verse
vehicle := class<abstract>:
      Speed():float             # Abstract method
      MaxPassengers:int = 1

      # Concrete method all vehicles share
      CanTransport(Count:int)<decides>:void =
          Count <= MaxPassengers

car := class(vehicle):
      Speed<override>():float = 60.0
      MaxPassengers<override>:int = 4

bicycle := class(vehicle):
      Speed<override>():float = 15.0
```

Abstract methods within abstract classes have no implementation —
they are pure declarations that establish what subclasses must
provide. An abstract method creates a contract: any non-abstract
subclass must override all abstract methods or the code will not compile.

### Castable

Verse supports runtime type checking for all classes and interfaces
through **fallible casts** and **infallible casts**. The `<castable>`
specifier serves a specific purpose: it enables the use of
`castable_subtype` constraints, which allow types to be used as
first-class values in type-constrained contexts.

All classes and interfaces support runtime type checking through
dynamic casts. You can cast between any class or interface types using the fallible cast
syntax `Type[Value]`:

<!--versetest-->
<!-- 076 -->
```verse
# No <castable> needed for basic dynamic casts
base := class:
    ID:int

derived := class(base):
    Name:string

# Fallible cast
ProcessBase(B:base):void =
    if (D := derived[B]):
        # Successfully cast to derived
        Print("Derived with name: {D.Name}")
    else:
        # Not a derived instance
        Print("Just a base")
```

#### When Do You Need `<castable>`

The `<castable>` specifier is required only when you want to use
`castable_subtype` constraints. These constraints enable powerful
patterns where types are used as first-class values, such as accepting
a type as a parameter and using it to perform casts:

<!--versetest
component := class<castable>{}
physics_component := class<castable>(component){}
render_component := class<castable>(component){}
ProcessSpecific(:component):void = {}
-->
<!-- 077 -->
```verse
# Requires <castable> for castable_subtype constraint
FilterByType(
    Items:[]component,
    TargetType:castable_subtype(component)  # Type as parameter
):[]component =
    for:
        Item : Items
        Specific := TargetType[Item]  # Use type variable for cast
    do:
        Specific

# Can pass different types at runtime
AllComponents:[]component = array{physics_component{}, render_component{}}
PhysicsOnly := FilterByType(AllComponents, physics_component)
PhysicsOnly.Length = 1
```

#### Fallible and Infallible Casts

Verse provides two forms of type casting: **fallible casts** (which
can fail at runtime) and **infallible casts** (which are verified at
compile time).

Fallible casts use bracket syntax `Type[Value]` are runtime checks that succeed only if the
value is actually an instance of the target type:

<!-- versetest
vector3:=class<final>{ X:float=0.0; Y:float=0.0; Z:float=0.0 }
ToString(:vector3):string=""
-->
<!-- 078 -->
```verse
# Classes with <castable> - enables castable_subtype usage
component := class<abstract><castable><allocates>:
    Name:string

physics_component := class<allocates>(component):
    Name<override>:string = "Physics"
    Velocity:vector3

render_component := class<allocates>(component):
    Name<override>:string = "Render"
    Material:string

# Fallible casts work whether or not <castable> is present
ProcessComponent(Comp:component):void =
    if (PhysicsComp := physics_component[Comp]):
        Print("Physics component with velocity: {PhysicsComp.Velocity}")
    else if (RenderComp := render_component[Comp]):
        Print("Render component with material: {RenderComp.Material}")
    else:
        Print("Unknown component type")
```

The cast expression has the `<decides>` effect—it fails if the object
is not an instance of the target type. This integrates naturally with
Verse's failure handling:

<!--versetest
vector3:=class<final><allocates>{ X:float=0.0; Y:float=0.0; Z:float=0.0 }
component := class<abstract><castable><allocates>:
    Name:string

physics_component := class<allocates>(component):
    Name<override>:string = "Physics"
    Velocity:vector3=vector3{}

SomeComponent:component=physics_component{}
UpdatePhysics(:physics_component)<computes>:void={}
-->
<!-- 079 -->
```verse
GetPhysicsComponent(Comp:component)<computes><decides>:physics_component =
    # Returns physics_component or fails
    physics_component[Comp]

# Use with failure handling
if (Physics := GetPhysicsComponent[SomeComponent]):
    UpdatePhysics(Physics)
```

Infallible casts use parenthesis syntax `Type(Value)` and are only
allowed when the compiler can verify the cast is safe—that is, when the
value type is a subtype of the target type. Attempting an infallible
downcast, from supertype to subtype, is a compile error, because the compiler
cannot guarantee it would succeed:

<!--versetest
assert_semantic_error(3509):
    p_base := class:
        ID:int
    p_derived := class(p_base):
        Name:string
    Bad(B:p_base):p_derived = p_derived(B)
-->
<!-- 080 -->
```verse
base := class:
    ID:int

derived := class(base):
    Name:string

GetDerived():derived = derived{ID := 1, Name := "Test"}

# Infallible upcast - derived is a subtype of base
BaseRef:base = base(GetDerived())  # Always safe
BaseRef.ID = 1

# ERROR: not a subtype relationship
# DerivedRef := derived(BaseRef)
```


#### Castable and Inheritance

The `<castable>` property is inherited by all subclasses. When you
mark a class as `<castable>`, every class that inherits from it
automatically becomes castable as well:

<!--versetest-->
<!-- 081 -->
```verse
base := class<castable>:
    Value:int

child := class(base):
    # Automatically castable - inherits from castable base
    Name:string

grandchild := class(child):
    # Also automatically castable
    Extra:string

# Can cast through the hierarchy
ProcessBase(Instance:base):void =
    if (AsChild := child[Instance]):
        Print("It's a child: {AsChild.Name}")
    if (AsGrandchild := grandchild[Instance]):
        Print("It's a grandchild: {AsGrandchild.Extra}")
```

#### Parametric Types and Casting

Parametric types cannot be marked `<castable>`. Verse erases type
parameters at runtime—only the concrete class structure exists, not the
specific type arguments. The runtime cannot distinguish between
`container(int)` and `container(string)`, which would make
`castable_subtype` constraints unsound.

Additionally, you cannot cast to a parametric type even if it is not
marked `<castable>`. Attempting to use a parametric type as a cast
target produces a compile error:

<!--versetest
assert_semantic_error(3678):
    container(t:type) := class<castable>:
        Value:t

assert_semantic_error(3502):
    container(t:type) := class:
        Value:t
    Test()<decides>:void =
        C := container(int){Value := 42}
        if (C2 := container(string)[C]) {}
<#
-->
<!-- 082 -->
```verse
# Invalid: parametric classes cannot be castable
# container(t:type) := class<castable>:  # ERROR
#     Value:t

# Invalid: cannot cast to parametric type
container(t:type) := class:
    Value:t

Test()<decides>:void =
    C := container(int){Value := 42}
    if (C2 := container(string)[C]) {}  # ERROR
```
<!-- #> -->

However, concrete instantiations of parametric types can be cast
targets, and non-parametric classes can be marked `<castable>` even
if they inherit from parametric types:

<!--versetest-->
<!-- 083 -->
```verse
container(t:type) := class:
    Value:t

# Valid: concrete instantiations can be cast targets
int_container := class<castable>(container(int)):
    Extra:string

string_container := class<castable>(container(string)):
    Extra:string

# Can cast to a concrete instantiation
Base:container(int) = int_container{Value := 42, Extra := "test"}
IC := int_container[Base]
IC.Extra = "test"

# Cannot cast between different instantiations
not string_container[Base]
```

#### Using castable_subtype

The `castable_subtype` type constructor works with `<castable>`
classes to enable type-safe filtered queries and dynamic type
dispatch:

<!--versetest-->
<!-- 084 -->
```verse
entity := class<abstract><unique><castable>:
    # The type argument doubles as the element type of the result
    FindDescendantEntities(entity_type:castable_subtype(entity)):[]entity_type
```

When you call `FindDescendantEntities(player)`, the function returns
only entities that are actually player instances or subclasses
thereof, verified at runtime through the castable mechanism. The type
parameter ensures type safety—the returned values have the specific
subtype you requested.

#### Permanence of Castable

Once a class is published with `<castable>`, this decision becomes
permanent. You cannot add or remove the `<castable>` specifier after
publication because doing so would break existing code that relies on
runtime type checking. Code that performs casts would suddenly fail or
behave incorrectly if the castable property changed.

This permanence is enforced through the versioning system—attempting
to change the `<castable>` status of a published class will result in
a compatibility error.

### Final

The `<final>` specifier prevents inheritance, creating a terminal
point in a class hierarchy. When you mark a class with `<final>`, no
other class can inherit from it. For methods, `<final>` prevents
overriding in subclasses, locking the implementation at that level of
the hierarchy.

Classes marked with `<final>` serve as concrete implementations that
cannot be extended. This is particularly important for persistable
classes, which require `<final>` to ensure their structure remains
stable for serialization:

<!--versetest-->
<!-- 085 -->
```verse
player_stats := struct<persistable>{}

player_profile := class<final><persistable>:
    Username:string = "Player"
    Level:int = 1
    Gold:int = 0

player_data := class<final><persistable>:
    Version:int = 1
    LastLogin:string = ""
    Statistics:player_stats = player_stats{}
```

The `<final>` requirement for persistable classes prevents schema
evolution problems. If subclasses could extend persistable classes,
the serialization system would face ambiguity about which fields to
persist and how to handle polymorphic deserialization.

For methods, `<final>` locks behavior at a specific point in the
inheritance chain:

<!--versetest
assert_semantic_error(3568):
    be2 := class:
        GetName():string = "Entity"
    go2 := class(be2):
        GetName<override><final>():string = "GameObject"
    sub2 := class(go2):
        GetName<override>():string = "Sub"
-->
<!-- 086 -->
```verse
base_entity := class:
    GetName():string = "Entity"

game_object := class(base_entity):
    GetName<override><final>():string = "GameObject"

# ERROR: a subclass of game_object cannot override GetName
# sub_object := class(game_object):
#     GetName<override>():string = "Sub"
```

For fields, `<final>` prevents modification through archetype
construction. When a field is marked `<final>` and has a default value,
that value is locked and cannot be changed when creating instances:

<!--versetest
assert_semantic_error(3568):
    foo2 := class<computes>:
        Val<final>:int = 0
        X:int = 5
    G2():void =
        InvalidFoo := foo2{Val := 10}
-->
<!-- 087 -->
```verse
foo := class<computes>:
    Val<final>:int = 0
    X:int = 5

# Valid: X can be changed during construction
ValidFoo := foo{X := 10}

# COMPILE ERROR: Cannot override final field Val
# InvalidFoo := foo{Val := 10}
```

This restriction ensures that final fields maintain their guaranteed
values throughout the object's lifetime. Final fields with default
values act as immutable constants for each instance. If you need a
field to be customizable during construction, do not mark it as
`<final>`. Final fields must also provide a default value — you cannot
declare a final field without initializing it.

#### Final on Interface Members

While `<final>` cannot be applied to interface or struct *types*
themselves, it can be used on interface *members* to prevent overriding
in implementing classes. Final interface members must provide a complete
implementation (body for methods, value for fields):

<!--versetest
assert_semantic_error(3568):
    base_behavior2 := interface:
        GetID<final>():int = 42
        MaxCount<final>:int = 100
        Process():void
    concrete_impl2 := class(base_behavior2):
        Process<override>():void = {}
        GetID<override>():int = 99
-->
<!-- 088 -->
```verse
base_behavior := interface:
    # Final method with default implementation
    GetID<final>():int = 42

    # Final field with default value
    MaxCount<final>:int = 100

    # Non-final method - can be overridden
    Process():void

concrete_impl := class(base_behavior):
    # Can implement Process
    Process<override>():void = {}

    # Cannot override GetID or MaxCount - they are final
    # GetID<override>():int = 99  # ERROR
```

Final members in interfaces propagate through interface inheritance.
When an interface extends another interface with final members, those
members remain final and cannot be overridden by any implementing
classes:

<!--versetest
assert_semantic_error(3568):
    b3 := interface:
        GetVersion<final>():int = 1
    d3 := interface(b3):
        GetName():string
    impl3 := class(d3):
        GetName<override>():string = "Implementation"
        GetVersion<override>():int = 2

assert_semantic_error(3596):
    final_ifc := interface<final>:
        F():int = 1
-->
<!-- 089 -->
```verse
base := interface:
    GetVersion<final>():int = 1

derived := interface(base):
    GetName():string

impl := class(derived):
    # Must implement GetName
    GetName<override>():string = "Implementation"

    # GetVersion remains final from base
    # GetVersion<override>():int = 2  # ERROR
```

Applying `<final>` to an interface or struct *type* rather than to one of
its members is an error; only the members may be final.

The related `<final_super>` specifier does **not** prevent further
subclassing. Instead, it guarantees that all subclasses of this class
will always directly inherit from it — there will be no intermediate
classes inserted between the `<final_super>` class and its
descendants in the inheritance chain. Subclasses can themselves be
further subclassed:

<!--versetest-->
<!-- 090 -->
```verse
entity := class{}

component := class<abstract><unique><castable><final_super_base>:
    Parent:entity

physics_component := class<final_super>(component):
    Mass:float = 1.0

# Valid: further subclassing is allowed
gravity_component := class(physics_component):
    GravityScale:float = 1.0
```

`<final_super_base>` marks the root of a restricted inheritance tree.
Its purpose is to work with `GetCastableFinalSuperClass`, which
finds the `<final_super>` class in the hierarchy for a given
instance. This enables component architectures where you need to
identify the "category" of a component at runtime:

<!-- 091 -->
```verse
#            base_type<castable>
#               /         \
#  a_class<final_super>   w_class
#         |                  |
#      b_class            x_class<final_super>
#         |                  |
#      c_class            y_class

# GetCastableFinalSuperClass[base_type, c_class{}]
# returns a_class — the <final_super> ancestor under base_type
```

This design is particularly valuable in component architectures
where you need a stable "category" class in the hierarchy that
runtime systems can rely on, while still allowing further
specialization below it.

### Persistable

The `<persistable>` specifier marks types that can be saved and
restored across game sessions, enabling permanent storage of player
progress, achievements, and game state. This specifier transforms
ephemeral gameplay into lasting progression, creating the foundation
for meaningful player investment.

Persistence works through module-scoped `weak_map(player, t)`
variables, where `t` is any persistable type.  These special maps
automatically synchronize with backend storage — when players join,
their data loads; when they leave or data changes, it saves. The
system handles all serialization, network transfer, and storage
management transparently.

<!--versetest
player := string

assert_semantic_error(3663):
    not_final := class<persistable>:
        Gold:int = 0

assert_semantic_error(3664):
    is_unique := class<final><persistable><unique>:
        Gold:int = 0

assert_semantic_error(3662):
    has_var := class<final><persistable>:
        var Gold:int = 0
-->
<!-- 092 -->
```verse
player_inventory := class<final><persistable>:
    Gold:int = 0
    Items:[]string = array{}
    UnlockedAreas:[]string = array{}

# This variable automatically persists across sessions
SavedInventories : weak_map(player, player_inventory) = map{}
```

The `<persistable>` specifier enforces strict structural requirements
to guarantee data integrity across versions. Classes must be `<final>`,
because inheritance would complicate serialization schemas. They cannot be
`<unique>`, since identity-based equality does not survive serialization, and
asking for both is rejected as well. Every data member must itself be
persistable, which rules out `var` fields — a mutable member is reported as
non-persistable, so immutability survives into storage. These constraints
ensure that what you save today can be reliably loaded tomorrow, next month,
or next year.

## Interfaces

Interfaces define contracts that classes can implement, specifying
both the data and behavior that implementing classes must
provide. Unlike many traditional languages where interfaces only
declare method signatures, Verse interfaces are rich contracts that
can include fields, default method implementations, and even custom
accessor logic.

An interface can declare method signatures, provide default
implementations, and define data members:

<!--versetest-->
<!-- 093 -->
```verse
damageable := interface:
    # Abstract method - implementing classes must provide
    TakeDamage(Amount:int)<transacts>:void

    # Method with default implementation
    GetHealth()<reads>:int = 100

    # Data member - implementing classes inherit or must provide
    MaxHealth:int = 100

    IsAlive()<reads>:logic = logic{GetHealth() > 0}

healable := interface:
    Heal(Amount:int)<transacts>:void
```

Interfaces can be purely abstract, partially concrete, or fully
implemented. A class implementing an interface must provide implementations
for its abstract methods; it inherits concrete implementations and default
field values.

### Implementing Interfaces

<!--versetest
damageable := interface:
    TakeDamage(Amount:int)<transacts>:void
    GetHealth()<reads>:int = 100
    MaxHealth:int = 100
    IsAlive()<reads>:logic = logic{GetHealth() > 0}

healable := interface:
    Heal(Amount:int)<transacts>:void
-->
<!-- 094 -->
```verse
character := class(damageable, healable):
    var Health : int = 100

    TakeDamage<override>(Amount:int)<transacts>:void =
        set Health = Max(0, Health - Amount)

    # MaxHealth and IsAlive are inherited unchanged
    GetHealth<override>()<reads>:int = Health

    Heal<override>(Amount:int)<transacts>:void =
        set Health = Min(MaxHealth, Health + Amount)

Hero := character{}
Hero.TakeDamage(30)
Hero.GetHealth() = 70
Hero.IsAlive() = true
Hero.Heal(100)
Hero.GetHealth() = 100
```

A class can implement multiple interfaces, achieving multiple
inheritance of contracts.

### Interface Fields

Interfaces can declare data members that implementing classes must provide
or inherit. These fields can be either immutable or mutable, and may include
default values:

<!--versetest-->
<!-- 095 -->
```verse
# Interface with various field types
entity_properties := interface:
    # Immutable field with default - classes inherit this value
    EntityID:int = 0

    # Mutable field with default
    var Health:float = 100.0

    # Field without default - classes must provide a value
    Name:string

    # Field that can be overridden
    MaxHealth:float = 100.0

player_entity := class(entity_properties):
    # Must provide Name (no default in interface)
    Name<override>:string = "Player"

    # Can override to change default
    MaxHealth<override>:float = 150.0

    # Inherits EntityID and Health with their defaults
```

Fields with defaults are inherited unless overridden. Fields without
defaults must be provided.

### Default Implementations

Interfaces can provide complete method implementations that
implementing classes inherit automatically:

<!--versetest-->
<!-- 096 -->
```verse
animated := interface:
    var CurrentFrame:int = 0
    TotalFrames:int = 10

    # Concrete implementation provided by interface
    NextFrame()<transacts><decides>:void =
        set CurrentFrame = Mod[(CurrentFrame + 1),TotalFrames] or 0

    # Can access interface fields
    ProgressPercent()<reads><decides>:rational =
        CurrentFrame / TotalFrames

sprite := class(animated):
    TotalFrames<override>:int = 20
    # Automatically inherits NextFrame and ProgressPercent implementations
```

Classes inherit these implementations without modification, allowing
interfaces to provide reusable behavior. Implementing classes can
override these methods if they need specialized behavior, but the
interface provides a working default.

### Overriding Members

Classes can override both fields and methods from interfaces to
provide specialized implementations:

<!--versetest-->
<!-- 097 -->
```verse
base_stats := interface:
    BaseHealth:int = 100

    CalculateFinalHealth():int = BaseHealth

warrior := class(base_stats):
    # Override field with different default
    BaseHealth<override>:int = 150

    # Override method for specialized calculation
    CalculateFinalHealth<override>():int =
        BaseHealth * 2  # Warriors get double health

mage := class(base_stats):
    BaseHealth<override>:int = 75

    CalculateFinalHealth<override>():int =
        BaseHealth + MagicBonus

    MagicBonus:int = 25
```

Field overrides can provide different default values or specialize to
subtypes. Method overrides replace the interface's implementation
entirely. All overrides must maintain type compatibility—fields can
only be overridden with subtypes, and method signatures must match
exactly.

### Multiple Interfaces with Sharing

Verse interfaces are more permissive than in many other languages —
they can declare data fields, provide concrete method implementations,
and a class can implement multiple interfaces even when they share
member names. This design avoids the friction of requiring globally
unique names across all interfaces. In practice, independent interface
authors may naturally use the same names (`Enable`, `Disable`,
`Power`, `Update`), and requiring every interface to use distinct
names would create artificial naming conflicts that scale poorly —
especially when interfaces form deep hierarchies with subinterfaces
for specialized variants.

When a class implements multiple interfaces that declare fields or
methods with the same name, you use qualified names to
disambiguate:

<!--versetest-->
<!-- 098 -->
```verse
magical := interface:
    Power:int = 50
    GetPowerLevel()<computes>:int = Power

physical := interface:
    Power:int = 75
    GetPowerLevel()<computes>:int = Power * 2

hybrid := class(magical, physical):
    MagicPower()<computes>:int = (magical:)Power             # magical's Power
    PhysicalPower()<computes>:int = (physical:)Power         # physical's Power
    MagicLevel()<computes>:int = (magical:)GetPowerLevel()
    PhysicalLevel()<computes>:int = (physical:)GetPowerLevel()

H := hybrid{}
H.MagicPower() = 50 and H.PhysicalPower() = 75
H.MagicLevel() = 50 and H.PhysicalLevel() = 150
```

The qualified name syntax `(InterfaceName:)MemberName` specifies which
interface's member you are accessing. Each interface maintains its own
instance of the field, allowing the class to support both contracts
simultaneously without conflict.

### Interface Hierarchies

Interfaces can extend other interfaces, creating hierarchies of
contracts that combine data and behavior requirements:

<!--versetest
damageable := interface:
    TakeDamage(Amount:int)<transacts>:void

healable := interface:
    Heal(Amount:int)<transacts>:void

assert_semantic_error(3592):
    dup_ifc := interface:
        F():int = 1
    dup_class := class(dup_ifc, dup_ifc):
        G():int = 2
-->
<!-- 099 -->
```verse
combatant := interface(damageable, healable):
    var AttackPower:int = 10

    Attack(Target:damageable):void =
        Target.TakeDamage(AttackPower)

    GetAttackPower():int = AttackPower

boss := interface(combatant):
    Phase:int = 1

    UseSpecialAbility():void
    GetPhase():int = Phase
```

A class implementing `boss` inherits all fields and methods from the
entire hierarchy—`boss`, `combatant`, `damageable`, and
`healable`. Diamond inheritance (where an interface is inherited
through multiple paths) is fully supported, with fields properly
merged so each field exists only once in the implementing class.

A class cannot name the same interface twice in its own inheritance list,
however: `class(interface1, interface1)` is a redundant
inheritance. Inheriting the interface indirectly, through diamond
inheritance, is fine, so `class(interface2, interface3)` is valid even when
both `interface2` and `interface3` inherit from the same base interface.

### Fields with Accessors

Interfaces can define fields with custom getter and setter logic,
encapsulating complex behavior behind simple field access syntax:

<!--versetest-->
<!-- 100 -->
```verse
subscribable_property := interface:
    # External field with accessor methods
    var Value<getter(GetValue)><setter(SetValue)>:int = external{}

    # Internal storage
    var Storage:int = 100

    # Getter adds computation
    GetValue(:accessor):int = Storage + 10

    # Setter adds validation
    SetValue(:accessor, NewValue:int):void =
        if (NewValue >= 0):
            set Storage = NewValue

tracked_value := class(subscribable_property){}

Object := tracked_value{}

# Uses the getter: Storage + 10
Object.Value = 110

# Uses the setter, which validates and writes Storage
set Object.Value = 150
Object.Value = 160
```

The `external{}` keyword indicates the field has no direct storage—all
access goes through the accessor methods. This pattern is powerful for
implementing property change notifications, validation, computed
properties, and other scenarios requiring logic around field access.

One restriction comes with it: a field with accessors declared in an
interface cannot be overridden in an implementing class. The accessor
implementation is fixed by the interface.
