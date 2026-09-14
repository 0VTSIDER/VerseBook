# Primitive Data Types

Verse's primitive types are the numeric types `int`, `float`, and
`rational`; `logic` for boolean values; `char`, `char32`, and `string`
for text; and two types with special roles in the hierarchy: `any`, the
supertype of all types, and `void`, which discards whatever it is
given.

## Intrinsics

Some of what looks like ordinary Verse code is not written in Verse at
all. *Intrinsic functions* are operations the compiler synthesises: the
operators, container indexing, and functions such as `Abs`, `Floor`,
and `Ceil`. They cannot be written in Verse because they need access to
runtime internals, and because the compiler recognises each one by name
it can also optimize the call. The [Runtime API
Reference](api/verse_runtime_api.html) catalogues them, alongside the
parts of the runtime that the engine implements in C++.

Most intrinsic functions *cannot be referenced as first-class
values*. This means you can call them directly, but you cannot store
them in variables or pass them as function arguments:

<!--versetest
assert_semantic_error(3502):
    F := Abs
-->
<!-- 01 -->
```verse
Result := Abs(-42)  # Returns 42

# Invalid: Cannot reference without calling
# F := Abs  # ERROR
# Invalid: Cannot pass as parameter
# ApplyFunction(Abs, -42)  # ERROR
```

This restriction exists because intrinsics often require special
calling conventions or optimizations that do not fit the standard
function model. If you need to pass intrinsic functionality around,
wrap it in a regular function or nested function.

## Integers

The `int` type represents integer, non-fractional values. An `int` can
contain a positive number, a negative number, or zero. At runtime,
integers are arbitrary precision and can grow beyond any fixed size.
However, integer *literals* must fit within a 64-bit signed range
(`-9,223,372,036,854,775,808` to `9,223,372,036,854,775,807`), and
integers exceeding 64-bit have limited support (e.g., cannot be used
in string interpolation or persisted).

You can include `int` values within your code as literals.

<!--versetest-->
<!-- 02 -->
```verse
A :int= -42                    # civilian size
#B := 42424242424242424242424242424242424242424242424242 # scary numbers...
                               # ...can be computed but not written as literals

AnswerToTheQuestion :int= 42   # A variable that never changes
CoinsPerQuiver :int= 100       # A quiver costs this many coins
ArrowsPerQuiver :int= 15       # A quiver contains this many arrows

# Mutable variables (see Mutability chapter for details on var and set)
var Coins :int= 225           # The player currently has 225 coins
var Arrows :int= 3            # The player currently has 3 arrows
var TotalPurchases :int= 0    # Track total purchases
```

You can use the four basic math operations with integers: `+` for
addition, `-` for subtraction, `*` for multiplication, and `/` for
division.

<!--versetest
MyInt:int=10
MyHugeInt:int=1010100101
-->
<!-- 03 -->
```verse
var C :int= (-MyInt + MyHugeInt - 2) * 3   # arithmetic
set C += 1                                 # like saying, set C = C + 1
set C *= 2                                 # like saying, set C = C * 2
```

For integers, the operator `/` is failable, and the result is a
`rational` type if it succeeds.

### Overflow and VM Differences

`int` behaves differently on the two VMs at the edges of the 64-bit range:

- **VerseVM** uses arbitrary precision. Arithmetic that would exceed 64 bits
  simply produces the larger value.
- **BPVM** uses 64-bit integers and raises a runtime error
  (`MathIntrinsicCallFailure`) on overflow — including via `+=`, `*=`, unary
  negation of the minimum value, and the bitwise intrinsics.

Code that must behave identically on both VMs should stay inside the signed
64-bit range.

## Rationals

The `rational` type represents exact fractions as ratios of
integers. Unlike `int` or `float`, you cannot write a `rational`
literal directly—integer division using the `/` operator creates
rationals.

<!--versetest-->
<!-- 04 -->
```verse
X := 7 / 3    # X has type rational, representing exactly 7÷3
```

Rationals provide *exact arithmetic* without the precision loss of
floating-point numbers, making them ideal for game logic requiring
precise fractional calculations (resource distribution, turn-based
systems, probability calculations).

Integer division with `/` produces a rational value. Division by zero fails:

<!--versetest-->
<!-- 05 -->
```verse
Half := 5 / 2           # rational: exactly 5/2
Third := 10 / 3         # rational: exactly 10/3
Quarter := 1 / 4        # rational: exactly 1/4

if (not (1 / 0)):
    # Division by zero fails
```

Rationals are automatically reduced to lowest terms for equality comparisons:

<!--versetest-->
<!-- 06 -->
```verse
# All these are equal - reduced to 5/2
(5 / 2) = (10 / 4)      # true
(5 / 2) = (15 / 6)      # true
(10 / 4) = (15 / 6)     # true
```

This normalization ensures that mathematically equivalent rationals
compare as equal regardless of how they were constructed.

Negative signs are normalized to the numerator:

<!--versetest-->
<!-- 07 -->
```verse
(1 / -3) = (-1 / 3)     # true: negative moves to numerator
(-1 / -3) = (1 / 3)     # true: double negative becomes positive
```

This canonical form simplifies equality checking and ensures
consistent behavior.

An important property: *`int` is a subtype of `rational`*. This means
any integer can be used where a rational is expected:

<!--versetest-->
<!-- 08 -->
```verse
ProcessRational(X:rational):rational = X

# Can pass integers directly
ProcessRational(5) = 5/1     # 5 is implicitly 5/1 (rational)
ProcessRational(0) = 0/1     # 0 is implicitly 0/1 (rational)
```

However, you *cannot* return a rational where an int is expected—that
would be a narrowing conversion:

<!--versetest
assert_semantic_error(3510):
    BadFunction(X:rational):int = X
<#
-->
<!-- 09 -->
```verse
BadFunction(X:rational):int = X  # Error
```
<!-- #> -->

Whole number rationals equal their integer equivalents:

<!--versetest-->
<!-- 10 -->
```verse
(2 / 1) = 2             # true
2 = (2 / 1)             # true
(4 / 2) = 2             # true: 4/2 reduces to 2/1, equals 2
(9 / 3) = 3             # true: 9/3 reduces to 3/1, equals 3
```

This enables seamless mixing of integer and rational values in calculations.

Two functions convert rationals to integers: `Floor` rounds toward
negative infinity, and `Ceil` toward positive infinity.

<!--versetest-->
<!-- 11 -->
```verse
# Positive rationals
Floor(5 / 2)= 2         # 2.5 → 2 (down)
Ceil(5 / 2) = 3         # 2.5 → 3 (up)

# Negative rationals - note direction!
Floor((-5) / 2) = -3    # -2.5 → -3 (toward negative infinity)
Ceil((-5) / 2) = -2     # -2.5 → -2 (toward positive infinity)

# With negative denominator
Floor(5 / -2) = -3      # Same as (-5)/2
Ceil(5 / -2) = -2       # Same as (-5)/2

# Both negative
Floor((-5) / -2) = 2    # 2.5 → 2
Ceil((-5) / -2) = 3     # 2.5 → 3
```

Rounding toward negative infinity is *not* truncation: the two agree
on positive values and part company on negative ones. On a rational
argument neither function can fail; the `float` overloads are
`<decides>`.

When you apply `Floor` or `Ceil` to an integer-valued rational (one
that reduces to a whole number), it returns that integer:

<!--versetest-->
<!-- 12 -->
```verse
# Integer-valued rationals
PositiveRational:rational = 5
NegativeRational:rational = -5

Floor(PositiveRational) = 5   # Returns the integer 5
Ceil(PositiveRational) = 5    # Returns the integer 5
Floor(NegativeRational) = -5  # Returns the integer -5
Ceil(NegativeRational) = -5   # Returns the integer -5

# Also works for rationals that reduce to integers
Floor(10 / 2) = 5             # 10/2 = 5/1, returns 5
Ceil(10 / 2) = 5              # 10/2 = 5/1, returns 5
```

Rationals can be used as parameter and return types:

<!--versetest-->
<!-- 13 -->
```verse
# Function returning rational
Half(X:int)<computes><decides>:rational = X / 2

# Use the result
if (Result := Half[7]):
    Floor(Result) = 3   # 7/2 = 3.5, Floor gives 3
    Ceil(Result) = 4    # 7/2 = 3.5, Ceil gives 4
```


Because `int` is a subtype of `rational`, you *cannot* overload based
solely on these types:

<!--versetest
assert_semantic_error(3532):
    ProcessValue(X:int):void = {}
    ProcessValue(X:rational):void = {}
<#
-->
<!-- 14 -->
```verse
ProcessValue(X:int):void = {}
ProcessValue(X:rational):void = {}  # Error!
```
<!-- #> -->

The compiler sees `int` as more specific than `rational`, so the
signatures would be ambiguous.

Rationals excel at resource distribution and fairness calculations:

<!--versetest-->
<!-- 15 -->
```verse
# Fair resource distribution
DistributeResources(TotalGold:int, NumPlayers:int)<decides>:int =
    GoldPerPlayer := TotalGold / NumPlayers
    Floor(GoldPerPlayer)  # Converts to whole gold pieces (can be 0)

# To fail when there's insufficient gold, check > 0
DistributeResourcesOrFail(TotalGold:int, NumPlayers:int)<decides>:int =
    GoldPerPlayer := TotalGold / NumPlayers
    Floor(GoldPerPlayer) > 0  # Fails if each player gets 0

# Item affordability calculation
Coins:int = 225
CoinsPerQuiver:int = 100
ArrowsPerQuiver:int = 15

if (NumberOfQuivers := Floor(Coins / CoinsPerQuiver)):
    TotalArrows:int = NumberOfQuivers * ArrowsPerQuiver
    # Player can afford 2 quivers = 30 arrows
```

## Floats

The `float` type represents all non-integer numerical values. It can
hold large values and precise fractions, such as `1.0`, `-50.5`, and
`3.14159`. A float is an IEEE 64-bit float, which means it can contain
a positive or negative number that has a decimal point in the range
`[-2^1024 + 1, … , 0, … , 2^1024 - 1]`, or has the value `NaN` (Not a
Number). The implementation differs from the IEEE standard in the
following ways:

- There is only one `NaN` value.
- `NaN` is equal to itself.
- Every number is equal to itself.
- `0` cannot be negative.

You can include float values within your code as literals:

<!--versetest-->
<!-- 16 -->
```verse
A:float = 1.0
B := 2.14
MaxHealth : float = 100.0

var C:float = A + B
C = 3.14              # succeeds
set C -= 3.14
C = 0.0               # succeeds
# C = 0              # compile error; 0 is not a `float` literal
```

You can use the four basic math operations with floats: `+` for
addition, `-` for subtraction, `*` for multiplication, and `/` for
division. There are also combined operators for doing the basic math
operations (addition, subtraction, multiplication, and division), and
updating the value of a variable:

<!--versetest-->
<!-- 17 -->
```verse
var CurrentHealth : float = 100.0
set CurrentHealth /= 2.0    # Halves the value of CurrentHealth
set CurrentHealth += 10.0   # Adds 10 to CurrentHealth
set CurrentHealth *= 1.5    # Multiplies CurrentHealth by 1.5
```

### Special Float Values

Float operations follow IEEE 754 semantics, which include special
values for infinity and Not-a-Number (NaN):

<!--versetest-->
<!-- 18 -->
```verse
# Infinity from division by zero
PosInf := 1.0 / 0.0
NegInf := -1.0 / 0.0

# NaN from invalid operations
NaNFromZeroDiv := 0.0 / 0.0
NaNFromSqrt := Sqrt(-1.0)
NaNFromInfDiv := PosInf / PosInf

# NaN propagates through operations
Result := NaNFromZeroDiv + 100.0  # Result is NaN
Product := NaNFromSqrt * 2.0      # Product is NaN
```

Division by zero produces `Inf` or `-Inf` rather than failing. Invalid
operations like `0.0 / 0.0`, `Sqrt(-1.0)`, or `Inf - Inf` produce NaN
values. Arithmetic operations with NaN propagate the NaN to the
result. Unlike standard IEEE 754, Verse's NaN equals itself when
compared.

To convert an `int` to a `float`, multiply it by `1.0`: `MyFloat:=MyInt*1.0`.

## Mathematical Functions

The mathematical functions are intrinsics. The [Runtime API
Reference](api/verse_runtime_api.html) lists every one of them with its
signature, its effects, and how it behaves at the edges of its domain; this
section pins down the behaviour that most often catches people out.

`Abs`, `Min` and `Max` are defined for both `int` and `float`. On floats they
follow Verse's rule that `NaN` is a value like any other rather than something
that poisons a comparison, so it propagates out of `Min` and `Max` instead of
being ignored:

<!--versetest-->
<!-- 19 -->
```verse
Abs(5) = 5
Abs(-5) = 5
Abs(3.14) = 3.14

# NaN propagates through comparison
Max(NaN, 5.0) = NaN
Min(NaN, 5.0) = NaN

# Infinity is ordered as you would expect
Max(Inf, 100.0) = Inf
Min(-Inf, 100.0) = -Inf
```

`Ceil`, `Floor`, `Round` and `Int` convert a `float` to an `int`, and all four
can fail: a non-finite argument has no integer to round to, which is why they
are written with square brackets. `Round` breaks ties to even rather than away
from zero, so a long run of rounded values does not drift upwards:

<!--versetest-->
<!-- 20 -->
```verse
Round[1.5] = 2     # tie, rounds to even 2
Round[2.5] = 2     # tie, rounds to even 2
Round[-1.5] = -2   # tie, rounds to even -2
Round[0.5] = 0     # tie, rounds to even 0

Round[1.4] = 1     # no tie, rounds down
Round[1.6] = 2     # no tie, rounds up
```

The rest of the floating-point functions never fail. Where a mathematician
would say the answer does not exist, they return `NaN` or an infinity and let
it flow onwards:

<!--versetest-->
<!-- 21 -->
```verse
Sqrt(4.0) = 2.0
Sqrt(-1.0) = NaN   # negative inputs have no real root
Sqrt(Inf) = Inf

Pow(2.0, 3.0) = 8.0     # Pow(Base, Exponent)
Pow(4.0, 0.5) = 2.0     # square root
Pow(2.0, -1.0) = 0.5    # reciprocal
Pow(0.0, 0.0) = 1.0     # by convention
Pow(NaN, 0.0) = 1.0     # a zero exponent always gives 1
Pow(1.0, NaN) = 1.0     # 1 to any power is 1

Exp(0.0) = 1.0
Exp(-Inf) = 0.0
Ln(1.0) = 0.0
Ln(Exp(1.0)) = 1.0      # ln(e) = 1
Ln(0.0) = -Inf
Ln(-1.0) = NaN

Log(10.0, 100.0) = 2.0  # log₁₀(100); the base comes first
Log(2.0, 8.0) = 3.0     # log₂(8)
```

The trigonometric functions work in radians, and `PiFloat` is the nearest
`float` to π rather than π itself. That distinction is visible: angles which
mathematically give exactly zero only come close.

<!--versetest-->
<!-- 22 -->
```verse
Sin(0.0) = 0.0
Sin(PiFloat / 2.0) = 1.0
Cos(0.0) = 1.0
Cos(PiFloat) = -1.0

Sin(NaN) = NaN
Sin(Inf) = NaN          # no meaningful angle

# PiFloat is not π, so these are near zero rather than zero
Sin(PiFloat) > 0.0 and Sin(PiFloat) < 0.000001
Cos(PiFloat / 2.0) > 0.0 and Cos(PiFloat / 2.0) < 0.000001

# The inverses answer an angle: ArcSin and ArcTan in [-π/2, π/2],
# ArcCos in [0, π]
ArcSin(1.0) = PiFloat / 2.0
ArcCos(-1.0) = PiFloat
ArcTan(1.0) = PiFloat / 4.0
```

Beware that `ArcSin` and `ArcCos` do not fail outside `[-1, 1]`, and do not
return `NaN` either: they clamp, so `ArcSin(2.0)` quietly answers π/2. The
engine leaves that behaviour unspecified, so range-check the argument yourself
when a bad input needs to be visible.

`IsFinite` is the guard for all of this. It fails for `Inf`, `-Inf` and `NaN`,
and otherwise succeeds with the value itself, which lets it sit in the middle
of a calculation:

<!--versetest

assert:
    (5.0).IsFinite[]
    (-100.0).IsFinite[]
    not (Inf).IsFinite[]
    not (-Inf).IsFinite[]
    not (NaN).IsFinite[]
    (15.16).IsFinite[] = 15.16
    SafeDivide[10.0, 4.0] = 2.5
    not SafeDivide[10.0, 0.0]
SafeDivide(X:float, Y:float)<computes><decides>:float =
    X.IsFinite[] and Y.IsFinite[]
    Result := X / Y
    Result.IsFinite[]
    Result
<#
-->
<!-- 23 -->
```verse
(5.0).IsFinite[]      # succeeds
(-100.0).IsFinite[]   # succeeds

(Inf).IsFinite[]  # fails
(NaN).IsFinite[]  # fails

# Succeeds with the value, so it can be used inline
(15.16).IsFinite[] = 15.16

# Validation: fails rather than yielding Inf or NaN
SafeDivide(X:float, Y:float)<computes><decides>:float =
    X.IsFinite[] and Y.IsFinite[]
    Result := X / Y
    Result.IsFinite[]
    Result
```
<!-- #> -->

Finally, the named constants:

<!--NoCompile-->
<!-- 24 -->
```verse
PiFloat # 3.14159265358979323846...
Inf     # Positive infinity
-Inf    # Negative infinity (negation of Inf)
NaN     # Not a Number
```
## Booleans

The `logic` type represents the Boolean values `true` and `false`.

<!--versetest-->
<!-- 25 -->
```verse
A:logic = true
B := false

# A = B          # fails
A?                # succeeds
# B?             # fails

true?             # succeeds
# false?         # fails
```

The `logic` type only supports query operations and comparison
operations.  Query expressions use the query operator `?` to check if
a logic value is true and fail if the logic value is `false`.  For
comparison operations, use the failable operator `=` to test if two
logic values are the same, and `<>` to test for inequality.

Many programming languages find it idiomatic to use a type like
`logic` to signal the success or failure of an operation. In Verse, we
use success and failure instead for that purpose, whenever
possible. The conditional only executes the `then` branch if the guard
succeeds:

<!--versetest
ShowTargetLockedIcon():void={}
TargetLocked:?int = option{42}
-->
<!-- 26 -->
```verse
if (TargetLocked?):
    ShowTargetLockedIcon()
```

To convert an expression that has the `<decides>` effect to `true` on
success or `false` on failure, use `logic{ exp }`:

<!--versetest
F()<decides>:void=
    GotIt := logic{5 > 3}
    GotIt?
<#
-->
<!-- 27 -->
```verse
GotIt := logic{5 > 3}    # the comparison succeeds, so GotIt is true
GotIt?                   # so this succeeds
GotIt = false            # and this fails
not GotIt?               # and this fails too
```
<!-- #> -->

## Characters and Strings

Text is represented in terms of characters and strings.  A `char` is a
single **UTF-8 code unit** (not a full Unicode code point). A string
is therefore an array of characters, written as `[]char`. For
convenience, Verse provides the type alias `string` for `[]char`:

<!--versetest-->
<!-- 28 -->
```verse
MyName :string = "Joseph"
MyAlterEgo := "José"
```

Verse uses UTF-8 as the character encoding scheme. Each UTF-8 code unit
is one byte. A Unicode code point may require between one and four
code units. Code points with lower values use fewer bytes, while
higher values require more.

For example:

- `"a"` requires one byte (`{0o61}`),
- `"á"` requires two bytes (`{0oC3}{0oA1}`),
- `"🐈"` (cat emoji) requires four bytes (`{0u1f408}`).

Thus, strings are sequences of code units, not necessarily sequences
of Unicode characters in the abstract sense.

Because strings are arrays of `char`, you can index into them with
`[]`. Indexing has the `<decides>` effect: it succeeds when the index
is valid and fails otherwise.

<!--versetest
MyName:string="J"
-->
<!-- 29 -->
```verse
TheLetterJ := MyName[0]     # succeeds
TheLetterJ = 'J'            # succeeds
# MyName[100]               # fails
```

The length of a string is the number of UTF-8 code units it contains,
accessed via `.Length`. Note that this is *not the same as the number
of Unicode characters*:

<!--versetest-->
<!-- 30 -->
```verse
"José".Length = 5           # succeeds; 5 UTF-8 code units
"Jose".Length = 4           # succeeds; 4 UTF-8 code units
```

Because `string` is just `[]char`, strings declared as `var` can be mutated:

<!--versetest-->
<!-- 31 -->
```verse
var OuterSpaceFriend :string = "Glorblex"
set OuterSpaceFriend[0] = 'F'
```

Strings can be concatenated using the `+` operator:

<!--versetest
MyName:string="Joe"
MyAlterEgo:string="Jak"
-->
<!-- 32 -->
```verse
MyAttemptAtFormatting := "My name is " + MyName + " but my alter ego is " + MyAlterEgo + "."
```

Verse also supports string interpolation for more readable formatting:

<!--versetest
MyName:string="3"
MyAlterEgo:string="asdsa"
-->
<!-- 33 -->
```verse
Formatting := "My name is {MyName} but my alter ego is {MyAlterEgo}."
```

Interpolation works for any value that has a `ToString()` function in scope.

Write literal characters with single quotes. The type depends on
whether the character falls within the ASCII range (`U+0000`–`U+007F`)
or not:

- `'e'` has type `char`,
- `'é'` has type `char32`.

<!--versetest-->
<!-- 34 -->
```verse
A :char = 'e'                       # ok
B :char32 = 'é'                     # ok
# C :char = 'é'                     # error: type of 'é' is char32
# D :char32 = 'e'                   # error: type of 'e' is char
```

Character literals can also be written using numeric escape sequences:

<!--versetest-->
<!-- 35 -->
```verse
E :char = 0o65                      # ok; same as 'e'
F :char32 = 0u00E9                  # ok; same as 'é'
```

- `char` represents a single UTF-8 code unit (one byte, `0oXX`).
- `char32` represents a full Unicode code point (`0uXXXXX`).

Hex notation:

- `0oXX` for `char`: two hex digits (0o00 to 0off)
- `0uXXXXX` for `char32`: up to six hex digits (0u00000 to 0u10ffff)

Unlike some languages, Verse does not allow implicit conversion between characters and integers.

**Character escape sequences** work in both character and string literals:

| Escape | Meaning | Codepoint |
|--------|---------|-----------|
| `\t` | Tab | U+0009 |
| `\n` | Newline | U+000A |
| `\r` | Carriage return | U+000D |
| `\"` | Double quote | U+0022 |
| `\'` | Single quote | U+0027 |
| `\\` | Backslash | U+005C |
| `\{` | Left brace | U+007B |
| `\}` | Right brace | U+007D |
| `\<` | Less than | U+003C |
| `\>` | Greater than | U+003E |
| `\&` | Ampersand | U+0026 |
| `\#` | Hash/pound | U+0023 |
| `\~` | Tilde | U+007E |

Examples:

<!--versetest-->
<!-- 36 -->
```verse
Tab := '\t'
Newline := '\n'
Quote := '\"'
Brace := '\{'
```

Strings can be compared using the failable operators `=` (equality)
and `<>` (inequality). Comparison is done by code point, and is case
sensitive.  Equality depends on exact code unit sequences, not visual
appearance. Unicode allows multiple encodings for the same abstract
character. For example, `"é"` may appear as the single code point
`{0u00E9}`, or as the two-code-point sequence `"e"` (`{0u0065}`) plus
a combining accent (`{0u0301}`). These two strings look the same, but
they are not equal in Verse.

Checking whether a player has selected the correct item:

<!--versetest-->
<!-- 37 -->
```verse
ExpectedItemInternalName :string = "RedPotion"
SelectedItemInternalName :string = "BluePotion"

if (SelectedItemInternalName = ExpectedItemInternalName):
    true
else:
    false
```

Padding a timer with leading zeros:

<!--versetest-->
<!-- 38 -->
```verse
SecondsLeft :int = 30
SecondsString :string = ToString(SecondsLeft)    # convert int to string

var Combined :string = "Time Remaining: "
if (SecondsString.Length > 2):
    set Combined += "99"               # clamp to maximum
else if (SecondsString.Length < 2):
    set Combined += "0{SecondsString}" # pad with zero
else:
    set Combined += SecondsString
```

String interpolation supports complex expressions, not just simple variables:

<!--versetest
Format(D:float, ?Decimals:int):string=""
-->
<!-- 39 -->
```verse
# Expression interpolation
Age := 30
Message := "Next year: {Age + 1}"

# Function calls with named arguments
Distance := 5.5
Formatted := "Distance: {Format(Distance, ?Decimals:=2)}"
```

Strings can span multiple lines using interpolation braces for continuation:

<!--versetest-->
<!-- 40 -->
```verse
LongMessage := "This is a multi-line {
}string that continues across {
}multiple lines."

# Attention to whitespace:
AnotherMessage := "This is another {
}  multi-line message with     {
    # This comment is ignored
}    many spaces."
```

Empty interpolants `{}` are ignored, which is useful for line
continuation without adding content.

Since `string` is `[]char`, strings and character arrays can be compared:

<!--versetest-->
<!-- 41 -->
```verse
"abc" = array{'a', 'b', 'c'}    # Succeeds
"" = array{}                     # Succeeds - empty string equals empty array
```

Block comments within strings are removed during parsing:

<!--versetest-->
<!-- 42 -->
```verse
Text := "abc<#this comment is removed#>def"    # Same as "abcdef"
```

### ToString()

The `ToString()` function converts values to their string
representations. It is overloaded, with a version for `int`, for
`float`, for `char`, and one for `string` that hands back what it was
given.

String interpolation implicitly calls `ToString()` on embedded values:

<!--versetest-->
<!-- 43 -->
```verse
Age := 25
Score := 98.5

# These are equivalent:
Message1 := "Age: " + ToString(Age) + ", Score: " + ToString(Score)
Message2 := "Age: {Age}, Score: {Score}"
# Both produce: "Age: 25, Score: 98.5"
```

This makes `ToString()` essential for formatting output, even when you
do not call it directly.

`ToString()` only works on primitive types. User-defined classes and
structs do not have automatic string conversion.

### ToDiagnostic()

The `ToDiagnostic()` function takes a value of any type and produces a
`diagnostic`, useful for debugging and logging. Where `ToString()` is
overloaded per type and refuses anything it has no overload for,
`ToDiagnostic()` accepts everything and may report more detail:

<!--versetest
SomeValue:int=1
-->
<!-- 44 -->
```verse
Diagnosis := ToDiagnostic(SomeValue)
```

`ToDiagnostic()` is primarily used for debugging output rather than
user-facing strings. The exact format it produces may vary between VM
implementations and is not guaranteed to be stable across versions.

## Type type

The `type` type is a *metatype* - a type whose values are themselves
types. Every Verse type can be used as a value of type `type`. This
enables powerful generic programming through parametric functions,
where types are parameters that can be passed around and constrained.

You can create variables and parameters that hold type values:

<!--versetest-->
<!-- 45 -->
```verse
# A name can hold a type value
IntType:type = int

# A function can take one as a parameter and use it in its own signature
CreateDefault(t:type):?t = false

X:?int = CreateDefault(int)
Y:?string = CreateDefault(string)
not X? and not Y?
```

Any type at all can be named this way, using `:=` rather than `:type =`
so that the name becomes usable in the positions where a type is expected:

<!--versetest-->
<!-- 46 -->
```verse
# User-defined types
my_class := class {}
my_struct := struct {Value:int}

# Collections
ArrayType := []int
MapType := [string]int
TupleType := tuple(int, string)
OptionType := ?int

# Functions
FuncType := int->string

# Metatypes
SubtypeValue := subtype(my_class)
TypeLiteralValue := type{_(:int):string}

# The names then stand in for the types they were given
Pair:TupleType = (7, "seven")
Pair(0) = 7
Which:SubtypeValue = my_class
```

This universality makes `type` the foundation for Verse's generic
programming - any type can be abstracted over.

### Type Parameters

The most common use of `type` is in **where clauses** to create
parametric (generic) functions:

<!--versetest-->
<!-- 47 -->
```verse
# Identity function - works with any type
Identity(X:t where t:type):t = X

# Usage - type parameter inferred
Identity(42)        # t = int
Identity("hello")   # t = string
Identity(true)      # t = logic
```

The `where t:type` constraint means "`t` can be any Verse type." The
type system infers `t` from the argument and ensures type safety
throughout the function.

While `where t:type` accepts any type, you can use more specific
constraints like `subtype` to limit which types are valid:

<!-- 48 -->
```verse
# Only accepts types that are subtypes of comparable
Sort(Items:[]t where t:subtype(comparable)):[]t =
    Items  # A real implementation can compare elements, because t is comparable
```

For comprehensive documentation on parametric functions, see the
Functions chapter.

### Type as First-Class Values

Unlike many languages where types only exist at compile time, Verse
treats types as *first-class values* that can be computed, stored, and
manipulated:

<!--versetest-->
<!-- 49 -->
```verse
# Function that returns a type value
GetTypeForSize(Size:int):type =
    if (Size <= 8):
        int
    else:
        string

# Store type in data structure
TypeRegistry:[string]type = map{
    "Integer" => int,
    "Text" => string,
    "Flag" => logic
}
```

Types can be passed between functions:

<!-- 50 -->
```verse
# Helper function that takes a type parameter
CreateArray(ElementType:type, Size:int):[]ElementType =
    array{}

# Function that uses the helper
MakeIntArray():[]int =
    CreateArray(int, 10)
```

### Returning Options of Type Parameters

A common pattern is to have functions return `?t` where `t` is a type
parameter, allowing the function to work with any type while
potentially failing:

<!--versetest
MaybeValue(Value:t, Condition:logic where t:type):?t =
    if (Condition?) then option{Value} else false

assert:
    X:?int = MaybeValue(5, false)
    Y:?float = MaybeValue(3.14, true)
<#
-->
<!-- 51 -->
```verse
# return type `t` must be the same type as the `Value` param type
MaybeValue(Value:t, Condition:logic where t:type):?t =
    if (Condition?) then option{Value} else false

# Usage
X:?int = MaybeValue(5, false)  # Returns false as ?int
Y:?float = MaybeValue(3.14, true)  # Returns option{3.14} as ?float
```
<!-- #> -->


<!--versetest
MaybeValueExplicit(T:type, Value:t, Condition:logic where t:subtype(T)):?T =
    if (Condition?):
        option{Value}
    else:
        false

assert:
    X:?int = MaybeValueExplicit(int, 5, false)
    Y:?float = MaybeValueExplicit(float, 3.14, true)
assert_semantic_error(3509):
    Maybe818(T:type, Value:t, Condition:logic where t:subtype(T)):?T =
        if (Condition?) then option{Value} else false
    G818():void =
        Z:?int = Maybe818(int, 3.14, true)
<#
-->
<!-- 52 -->
```verse
# Alternative: explicitly pass the type parameter
MaybeValueExplicit(T:type, Value:t, Condition:logic where t:subtype(T)):?T =
    if (Condition?):
        option{Value}
    else:
        false

# Usage
X:?int = MaybeValueExplicit(int, 5, false)  # Returns false as ?int
Y:?float = MaybeValueExplicit(float, 3.14, true)  # Returns option{3.14} as ?float
# Z:?int = MaybeValueExplicit(int, 3.14, true) # ERROR: float not subtype of int
```
<!-- #> -->

This pattern is particularly useful for generic containers and factory
functions that may or may not be able to produce a value.

### Type Constraints

The `type` constraint in where clauses is the most permissive - it
accepts any Verse type. For more specific requirements, Verse provides
additional constraints:

<!--versetest-->
<!-- 53 -->
```verse
# Most permissive: any type
Generic(X:t where t:type):t = X

# More specific: must be subtype of comparable
RequiresComparison(X:t where t:subtype(comparable))<decides>:void =
    X = X  # Can use = because t is comparable

# Even more specific: must be exact subtype
RequiresExactType(X:t, Y:u where t:type, u:subtype(t)):t =
    X  # Y is guaranteed to be compatible with t
```

The type system enforces these constraints at compile time, preventing
invalid type usage.

### Limitations

While `type` enables powerful abstractions, there are some limitations:

There is no way to construct a value of an arbitrary type:

<!--NoCompile-->
<!-- 54 -->
```verse
# Cannot do this - no way to construct a value of arbitrary type t
MakeValue(T:type):T = ???  # What would this return for T=int? T=string?
```

There is no runtime type introspection:

<!--NoCompile-->
<!-- 55 -->
```verse
# Cannot do this - no runtime type introspection
GetFieldNames(T:type):string = ???
```

A `where` clause cannot open a parameter list, so a type parameter has to
arrive alongside a parameter that mentions it:

<!--versetest
Identity(X:t where t:type):t = X

assert:
    Identity(42)

assert_syntax_error(3100){"MakeDefault85(where t:type):t = false"}
<#
-->
<!-- 56 -->
```verse
# Type parameter must be determinable from usage
Identity(X:t where t:type):t = X

# OK: t inferred from argument
Identity(42)

# ERROR: "Expected expression or ')', got 'where'"
# MakeDefault(where t:type):t = false
```
<!-- #> -->

## Any

The `any` type is the *supertype of all types*. Every type in the
language is a subtype of `any`. Because of this, `any` itself supports
very few operations: whatever functionality `any` provides must also
be implemented by every other type. In practice, there is very little
you can do directly with values of type `any`. Still, it is important
to understand the type, because it sometimes arises when working with
code that mixes different kinds of values, or when the type checker
has no more precise type to assign.

One way `any` appears is when combining values that do not share a
more specific supertype. For example:

<!--versetest
letters := enum:
    A
    B
    C

letter := class:
    Value : char
-->
<!-- 57 -->
```verse
Main(Arg : int) : void =
    X := if (Arg > 0) then:
        letters.A
    else:
        letter{Value := 'D'}
```

In this example, the code assigns `X` either a value of type `letters` or
of type `letter`. Since these two types are unrelated, the compiler
assigns `X` the type `any`, which is their lowest common supertype.

A more useful role for `any` is as the type of a parameter that is
required syntactically but not actually used. This pattern can arise
when implementing interfaces that require a certain method signature.

<!--versetest-->
<!-- 58 -->
```verse
FirstInt(X:int, :any) : int = X
```

Here, the second parameter is ignored. Because it can be any value of
any type, it is given the type `any`.

In more general code, the same idea can be expressed using *parametric
types*, making the function flexible while still precise:

<!--versetest-->
<!-- 59 -->
```verse
First(X:t, :any where t:type) : t = X
```

This version works for any type `t`, returning a value of type `t`
while discarding the unused argument of type `any`.

## Void

The `void` type represents the absence of a meaningful result and is
used in places where no result is returned. Technically, `void` is
a function that accepts any value and evaluates to `false`.

This design allows a function with return type `void` to have a body
that evaluates to any type, while ensuring that callers cannot use
the result. The body passes the value it produces to `void`, which
discards it and returns `false`.

A function whose purpose is to perform an effect, rather than compute
a value, has return type `void`.

<!--versetest-->
<!-- 60 -->
```verse
LogMessage(Msg:string) : void =
    Print(Msg)
```

Here, `LogMessage` performs an action (printing) but does not return a
result. The `void` return type makes that explicit.

### void, true, tuple() and false

Verse has a single "there is nothing interesting here" value. It can be written
`false` or `()`, and the types `void`, `true` and `tuple()` all describe it.
These are interchangeable:

<!--versetest
assert:
    Nothing:void    = false
    Unit:tuple()    = false
    Flag:true       = false
    Unit = ()
    Unit = false
    Nothing = false
    Flag = false
<#
-->
<!-- 61 -->
```verse
Nothing:void    = false
Unit:tuple()    = false
Flag:true       = false

# All the same value
Unit = ()
Unit = false
```
<!-- #> -->

`true` is a subtype of `logic`, so the unit value flows into logic positions:

<!--versetest
assert:
    Flag:true = false
    AsLogic:logic = Flag
<#
-->
<!-- 62 -->
```verse
Flag:true = false
AsLogic:logic = Flag
```
<!-- #> -->

The empty value also stands in for empty containers. `false` is accepted
wherever an empty array or map is expected:

<!--versetest
assert:
    Empty:[]int = false
    Empty.Length = 0
    Empty = false
<#
-->
<!-- 63 -->
```verse
Empty:[]int = false
Empty.Length = 0        # 0 - false is the empty array
Empty = false
```
<!-- #> -->

and `void`/`true` interchange through optionals, arrays and maps:

<!--versetest
assert:
    MaybeVoid:?void = option{0}
    MaybeTrue:?true = MaybeVoid
    MaybeTrue?
<#
-->
<!-- 64 -->
```verse
MaybeVoid:?void = option{0}
MaybeTrue:?true = MaybeVoid     # ?void and ?true interchange
```
<!-- #> -->

#### Write the value, not the type name

`void` names a type; the unit value is `false` (or `()`). A parameter declared
literally `:void` accepts any value, so passing the type name happens to work
there. It does not work when `void` reaches the parameter through a type
parameter, so write the value:

<!--versetest
assert_valid:
    IgA(:void):int = 42
    G909a():void =
        X := IgA(void)
assert_semantic_error(3509):
    holder909(t:type) := interface:
        Method(X:t):t = X
    holder909_void := holder909(void)
    c909 := class(holder909_void) {}
    G909b():void =
        C := c909{}
        C.Method(void)
assert_valid:
    holder909b(t:type) := interface:
        Method(X:t):t = X
    holder909b_void := holder909b(void)
    c909b := class(holder909b_void) {}
    G909c():void =
        C := c909b{}
        C.Method(false)
Ignore(:void):int = 42
assert:
    Ignore(false) = 42
<#
-->
<!-- 65 -->
```verse
Ignore(:void):int = 42

Ignore(false)    # OK - the unit value
Ignore()         # OK

# A `:void` parameter accepts anything, so even the type name is taken here
Ignore(void)     # OK, but misleading - prefer `false`

# Through a type parameter bound to void, the type name is rejected:
holder(t:type) := interface:
    Method(X:t):t = X

# C.Method(void)    # ERROR
# C.Method(false)   # OK
```
<!-- #> -->

!!! warning
    That last error reads *"expects a value of type `true`, but this
    argument is an incompatible value of type `true`"*. Both sides print as
    `true`, because the type of a type expression renders the same way. If you
    see a message that appears to say a type is incompatible with itself, check
    whether you passed a type name where a value belongs.

#### Conversion is one-way

Any value converts to `void`, and that extends through containers in ordinary
parameter positions — `[]int` satisfies `[]void`. A *type parameter* bound to
`[]void` is invariant, though, so only `[]void` (or `[]true`) fits there:

<!--versetest
assert_valid:
    Main():void =
        X:void = 1
assert_valid:
    Sink(:[]void):void = {}
    Main():void =
        Y:[]int = array{1}
        Sink(Y)
assert_semantic_error(3509):
    box(t:type) := class:
        Put(:t):void = {}
    Main():void =
        Y:[]int = array{1}
        box([]void){}.Put(Y)
<#
-->
<!-- 66 -->
```verse
X:void = 1              # OK - any value converts to void

Sink(:[]void):void = {}
Y:[]int = array{1}
Sink(Y)                 # OK - []int satisfies []void

box(t:type) := class:
    Put(:t):void = {}

# box([]void){}.Put(Y)  # ERROR - a type parameter bound to []void is
                        # invariant, so []int does not fit
```
<!-- #> -->
