# The Verse Programming Language

## Overview

Verse is a multi-paradigm programming language developed by Epic Games for creating gameplay in Unreal Editor for Fortnite and building experiences in the metaverse. Drawing from functional, logic, and imperative traditions, Verse represents a departure from traditional programming languages, designed for long-term evolution and stability.

Verse is built on three fundamental principles:

- **It's Just Code**:
Complex concepts that might require special syntax or constructs in other languages are expressed as regular Verse code. There's no magic—everything is built from the same primitive constructs, creating a uniform and predictable programming model.

- **Just One Language**:
The same language constructs work at both compile-time and run-time. There is no preprocessor. What you write is what executes, whether during compilation or at runtime.

- **Metaverse First**:
Verse is designed for a future where code runs in a single global simulation—the metaverse. This influences every aspect of the language, from its strong compatibility guarantees to its effect system that tracks side effects and ensures safe concurrent execution.

Verse aims to be:

- **Simple enough** for first-time programmers to learn, with consistent rules and minimal special cases.

- **Expressive enough** for sophisticated game logic and distributed systems, with advanced features that scale to large codebases.

- **Safe enough** for untrusted code to run in a shared environment, with strong sandboxing and effect tracking.

- **Fast enough** for real-time games and simulations, with an implementation that can optimize pure computations aggressively.

- **Stable enough** to last for decades, with strong backward compatibility guarantees and careful evolution.

#### Why Verse?

Traditional programming languages carry decades of historical baggage and design compromises. Verse starts fresh, learning from the past but not being bound by it. It's designed for a future where:

- Code lives forever in a persistent metaverse
- Millions of developers contribute to a shared codebase
- Programs must be safe, concurrent, and composable by default
- Backward compatibility is not optional but essential
- The boundary between compile-time and runtime is fluid

Ready to dive in? Start with [Built-in Types](02_primitives.md) to understand Verse's fundamental data types, or jump to [Expressions](01_expressions.md) to see how everything in Verse computes values.

For experienced programmers coming from other languages, the [Failure System](08_failure.md) and [Effects](13_effects.md) sections highlight some of Verse's distinctive features.

## Key Features

#### Everything is an Expression

In Verse, there are no statements—everything is an expression that produces a value. This creates a composable system where any piece of code can be used anywhere a value is expected.

<!-- 01 -->
```verse
Scores := array{10, 20, 30}

# Even control flow produces a value
Verdict := if (Scores.Length > 2) then "long" else "short"
Verdict = "long"

# So does a loop
Doubled := for (Score : Scores) { Score * 2 }
Doubled = array{20, 40, 60}
```

#### Failure as Control Flow

Instead of boolean conditions and exceptions, Verse uses failure as a primary control flow mechanism. Expressions can succeed (producing a value) or fail (producing no value), enabling natural control flow patterns:

<!-- 02 -->
```verse
ValidateName(N:string)<computes><decides>:void = N.Length > 0
Greet(N:string):void = Print("Hello, {N}")

Welcome(Name:string):void =
    if (ValidateName[Name]):  # Square brackets: this call may fail
        Greet(Name)           # Parentheses: this call must succeed
```

The [Failure](08_failure.md) chapter covers failable expressions and failure contexts in depth, and [Control Flow](07_control.md) explains if expressions.

#### Strong Static Typing with Inference

Verse features a powerful type system that catches errors at compile time while minimizing the need for type annotations through inference. See [Types](11_types.md) for more on the type system and subtyping.

<!-- 03 -->
```verse
Level := 42                     # int, inferred from the literal
Names := array{"Ada", "Alan"}   # []string, inferred from the elements
```

#### Effect Tracking

Functions declare their side effects through specifiers like `<computes>`, `<reads>`, `<writes>`, `<transacts>`, `<decides>`, and `<suspends>`. These effect specifiers make it immediately clear what a function can do beyond computing its return value:

<!-- 04 -->
```verse
scoreboard := class:
    var Score:int = 0

    BonusFor(Streak:int)<computes>:int = Streak * 100  # No side effects
    CurrentScore()<reads>:int = Score                  # Can read mutable state
    AddPoints(N:int)<transacts>:void = set Score += N  # Can read, write, allocate
```

The [Effects](13_effects.md) chapter provides complete details on the effect system.

#### Built-in Concurrency

Concurrency is a first-class feature with structured concurrency primitives that make concurrent programming safe and predictable.

<!--versetest
LoadTerrain()<suspends>:void = {}
LoadTextures()<suspends>:void = {}
ReadFromCache()<suspends>:void = {}
FetchFromServer()<suspends>:void = {}
-->
<!-- 05 -->
```verse
StartLevel()<suspends>:void =
    # Run both and wait for the slower one to finish
    sync:
        LoadTerrain()
        LoadTextures()

    # Run both and keep whichever finishes first
    race:
        ReadFromCache()
        FetchFromServer()
```

#### Speculative Execution

Verse can speculatively execute code and roll back changes if the execution fails, enabling flexible patterns for validation and error handling.

<!-- 06 -->
```verse
wallet := class:
    var Gold:int = 100

    # Deducts the price, then fails if that overdrew the account
    Buy(Price:int)<transacts><decides>:void =
        set Gold -= Price
        Gold >= 0

Purse := wallet{}
not Purse.Buy[150]  # Too expensive, so the whole call fails...
Purse.Gold = 100    # ...and the deduction it had already made is rolled back
Purse.Buy[30]
Purse.Gold = 70
```

#### Reactive Programming with Live Variables

Verse provides first-class support for reactive programming through live variables that automatically recompute when their dependencies change, reducing the need for manual event handling.

<!--versetest
Log(:string)<transacts>:void={}
-->
<!-- 07 -->
```verse
var MaxHealth:int = 100
var Damage:int = 0
var live Health:int = MaxHealth - Damage

# Reactive constructs for event handling
when(Health < 25):
    Log("Low health warning!")

# Health recomputes whenever a variable it reads changes
set Damage = 20
Health = 80
set MaxHealth = 150
Health = 130
```

Verse provides a foundation for building interactive experiences in persistent virtual environments.

## An Example

The following example demonstrates key language features by building an inventory management system for a game, showing how Verse's constructs create robust, maintainable code.

<!-- 08 -->
```verse
# An enumeration: type-safe constants, no boilerplate
item_rarity := enum<persistable>:
    common
    rare
    legendary

# A struct: immutable value data, saved and restored with the player's profile
item_stats := struct<persistable>:
    Weight:float = 1.0
    Value:int = 0

game_item := class<final><persistable>:
    Name:string
    Rarity:item_rarity = item_rarity.common
    Stats:item_stats = item_stats{}

    # <decides> marks a function that may fail instead of returning
    GetRarityMultiplier()<computes><decides>:float =
        case(Rarity):
            item_rarity.common => 1.0
            item_rarity.rare => 2.0
            _ => {false?; 0.0}  # Fails on a rarity we have not priced

    GetEffectiveValue()<reads><decides>:int =
        Floor[Stats.Value * GetRarityMultiplier[]]

inventory_system := class:
    var Items:[]game_item = array{}
    var Gold:int = 1000
    MaxWeight:float = 20.0

    GetTotalWeight()<transacts>:float =
        var Total:float = 0.0
        for (Item : Items):
            set Total += Item.Stats.Weight
        Total

    AddItem(NewItem:game_item)<transacts><decides>:void =
        NewWeight := GetTotalWeight() + NewItem.Stats.Weight
        NewWeight <= MaxWeight  # A plain fact: if it is false, nothing below runs
        set Items += array{NewItem}

    # Any failure below rolls back the gold as well as the item
    PurchaseItem(ShopItem:game_item)<transacts><decides>:void =
        Price := ShopItem.GetEffectiveValue[]
        Price <= Gold
        set Gold -= Price
        AddItem[ShopItem]

    RemoveItem(ItemName:string)<transacts><decides>:game_item =
        var Found:?game_item = false
        var Rest:[]game_item = array{}
        for (Item : Items):
            if (Item.Name = ItemName, not Found?):
                set Found = option{Item}
            else:
                set Rest += array{Item}
        set Items = Rest
        Found?  # Fails if no item had that name

    FilterItems(Predicate:type{_(:game_item)<computes><decides>:void})<reads>:[]game_item =
        for (Item : Items, Predicate[Item]):
            Item

Bag := inventory_system{}
Sword := game_item{Name := "Rusty Sword", Stats := item_stats{Weight := 5.0, Value := 50}}
Crown := game_item{Name := "Golden Crown", Rarity := item_rarity.rare, Stats := item_stats{Weight := 90.0, Value := 300}}

Bag.PurchaseItem[Sword]
Bag.Gold = 950

# The crown is affordable but too heavy, so its price is refunded too
not Bag.PurchaseItem[Crown]
Bag.Gold = 950

IsRareOrLegendary(I:game_item)<computes><decides>:void =
    I.Rarity = item_rarity.rare or I.Rarity = item_rarity.legendary

Bag.FilterItems(IsRareOrLegendary).Length = 0
Bag.RemoveItem["Rusty Sword"].Name = "Rusty Sword"
Bag.Items.Length = 0
```

Several things in this example are specific to Verse.

Data modeling comes first, and it leans on Verse's rich type system. Types flow naturally through the code; many type annotations are omitted as they can be inferred. When we do specify types, like `Items:[]game_item`, they document intent rather than just satisfy the compiler. The `item_rarity` enum provides type-safe constants without the boilerplate of traditional enumerations. The `item_stats` struct marked as `<persistable>` can be saved and loaded from persistent storage, essential for game saves. The `game_item` class is marked `<final>` and `<persistable>` so its instances can be saved and restored; because persistable data is serialized by value, such classes cannot also be `<unique>`.

Failure, rather than exceptions or error codes, is what drives control flow throughout the code. The `<decides>` effect marks functions that can fail, and failure propagates naturally through expressions. When `GetRarityMultiplier()` encounters an unknown rarity, it does not throw an exception or return a sentinel value - it simply fails, and the calling code handles this gracefully.
The `AddItem` method demonstrates how failure creates declarative validation. The expression `NewWeight <= MaxWeight` either succeeds (allowing execution to continue) or fails (preventing the item from being added). There's no explicit control flow - just a declarative assertion of what must be true.

Transactional semantics and speculative execution fall out of that same mechanism. Methods marked with `<transacts>` provide automatic rollback on failure. In `PurchaseItem`, we deduct gold from the player, then try to add the item. If adding fails (as it does for the crown, which is too heavy to carry), the gold deduction is automatically rolled back, and the assertion that follows the failed purchase checks that the gold really did come back. This eliminates entire categories of bugs related to partial state updates.
This transactional behavior extends to complex operations. When multiple changes need to succeed or fail together, Verse ensures consistency without need for manual clean up.

Functions are first-class values, which the example uses twice. The `FilterItems` method accepts a predicate function, demonstrating higher-order programming. The locally defined `IsRareOrLegendary` shows how functions can be written right where they are needed and passed around like any other value. This functional programming style combines naturally with the imperative and object-oriented features.

Optional types and query operators are how Verse describes a value that may not be there. The inventory removal logic uses optional types (`?game_item`) to represent values that might not exist. The query operator `?` extracts values from options, failing if the option is empty. This eliminates null pointer exceptions while providing convenient syntax for handling absent values.

Pattern matching is another place where control flow produces a value. The `case` expression in `GetRarityMultiplier` demonstrates pattern matching. Unlike a switch statement, `case` is an expression that produces a value. The underscore `_` provides a catch-all pattern, though in this example it leads to failure.
The `if` expression similarly produces values and can bind variables in its condition. The compound conditions show how multiple operations can be chained with automatic failure propagation.

The module system and its access control surround all of this. A Verse file normally begins with `using` statements that import functionality from other modules; this example draws only on the built-in types, so it needs none of its own. The path-based module system ensures that dependencies are unambiguous and permanently addressable. Access specifiers like `<public>` control visibility at a fine-grained level.

Data is immutable by default. Data structures are immutable unless explicitly marked with `var`, which is why `MaxWeight` is fixed for the life of an inventory while `Gold` and `Items` can change. This eliminates large classes of bugs and makes concurrent programming safer. When we do need mutation, it is explicit and tracked by the effect system. See [Mutability](05_mutability.md) for complete details on `var` and `set`.

## Naming Conventions

Verse has a set of naming conventions that make code readable and predictable. While the language does not enforce these conventions, following them ensures your code integrates well with the broader Verse ecosystem and is immediately familiar to other Verse developers.

Identifiers should be in PascalCase (CamelCase starting with uppercase), while the names of types are written in snake_case:

<!-- 09 -->
```verse
# Variables, constants, functions, fields and methods use PascalCase
MaxInventorySize:int = 50
CalculateDamage(Base:float, Multiplier:float):float = Base * Multiplier

# Classes, structs, enums and their enumerators use snake_case
inventory_item := struct:
    ItemId:int
    Quantity:int

game_state := enum:
    main_menu
    in_game
    game_over
```

Generic type parameters use single lowercase letters or short descriptive names:

<!--versetest-->
<!-- 10 -->
```verse
Find(Array:[]t, Target:t where t:type):?int = false

Transform(Input:in_t, Processor:type{_(:in_t):out_t} where in_t:type, out_t:type):?out_t = false
```

Module names always use PascalCase, and so does every segment of a module path, so the modules you define yourself follow the same rule as the ones you import with `using { /Fortnite.com/Characters }` or `using { /Verse.org/Random }`:

<!-- 11 -->
```verse
InventorySystem := module:
    MaxStackSize:int = 64
```

Class and struct fields use PascalCase, and methods follow the same PascalCase convention as functions.

## Code Formatting

Verse code follows consistent formatting patterns to emphasize readability. Use four spaces to indent code blocks, as every example in this chapter does. The colon at the end of a line introduces a block, and the lines indented beneath it are the contents of that block, whether it is the body of an `if`, a `for`, a class, or a function.

Complex expressions benefit from clear formatting that shows structure:

<!--versetest
player_type := struct{Health:int = 75}
BaseDamage:float = 100.0
LevelMultiplier:float = 1.5
BonusPercentage:float = 10.0
-->
<!-- 12 -->
```verse
Player:player_type = player_type{}

# Multi-line conditionals
Condition := if (Player.Health > 50):
    "healthy"
else if (Player.Health > 20):
    "injured"
else:
    "critical"
Condition = "healthy"

# Chained operations with clear precedence
FinalDamage :=
    BaseDamage *
    LevelMultiplier *
    (1.0 + BonusPercentage / 100.0)
```

Functions follow a consistent pattern with effects and return types clearly specified:

<!--versetest
difficulty_level := enum{easy; medium; hard}
ValidateAmount(Amount:int)<transacts><decides>:void = {}
DeductBalance(Amount:int)<transacts>:void = {}
RecordTransaction()<transacts>:void = {}
GetBaseReward(Difficulty:difficulty_level)<decides>:?int = option{100}
CalculateTimeBonus(CompletionTime:float):int = 50
-->
<!-- 13 -->
```verse
ProcessTransaction(Amount:int)<transacts><decides>:void =
    ValidateAmount[Amount]
    DeductBalance(Amount)
    RecordTransaction()

# A long signature splits across lines, one parameter per line
CalculateReward(
    PlayerLevel:int,
    Difficulty:difficulty_level,
    CompletionTime:float
)<decides>:int =
    BaseReward := GetBaseReward[Difficulty]?
    LevelBonus := PlayerLevel * 10
    TimeBonus := CalculateTimeBonus(CompletionTime)
    BaseReward + LevelBonus + TimeBonus
```

## Comments

Comments are ignored during execution but help with understanding and maintaining code. Verse offers several styles of comments to suit different documentation needs. The simplest is the single-line comment, which begins with `#` and continues to the end of the line:

<!--versetest-->
<!-- 14 -->
```verse
CriticalDamage := 100.0 * 1.5   # Apply critical hit multiplier
```

When you need to document something within a line of code without breaking it up, inline block comments provide the perfect solution. These are enclosed between `<#` and `#>`:

<!--versetest
BaseValue:int = 100
Multiplier:int = 2
Bonus:int = 10
-->
<!-- 15 -->
```verse
Result := BaseValue <# original amount #> * Multiplier <# scaling factor #> + Bonus
```

The same can be used to write multi-line block comments, making them ideal for explaining complex algorithms or providing detailed context:

<!--versetest-->
<!-- 16 -->
```verse
<# The quadratic damage falloff makes damage decrease smoothly with
   distance, which rewards players for careful positioning. #>
CalculateFalloffDamage(Distance:float, MaxDamage:float):float =
    MaxDamage  # Implementation here
```

Block comments nest, which allows you to temporarily disable code that already contains comments without having to remove or modify existing documentation:

<!--versetest-->
<!-- 17 -->
```verse
<# Temporarily disabled for testing
   OriginalFunction()  <# This had a bug #>
#>
```

Indented comments begin with a `<#>` on its own line; everything indented by four spaces on subsequent lines becomes part of the comment:

<!--versetest
DoSomething():void = {}
-->
<!-- 18 -->
```verse
<#>
    This entire block is a comment because it is indented.
    It provides a clean way to write longer documentation
    without cluttering each line with comment markers.

DoSomething()  # Not part of the comment.
```

## Syntactic Styles

Verse offers flexible syntax to accommodate different programming styles. The same logic can be expressed using braces, indentation, or inline forms, allowing you to choose the clearest representation for each context.

The braced style uses curly braces to delimit blocks, familiar from C-family languages. The indented style uses colons and indentation to define structure, similar to Python. For simple expressions, the inline style keeps everything on one line. The dotted style uses a period to introduce the expression. Here is one conditional written in all four:

<!-- 19 -->
```verse
Score := 85

Braced := if (Score > 90) { "excellent" } else { "needs improvement" }

Indented := if (Score > 90):
    "excellent"
else:
    "needs improvement"

Inline := if (Score > 90) then "excellent" else "needs improvement"

Dotted := if (Score > 90). "excellent" else. "needs improvement"

Braced = Indented and Indented = Inline and Inline = Dotted
```

You can even mix styles when it makes sense:

<!--versetest
ComplexCondition()<transacts><decides>:void = {}
AnotherCheck()<transacts><decides>:void = {}
YetAnotherValidation()<transacts><decides>:void = {}
-->
<!-- 20 -->
```verse
Result := if:
    ComplexCondition[] and
    AnotherCheck[] and
    YetAnotherValidation[]
then { "condition met" } else { "condition not met" }
```

All these forms produce the same result, which is what the last line of the four-way example checks. The choice between them is about readability and context.
Use braces when working with existing brace-heavy code, indentation for cleaner vertical layouts,
and inline forms for simple expressions. This flexibility lets you write code that reads naturally.
