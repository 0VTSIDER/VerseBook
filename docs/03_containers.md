# Container Types

Verse has five container types. An optional (`?t`) holds either a value or nothing. A tuple groups a fixed number of values that may have different types. An array (`[]t`) holds any number of values of one type, with indexed access. A map (`[k]v`) associates keys with values. A `weak_map` is a map that does not keep its keys alive, and is the basis for persistent storage.

## Optionals

An optional is an immutable container that either holds a value of type `t` or nothing at all. The type is written `?t`. Optionals are useful whenever a value may or may not be present, such as when looking up a key in a map or calling a function that can fail. By making this possibility explicit in the type, Verse allows programmers to handle "no result" situations directly and consistently, instead of relying on ad hoc error codes or special values.

You can create a non-empty optional with `option{...}`, which wraps a value into an optional. For example:

<!--versetest-->
<!-- 01 -->
```verse
A:?int = option{42}    # an optional containing the integer 42
```

If you want to represent "no value," you use the special constant `false`. This is how Verse spells the empty optional:

<!--versetest-->
<!-- 02 -->
```verse
var B:?int = false     # this optional has no element
B = false              # still empty
```

To extract the element of an optional, you write `?` after the optional expression. This produces a `<decides>` expression that succeeds if the optional has an element and fails otherwise. For example:

<!--versetest-->
<!-- 03 -->
```verse
A:?int = option{42}
A? + 2 = 44            # succeeds with 44 because A contains 42
```

If `A` had been `false`, then the attempt to use `A?` would fail and so would the whole computation. A failing case makes this clearer:

<!--versetest-->
<!-- 04 -->
```verse
B:?int = false
not B?                 # fails because B is false and has no element
```

This shows how Verse integrates optionals tightly with the effect system: the presence or absence of a value can cause an entire computation to succeed or fail.

The `option{...}` form also works in the opposite direction. When you have a computation with the `<decides>` effect, wrapping it in `option{...}` converts it to an optional. On success you get a non-empty optional; on failure you get `false`:

<!--versetest-->
<!-- 05 -->
```verse
GetAFloatOrFail()<transacts><decides>:float = 3.14

MaybeAFloat := option{GetAFloatOrFail[]}
MaybeAFloat? = 3.14
```

The two are inverses: `?` turns an optional into a `<decides>` expression, and `option{...}` turns a `<decides>` expression into an optional.

Although an optional value itself is immutable, you can keep one in a variable and change which optional the variable points to. The keyword `set` is used for this:

<!--versetest-->
<!-- 06 -->
```verse
var C:?int = false
set C = option{2}      # C now refers to an optional containing 2
C? = 2                 # succeeds, since C is not empty
```

This ability is useful whenever you want to track success or failure over time, such as gradually computing a result and updating the variable only when you succeed.

A common use case is searching for something that may or may not be there. Imagine a function `FindIndex` that looks through an array of integers and returns the index of the element you want. If the element exists, the function returns `option{index}`; if not, it returns `false`. The caller can then safely decide what to do:

<!--versetest-->
<!-- 07 -->
```verse
FindIndex(Values:[]int, Target:int):?int =
    for (I := 0..Values.Length-1):
        if (Values[I] = Target) then return option{I}
    return false

Found := FindIndex(array{10, 20, 30}, 20)
Found? = 1                  # unwraps the optional

Missing := FindIndex(array{10, 20, 30}, 99)
not Missing?                # nothing to unwrap
```

The return type `?int` states in the signature that the search may not
find anything, so callers cannot forget to handle that case.

## Tuple

A tuple is a container that groups two or more values. Unlike arrays, Tuples allow you to combine values of mixed types and treat them as a unit. The elements of a tuple appear in the order in which you list them, and you access them by their position, called the index. Because the number of elements is always known at compile time, a tuple is both simple to create and safe to use.

The term *tuple* is a back formation from *quadruple*, *quintuple*, *sextuple*, and so on. Conceptually, a tuple is like an unnamed data structure with ordered fields, or like a fixed-size array where each element may have a different type.

Write a tuple literal by enclosing a comma-separated list of expressions in parentheses. For example:

<!--versetest-->
<!-- 08 -->
```verse
Tuple1 := (1, 2, 3)
```

The order of elements matters, so `(3, 2, 1)` is a completely different value. Since tuples allow mixed types, you might write:

<!--versetest-->
<!-- 09 -->
```verse
Tuple2 := (1, 2.0, "three")
```

Tuples can also nest inside each other:

<!--versetest-->
<!-- 10 -->
```verse
X:tuple(int,tuple(int,float,string),string) = (1, (10, 20.0, "thirty"), "three")
```

Tuples are useful when you want to return multiple values from a function or when you want a lightweight grouping of values without the overhead of defining a struct or class. Write the type of a tuple with the `tuple` keyword followed by the types of the elements, but in most cases the compiler can infer it. For instance, you can write `MyTuple : tuple(int, float, string) = (1, 2.0, "three")`, or simply `MyTuple := (1, 2.0, "three")` and let the compiler deduce the type.

Access the elements of a tuple using a zero-based index operator written with parentheses. If `MyTuple := (1, 2.0, "three")`, then `MyTuple(0)` is the integer `1`, `MyTuple(1)` is the float `2.0`, and `MyTuple(2)` is the string `"three"`. Because the compiler knows the number of elements in every tuple, tuple indexing cannot fail: any attempt to use an out-of-bounds index results in a compile-time error.

Another feature of tuples is *expansion*. When you pass a tuple to a function as a single argument, Verse automatically expands its elements as if the function had been called with each element separately. For example:

<!--versetest-->
<!-- 11 -->
```verse
Describe(Count:int, Name:string):string = "{Count} {Name}"

MyTuple := (1, "two")
Describe(MyTuple) = "1 two"   # expands to Describe(1, "two")
```

Tuples also play a role in structured concurrency. The `sync` expression produces a tuple of results, allowing several computations that unfold over time to be evaluated simultaneously. In this way, tuples provide not only a convenient grouping mechanism but also a foundation for composing concurrent computations.

Tuples can also be automatically converted to arrays when used with array concatenation operators `+` and `+=`. See [From Tuples to Arrays](#from-tuples-to-arrays) for more details.

## Arrays

An array is an immutable container that holds zero or more values of the same type `t`. The elements of an array are ordered, and each can be accessed by a zero-based index. Write arrays with square brackets in their type, for example `[]int` or `[]float`, and create them with the `array{...}` literal form. For instance, `A : []int = array{}` creates an empty array, while `B : []int = array{1, 2, 3}` creates an array of three integers. Accessing elements by index is a failable operation: `B[0]` succeeds with the value `1`, while `B[10]` fails because the index is out of bounds.

Arrays can be concatenated with the `+` operator, and when declared as `var` they can be extended with the shorthand operator `+=`. For example, `var C:[]int= B + array{4}` gives `C` the value `array{1,2,3,4}`, and `set C += array{5}` updates it to `array{1,2,3,4,5}`. Tuples can also be used directly with these operators, and will be automatically converted to arrays. The length of an array is available through the `.Length` member, so `C.Length` here would be `5`. Elements are always stored in the order they are inserted, and indexing starts at `0`. Thus `array{10,20,30}[0]` is `10`, and the last valid index of any array is always one less than its length.

Although arrays themselves are immutable, variables declared with `var` can be reassigned to new arrays, or can appear to have their elements changed. For example, `var D:[]int = array{1,2,3}` allows the update `set D[0] = 3`, after which `D` will hold `array{3,2,3}`. What actually happens is that Verse creates a brand new array under the hood, with the specified element updated. In effect, `set D[0] = 3` is compiled into `set D = array{3,D[1],D[2]}`. The old array continues to exist if another variable was referencing it, which means that if `A` and `B` both start as `array{1}` and we update `A[0]`, then `A` and `B` will diverge: `A[0]` is now `2` while `B[0]` is still `1`.

Arrays are useful whenever you want to store multiple values of the same type, such as a list of players in a game: `Players:[]player = array{Player1,Player2}`. Access is by index, for example `Players[0]` is the first player. Since indexing is failable, it is often combined with `if` expressions or iteration. For instance, the following code safely prints out every element of an array:

<!--versetest-->
<!-- 12 -->
```verse
ExampleArray : []int = array{10, 20, 30}
for (Index := 0..ExampleArray.Length - 1):
    if (Element := ExampleArray[Index]):
        Print("{Element} in ExampleArray at index {Index}")
```

produces

```
10 in ExampleArray at index 0
20 in ExampleArray at index 1
30 in ExampleArray at index 2
```

Because arrays are values, "changing" them always means replacing the old array with a new one. With `var` this feels natural, since variables can be reassigned. For example, you can concatenate arrays and then update an element:

<!--versetest-->
<!-- 13 -->
```verse
Array1 : []int = array{10, 11, 12}
var Array2 : []int = array{20, 21, 22}
set Array2 = Array1 + Array2 + array{30, 31}
if (set Array2[1] = 77) {}
Array2 = array{10, 77, 12, 20, 21, 22, 30, 31}
```

After this code runs, iterating through `Array2` prints `10, 77, 12, 20, 21, 22, 30, 31`.

Tuples can be used directly with the `+` and `+=` operators on arrays, and will be automatically converted to arrays. This provides a concise way to add multiple elements without wrapping them in `array{...}`:

<!--versetest-->
<!-- 14 -->
```verse
var Values:[]int = array{1, 2, 3}

# Concatenate using a tuple - automatically converted to array
set Values = Values + (4, 5, 6)

# Shorthand form also works with tuples
set Values += (7, 8, 9)

Values = array{1, 2, 3, 4, 5, 6, 7, 8, 9}
```

This tuple-to-array conversion with operators is distinct from tuple expansion in function calls. With operators, the tuple elements are added to the array as individual items, just as if you had written `array{4, 5, 6}`.

Arrays can also be nested to form multi-dimensional structures, similar to rows and columns of a table. For example, the following creates a two-dimensional 4×3 array of integers:

<!--versetest-->
<!-- 15 -->
```verse
var Counter : int = 0
Example : [][]int =
    for (Row := 0..3):
        for (Column := 0..2):
            set Counter += 1

Example[0] = array{1, 2, 3}
Example[3] = array{10, 11, 12}
```

This array can be visualized as

```
Row 0:  1  2  3
Row 1:  4  5  6
Row 2:  7  8  9
Row 3: 10 11 12
```

and is accessed with two indices: `Example[0][0]` is `1`, `Example[0][1]` is `2`, and `Example[1][0]` is `4`. You can loop through all rows and columns with nested iteration. Arrays in Verse are not restricted to rectangular shapes: each row can have a different length, producing a jagged structure. For example,

<!--versetest-->
<!-- 16 -->
```verse
Example : [][]int =
    for (Row := 0..3):
        for (Column := 0..Row):
            Row * Column

Example[0] = array{0}
Example[3] = array{0, 3, 6, 9}
```

produces a triangular array with rows of increasing length: row 0 has a single `0`, row 1 has `0, 1`, row 2 has `0, 2, 4`, and row 3 has `0, 3, 6, 9`.

Nested arrays with complex initialization work naturally as class field defaults:

<!--versetest-->
<!-- 17 -->
```verse
tile := class:
    Position:tuple(int, int)
    var IsOccupied:logic = false

game_board := class:
    # A 10×10 grid of tiles
    Tiles:[][]tile =
        for (Y := 0..9):
            for (X := 0..9):
                tile{Position := (X, Y)}

    GetTile(X:int, Y:int)<computes><decides>:tile =
        Row := Tiles[Y]
        Row[X]

Board := game_board{}

if (CenterTile := Board.GetTile[5, 5]):
    set CenterTile.IsOccupied = true
```

When you create an empty array with `array{}`, Verse infers the element type from the variable's type annotation:

<!--versetest-->
<!-- 18 -->
```verse
IntArray : []int = array{}       # Empty array of integers
FloatArray : []float = array{}   # Empty array of floats
```

Without a type annotation, the compiler cannot determine what type of array you want, so you must either provide the type explicitly or include at least one element that establishes the type.

Arrays determine their element type from the common supertype of all elements. When you create an array with values of different but related types, Verse finds the most specific type that encompasses all elements:

<!--versetest-->
<!-- 19 -->
```verse
shape := class {}
circle := class(shape) {}
square := class(shape) {}

# The element type is shape, the common supertype of circle and square
Shapes : []shape = array{circle{}, square{}}
Shapes.Length = 2
```

This applies to any type hierarchy, including interfaces. If you mix completely unrelated types, the element type becomes `any`:

<!--versetest-->
<!-- 20 -->
```verse
# Array of comparable - different types sharing comparable in common
DisjointArray : []comparable = array{42, 13.37, true}

# Array of any - different types with no common supertype
AnyArray : []any = array{15.61, "Message", void}
```

### From Tuples to Arrays

Verse provides automatic conversion between tuples and arrays in specific contexts, enabling flexible function calls while maintaining type safety. This conversion is *one-way*: tuples can become arrays, but arrays cannot become tuples.

Tuples can be directly assigned to array variables when all tuple elements are compatible with the array's element type:

<!--versetest-->
<!-- 21 -->
```verse
# Homogeneous tuple to array
X:tuple(int, int) = (1, 2)
Y:[]int = X            # Valid - both elements are int
Y[1] = 2               # Can use as normal array

# Longer tuples work too
NumTuple:tuple(int, int, int, int) = (1, 2, 3, 4)
NumberArray:[]int = NumTuple
NumberArray.Length = 4
```

This conversion creates an array containing all the tuple's elements in order.

When a function has a single array parameter, you can call it with multiple arguments, which automatically form an array. This "variadic-like" syntax provides convenience while keeping the function signature simple:

<!--versetest-->
<!-- 22 -->
```verse
Sum(Values:[]int):int =
    var Total:int = 0
    for (N : Values):
        set Total += N
    Total

Sum(1, 2, 3, 4) = 10      # several arguments form an array
Sum((5, 6)) = 11          # a tuple literal becomes an array
Triple := (10, 20, 30)
Sum(Triple) = 60          # so does a tuple variable
```

Array conversion only succeeds when **all tuple elements are compatible** with the array's element type:

<!--versetest-->
<!-- 23 -->
```verse
entity := class:
    ID:int

player := class(entity):
    Name:string

CountEntities(Entities:[]entity):int = Entities.Length

Hero := player{ID := 1, Name := "Alice"}
Rock := entity{ID := 2}

# Valid - player is a subtype of entity
CountEntities(Hero, Rock) = 2
```

Functions taking `[]any` accept **any tuple**, regardless of element types:

<!--versetest-->
<!-- 24 -->
```verse
GetLength(Items:[]any):int = Items.Length

GetLength(1, 2.0) = 2                  # mixed types
GetLength("a", 42, true) = 3           # different types
GetLength((1, 2.0, "hello")) = 3       # explicit tuple
```

This enables generic functions that work with heterogeneous data.

When tuple elements share a common supertype (via inheritance or interface), they convert to an array of that supertype:

<!--versetest-->
<!-- 25 -->
```verse
identified := interface:
    GetID():int

sword := class(identified):
    GetID<override>():int = 1

shield := class(identified):
    GetID<override>():int = 2

CountItems(Items:[]identified):int = Items.Length

# Valid - both classes implement identified
CountItems(sword{}, shield{}) = 2
```

The compiler finds the most specific common supertype and uses it for the array element type.

Tuple-to-array conversion works with nested structures. A tuple of tuples becomes an array of arrays:

<!--versetest-->
<!-- 26 -->
```verse
ProcessMatrix(Matrix:[][]int):int = Matrix.Length

MatrixData := ((1, 2), (3, 4))
ProcessMatrix(MatrixData) = 2

# Or with explicit nesting
ProcessMatrix((1, 2), (3, 4)) = 2
```

An optional tuple becomes an optional array:

<!--versetest-->
<!-- 27 -->
```verse
ProcessOptional(Items:?[]int)<transacts><decides>:int = Items?[0]

Pair := option{(1, 2)}
ProcessOptional[Pair] = 1
```

And a tuple whose own elements are tuples converts them element by element:

<!--versetest-->
<!-- 28 -->
```verse
ProcessComplex(Data:tuple([]int, int)):int = Data(0).Length

# The first element of the tuple becomes an array
ProcessComplex(((1, 2), 3)) = 2
```

### Array Slicing

Arrays support slicing operations through the `.Slice` method, which extracts a contiguous portion of an array. Slicing is a failable operation—it succeeds only when the indices are valid.

The two-parameter form `Array.Slice[Start, End]` returns elements from index `Start` up to but not including index `End`:

<!--versetest-->
<!-- 29 -->
```verse
NumArray : []int = array{10, 20, 30, 40, 50}
NumArray.Slice[1, 4] = array{20, 30, 40}
```

The one-parameter form `Array.Slice[Start]` returns all elements from `Start` to the end:

<!--versetest
NumArray : []int = array{10, 20, 30, 40, 50}
-->
<!-- 30 -->
```verse
NumArray.Slice[2] = array{30, 40, 50}
```

Slicing fails if indices are negative, out of bounds, or if `Start` is greater than `End`. Creating an empty slice is valid when `Start` equals `End`:

<!--versetest
NumArray:[]int = array{10, 20, 30, 40, 50}
-->
<!-- 31 -->
```verse
NumArray.Slice[2, 2] = array{}     # empty slice: Start equals End
not NumArray.Slice[2, 1]           # Start greater than End
not NumArray.Slice[-1, 2]          # negative index
not NumArray.Slice[0, 10]          # End beyond the array length
```

Slicing also works on strings and character tuples, returning a string:

<!--versetest-->
<!-- 32 -->
```verse
"hello".Slice[1, 4] = "ell"
```

### Array Methods

Arrays provide intrinsic methods for searching, removing, and replacing elements. These operations create new arrays rather than modifying existing ones, maintaining Verse's immutability guarantees.

The `Find()` method searches for the first occurrence of an element and returns its index, or fails if not found. It is available whenever the element type is a subtype of `comparable`:

<!--versetest-->
<!-- 33 -->
```verse
NumArray := array{1, 2, 3, 1, 2, 3}

NumArray.Find[2] = 1           # the index of the first occurrence
not NumArray.Find[0]           # 0 is not in the array

Fruits := array{"Apple", "Orange", "Strawberry"}
Fruits.Find["Strawberry"] = 2
```

`Find()` returns the first found index on success (`int`), or fails if the element was not found, enabling safe handling of missing elements without exceptions or special sentinel values.

`RemoveFirstElement()` removes the first occurrence, and fails if the element is not there:

<!--versetest-->
<!-- 34 -->
```verse
NumArray := array{1, 2, 3, 1, 2, 3}

NumArray.RemoveFirstElement[2] = array{1, 3, 1, 2, 3}
not NumArray.RemoveFirstElement[0]     # element not found
```

`RemoveAllElements()` removes all occurrences:

<!--versetest-->
<!-- 35 -->
```verse
NumArray := array{1, 2, 3, 1, 2, 3}
NumArray.RemoveAllElements(2) = array{1, 3, 1, 3}

# The array comes back unchanged if the element is not found
NumArray.RemoveAllElements(0) = array{1, 2, 3, 1, 2, 3}
```

`Remove()` removes the elements in a half-open index range, from the first index up to but not including the second:

<!--versetest-->
<!-- 36 -->
```verse
NumArray := array{10, 20, 30, 40}

NumArray.Remove[1, 2] = array{10, 30, 40}
not NumArray.Remove[-1, 0]     # negative index
not NumArray.Remove[6, 10]     # out of bounds
```

`ReplaceFirstElement()` replaces the first occurrence:

<!--versetest-->
<!-- 37 -->
```verse
NumArray := array{1, 2, 3, 1, 2, 3}

NumArray.ReplaceFirstElement[2, 99] = array{1, 99, 3, 1, 2, 3}
not NumArray.ReplaceFirstElement[0, 99]    # element not found
```

`ReplaceAllElements()` replaces all occurrences, and cannot fail:

<!--versetest-->
<!-- 38 -->
```verse
NumArray := array{1, 2, 3, 1, 2, 3}
NumArray.ReplaceAllElements(2, 99) = array{1, 99, 3, 1, 99, 3}

# The array comes back unchanged if the element is not found
NumArray.ReplaceAllElements(0, 99) = array{1, 2, 3, 1, 2, 3}
```

`ReplaceElement()` replaces at a specific index:

<!--versetest-->
<!-- 39 -->
```verse
NumArray := array{10, 20, 30, 40}

NumArray.ReplaceElement[1, 99] = array{10, 99, 30, 40}
not NumArray.ReplaceElement[-1, 99]    # negative index
not NumArray.ReplaceElement[10, 99]    # out of bounds
```

`ReplaceAll()` is a pattern-based replacement:

<!--versetest-->
<!-- 40 -->
```verse
NumArray := array{1, 2, 3, 4, 2, 3, 5}
Pattern := array{2, 3}
Replacement := array{99}
Updated := NumArray.ReplaceAll(Pattern, Replacement)
Updated = array{1, 99, 4, 99, 5}

# Works with different length patterns
NumArray2 := array{1, 2, 2, 1, 2, 2, 1}
Updated2 := NumArray2.ReplaceAll(array{2, 2}, array{9, 9, 9})
Updated2 = array{1, 9, 9, 9, 1, 9, 9, 9, 1}

# Strings are []char
SomeMessage := "Hey, this is a string, Hello!"
NewMessage := SomeMessage.ReplaceAll("He", "Apples") # Note: Case sensitive!
NewMessage = "Applesy, this is a string, Applesllo!"
```

`ReplaceAll()` finds contiguous subsequences matching `Pattern` and replaces each with `Replacement`. The replacement can be any length, including empty.

`Insert()` inserts a whole array of elements at a given index, shifting the existing elements right. Inserting at `Length` is valid and appends:

<!--versetest-->
<!-- 41 -->
```verse
NumArray := array{10, 20, 40}

NumArray.Insert[2, array{30}] = array{10, 20, 30, 40}
NumArray.Insert[0, array{5}] = array{5, 10, 20, 40}
NumArray.Insert[NumArray.Length, array{50}] = array{10, 20, 40, 50}

not NumArray.Insert[-1, array{5}]                  # negative index
not NumArray.Insert[NumArray.Length + 1, array{5}] # beyond Length
```

The `Concatenate()` function combines an array of arrays into a single flat array. Thanks to tuple-to-array coercion, you can pass multiple array arguments directly and they are automatically gathered into the array-of-arrays parameter. Unlike the `+` operator which joins exactly two arrays, `Concatenate()` accepts any number of array arguments, and empty arrays simply contribute nothing:

<!--versetest-->
<!-- 42 -->
```verse
# An empty call returns an empty array
Empty:[]int = Concatenate()
Empty = array{}

# A single array, passed as an array-of-arrays
Concatenate(array{array{1, 2, 3}}) = array{1, 2, 3}

# Two arrays, or any number of them
Concatenate(array{1, 2}, array{3, 4}) = array{1, 2, 3, 4}
Concatenate(array{1}, array{2, 3}, array{4}, array{5, 6}) = array{1, 2, 3, 4, 5, 6}

# Empty arrays contribute nothing
Concatenate(array{1, 2}, array{}, array{3}) = array{1, 2, 3}
```

The `+` operator is binary, so joining three arrays with it takes two operations where `Concatenate()` takes one:

<!--versetest-->
<!-- 43 -->
```verse
First := array{1, 2}
Second := array{3, 4}
Third := array{5, 6}

First + Second + Third = Concatenate(First, Second, Third)
```

#### Last

`Last` reads from the end of an array. It is failable, so it must be called with
`[]` in a failure context. `Last[]` is the final element; `Last[N]` counts back
from the end, so `Last[0]` is the last element and `Last[1]` the one before it.

<!--versetest-->
<!-- 44 -->
```verse
Values := array{10, 20, 30}

Values.Last[] = 30       # the last element
Values.Last[2] = 10      # two back from the end
not array{}.Last[]       # fails - the array is empty
not Values.Last[-1]      # fails - negative index
```

Arrays are immutable values; a `var` holding an array can be reassigned, but the array itself never changes in place.

## Maps

Maps are one of the core container types, alongside arrays and optionals. If arrays are ordered sequences indexed by integers, and optionals are the smallest container of all, holding either zero or one value, then Maps generalize both ideas: like arrays, they provide efficient lookup, but instead of being limited to integer indices, they allow any *comparable* type as a key. You can think of a map as an array indexed by arbitrary keys, or as a larger optional that can hold many key–value associations at once.

A map is an immutable associative container that stores zero or more key–value pairs of type `[k]v`, written as `(Key:k, Value:v)`. Maps are the standard way to associate values with other values: you supply a key, and the map returns the value associated with it.

Maps are useful whenever you want to store data that is naturally indexed by something other than an integer position. For example, you might want to store the weights of different objects keyed by their names:

<!--versetest-->
<!-- 45 -->
```verse
var Weights:[string]float = map{
    "ant" => 0.0001,
    "elephant" => 500.0,
    "galaxy" => 500000000000.0
}
```

Looking up a value in a map uses square brackets. The expression succeeds if the key is present and fails if it is not. Lookups are designed to be fast, with amortized *O(1)* time complexity:

<!--versetest
Weights:[string]float = map{"ant" => 0.0001}
-->
<!-- 46 -->
```verse
Weights["ant"] = 0.0001   # succeeds, "ant" is a key of the map
not Weights["car"]        # fails, "car" is not
```

If you want to update a map stored in a variable, you use `set`. This works both for adding a new key–value pair and for changing the value of an existing key. If you try to modify a key that is not present, the operation fails:

<!--versetest-->
<!-- 47 -->
```verse
var Friendliness:[string]int = map{"peach" => 1000}

set Friendliness["pelican"] = 17          # succeeds: adds a new key
set Friendliness["peach"] += 2000         # succeeds: updates an existing key
not (set Friendliness["tomato"] += 1000)  # fails: "tomato" is not a key

Friendliness = map{"peach" => 3000, "pelican" => 17}
```

Every map also carries its size, accessible as the `Length` field:

<!--versetest
Friendliness:[string]int = map{"peach" => 1000, "pelican" => 17}
-->
<!-- 48 -->
```verse
Friendliness.Length = 2         # succeed: the map has 2 entries
```

When constructing a map with duplicate keys, only the last value is kept. This is because a map enforces uniqueness of keys, so earlier entries are silently overwritten:

<!--versetest-->
<!-- 49 -->
```verse
WordCount:[string]int = map{
    "apple" => 0,
    "apple" => 1,
    "apple" => 2
}
WordCount = map{"apple" => 2}
```

Maps can also be iterated over, letting you traverse all key–value pairs exactly in the order they were inserted:

<!--versetest-->
<!-- 50 -->
```verse
ExampleMap:[string]string = map{
    "a" => "apple",
    "b" => "bear",
    "c" => "candy"
}

for (Key -> Value : ExampleMap):
    Print("{Value} in ExampleMap at key {Key}")
```

This produces:

- "apple in ExampleMap at key a"
- "bear in ExampleMap at key b"
- "candy in ExampleMap at key c"

Sometimes you want to remove an entry from a map. Since maps are immutable, "removing" means creating a new map that excludes the given key. For example, here is a function that removes an element from a `[string]int` map:

<!--versetest-->
<!-- 51 -->
```verse
RemoveKeyFromMap(TheMap:[string]int, ToRemove:string):[string]int =
    var NewMap:[string]int = map{}
    for (Key -> Value : TheMap, Key <> ToRemove):
        set NewMap = ConcatenateMaps(NewMap, map{Key => Value})
    return NewMap

RemoveKeyFromMap(map{"a" => 1, "b" => 2}, "a") = map{"b" => 2}
```

The key type of a map must belong to the class `comparable`, which guarantees that two keys can be checked for equality. All basic scalar types such as `int`, `float`, `rational`, `logic`, `char`, and `char32` are comparable, and so are compound types like arrays, maps, tuples, and `struct`s whose components are comparable.  Classes and interfaces (without the `<unique>` specifier) cannot be used as keys, since their instances do not provide a built-in notion of equality. However, classes and interfaces marked with `<unique>` can be used as keys because they support identity-based equality.

Not all types can be used as map keys. A type must be comparable—meaning values of that type can be checked for equality. Here's a comprehensive guide to what can and cannot be used as map keys:

These types are comparable, and so can be used as map keys:

- `logic` - boolean values
- `int`, `float`, `rational` - numeric types
- `char`, `char32` - character types
- `string` - text
- Enumerations - custom enum types
- Classes and Interfaces marked with `<unique>`
- `?t` where `t` is comparable - optionals of comparable types
- `[]t` where `t` is comparable - arrays of comparable elements
- `tuple(t0, t1, ...)` where all elements are comparable - tuples of comparable types
- `struct` types where all fields are comparable

### Map Key Type Examples

The following examples demonstrate various comparable types used as map keys.

A tuple of comparable elements makes a natural compound key, such as a coordinate pair:

<!--versetest-->
<!-- 52 -->
```verse
Grid:[tuple(int, int)]string = map{
    (0, 0) => "origin",
    (1, 0) => "east",
    (0, 1) => "north",
    (-1, 0) => "west"
}
Grid[(1, 0)] = "east"
```

A struct works the same way, and gives the components names:

<!--versetest-->
<!-- 53 -->
```verse
point := struct{X:int, Y:int}
Landmarks:[point]string = map{
    point{X := 0, Y := 0} => "origin",
    point{X := 10, Y := 20} => "tower"
}
Landmarks[point{X := 10, Y := 20}] = "tower"
```

Enumerations are comparable too, which makes them convenient for small fixed key sets:

<!--versetest-->
<!-- 54 -->
```verse
direction := enum{North, South, East, West}
Instructions:[direction]string = map{
    direction.North => "Go up",
    direction.South => "Go down",
    direction.East => "Turn right",
    direction.West => "Turn left"
}
Instructions[direction.East] = "Turn right"
```

Rational keys need a little more care.
Integer division is failable, so a rational cannot be written directly as a map
literal key: failure in map literal keys is not implemented. Bind the keys
first, in a failure context:

<!--versetest-->
<!-- 55 -->
```verse
Half := 1/2
Third := 1/3
Whole := 1/1

Fractions:[rational]string = map{Half => "half", Third => "third", Whole => "whole"}

Fractions[Half] = "half"
Fractions[2/2] = "whole"   # 2/2 and 1/1 are the same key
```

Equivalent rational numbers (like `1/1` and `2/2`) are treated as the same key.

Because `char32` is comparable, any Unicode character can be a key:

<!--versetest-->
<!-- 56 -->
```verse
Translations:[char32]string = map{
    '😀' => "grinning face",
    '你' => "you (Chinese)",
    '好' => "good (Chinese)"
}
Translations['好'] = "good (Chinese)"
```

Even the special float values `NaN` and `Inf` can be used as map keys:

<!--versetest-->
<!-- 57 -->
```verse
SpecialFloats:[float]string = map{
    Inf => "positive infinity",
    -Inf => "negative infinity",
    0.0 => "zero"
}
SpecialFloats[-Inf] = "negative infinity"
```

These types, on the other hand, cannot be used as map keys:

- `false` - the empty type
- `type` - type values themselves
- Function types like `t -> u`
- `subtype(t)` - subtype expressions
- Classes (without `<unique>`)
- Interfaces (without `<unique>`)

Attempting to use a non-comparable type as a key results in a compile-time error.

Like arrays, maps infer their key and value types from the common supertype of all keys and values. When you create a map with mixed but related types, Verse finds the most specific types that encompass all keys and all values:

<!--versetest-->
<!-- 58 -->
```verse
shape := class<unique> {}
circle := class<unique>(shape) {}
square := class<unique>(shape) {}

TheCircle := circle{}
TheSquare := square{}

# The key type is shape, the common supertype of circle and square,
# while the value type remains int
MixedKeyMap : [shape]int = map{TheCircle => 1, TheSquare => 2}
MixedKeyMap[TheCircle] = 1
```

### Ordering and Equality

Maps preserve insertion order, which is significant for both iteration and equality checks. When you insert entries into a map, they maintain the order of insertion. Two maps are equal only if they contain the same key–value pairs **in the same order**:

<!--versetest-->
<!-- 59 -->
```verse
var Scores:[string]int = map{}
set Scores["Alice"] = 100
set Scores["Bob"] = 90
set Scores["Carol"] = 95

# This map equals Scores
Map1 := map{"Alice" => 100, "Bob" => 90, "Carol" => 95}
Scores = Map1

# This map does NOT equal Scores - different order
Map2 := map{"Bob" => 90, "Alice" => 100, "Carol" => 95}
not Scores = Map2
```

When a map literal contains duplicate keys, the last value overwrites earlier values, and the key takes the position of its *last* occurrence rather than its first. Here the key `0` is written before `1` and `2` but ends up after them:

<!--versetest-->
<!-- 60 -->
```verse
Ordered := map{0 => "zero", 1 => "one", 0 => "ZERO", 2 => "two"}

Ordered = map{1 => "one", 0 => "ZERO", 2 => "two"}
not Ordered = map{0 => "ZERO", 1 => "one", 2 => "two"}
```

Iteration over the map will visit entries in their preserved insertion order.

### Empty Map Types

Empty maps can infer their key and value types from context, similar to arrays:

<!--versetest
-->
<!-- 61 -->
```verse
StringToInt : [string]int = map{}  # Empty map with inferred types

var Scores : [string]int = map{}
set Scores = ConcatenateMaps(Scores, map{"Alice" => 100})
```

Without type context, you may need to provide explicit type annotations.

### Variance

Maps are **covariant** in both their key and value types. A map type `[K1]V1` is a subtype of `[K2]V2` when:

- **Keys are covariant**: `K1` is a subtype of `K2` (more specific keys → more general keys)
- **Values are covariant**: `V1` is a subtype of `V2` (more specific values → more general values)

This covariance is necessary because map iteration exposes the key type. When you iterate a map, you receive the actual key objects, which must be safely usable as the declared key type.

While map types are covariant, map lookup operations accept keys that are `comparable` to the key type, which may appear contravariant. This is a convenience for lookups but does not affect the variance of the map type itself.

<!--versetest-->
<!-- 62 -->
```verse
animal := class<unique> {}
dog := class<unique>(animal) {}

# Map types are covariant: a [dog]int can be used as an [animal]int
DogMap : [dog]int = map{dog{} => 1}
AnimalMap : [animal]int = DogMap

# A lookup only needs a key comparable to the map's key type
Rex : dog = dog{}
RexAsAnimal : animal = Rex        # the same dog instance
Ages : [dog]int = map{Rex => 3}

Ages[Rex] = 3                     # lookup with the exact key type
Ages[RexAsAnimal] = 3             # a supertype key works too
```

When modifying a mutable map through `set`, you can only insert keys and values that match the map's declared types:

<!--versetest
assert_semantic_error(3509):
    animal2 := class<unique> {}
    dog2 := class<unique>(animal2) {}
    F()<transacts><decides>:void =
        var M : [dog2]int = map{}
        K2 : dog2 = dog2{}
        K1 : animal2 = K2
        set M[K1] = 2
-->
<!-- 63 -->
```verse
animal := class<unique> {}
dog := class<unique>(animal) {}

var Ages : [dog]int = map{}
Rex : dog = dog{}
RexAsAnimal : animal = Rex

set Ages[Rex] = 1              # valid - exact type match
# set Ages[RexAsAnimal] = 2    # ERROR - cannot use a supertype as a key
```

### Nested Maps

Maps can contain other maps as values, enabling multi-level associations:

<!--versetest-->
<!-- 64 -->
```verse
# Map from strings to maps of ints to strings
NestedMap : [string][int]string = map{
    "numbers" => map{1 => "one", 2 => "two"},
    "letters" => map{0 => "a", 1 => "b"}
}

NestedMap["numbers"][1] = "one"
```

Maps can be used as keys of other maps if all values and keys from it are comparable.

### Concatenating Maps

The `ConcatenateMaps()` function merges two maps into a single map. It takes exactly two maps and combines them into one. When maps contain duplicate keys, values from the **second** map override values from the first:

<!--versetest-->
<!-- 65 -->
```verse
Map1 := map{1 => "one", 2 => "two"}
Map2 := map{3 => "three", 4 => "four"}

Combined := ConcatenateMaps(Map1, Map2)
Combined = map{1 => "one", 2 => "two", 3 => "three", 4 => "four"}

# To merge more than two maps, chain calls
Map3 := map{5 => "five"}
All := ConcatenateMaps(ConcatenateMaps(Map1, Map2), Map3)
All = map{1 => "one", 2 => "two", 3 => "three", 4 => "four", 5 => "five"}
```

When both maps hold the same key, the value from the second one survives:

<!--versetest-->
<!-- 66 -->
```verse
Base := map{1 => "original", 2 => "base"}
Override := map{2 => "updated", 3 => "new"}

Result := ConcatenateMaps(Base, Override)
Result = map{1 => "original", 2 => "updated", 3 => "new"}
# Key 2 was overridden by the later map
```

The right-to-left precedence ensures that later maps take priority, enabling a natural override pattern.

An empty map contributes nothing to the result:

<!--versetest-->
<!-- 67 -->
```verse
FirstMap := map{1 => "a"}
EmptyMap : [int]string = map{}

Combined := ConcatenateMaps(FirstMap, EmptyMap)
Combined = map{1 => "a"}
```

The resulting map type will coerce to the most specific shared type from the input maps:

<!--versetest-->
<!-- 68 -->
```verse
shape := class {}
circle := class(shape) {}
square := class(shape) {}

Circles:[int]circle = map{1 => circle{}}
Squares:[int]square = map{2 => square{}}

# The result takes the common supertype of both value types
Shapes:[int]shape = ConcatenateMaps(Circles, Squares)
Shapes.Length = 2
```

## Weak Maps

The `weak_map` type is a specialized supertype of `map` designed for persistent data storage with weak key references. It behaves similarly to ordinary maps for individual entry access, but deliberately restricts bulk operations. You cannot ask for its length, you cannot iterate over its entries, and you cannot use `ConcatenateMaps`. These restrictions enable efficient weak reference semantics and integration with Verse's persistence system.

A `weak_map` is declared with `weak_map(k,v)` and can be initialized from an ordinary `map{}`. Updating and accessing individual entries works the same way as regular maps:

<!--versetest-->
<!-- 69 -->
```verse
var MyWeakMap:weak_map(int,int) = map{}

set MyWeakMap[0] = 1
MyWeakMap[0] = 1              # the entry is there

set MyWeakMap = map{0 => 2}   # reassignment still works (for local variables)
MyWeakMap[0] = 2
```

Because `weak_map` is a supertype of `map`, you can assign regular maps to weak_map variables when needed, but you lose the ability to count or iterate once you are working with a weak map.

### Restrictions

Bulk operations are what a `weak_map` gives up. There is no `Length` property, no iteration, no coercion to `comparable`, and no way to join one with a regular map to produce a regular map. Looking up a single key still works:

<!--versetest
assert_semantic_error(3506):
    G()<transacts>:void =
        var W:weak_map(int,int) = map{1 => 2}
        Size := W.Length
assert_semantic_error(3524):
    H()<transacts>:void =
        var W:weak_map(int,int) = map{1 => 2}
        for (Entry : W) {}
assert_semantic_error(3509):
    I()<transacts>:void =
        var W:weak_map(int,int) = map{1 => 2}
        C:comparable = W
assert_semantic_error(3509):
    J()<transacts><decides>:void =
        var W:weak_map(int,int) = map{1 => 2}
        Joined:[int]int = if (true?) then W else map{3 => 4}
-->
<!-- 70 -->
```verse
var MyWeakMap:weak_map(int,int) = map{1 => 2}

MyWeakMap[1] = 2                 # individual lookup works

# ERROR: MyWeakMap.Length                            - no Length
# ERROR: for (Entry : MyWeakMap) {}                  - no iteration
# ERROR: Comparable:comparable = MyWeakMap           - not comparable
# ERROR: Joined:[int]int = if (true?) then MyWeakMap else map{3 => 4}
```

### Module-Scoped weak_map Variables

When using `weak_map` as a module-scoped variable (for persistent data), there are additional restrictions. The complete map can neither be read nor replaced, while reading and writing one entry at a time is allowed:

<!--versetest
assert_semantic_error(3502):
    k85 := class<unique><allocates><computes><persistent><module_scoped_var_weak_map_key>{}
    M85 := module:
        var Scores:weak_map(k85, int) = map{}
        GetAll()<transacts>:weak_map(k85, int) = Scores
assert_semantic_error(3502):
    k86 := class<unique><allocates><computes><persistent><module_scoped_var_weak_map_key>{}
    M86 := module:
        var Scores:weak_map(k86, int) = map{}
        Reset()<transacts>:void =
            set Scores = map{}
-->
<!-- 71 -->
```verse
scoreboard := module:
    var Scores:weak_map(persistent_key, int) = map{}

    # OK: read one entry
    GetScore(Key:persistent_key)<transacts>:int =
        if (Score := Scores[Key]) then Score else 0

    # OK: write one entry
    SetScore(Key:persistent_key, Score:int)<transacts><decides>:void =
        set Scores[Key] = Score

    # ERROR: GetAll()<transacts>:weak_map(persistent_key, int) = Scores
    # ERROR: Reset()<transacts>:void = set Scores = map{}
```

These restrictions exist because module-scoped weak_maps integrate with the persistence system, which only tracks individual entry updates, not complete map replacements.

For module-scoped `var weak_map` variables, both key and value types have strict requirements. The key type must carry the `<module_scoped_var_weak_map_key>` specifier:

<!--versetest
assert_semantic_error(3502):
    plain88 := class<unique><allocates><computes>{}
    M88 := module:
        var InvalidData:weak_map(plain88, int) = map{}
-->
<!-- 72 -->
```verse
# A valid key type carries <module_scoped_var_weak_map_key>
badge_key := class<unique><allocates><computes><persistent><module_scoped_var_weak_map_key> {}

# A plain class does not
plain_class := class<unique><allocates><computes> {}

badges := module:
    var Badges:weak_map(badge_key, int) = map{}

    # ERROR: var Invalid:weak_map(plain_class, int) = map{}
```

The value type must be persistable:

<!--versetest
assert_semantic_error(3502):
    k89 := class<unique><allocates><computes><persistent><module_scoped_var_weak_map_key>{}
    plain89 := struct:
        Value:int
    M89 := module:
        var InvalidData:weak_map(k89, plain89) = map{}
-->
<!-- 73 -->
```verse
# A persistable value type
saved_score := struct<persistable>:
    Value:int

# A plain struct is not persistable
plain_score := struct:
    Value:int

scores := module:
    var Scores:weak_map(persistent_key, saved_score) = map{}

    # ERROR: var Invalid:weak_map(persistent_key, plain_score) = map{}
```

Common key types that satisfy the requirements:

- **`player`** - The standard key type for player-specific data
- **`persistent_key`** - Custom persistent keys with validity tracking
- **`session_key`** - Transient keys that do not persist across sessions

### Covariance

The `weak_map` type is **covariant** in its key type, meaning you can use a weak_map with a subclass key type where a parent class key type is expected. The same covariance lets a regular map be assigned to a weak_map with a compatible key type:

<!--versetest
assert_semantic_error(3509):
    b2 := class<unique> {}
    d2 := class(b2) {}
    v2 := struct {}
    Mk():weak_map(d2, v2) = map{}
    G():void =
        BM:weak_map(b2, v2) = Mk()
        DM:weak_map(d2, v2) = BM
-->
<!-- 74 -->
```verse
base_class := class<unique> {}
derived_class := class(base_class) {}

value_struct := struct {}

CreateDerivedMap():weak_map(derived_class, value_struct) =
    map{}

# OK: weak_map is covariant in key type
BaseMap:weak_map(base_class, value_struct) = CreateDerivedMap()

# ERROR: DerivedMap:weak_map(derived_class, value_struct) = BaseMap

# A regular map converts to a weak_map with a covariant key too
DerivedKey := derived_class{}
RegularMap:[derived_class]value_struct = map{DerivedKey => value_struct{}}
WeakMap:weak_map(base_class, value_struct) = RegularMap
```

### Updating Stored Values

A persistable value type cannot have `var` fields, so there is no way to update one field of a stored struct in place. What you can do is replace the whole value, or reach through it with an index when the value is itself a container:

<!-- 75 -->
```verse
inventory := module:
    var Items:weak_map(persistent_key, []int) = map{}

    Restock(Key:persistent_key)<transacts><decides>:void =
        set Items[Key] = array{1, 2, 3}    # replace the whole value
        set Items[Key][0] = 99             # update one element inside it
```

### Transaction and Rollback Semantics

Like all mutable state in Verse, `weak_map` updates participate in transaction semantics. If a `<decides>` expression fails, all changes are rolled back:

<!-- 76 -->
```verse
var GameData:weak_map(int,int) = map{}

AttemptUpdate()<transacts>:void =
    if:
        set GameData[1] = 100
        set GameData[2] = 200
        false?              # the transaction fails here

AttemptUpdate()
not GameData[1]             # both updates were rolled back
not GameData[2]
```

This applies to complete map replacements (for local variables), individual entries, and updates that reach inside a stored value.
