# Verse runtime documentation overrides

Prose written here replaces the `@doc` comment that `bin/verse_api` reads out
of the engine, for the declaration named in the heading above it. Leave a
section's body empty to keep whatever the engine says.

Only `##` headings and the prose under them are read. Everything else,
including HTML comments, is ignored — which is why the engine's current text is
kept beside each heading for reference.

Run `bin/verse_api --stubs` again after the engine changes: it appends
headings for anything new and never touches what is already here.

## cancelable

<!-- engine text:
Implemented by classes that allow users to cancel an operation. For example, calling `subscribable.Subscribe` with a callback returns a `cancelable` object. Calling `Cancel` on the return object unsubscribes the callback.
-->

## cancelable.Cancel

<!-- engine text:
Prevents any current or future work from completing.
-->

## classifiable_subset

<!-- engine text:
A `classifiable_subset` is a container that holds a set of elements. A classifiable_subset can hold multiple elements of the same type.
-->

## classifiable_subset.GetDiagnostic

<!-- no documentation in the engine source -->

## MakeClassifiableSubset

<!-- engine text:
Constructs a `classifiable_subset` containing the `InElements`.
-->

## operator'+'

<!-- engine text:
Returns a new set that is the union of all elements in `InSetL` set and `InSetR`.
-->

## FilterByType

<!-- engine text:
Returns a new set that contains all the elements in `InSet` that are of type `element_type`.
-->

## disposable

<!-- engine text:
Implemented by classes whose instances have limited lifetimes.
-->

## disposable.Dispose

<!-- engine text:
Cleans up this object.
-->

## Easing

<!-- no documentation in the engine source -->

## Easing.CubicBezier

Builds an easing function from the two interior control points of a cubic
Bézier curve, following the CSS easing specification. The curve always runs
from `(0, 0)` to `(1, 1)`; `(X1, Y1)` and `(X2, Y2)` bend it in between. The
shape is exactly what `cubic-bezier(X1, Y1, X2, Y2)` would give you in CSS, so
the control points published for a CSS easing can be pasted straight in.

`X1` and `X2` must both lie in `[0, 1]`. Outside that the curve would double
back and a single progress value would have several answers. The function does
not fail when they do not: it quietly returns the identity instead, so a
mistyped X coordinate shows up as an animation that no longer eases rather than
as an error.

The Y coordinates carry no such restriction, and taking them outside `[0, 1]`
is how you build a curve that overshoots and settles back.

The eased value is found by Newton-Raphson iteration rather than in closed
form, so it is an approximation — close enough for animation, not for anything
that needs the exact root.

<!-- engine text:
Make a cubic bezier interpolation function.
-->

## Easing.Linear

Returns its argument unchanged: progress maps straight to output, so motion
driven by it moves at a constant speed and starts and stops abruptly. It is
the baseline the other curves are departures from.

<!-- engine text:
Linear interpolation function. `Linear` animations move at a constant speed.
-->

## Easing.Ease

The default easing, equivalent to CSS `ease` and to control points
`(0.25, 0.1)` and `(0.25, 1.0)`. Motion begins slowly, accelerates through the
middle and settles at the end, easing out over a longer stretch than it eases
in. That asymmetry is what makes it read as natural rather than mechanical,
and it is the right first choice when nothing else suggests itself.

<!-- engine text:
Ease interpolation function. `Ease` animations start slowly, speed up, then end slowly. The speed of the animation is slightly slower at the end than the start.
-->

## Easing.EaseIn

Equivalent to CSS `ease-in`, control points `(0.42, 0.0)` and `(1.0, 1.0)`.
Starts from rest and accelerates the whole way, arriving at full speed. Suited
to something leaving the screen or a state the viewer is not meant to dwell
on, since the abrupt stop is hidden by whatever follows.

<!-- engine text:
Ease-in interpolation function. `EaseIn` animations start slow, then speed up towards the end.
-->

## Easing.EaseOut

Equivalent to CSS `ease-out`, control points `(0.0, 0.0)` and `(0.58, 1.0)`.
The mirror of `EaseIn`: full speed immediately, then a decelerating approach
to the end. Good for something arriving, where the eye follows it in and wants
to see it come to rest.

<!-- engine text:
Ease-out interpolation function. `EaseOut` animations start fast, then slow down towards the end.
-->

## Easing.EaseInOut

Equivalent to CSS `ease-in-out`, control points `(0.42, 0.0)` and
`(0.58, 1.0)`. Accelerates away and decelerates in, symmetric about the
midpoint. `Ease` does much the same thing with a bias towards the end; this
one is the even-handed version, and the better choice when a movement should
not favour either end.

<!-- engine text:
Ease-in-out interpolation function. `EaseInOut` animations are similar to `Ease` but the start and end animation speed is symmetric.
-->

## enableable

<!-- engine text:
Implemented by classes whose instances can be enabled and disabled.
-->

## enableable.Enable

Puts the object into its enabled state, so that it takes part in simulation
again. Enabling an object that is already enabled has no effect.

<!-- engine text:
Enable this object.
-->

## enableable.Disable

Puts the object into its disabled state. A disabled object keeps its identity
and its data, but stops taking part in simulation until `Enable` is called
again. Disabling an object that is already disabled has no effect.

<!-- engine text:
Disable this object.
-->

## enableable.IsEnabled

<!-- engine text:
Succeeds if the object is enabled, fails if it’s disabled.
-->

## Err

Stops the program. The message is written to the runtime log as an error and
no further Verse code runs in the surrounding content scope, so this is a way
to abandon an impossible situation rather than to report a recoverable one —
for that, use a `<decides>` function and let the caller handle the failure.

Its declared result is `false`, the type with no values, which is the type
system's way of saying the call never comes back.

<!-- engine text:
Halts the Verse runtime with error `Message`.
-->

## event

<!-- engine text:
A *recurring*, successively signaled parametric `event` with a `payload` allowing a simple mechanism to coordinate between concurrent tasks.
-->

## event.Await

<!-- engine text:
Suspends the current task until another task calls `Signal`.
If called during another invocation of `Signal`, the the task will still suspend and resume during the next call to `Signal`.
-->

## event.Signal

Wakes everything waiting on the event, handing each one `Val`.

Tasks suspended in `Await` are resumed first, in the order they suspended, so
the order the waits appear in your code is the order they come back. Each
resumed task runs until it blocks again before the next one is given a turn,
which makes the sequence deterministic but also means one slow waiter delays
the rest.

A task that calls `Await` while this `Signal` is still running joins the next
round rather than this one. Without that rule a task could wake itself in a
loop and the signal would never finish.

Subscribers, on implementations that have them, are invoked only after every
waiting task has been resumed.

<!-- engine text:
Concurrently resumes the tasks that were suspended by `Await` calls before this call to `Signal`.

Tasks are resumed in the order they were suspended. Each task will perform as much work as it can until it encounters a blocking call, whereupon it will transfer control to the next suspended task.
-->

## GetSecondsSinceEpoch

Unix time: seconds elapsed since 1 January 1970 UTC, ignoring leap seconds.

The clock behind it is sampled once at the start of each frame, not on each
call, so every call made during one frame returns the same reading and the
resolution of the whole thing is a frame. Subtracting two readings taken within
one frame gives zero, which makes this the wrong tool for measuring how long a
piece of code took and the right one for asking what time it is.

The reading is also monotonic. If the machine's clock is moved backwards, it
holds its last value until real time catches up, so a duration computed from
two readings is never negative.

<!-- engine text:
Returns the number of seconds since January 1, 1970 UTC, ignoring leap seconds. I.e, this function implements Unix time. This function always returns the same value within the same transaction.
-->

## invalidatable

<!-- engine text:
Implemented by classes whose instances can become invalid at runtime.
-->

## invalidatable.IsValid

<!-- engine text:
Succeeds if this object is still valid.
-->

## listenable

<!-- engine text:
A parametric interface combining `awaitable` and `subscribable`.
-->

## locale

<!-- engine text:
Used for message localization.
-->

## message

<!-- engine text:
A localizable text message.
-->

## Localize

<!-- engine text:
Makes a `string` by localizing `Message` based on the current `locale`.
-->

## Join([]message,message)

<!-- engine text:
Makes a `message` by concatenating `Separator` between the elements of `Messages`.
-->

## Clamp

<!-- engine text:
Constrains the value of `Val` between `A` and `B`. Robustly handles different argument orderings.
Returns the median of `Val`, `A`, and `B`.
-->

## Sqrt

Returns the square root of `X`. Unlike `Ceil` or `Floor`, this cannot fail: a
negative argument yields `NaN`, which then flows through the rest of the
calculation rather than stopping it.

Verse considers `-0.0` and `0.0` to be the same value, so `Sqrt` normalises its
argument before computing and answers `0.0` for both. Plain IEEE-754 would hand
back `-0.0` for the negative zero.

<!-- engine text:
Returns the square root of `X` if `X >= 0.0`.
Returns `NaN` if `X < 0.0`.
-->

## Sin

<!-- engine text:
Returns the sine of `X`, where `X` is interpreted as a value in radians, if `IsFinite[X]`.
Returns `NaN` if `not IsFinite[X]`.
-->

## Cos

<!-- engine text:
Returns the cosine of `X`, where `X` is interpreted as a value in radians, if `IsFinite[X]`.
Returns `NaN` if `not IsFinite[X]`.
-->

## Tan

<!-- engine text:
Returns the tangent of `X`, where `X` is interpreted as a value in radians, if `IsFinite[X]`.
Returns `NaN` if `not IsFinite[X]`.
-->

## ArcSin

<!-- engine text:
Returns the inverse sine (arcsine) of `X` as a value in radians if `-1.0 <= X <= 1.0`.
-->

## ArcCos

<!-- engine text:
Returns the inverse cosine (arccosine) of `X` as a value in radians if `-1.0 <= X <= 1.0`.
-->

## ArcTan(float)

<!-- engine text:
Returns the inverse tangent (arctangent) of `X` as a value in radians such that:`-PiFloat/2.0 <= ArcTan(x) <= PiFloat/2.0`.
-->

## ArcTan(float,float)

<!-- engine text:
Returns the angle in radians at the origin between a ray pointing to `(X, Y)` and the positive `X` axis such that `-PiFloat < ArcTan(Y, X) <= PiFloat`.
Returns `0.0` if `X=0.0 and Y=0.0`.
-->

## Sinh

<!-- engine text:
Returns the hyperbolic sine of `X`.
-->

## Cosh

<!-- engine text:
Returns the hyperbolic cosine of `X`.
-->

## Tanh

<!-- engine text:
Returns the hyperbolic tangent of `X`.
-->

## ArSinh

<!-- engine text:
Returns the inverse hyperbolic sine of `X` if `IsFinite(X)`.
-->

## ArCosh

<!-- engine text:
Returns the inverse hyperbolic cosine of `X` if `1.0 <= X`.
-->

## ArTanh

<!-- engine text:
Returns the inverse hyperbolic tangent of `X` if `IsFinite(X)`.
-->

## Pow

<!-- engine text:
Returns `A` to the power of `B`.
-->

## Quotient

Integer division, rounded so that `Quotient[X, Y] * Y + Mod[X, Y]` always
reconstructs `X` and `Mod` is never negative. That means rounding down when `Y`
is positive and up when `Y` is negative — Euclidean division, not the
truncate-towards-zero division that C and most of its descendants use. The two
agree whenever both operands are positive and part company as soon as one is
not: `Quotient[-7, 2]` is `-4` here, where a truncating language says `-3`.

Fails when `Y` is zero. One case it cannot express at all: the smallest `int`
divided by `-1` is one past the largest, and that raises an integer-overflow
runtime error which stops execution in the surrounding content scope rather
than failing in the ordinary way you could recover from.

<!-- engine text:
Returns the quotient `X/Y` as defined by Euclidean division, i.e.:
 * `Quotient[X/Y] = Floor[X/Y]` when `Y > 0`
 * `Quotient[X/Y] = Ceil[X/Y]` when `Y < 0`
 * `Quotient[X/Y] * Y + Mod[X,Y] = X`
Fails if `Y = 0`.
-->

## Mod

The remainder that pairs with `Quotient`, and the reason to prefer this
division over C's: the result always lies in `[0, Abs(Y))`, never negative.
`Mod[-7, 2]` is `1`, where C's `%` gives `-1`. Wrapping an index or stepping
round a cycle therefore works without the usual correction for negative
inputs.

Fails when `Y` is zero, and raises an integer-overflow runtime error for the
smallest `int` with `Y = -1`, the one pair whose quotient does not fit.

<!-- engine text:
Returns the remainder of `X/Y` as defined by Euclidean division, i.e.:
 * `Mod[X,Y] = X - Quotient(X/Y)*Y`
 * `0 <= Mod[X,Y] < Abs(Y)`
Fails if `Y=0`.
-->

## Exp

<!-- engine text:
Returns the natural exponent of `X`.
-->

## Ln

<!-- engine text:
Returns the natural logarithm of `X`.
-->

## Lerp

Blends between `From` at `Parameter = 0.0` and `To` at `Parameter = 1.0`, and
keeps going outside that range: `2.0` lands as far beyond `To` as `To` is
beyond `From`, and `-1.0` as far before `From`. Nothing clamps the parameter,
so extrapolation is a feature rather than an accident.

It computes `From*(1 - Parameter) + To*Parameter` rather than the cheaper
`From + Parameter*(To - From)`. The two differ only in rounding, but they
differ where it is most visible: this form returns exactly `From` and exactly
`To` at the endpoints, so an animation driven by it starts and finishes on its
keyframes instead of a rounding step away from them.

Expects finite arguments; an infinity or a `NaN` anywhere propagates.

<!-- engine text:
Used to linearly interpolate/extrapolate between `From` (when `Parameter = 0.0`) and `To` (when `Parameter = 1.0`). Expects that all arguments are finite.
Returns `From*(1 - Parameter) + To*Parameter`.
-->

## result

<!-- engine text:
Implemented by classes that provide a result for an operation, which can fail or be successful
-->

## result.GetSuccess

<!-- engine text:
Returns the success data of the specified type.
-->

## result.GetError

<!-- engine text:
Returns the error data of the specified type.
-->

## showable

<!-- engine text:
Implemented by classes whose instances can change visibility to be shown or hidden.
-->

## showable.Show

<!-- engine text:
Set this value to hide or show the class.
-->

## signalable

<!-- engine text:
A parametric interface implemented by events with a `payload` that can be signaled.
Can be used with `awaitable`, `subscribable`, or both (see: `listenable`).
-->

## signalable.Signal

<!-- engine text:
Concurrently resumes the tasks waiting for this event in `awaitable.Await` and synchronously invokes any callbacks added to this event by `subscribable.Subscribe`.
-->

## Join([]string,string)

Concatenates the elements of `Strings` with `Separator` between each adjacent
pair, and none at either end. An empty array gives an empty string and a single
element comes back untouched, so there is no special case to write at the call
site.

Lengths are counted in UTF-8 code units, and the result has an upper bound: if
the pieces together would exceed roughly two billion code units the call raises
a runtime error rather than returning something truncated.

<!-- engine text:
Makes a `string` by concatenating `Separator` between the elements of `Strings`.
-->

## ToString(char)

Wraps a single `char` into a `string` one code unit long.

Because a `char` is one UTF-8 code unit rather than a whole Unicode code point,
that is a complete character only below `0x80`. Hand it a code unit taken from
the middle of a multi-byte character and you get one byte of that sequence,
which means nothing until it is rejoined with its neighbours. Slicing a string
at arbitrary `char` boundaries and converting the pieces back has the same
hazard.

<!-- engine text:
Makes a `string` from `Character`.
-->

## subscribable

<!-- engine text:
A parametric interface implemented by events with a `payload` that can be subscribed to.
Matched with `signalable.`
-->

## subscribable.Subscribe

Registers `Callback` to run each time the event is signalled, and hands back a
`cancelable` whose `Cancel` unregisters it again. Holding on to that object is
the only way to stop the callback short of the whole scope going away.

Do not let one callback depend on another having already run. Nothing orders
subscribers, and the standard event implementation goes further by shuffling
them before every signal, so an accidental dependency will work in testing and
fail later. Each callback is also run in a transaction of its own: one that
fails rolls back its own work only, and the remaining subscribers still run.

<!-- engine text:
Registers `Callback` to be invoked on matching calls to `signable.Signal`.
Returns an unsubscriber object. Call `cancelable.Cancel` on the unsubscriber to unregister `Callback`.
-->

## diagnostic

<!-- engine text:
An opaque diagnostic message that only shows up in diagnostic logs. The format of the diagnostic may change at any time without warning and may not be inspected by Verse code.
-->

## diagnostic.GetDiagnostic

<!-- no documentation in the engine source -->

## ToDiagnostic

<!-- engine text:
Converts any Verse value into an opaque diagnostic message.
-->

## Ceil

<!-- engine text:
Returns the smallest `int` that is greater than or equal to `Val`.
Fails if `not IsFinite(Val)`.
-->

## Floor

<!-- engine text:
Returns the largest `int` that is less than or equal to `Val`.
Fails if `not IsFinite(Val)`.
-->

## Round

<!-- engine text:
Returns `Val` rounded to the nearest `int`. When the fractional part of `Val` is `0.5`, rounds to the nearest *even* `int` (per the IEEE-754 default rounding mode).
Fails if `not IsFinite(Val)`.
-->

## Int

<!-- engine text:
Returns the `int` that equals `Val` without the fractional part.
Fails if `not IsFinite(val)`.
-->

## ToString(float)

<!-- engine text:
Makes a `string` representation of `Val`.
-->

## ToString(int)

<!-- engine text:
Makes a printable `string` representation of `Val`.
-->

## operator'='

<!-- no documentation in the engine source -->

## operator'<>'

<!-- no documentation in the engine source -->

## prefix'-'(int)

<!-- no documentation in the engine source -->

## operator'+'(int,int)

<!-- no documentation in the engine source -->

## operator'-'(int,int)

<!-- no documentation in the engine source -->

## operator'*'(int,int)

<!-- no documentation in the engine source -->

## operator'/'(int,int)

<!-- no documentation in the engine source -->

## operator'+='(ref(int),int)

<!-- no documentation in the engine source -->

## operator'-='(ref(int),int)

<!-- no documentation in the engine source -->

## operator'*='(ref(int),int)

<!-- no documentation in the engine source -->

## Abs(int)

<!-- no documentation in the engine source -->

## BitAnd

<!-- no documentation in the engine source -->

## BitOr

<!-- no documentation in the engine source -->

## BitXor

<!-- no documentation in the engine source -->

## BitNot

<!-- no documentation in the engine source -->

## operator'>'(int,int)

<!-- no documentation in the engine source -->

## operator'>='(int,int)

<!-- no documentation in the engine source -->

## operator'<'(int,int)

<!-- no documentation in the engine source -->

## operator'<='(int,int)

<!-- no documentation in the engine source -->

## MakeRationalFromInt

<!-- no documentation in the engine source -->

## Ceil(rational)

<!-- no documentation in the engine source -->

## Floor(rational)

<!-- no documentation in the engine source -->

## prefix'-'(float)

<!-- no documentation in the engine source -->

## operator'+'(float,float)

<!-- no documentation in the engine source -->

## operator'-'(float,float)

<!-- no documentation in the engine source -->

## operator'*'(float,float)

<!-- no documentation in the engine source -->

## operator'/'(float,float)

<!-- no documentation in the engine source -->

## operator'+='(ref(float),float)

<!-- no documentation in the engine source -->

## operator'-='(ref(float),float)

<!-- no documentation in the engine source -->

## operator'*='(ref(float),float)

<!-- no documentation in the engine source -->

## operator'/='

<!-- no documentation in the engine source -->

## Abs(float)

<!-- no documentation in the engine source -->

## operator'*'(int,float)

<!-- no documentation in the engine source -->

## operator'*'(float,int)

<!-- no documentation in the engine source -->

## operator'>'(float,float)

<!-- no documentation in the engine source -->

## operator'>='(float,float)

<!-- no documentation in the engine source -->

## operator'<'(float,float)

<!-- no documentation in the engine source -->

## operator'<='(float,float)

<!-- no documentation in the engine source -->

## operator'?'(logic)

<!-- no documentation in the engine source -->

## operator'+'([]t,[]t)

<!-- no documentation in the engine source -->

## operator'+='(ref([]t),[]t)

<!-- no documentation in the engine source -->

## operator'array.Length'

<!-- no documentation in the engine source -->

## operator'()'([]t,int)

<!-- no documentation in the engine source -->

## operator'()'(ref([]t,[]u),int)

<!-- no documentation in the engine source -->

## operator'()'(ref(false,[]u),int)

<!-- no documentation in the engine source -->

## operator'()'(ref([t]u,[t]v),t)

<!-- no documentation in the engine source -->

## operator'map.Length'

<!-- no documentation in the engine source -->

## ConcatenateMaps

<!-- no documentation in the engine source -->

## operator'()'(weak_map(t,u),t)

<!-- no documentation in the engine source -->

## operator'()'(ref(weak_map(t,u),weak_map(t,v)),t)

<!-- no documentation in the engine source -->

## operator'()'(ref(false,weak_map(comparable,v)),comparable)

<!-- no documentation in the engine source -->

## weak_map

<!-- no documentation in the engine source -->

## operator'?'(?t)

<!-- no documentation in the engine source -->

## FitsInPlayerMap

<!-- no documentation in the engine source -->

## operator'char.ToCodeUnit'

<!-- no documentation in the engine source -->

## operator'char32.ToCodePoint'

<!-- no documentation in the engine source -->

## operator'char.ToAsciiChar32'

<!-- no documentation in the engine source -->

## operator'char32.ToAsciiString'

<!-- no documentation in the engine source -->

## operator'int.ToChar'

<!-- no documentation in the engine source -->

## operator'int.ToChar32'

<!-- no documentation in the engine source -->

## UnsafeCast

<!-- no documentation in the engine source -->

## PredictsGetDataValue

<!-- no documentation in the engine source -->

## PredictsGetDataRef

<!-- no documentation in the engine source -->

## Inf

<!-- no documentation in the engine source -->

## NaN

<!-- no documentation in the engine source -->

## test_rootobject_native

<!-- no documentation in the engine source -->

## test_phases

<!-- no documentation in the engine source -->

## test_phases.Gameplay

<!-- no documentation in the engine source -->

## test_phases.PrePhysics

<!-- no documentation in the engine source -->

## test_phases.PostPhysics

<!-- no documentation in the engine source -->

## test_phases.Counter

<!-- no documentation in the engine source -->

## test_phase_user

<!-- no documentation in the engine source -->

## test_phase_user.ExecuteCounter

<!-- no documentation in the engine source -->

## test_phase_user.ExecuteTime

<!-- no documentation in the engine source -->

## test_phase_user.EventCounter

<!-- no documentation in the engine source -->

## test_phase_user.EventTime

<!-- no documentation in the engine source -->

## test_phase_user.Connection

<!-- no documentation in the engine source -->

## test_phase_user.Connection2

<!-- no documentation in the engine source -->

## test_phase_user.Counter2

<!-- no documentation in the engine source -->

## test_phase_user.Init

<!-- no documentation in the engine source -->

## test_phase_user.Cancel

<!-- no documentation in the engine source -->

## test_phase_user.OrderAfter

<!-- no documentation in the engine source -->

## test_phase_user.OrderBefore

<!-- no documentation in the engine source -->

## test_phase_user.CountNextExecute

<!-- no documentation in the engine source -->

## test_phase_user.CountNextEvent

<!-- no documentation in the engine source -->

## test_phase_user.OnExecute

<!-- no documentation in the engine source -->

## test_phase_user.OnEvent

<!-- no documentation in the engine source -->

## value

<!-- no documentation in the engine source -->

## value.AsObject

<!-- engine text:
Retrieve an object value or fail if value is not a json object
-->

## value.AsArray

<!-- engine text:
Retrieve an array value or fail if value is not a json array
-->

## value.AsInt

<!-- engine text:
Retrieve an integer value or fail if value is not a json number
-->

## value.AsFloat

<!-- engine text:
Retrieve a float value or fail if value is not a json number
-->

## value.AsString

<!-- engine text:
Retrieve an object value or fail if value is not a string
-->

## value.AsNull

<!-- engine text:
Retrieve an object value or fail if value is not null
-->

## Parse

<!-- engine text:
Parse a JSON string returning a value with its contents
-->

## party_member_info

<!-- engine text:
Per-member info for party members. Can be extended with additional fields in future versions.
-->

## GetLocalParty

<!-- engine text:
Returns the party context for `InPlayer`.
Filters by the simulation_entity owning this player.
A player is always in a party of at least 1 (themselves).
-->

## SortBy

<!-- engine text:
Stably sort `Array` using `Less` where `Less` succeeding indicates `Left` should precede `Right`
-->

## curve_float_base

<!-- no documentation in the engine source -->

## editable_curve

<!-- no documentation in the engine source -->

## editable_curve.Evaluate

<!-- engine text:
Evaluates this float curve at the specified time and returns the result as a float
-->

## debug_draw_duration_policy

<!-- engine text:
Enumerated presets for policies describing a desired draw duration.
-->

## debug_draw_duration_policy.SingleFrame

<!-- no documentation in the engine source -->

## debug_draw_duration_policy.FiniteDuration

<!-- no documentation in the engine source -->

## debug_draw_duration_policy.Persistent

<!-- no documentation in the engine source -->

## debug_draw_channel

<!-- engine text:
debug_draw_channel is the base class used to define debug draw channels.
-->

## debug_draw

<!-- engine text:
debug draw class to draw debug shapes on screen.
-->

## debug_draw.Channel

<!-- engine text:
Channel will be used to clear specific debug draw.
-->

## debug_draw.ShowChannel

<!-- engine text:
Show Debug Draw for the channel for all users.
-->

## debug_draw.HideChannel

<!-- engine text:
Hide Debug Draw for the channel for all users.
-->

## debug_draw.ClearChannel

<!-- engine text:
Clears all debug draw for the channel.
-->

## debug_draw.Clear

<!-- engine text:
Clears all debug draw from this debug_draw instance.
-->

## debug_draw.DrawSphere((/Verse.org/SpatialMath:)vector3,float=DefaultDebugDrawSize,color=DefaultDebugDrawColor,int=12,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a sphere at the named location, and using the provided draw parameters.
-->

## debug_draw.DrawSphere((/UnrealEngine.com/Temporary/SpatialMath:)vector3,float=DefaultDebugDrawSize,color=DefaultDebugDrawColor,int=12,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a sphere at the named location, and using the provided draw parameters.
-->

## debug_draw.DrawBox((/Verse.org/SpatialMath:)vector3,(/Verse.org/SpatialMath:)rotation,(/Verse.org/SpatialMath:)vector3=(/Verse.org/SpatialMath:)vector3{Forward:=DefaultDebugDrawSize,Left:=DefaultDebugDrawSize,Up:=DefaultDebugDrawSize},color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a box at the named location, and using the provided draw parameters
-->

## debug_draw.DrawBox((/UnrealEngine.com/Temporary/SpatialMath:)vector3,(/UnrealEngine.com/Temporary/SpatialMath:)rotation,(/UnrealEngine.com/Temporary/SpatialMath:)vector3=(/UnrealEngine.com/Temporary/SpatialMath:)vector3{X:=DefaultDebugDrawSize,Y:=DefaultDebugDrawSize,Z:=DefaultDebugDrawSize},color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a box at the named location, and using the provided draw parameters
-->

## debug_draw.DrawCapsule((/Verse.org/SpatialMath:)vector3,(/Verse.org/SpatialMath:)rotation,float=DefaultDebugDrawSize,float=25.0,color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a capsule at the named location, and using the provided draw parameters.
-->

## debug_draw.DrawCapsule((/UnrealEngine.com/Temporary/SpatialMath:)vector3,(/UnrealEngine.com/Temporary/SpatialMath:)rotation,float=DefaultDebugDrawSize,float=25.0,color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a capsule at the named location, and using the provided draw parameters.
-->

## debug_draw.DrawCone((/Verse.org/SpatialMath:)vector3,(/Verse.org/SpatialMath:)vector3,float=DefaultDebugDrawSize,int=12,float=PiFloat/4.0,float=PiFloat/4.0,color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a cone at the named location, and using the provided draw parameters.
-->

## debug_draw.DrawCone((/UnrealEngine.com/Temporary/SpatialMath:)vector3,(/UnrealEngine.com/Temporary/SpatialMath:)vector3,float=DefaultDebugDrawSize,int=12,float=PiFloat/4.0,float=PiFloat/4.0,color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a cone at the named location, and using the provided draw parameters.
-->

## debug_draw.DrawCylinder((/Verse.org/SpatialMath:)vector3,(/Verse.org/SpatialMath:)vector3,int=12,float=DefaultDebugDrawSize,color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a cylinder at the named location, and using the provided draw parameters.
-->

## debug_draw.DrawCylinder((/UnrealEngine.com/Temporary/SpatialMath:)vector3,(/UnrealEngine.com/Temporary/SpatialMath:)vector3,int=12,float=DefaultDebugDrawSize,color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a cylinder at the named location, and using the provided draw parameters.
-->

## debug_draw.DrawLine((/Verse.org/SpatialMath:)vector3,(/Verse.org/SpatialMath:)vector3,color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a line from Start to End locations, and using the provided draw parameters.
-->

## debug_draw.DrawLine((/UnrealEngine.com/Temporary/SpatialMath:)vector3,(/UnrealEngine.com/Temporary/SpatialMath:)vector3,color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a line from Start to End locations, and using the provided draw parameters.
-->

## debug_draw.DrawPoint((/Verse.org/SpatialMath:)vector3,color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a point at the named location, and using the provided draw parameters.
-->

## debug_draw.DrawPoint((/UnrealEngine.com/Temporary/SpatialMath:)vector3,color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws a point at the named location, and using the provided draw parameters.
-->

## debug_draw.DrawArrow((/Verse.org/SpatialMath:)vector3,(/Verse.org/SpatialMath:)vector3,float=25.0,color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws an arrow pointing from Start to End locations, and using the provided draw parameters.
-->

## debug_draw.DrawArrow((/UnrealEngine.com/Temporary/SpatialMath:)vector3,(/UnrealEngine.com/Temporary/SpatialMath:)vector3,float=25.0,color=DefaultDebugDrawColor,float=DefaultDebugDrawThickness,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration)

<!-- engine text:
Draws an arrow pointing from Start to End locations, and using the provided draw parameters.
-->

## debug_draw.DrawText(string,(/Verse.org/SpatialMath:)vector3,color=DefaultDebugDrawColor,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration,float=DefaultDebugTextFontScale,logic=false)

<!-- engine text:
Draws a 3D text using the provided draw parameters.
-->

## debug_draw.DrawText(string,(/UnrealEngine.com/Temporary/SpatialMath:)vector3,color=DefaultDebugDrawColor,debug_draw_duration_policy=DefaultDebugDrawDurationPolicy,float=DefaultDebugDrawDuration,float=DefaultDebugTextFontScale,logic=false)

<!-- engine text:
Draws a 3D text using the provided draw parameters.
-->

## log_level

<!-- engine text:
log levels available for various log commands
-->

## log_level.Debug

<!-- no documentation in the engine source -->

## log_level.Verbose

<!-- no documentation in the engine source -->

## log_level.Normal

<!-- no documentation in the engine source -->

## log_level.Warning

<!-- no documentation in the engine source -->

## log_level.Error

<!-- no documentation in the engine source -->

## log_channel

<!-- engine text:
log_channel is the base class used to define log channels. When printing a message to a log, the log channel class name will be prefixed to the output message.
-->

## log

<!-- engine text:
log class to send messages to the default log
-->

## log.Channel

<!-- engine text:
Channel class name will be added as a prefix used when printing the message e.g. '[log_channel]: #Message
-->

## log.DefaultLevel

<!-- engine text:
Sets the default log level of the displayed message. See log_level enum for more info on log levels. Defaults to log_level.Normal.
-->

## log.Print(string,log_level=DefaultLevel)

<!-- engine text:
Print `Message` using the given log level.
-->

## log.Print(diagnostic,log_level=DefaultLevel)

<!-- engine text:
Print `Message` diagnostic using the given log level.
-->

## log.PrintCallStack

<!-- engine text:
Prints the current script call stack using the given log level.
-->

## Rotation_Deprecated:rotation()

<!-- engine text:
An abstract representation of an orientation change in 3d-space.
-->

## MakeRotation

<!-- engine text:
Makes a `rotation` from `Axis` and `AngleRadians` using a left-handed sign convention (e.g. a positive rotation around +Z takes +X to +Y). If `Axis.IsAlmostZero[]`, make the identity rotation.
-->

## Rotation_Deprecated:MakeRotationFromYawPitchRollDegrees(float,float,float)

<!-- engine text:
Makes a `rotation` by applying `YawRightDegrees`, `PitchUpDegrees`, and `RollClockwiseDegrees`, in that order:
 * first a *yaw* about the Z axis with a positive angle indicating a clockwise rotation when viewed from above,
 * then a *pitch* about the new Y axis with a positive angle indicating 'nose up',
 * followed by a *roll* about the new X axis axis with a positive angle indicating a clockwise rotation when viewed along +X.
Note that these conventions differ from `MakeRotation` but match `ApplyYaw`, `ApplyPitch`, and `ApplyRoll`.
-->

## Rotation_Deprecated:IdentityRotation()

<!-- engine text:
Makes the identity `rotation`.
-->

## Rotation_Deprecated:Distance(rotation,rotation)

<!-- engine text:
Returns the 'distance' between `Rotation1` and `Rotation2`. The result will be between:
 * `0.0`, representing equivalent rotations and
 * `1.0` representing rotations which are 180 degrees apart (i.e., the shortest rotation between them is 180 degrees around some axis).
-->

## AngularDistance

<!-- engine text:
Returns the 'smallest angular distance' between `Rotation1` and `Rotation2` in radians.
-->

## ApplyPitch

<!-- engine text:
Makes a `rotation` by applying `PitchUpRadians` of right-handed rotation around the local +Y axis to `InitialRotation`.
-->

## ApplyRoll

<!-- engine text:
Makes a `rotation` by applying `RollClockwiseRadians` of right-handed rotation around the local +X axis to `InitialRotation`.
-->

## ApplyYaw

<!-- engine text:
Makes a `rotation` by applying `YawRightRadians` of left-handed rotation around the local +Z axis to `InitialRotation`.
-->

## ApplyWorldRotationX

<!-- engine text:
Makes a `rotation` by applying `AngleRadians` of left-handed rotation around the world +X axis to `InitialRotation`.
-->

## ApplyWorldRotationY

<!-- engine text:
Makes a `rotation` by applying `AngleRadians` of left-handed rotation around the world +Y axis to `InitialRotation`.
-->

## ApplyWorldRotationZ

<!-- engine text:
Makes a `rotation` by applying `AngleRadians` of left-handed rotation around the world +Z axis to `InitialRotation`.
-->

## RotateBy

<!-- engine text:
Makes a `rotation` by composing `AdditionalRotation` to `InitialRotation`.
-->

## UnrotateBy

<!-- engine text:
Makes a `rotation` by composing the inverse of `RotationToRemove` from `InitialRotation`. such that InitialRotation = RotateBy(UnrotateBy(InitialRotation, RotationToRemove), RotationToRemove). This is equivalent to RotateBy(InitialRotation, InvertRotation(RotationToRemove))
-->

## Rotation_Deprecated:GetYawPitchRollDegrees()

<!-- engine text:
Makes an `[]float` with three elements:
 * *yaw* degrees of `rotation`
 * *pitch* degrees of `rotation`
 * *roll* degrees of `rotation`
using the conventions of `MakeRotationFromYawPitchRollDegrees`.
-->

## Rotation_Deprecated:GetAxis()

<!-- engine text:
Makes a `vector3` from the axis of `rotation`.
If `rotation` is nearly identity, this will return the +X axis. See also `GetAngle`.
-->

## GetAngle

<!-- engine text:
Returns the radians of `rotation` around the axis of `rotation`. See also `GetAxis`.
-->

## MakeShortestRotationBetween(rotation,rotation)

<!-- engine text:
Makes the smallest angular `rotation` from `InitialRotation` to `FinalRotation` such that:
`InitialRotation.RotateBy(MakeShortestRotationBetween(InitialRotation, FinalRotation)) = FinalRotation` and
`MakeShortestRotationBetween(InitialRotation, FinalRotation)?.GetAngle()` is as small as possible.
-->

## Rotation_Deprecated:MakeShortestRotationBetween(vector3,vector3)

<!-- engine text:
Makes the smallest angular `rotation` from `InitialVector` to `FinalVector` such that:
`InitialVector.RotateBy(MakeShortestRotationBetween(InitialVector, Vector)) = FinalVector` and
`MakeShortestRotationBetween(InitialVector, FinalVector)?.GetAngle()` is as small as possible.
-->

## MakeComponentWiseDeltaRotation

<!-- engine text:
Makes a new `rotation` from the component wise subtraction of the Euler angle components in `RotationA` by 
the Euler angle components in `RotationB` and ensures the returned value is normalized.
-->

## Rotation_Deprecated:Slerp(rotation,rotation,float)

<!-- engine text:
Used to perform spherical linear interpolation between `From` (when `Parameter = 0.0`) and `To` (when `Parameter = 1.0`). Expects that `0.0 <= Parameter <= 1.0`.
-->

## RotateVector

<!-- engine text:
Makes a `vector3` by applying `Rotation` to `Vector`.
-->

## UnrotateVector

<!-- engine text:
Makes a `vector3` by applying the inverse of `Rotation` to `Vector`.
-->

## Rotation_Deprecated:Invert()

<!-- engine text:
Makes a `rotation` by inverting `Rotation` such that `ApplyRotation(Rotation, Rotation.Invert())) = IdentityRotation`.
-->

## Rotation_Deprecated:IsFinite()

<!-- engine text:
Returns `Rotation` if it does not contain `NaN`, `Inf` or `-Inf`.
-->

## Transform_Deprecated:transform()

<!-- engine text:
A combination of scale, rotation, and translation, applied in that order.
-->

## Transform_Deprecated:transform.Scale()

<!-- engine text:
The scale of this `transform`.
-->

## Transform_Deprecated:transform.Rotation()

<!-- engine text:
The rotation of this `transform`.
-->

## Transform_Deprecated:transform.Translation()

<!-- engine text:
The location of this `transform`.
-->

## vector2

<!-- engine text:
2-dimensional vector with `float` components.
-->

## vector2.X

<!-- no documentation in the engine source -->

## vector2.Y

<!-- no documentation in the engine source -->

## vector2i

<!-- engine text:
2-dimensional vector with `int` components.
-->

## vector2i.X

<!-- no documentation in the engine source -->

## vector2i.Y

<!-- no documentation in the engine source -->

## Vector3_Deprecated:vector3()

<!-- engine text:
3-dimensional vector with `float` components.
-->

## vector3.X

<!-- no documentation in the engine source -->

## vector3.Y

<!-- no documentation in the engine source -->

## vector3.Z

<!-- no documentation in the engine source -->

## modifier

<!-- engine text:
Implemented by classes to provide a method for modification evaluation.
-->

## modifier.Evaluate

<!-- no documentation in the engine source -->

## modifier_stack

<!-- engine text:
Modifier stacks provide an ordered application of modifiers.
-->

## modifier_stack.Evaluate

<!-- engine text:
Returns a t which is the input evaluated against each modifier in the stack, executed in position order.
-->

## modifier_stack.AddModifier

<!-- engine text:
Insert a Modifier at Position in the stack.
If multiple modifiers are added at the same position, they are applied such that the most recently added is the last evaluated.
Returns a cancelable which can be used to remove Modifier from the stack.
-->

## modifier_stack.FirstPosition

<!-- engine text:
Returns the current first position in the stack. If the stack is empty, this is the default position (0).
-->

## modifier_stack.LastPosition

<!-- engine text:
Returns the current last position in the stack. If the stack is empty, this is the default position (0).
-->

## sticky_event

<!-- engine text:
---------------------------------------------------------------------------------------- A *persistent* event state allowing a simple mechanism to coordinate between concurrent tasks: - several tasks wait on the event - another task sets the event signal state and resumes any waiting tasks See `event` for a version of an event that is designed to be successively signaled and stateless.
-->

## sticky_event.IsSignaled

<!-- engine text:
Returns true if the event is in a signaled state. [There will also be no `Await()` calls pending since they are only suspended when not in a signaled state.] Call `Signal()` to set the signaled state and `ClearSignal()` to clear it. Note: The signal state may be cleared while in the middle of a call to `Signal()` as `Await()` tasks are being resumed.
-->

## sticky_event.ClearSignal

<!-- engine text:
Clears the signaled state if it is set. Once the signaled state is clear any new calls to `Await()` will suspend/block until the event is signaled again. If the event is already not in a signaled state then do nothing. Note: This can be called while in the middle of a call to `Signal()` in a resuming `Await()` task so that new calls to `Await()` will suspend.
-->

## sticky_event.Await

<!-- engine text:
Suspends/blocks the current task until this event is signaled by having another task call `Signal()`. If this event is already in a signaled state then this coroutine completes immediately.
-->

## sticky_event.Signal

<!-- engine text:
The Await() calls' tasks are resumed in the order that they were made and each task will do as much atomic work as it can until it encounters a block/yield in the form of a call to a coroutine/async call whereupon it will cooperatively transfer control to the next Await() task until all the tasks are resumed. If this is called while the signaled state is already set or while in the middle of of a `Signal()` call resuming suspended Await() tasks, it asserts. Call `ClearSignal()` to clear the signaled state and allow calls to `Await()` suspend until signaled again rather than return immediately. The resumed Await() tasks can have more calls to `Await()` in the middle of this call to `Signal()` before they yield. Any such new Await() calls will return immediately() if this event is still in a signaled state. If it is desired to have new Await() calls to suspend until the next signal then a call to `ClearSignal()` must be made in one or more resumed tasks before any new calls to Await() are made (or use the `event` instead).
-->

## member_info_interface

<!-- engine text:
Interface that defines a class as being usable as member info in an agent group
-->

## agent_group_interface

<!-- engine text:
Interface that defines a class as providing an agent group.
-->

## agent_group_interface.GetMemberMap

<!-- engine text:
Get the members of this agent group with their member info
-->

## agent_group_interface.AddMemberEvent

<!-- engine text:
Signalled whenever an agent successfully joins this agent group.Passes in the agent that joined along with their member_info.
-->

## agent_group_interface.RemoveMemberEvent

<!-- engine text:
Signalled whenever an agent successfully leaves this agent group.Passes in the agent that left along with their member_info.
-->

## agent_group_interface.MemberInfoChangeEvent

<!-- engine text:
Signalled whenever the MemberInfo class is re-instantiated for a given agent.Passes in the agent that was updated along with their new member_info.
-->

## agent_group

<!-- engine text:
An agent group is defined as a set of agents that share a common ownership.This class stores agents and specific information about each member via the member_info type provided.
-->

## agent_group.GetMemberMap

<!-- engine text:
Get the members of this agent group with their member info
-->

## agent_group.AddMember

<!-- engine text:
Attempt to add the given agent to this agent group.This function returns a result that will either succeed or return an error.
-->

## agent_group.RemoveMember

<!-- engine text:
Attempt to remove the given agent from this agent group.This function returns a result that will either succeed or return an error.
-->

## agent_group.AddMemberEvent

<!-- engine text:
Signalled whenever an agent successfully joins this agent group.Passes in the agent that joined along with their member_info.
-->

## agent_group.RemoveMemberEvent

<!-- engine text:
Signalled whenever an agent successfully leaves this agent group.Passes in the agent that left along with their member_info.
-->

## agent_group.MemberInfoChangeEvent

<!-- engine text:
Signalled whenever the MemberInfo class is re-instantiated for a given agent.Passes in the agent that was updated along with their new member_info.
-->

## add_member_error

<!-- engine text:
Base class for all errors returned from agent_group.AddMember.
-->

## remove_member_error

<!-- engine text:
Base class for all errors returned from agent_group.RemoveMember.
-->

## asset_base

<!-- no documentation in the engine source -->

## animation_sequence

<!-- no documentation in the engine source -->

## material

<!-- no documentation in the engine source -->

## material.OnPropertyChangedFromVerse

<!-- no documentation in the engine source -->

## particle_system

<!-- no documentation in the engine source -->

## mesh

<!-- no documentation in the engine source -->

## sound_wave

<!-- no documentation in the engine source -->

## texture

<!-- no documentation in the engine source -->

## texture.Height

<!-- no documentation in the engine source -->

## texture.Width

<!-- no documentation in the engine source -->

## input_action

<!-- no documentation in the engine source -->

## input_mapping

<!-- no documentation in the engine source -->

## has_icon

<!-- engine text:
Interface that provides an icon.
-->

## has_icon.Icon

<!-- engine text:
A texture used as the 2D visual representation of this entity (e.g. an icon or portrait).
-->

## parameterized_property_interface_base

<!-- no documentation in the engine source -->

## task

<!-- engine text:
---------------------------------------------------------------------------------------- A stateful, asynchronous future used to represent the invoked context for an async expression (such as an invoked coroutine) executing concurrently in a cooperatively multitasked environment over time - having a lifespan of one or more updates / ticks / frames of the Verse runtime system before it completes. A task is usually obtained from the result of a unstructured concurrency `spawn` expression.
-->

## task.Await

<!-- engine text:
Wait until the current task has completed - this essentially anchors this task and adds a caller for it to return to at this call point. Notes: - Multiple `Await()` calls can be made on this one same task - essentially giving it multiple callers to return to. - The order that `Await()` calls are accumulated is important - they are woken in first in first out (FIFO) order. - If this task has already completed, then this coroutine completes immediately. - If this task is canceled, this `Await()` coroutine will not be notified and will appear to take forever. - If this `Await()` task is canceled then it will automatically unregister itself to be woken up from this task. - This task is not registered as a subtask to the `Await()` task so if the `Await()` task or any of its calling tasks are canceled, this task will *not* also be canceled as with a standard subtask of a caller.
-->

## GetRandomFloat

<!-- engine text:
Returns a uniformly distributed, cryptographically-secure random `float` between `Low` and `High`, inclusive. (`Low` and `High` can be out of order.)
-->

## GetRandomInt

<!-- engine text:
Returns a uniformly distributed, cryptographically-secure random `int` between `Low` and `High`, inclusive. (`Low` and `High` can be out of order.)
-->

## capsule_light_component

<!-- engine text:
A `capsule_light_component` emits light in all directions into the scene from a capsule shaped source with a specified radius and length. A radius and length of 0 makes it a point light. You can use these
to simulate any kind of light sources that emit in all directions and need an elongated source shape, such as a long light bulb.
-->

## capsule_light_component.OnAddedToSceneInternal

<!-- engine text:
component interface
-->

## capsule_light_component.Intensity

<!-- engine text:
Set the visible light intensity emitted in SI unit Candela.
Specified before ColorFilter (which multiplies each color component after the intensity calculation and can change the effective intensity of the light).
-->

## capsule_light_component.AttenuationRadius

<!-- engine text:
The bounds of the light's visible influence. This clamping of the light's influence is not physically correct but very important for performance,
larger lights cost more. The light falloff is based on Inverse Square law. Towards the tail end of the AttenuationRadius,
there is an additional smoothing factor to fade out the light contribution to 0 to avoid a hard cutoff.
-->

## capsule_light_component.SourceRadius

<!-- engine text:
Radius of the source capsule shape in centimeters around the local Z axis. Note that light shapes which intersect shadow casting geometry can cause shadowing artifacts.
-->

## capsule_light_component.SourceLength

<!-- engine text:
Length of the source capsule shape in centimeters along the local Z axis. Note that light shapes which intersect shadow casting geometry can cause shadowing artifacts.
-->

## capsule_light_component.OnRep__Intensity

<!-- no documentation in the engine source -->

## capsule_light_component.OnRep__AttenuationRadius

<!-- no documentation in the engine source -->

## capsule_light_component.OnRep__SourceRadius

<!-- no documentation in the engine source -->

## capsule_light_component.OnRep__SourceLength

<!-- no documentation in the engine source -->

## collision_interaction

<!-- engine text:
Specifies how a collision volume pair should interact. See collision_profile.
-->

## collision_interaction.Ignore

<!-- engine text:
The pair will not be detected by Overlap and Sweep queries. The pair will not collide in the physics simulation.
-->

## collision_interaction.Overlap

<!-- engine text:
The pair will be detected by Overlap and Sweep queries. The pair will not collide in the physics simulation.
-->

## collision_interaction.Block

<!-- engine text:
The pair will be detected by Overlap and Sweep queries. The pair will collide in the physics simulation.
-->

## collision_channel

<!-- engine text:
Every volume has a collision channel as part of its collision_profile. It is used to determine how two volumes interact. See collision_profile.
-->

## collision_profile

<!-- engine text:
A collision profile determines how a volume interacts with other volumes for Overlap queries, Sweep queries, and physics simulation. When two volumes are being tested to see how they interact, the algorithm looks like this:
   GetInteraction(A:collision_profile, B:collision_profile):collision_interaction = 
       InteractionA = B.GetChannelInteraction(A.Channel) 
       InteractionB = A.GetChannelInteraction(B.Channel) 
       return Min(InteractionA, InteractionB) 

-->

## collision_profile.Channel

<!-- engine text:
The collision channel for the owning object.
-->

## collision_profile.GetChannelInteraction

<!-- engine text:
How the owning object should interact with other objects.GetChannelInteraction is a function which maps a collision_channel to a collision_interaction. It can be implemented as an simple sequence of if statements. For example, to block all channels except camera:
    BlockAllIgnoreCamera(Channel:collision_channel)<computes>:collision_interaction =
        if (CollisionChannels.camera[Channel]):
            return collision_interaction.Ignore
        return collision_interaction.Block
    MyProfile<public>:collision_profile = MakeCollisionProfile(CollisionChannels.dynamic, BlockAllIgnoreCamera)
-->

## CollisionChannels

<!-- engine text:
The set of built-in collision_channels. This is a closed set for now.
-->

## CollisionChannels.stationary

<!-- no documentation in the engine source -->

## CollisionChannels.dynamic

<!-- no documentation in the engine source -->

## CollisionChannels.avatar

<!-- no documentation in the engine source -->

## CollisionChannels.visibility

<!-- no documentation in the engine source -->

## CollisionChannels.camera

<!-- no documentation in the engine source -->

## CollisionChannels.physics

<!-- no documentation in the engine source -->

## overlap_hit

<!-- engine text:
The results of an overlap query. See entity.FindOverlapHits(). We will get one overlap_hit for each intersection of any volume in SourceVolumes with any other volume.
-->

## overlap_hit.SourceComponent

<!-- engine text:
The source component and volume (query input). For compound inputs (like an entity hierarchy) this will be a component/volume in that hierarchy. The SourceTransform is the transform of SourceVolume used for the overlap test. For single volume inputs like a sphere, the Source volume and transform are just the inputs to the overlap test, and the component is false.
-->

## overlap_hit.SourceVolume

<!-- engine text:
The source volume (query input)
-->

## overlap_hit.SourceGlobalTransform

<!-- engine text:
The source volume transform
-->

## overlap_hit.TargetComponent

<!-- engine text:
The component that was hit by SourceVolume
-->

## overlap_hit.TargetVolume

<!-- engine text:
The volume that was hit by SourceVolume
-->

## overlap_hit.SourceMeshHit

<!-- engine text:
Hit data for the source mesh
-->

## overlap_hit.TargetMeshHit

<!-- engine text:
Hit data for the target mesh
-->

## sweep_hit

<!-- engine text:
The results of a sweep query. See entity.FindSweepHits(). We will get one sweep_hit for each intersection of any volume in SourceVolumes with any other volume.
-->

## sweep_hit.SourceComponent

<!-- engine text:
The source component and volume (query input). For compound inputs (like an entity hierarchy) this will be a component/volume in that hierarchy. The SourceGlobalTransform is the transform of SourceVolume at the start of the sweep. For single volume inputs like a sphere, the volume and transform are just the inputs to the sweep, and the component is false.
-->

## sweep_hit.SourceVolume

<!-- engine text:
The source volume (query input).
-->

## sweep_hit.SourceStartGlobalTransform

<!-- engine text:
The source volume transform at the start of the sweep.
-->

## sweep_hit.SourceHitTranslation

<!-- engine text:
The world-space translation (relative to SourceStartGlobalTransform) of SourceVolume when it touches TargetVolume.
-->

## sweep_hit.TargetComponent

<!-- engine text:
The component that was hit by SourceVolume.
-->

## sweep_hit.TargetVolume

<!-- engine text:
The volume that was hit by SourceVolume.
-->

## sweep_hit.SourceMeshHit

<!-- engine text:
Hit data for the source mesh
-->

## sweep_hit.TargetMeshHit

<!-- engine text:
Hit data for the target mesh
-->

## sweep_hit.SourceHitDistance

<!-- engine text:
The Distance along the sweep at which SourceVolume touches TargetVolume.
-->

## sweep_hit.ContactPosition

<!-- engine text:
The point of contact between SourceVolume and TargetVolume.
-->

## sweep_hit.ContactNormal

<!-- engine text:
The normal on TargetVolume at the HitPosition.
-->

## sweep_hit.ContactFaceNormal

<!-- engine text:
If TargetVolume is a polygonal object (mesh, convex hull, etc.) and the contact point is on an edge or vertex, this is the most-opposing face normal of the faces that share that edge or vertex. Otherwise it is the same as HitNormal.
-->

## contact_point

<!-- no documentation in the engine source -->

## contact_point.ContactPosition

<!-- no documentation in the engine source -->

## contact_point.ContactNormal

<!-- no documentation in the engine source -->

## contact_point.ContactImpulse

<!-- no documentation in the engine source -->

## contact_point.ContactDepth

<!-- no documentation in the engine source -->

## collision_hit

<!-- engine text:
The result of a collision in the physics engine. See has_collision::GetCollisionEvent()
-->

## collision_hit.SourceMeshHit

<!-- engine text:
Hit data for the source mesh
-->

## collision_hit.TargetMeshHit

<!-- engine text:
Hit data for the target mesh
-->

## collision_hit.ContactPoints

<!-- engine text:
Array of physical contact points between the two meshes/mesh_parts.
-->

## collision_volume

<!-- engine text:
Collision Volumes represent the collision shapes of meshes. They can be detected by Overlap and Sweep queries and generate collisions in the physics simulation.
-->

## collision_volume.Collidable

<!-- engine text:
Enable/disable collision on this volume.
-->

## collision_volume.Queryable

<!-- engine text:
Enable/disable spatial queries against this volume.
-->

## collision_volume.GetLocalTransform

<!-- engine text:
Get the transform of this volume in the space of its owner (usually a component on an entity)
-->

## collision_volume.SetLocalTransform

<!-- engine text:
Set the transform of this volume in the space of its owner (usually a component on an entity)
-->

## collision_volume.CollidableInternal

<!-- engine text:
Begin Collidable implementation CollidableToolTip<private><localizes>:message = "Enable/disable collision on this volume." ToolTip := CollidableToolTip
-->

## collision_volume.GetCollidable

<!-- no documentation in the engine source -->

## collision_volume.SetCollidable

<!-- no documentation in the engine source -->

## collision_volume.OnRep_CollidableInternal

<!-- no documentation in the engine source -->

## collision_volume.OnCollidableModified

<!-- no documentation in the engine source -->

## collision_volume.QueryableInternal

<!-- engine text:
Begin Queryable implementation QueryableToolTip<private><localizes>:message = "Enable/disable spatial queries against this volume." ToolTip := QueryableToolTip
-->

## collision_volume.GetQueryable

<!-- no documentation in the engine source -->

## collision_volume.SetQueryable

<!-- no documentation in the engine source -->

## collision_volume.OnRep_QueryableInternal

<!-- no documentation in the engine source -->

## collision_volume.OnQueryableModified

<!-- no documentation in the engine source -->

## collision_volume.LocalTransformInternal

<!-- engine text:
Begin LocalTransform implementation LocalTransformToolTip<private><localizes>:message = "The transform of this volume relative to its owner." ToolTip := LocalTransformToolTip
-->

## collision_volume.OnRep_LocalTransformInternal

<!-- no documentation in the engine source -->

## collision_volume.OnLocalTransformModified

<!-- no documentation in the engine source -->

## collision_element

<!-- engine text:
Base class for collision_volumes that consist of a single volume with a single collision_profile and collision_material for the whole volume. This covers most volume types used in queries and physics, except compound types like a mesh. A query will always return an element rather than a general volume. For example when colliding with a mesh, the element will be a collision_triangle, which is a collision_element and has a single material, rather than a collision_triangle_mesh, which is not an element and has a material palette.
-->

## collision_element.CollisionProfile

<!-- engine text:
The collision_profile for this volume.
-->

## collision_element.GetCollisionProfile

<!-- no documentation in the engine source -->

## collision_element.SetCollisionProfile

<!-- no documentation in the engine source -->

## collision_element.OnRep_CollisionProfileInternal

<!-- no documentation in the engine source -->

## collision_element.OnCollisionProfileModified

<!-- no documentation in the engine source -->

## collision_capsule

<!-- engine text:
A collision capsule aligned along the Z axis.
-->

## collision_capsule.Radius

<!-- engine text:
The radius of the capsule
-->

## collision_capsule.Length

<!-- engine text:
The length of the capsule's cylindrical section (distance between the two end cap centers)
-->

## collision_capsule.GetRadius

<!-- no documentation in the engine source -->

## collision_capsule.SetRadius

<!-- no documentation in the engine source -->

## collision_capsule.GetRadiusInternal

<!-- no documentation in the engine source -->

## collision_capsule.SetRadiusInternal

<!-- no documentation in the engine source -->

## collision_capsule.OnRep_RadiusInternal

<!-- no documentation in the engine source -->

## collision_capsule.OnRadiusModified

<!-- no documentation in the engine source -->

## collision_capsule.GetLength

<!-- no documentation in the engine source -->

## collision_capsule.SetLength

<!-- no documentation in the engine source -->

## collision_capsule.GetLengthInternal

<!-- no documentation in the engine source -->

## collision_capsule.SetLengthInternal

<!-- no documentation in the engine source -->

## collision_capsule.OnRep_LengthInternal

<!-- no documentation in the engine source -->

## collision_capsule.OnLengthModified

<!-- no documentation in the engine source -->

## collision_sphere

<!-- engine text:
A collision sphere.
-->

## collision_sphere.Radius

<!-- engine text:
The radius of the sphere
-->

## collision_sphere.GetRadius

<!-- no documentation in the engine source -->

## collision_sphere.SetRadius

<!-- no documentation in the engine source -->

## collision_sphere.GetRadiusInternal

<!-- no documentation in the engine source -->

## collision_sphere.SetRadiusInternal

<!-- no documentation in the engine source -->

## collision_sphere.OnRep_RadiusInternal

<!-- no documentation in the engine source -->

## collision_sphere.OnRadiusModified

<!-- no documentation in the engine source -->

## collision_point

<!-- engine text:
A collision point.
-->

## collision_box

<!-- engine text:
An axis-aligned collision box.
-->

## collision_box.Extents

<!-- no documentation in the engine source -->

## collision_box.ExtentsInternal

<!-- engine text:
Begin Extents implementation ExtentsToolTip<private><localizes>:message = "The box extents (half the size)." ToolTip := ExtentsToolTip
-->

## collision_box.GetExtents(accessor)

<!-- no documentation in the engine source -->

## collision_box.GetExtents(accessor,[]char)

<!-- no documentation in the engine source -->

## collision_box.SetExtents(accessor,vector3)

<!-- no documentation in the engine source -->

## collision_box.SetExtents(accessor,[]char,float)

<!-- no documentation in the engine source -->

## collision_box.OnRep_ExtentsInternal

<!-- no documentation in the engine source -->

## collision_box.OnExtentsModified

<!-- no documentation in the engine source -->

## directional_light_component

<!-- engine text:
A `directional_light_component` simulates light that is being emitted from a source that is infinitely far away. This means that all shadows cast by this light will be parallel, making this the ideal choice for simulating sunlight.
-->

## directional_light_component.OnAddedToSceneInternal

<!-- engine text:
component interface
-->

## directional_light_component.Illuminance

<!-- engine text:
Intensity of the light hitting the surface. In Lux (Lumen per square meter).
-->

## directional_light_component.SourceAngleDegrees

<!-- engine text:
Angle subtended by light source in degrees (also known as angular diameter). Defaults to 0.5357 which is the angle for our sun.
-->

## directional_light_component.OnRep__Illuminance

<!-- no documentation in the engine source -->

## directional_light_component.OnRep__SourceAngleDegrees

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.MinValue()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.MaxValue()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.MinValue()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.MaxValue()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.MinValue()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.MaxValue()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.MinValue()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.MaxValue()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.MinValue()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.MaxValue()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## DirectionalLightComponent:directional_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## has_collision

<!-- no documentation in the engine source -->

## has_collision.GetCollidable

<!-- engine text:
True if any associated physics objects are physically collidable
-->

## has_collision.SetCollidable

<!-- engine text:
Set the physics collidability for all associated physics objects
-->

## has_collision.GetBeginCollisionEvent

<!-- engine text:
Temp workaround: Once <native> can be written in interfaces, use the listenable that lives on the interfaces directly.
-->

## has_collision.GetEndCollisionEvent

<!-- engine text:
Temp workaround: Once <native> can be written in interfaces, use the listenable that lives on the interfaces directly.
-->

## has_collision.GetBeginOverlapEvent

<!-- engine text:
Temp workaround: Once <native> can be written in interfaces, use the listenable that lives on the interfaces directly.
-->

## has_collision.GetEndOverlapEvent

<!-- engine text:
Temp workaround: Once <native> can be written in interfaces, use the listenable that lives on the interfaces directly.
-->

## has_dynamics

<!-- no documentation in the engine source -->

## has_dynamics.GetDynamic

<!-- engine text:
By default, true if any associated physics objects are physically simulated
-->

## has_dynamics.SetDynamic

<!-- engine text:
By default, set the dynamic state for all associated physics objects
-->

## has_dynamics.ApplyLinearImpulse

<!-- no documentation in the engine source -->

## has_dynamics.ApplyAngularImpulse

<!-- no documentation in the engine source -->

## has_dynamics.GetLinearVelocity

<!-- no documentation in the engine source -->

## has_dynamics.SetLinearVelocity

<!-- no documentation in the engine source -->

## has_dynamics.GetAngularVelocity

<!-- no documentation in the engine source -->

## has_dynamics.SetAngularVelocity

<!-- no documentation in the engine source -->

## has_dynamics.ApplyForce

<!-- no documentation in the engine source -->

## has_dynamics.ApplyTorque

<!-- no documentation in the engine source -->

## has_dynamics.GetMass

<!-- no documentation in the engine source -->

## KeyframedMovement

<!-- engine text:
Animate Scene Graph entities with keyframes.
-->

## KeyframedMovement.easing_function

<!-- engine text:
Base class for an animation easing function.
-->

## KeyframedMovement.easing_function.Evaluate

<!-- no documentation in the engine source -->

## KeyframedMovement.cubic_bezier_easing_function

<!-- engine text:
Cubic bezier easing function. See CubicBezierEasingFunctions for some basic easing values.
-->

## KeyframedMovement.cubic_bezier_easing_function.X0

<!-- no documentation in the engine source -->

## KeyframedMovement.cubic_bezier_easing_function.Y0

<!-- no documentation in the engine source -->

## KeyframedMovement.cubic_bezier_easing_function.X1

<!-- no documentation in the engine source -->

## KeyframedMovement.cubic_bezier_easing_function.Y1

<!-- no documentation in the engine source -->

## KeyframedMovement.cubic_bezier_easing_function.Evaluate

<!-- no documentation in the engine source -->

## KeyframedMovement.linear_easing_function

<!-- engine text:
`Linear` animations move at a constant speed.
-->

## KeyframedMovement.linear_easing_function.X0

<!-- no documentation in the engine source -->

## KeyframedMovement.linear_easing_function.Y0

<!-- no documentation in the engine source -->

## KeyframedMovement.linear_easing_function.X1

<!-- no documentation in the engine source -->

## KeyframedMovement.linear_easing_function.Y1

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_cubic_bezier_easing_function

<!-- engine text:
`Ease` animations start slowly, speed up, then end slowly. The speed of the animation is slightly slower at the end than the start.
-->

## KeyframedMovement.ease_cubic_bezier_easing_function.X0

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_cubic_bezier_easing_function.Y0

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_cubic_bezier_easing_function.X1

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_cubic_bezier_easing_function.Y1

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_in_cubic_bezier_easing_function

<!-- engine text:
`EaseIn` animations start slow, then speed up towards the end.
-->

## KeyframedMovement.ease_in_cubic_bezier_easing_function.X0

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_in_cubic_bezier_easing_function.Y0

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_in_cubic_bezier_easing_function.X1

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_in_cubic_bezier_easing_function.Y1

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_out_cubic_bezier_easing_function

<!-- engine text:
`EaseOut` animations start fast, then slow down towards the end.
-->

## KeyframedMovement.ease_out_cubic_bezier_easing_function.X0

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_out_cubic_bezier_easing_function.Y0

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_out_cubic_bezier_easing_function.X1

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_out_cubic_bezier_easing_function.Y1

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_in_out_cubic_bezier_easing_function

<!-- engine text:
`EaseInOut` animations are similar to `Ease` but the start and end animation speed is symmetric.
-->

## KeyframedMovement.ease_in_out_cubic_bezier_easing_function.X0

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_in_out_cubic_bezier_easing_function.Y0

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_in_out_cubic_bezier_easing_function.X1

<!-- no documentation in the engine source -->

## KeyframedMovement.ease_in_out_cubic_bezier_easing_function.Y1

<!-- no documentation in the engine source -->

## KeyframedMovement.keyframed_movement_playback_mode

<!-- engine text:
Controls how the animation plays back.
-->

## KeyframedMovement.oneshot_keyframed_movement_playback_mode

<!-- engine text:
Play once and stop.
-->

## KeyframedMovement.loop_keyframed_movement_playback_mode

<!-- engine text:
Play once and repeat indefinitely.
-->

## KeyframedMovement.pingpong_keyframed_movement_playback_mode

<!-- engine text:
Play continuously reversing direction at each end.
-->

## KeyframedMovement.keyframed_movement_delta

<!-- engine text:
Represents a change in pose and scale over a duration.
-->

## KeyframedMovement.keyframed_movement_delta.Transform

<!-- engine text:
Represents a change in the transform relative to the previous keyframe or initial animation position. Translation and Scale are interpreted additively.
-->

## KeyframedMovement.keyframed_movement_delta.MinValue

<!-- engine text:
Duration of this keyframe in seconds.
-->

## KeyframedMovement.keyframed_movement_delta.Duration

<!-- no documentation in the engine source -->

## KeyframedMovement.keyframed_movement_delta.Easing

<!-- engine text:
Easing function to use for playback.
-->

## KeyframedMovement.keyframed_movement_component

<!-- engine text:
Provides teleportation and simple keyframe-based animation for an entity. Animations play back in the Pre-Physics tick phase. When animating an entity with a parent_constraint, animation will be relative to the parent entity.
-->

## KeyframedMovement.keyframed_movement_component.Pause

<!-- engine text:
Pause movement. Subsequently calling Play() will resume from the point in the animation when it was paused.
-->

## KeyframedMovement.keyframed_movement_component.Play

<!-- engine text:
Begin or resume playback.
-->

## KeyframedMovement.keyframed_movement_component.Stop()

<!-- engine text:
Stop and reset transform to the initial state. Subsequently calling Play() will begin the animation anew.
-->

## KeyframedMovement.keyframed_movement_component.Stop(float)

<!-- engine text:
Stop and reset transform to the initial state. Subsequently calling Play() will begin the animation anew.
-->

## KeyframedMovement.keyframed_movement_component.StoppedEvent

<!-- engine text:
Get the event that fires when the animation is Stopped.
-->

## KeyframedMovement.keyframed_movement_component.PlayedEvent

<!-- engine text:
Get the event that fires when the animation begins or resumes Playing.
-->

## KeyframedMovement.keyframed_movement_component.PausedEvent

<!-- engine text:
Get the event that fires when the animation is Paused.
-->

## KeyframedMovement.keyframed_movement_component.IsPlaying

<!-- engine text:
Is the animation currently playing?
-->

## KeyframedMovement.keyframed_movement_component.IsPaused

<!-- engine text:
Is the animation paused?
-->

## KeyframedMovement.keyframed_movement_component.Duration

<!-- engine text:
Gets the duration in seconds this keyframed movement will take. Fails if a fixed duration is not known (ex: looping animations).
-->

## KeyframedMovement.keyframed_movement_component.FinishedEvent

<!-- engine text:
Get the event that fires when the animations ends, failing if the animation is of infinite duration
-->

## KeyframedMovement.keyframed_movement_component.SetKeyframes

<!-- engine text:
Stop any ongoing animation, sets the animation path and rebases it relative to the actor's current transform. Does not start playing until you call Play().
-->

## KeyframedMovement.keyframed_movement_component.HasValidAnimation

<!-- engine text:
Is there a valid set of playable keyframes?
-->

## KeyframedMovement.keyframed_movement_component.KeyframeReachedEvent

<!-- engine text:
Signaled when any keyframe is reached. (Keyframe:int, IsReversed:logic).
-->

## KeyframedMovement.keyframed_movement_component.OnInitializedInternal

<!-- engine text:
component interface
-->

## KeyframedMovement.keyframed_movement_component.OnEndSimulationInternal

<!-- no documentation in the engine source -->

## light_component

<!-- engine text:
Base class for light components in the SceneGraph.

Dependencies:
  * `transform_component` on the entity positions the light.

Examples of components implementing `light_component`:
  * `directional_light_component`
  * `capsule_light_component`
  * `sphere_light_component`
  * `rect_light_component`
  * `spot_light_component`
-->

## light_component.OnInitializedInternal

<!-- engine text:
component interface
-->

## light_component.OnUninitializingInternal

<!-- no documentation in the engine source -->

## light_component.OnAddedToSceneInternal

<!-- no documentation in the engine source -->

## light_component.OnRemovingFromSceneInternal

<!-- no documentation in the engine source -->

## light_component.CastShadows

<!-- engine text:
Whether the light should cast any shadows.
-->

## light_component.ColorFilter

<!-- engine text:
Set the filter color of the light. This acts as a colored filter in front of the light source. Note that this can change the light's effective intensity. In normalized range 0-1.
-->

## light_component.SpecularScale

<!-- engine text:
Multiplier on specular highlights. Can be used to artistically remove highlights mimicking polarizing filters or photo touch up. Any value besides 1.0 is not physical. 0.0 means no specular contribution from this light.
-->

## light_component.DiffuseScale

<!-- engine text:
Multiplier on diffuse lighting. Any value besides 1.0 is not physical. 0.0 means no diffuse contribution from this light.
-->

## light_component.Enable

<!-- engine text:
Enables rendering of this light.
-->

## light_component.Disable

<!-- engine text:
Disables rendering of this light.
-->

## light_component.IsEnabled

<!-- engine text:
Succeeds if the component is enabled, fails if it's disabled.
-->

## light_component.OnRep__CastShadows

<!-- no documentation in the engine source -->

## light_component.OnRep__ColorFilter

<!-- no documentation in the engine source -->

## LightComponent:light_component.MinValue()

<!-- no documentation in the engine source -->

## LightComponent:light_component.MaxValue()

<!-- no documentation in the engine source -->

## light_component.OnRep__SpecularScale

<!-- no documentation in the engine source -->

## LightComponent:light_component.MinValue()

<!-- no documentation in the engine source -->

## LightComponent:light_component.MaxValue()

<!-- no documentation in the engine source -->

## light_component.OnRep__DiffuseScale

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.MinValue()

<!-- no documentation in the engine source -->

## LightComponent:light_component.MaxValue()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.MinValue()

<!-- no documentation in the engine source -->

## LightComponent:light_component.MaxValue()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.MinValue()

<!-- no documentation in the engine source -->

## LightComponent:light_component.MaxValue()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.EpicOnly()

<!-- no documentation in the engine source -->

## LightComponent:light_component.MinValue()

<!-- no documentation in the engine source -->

## LightComponent:light_component.MaxValue()

<!-- no documentation in the engine source -->

## mesh_component

<!-- no documentation in the engine source -->

## mesh_component.OnInitializedInternal

<!-- engine text:
component interface
-->

## mesh_component.OnUninitializingInternal

<!-- no documentation in the engine source -->

## mesh_component.OnAddedToSceneInternal

<!-- no documentation in the engine source -->

## mesh_component.OnRemovingFromSceneInternal

<!-- no documentation in the engine source -->

## mesh_component.OnBeginSimulationInternal

<!-- no documentation in the engine source -->

## mesh_component.OnEndSimulationInternal

<!-- no documentation in the engine source -->

## mesh_component.Enable

<!-- engine text:
Enables rendering of this mesh.
-->

## mesh_component.Disable

<!-- engine text:
Disables rendering of this mesh.
-->

## mesh_component.IsEnabled

<!-- engine text:
Succeeds if the component is enabled, fails if it's disabled.
-->

## mesh_component.Collidable

<!-- engine text:
Enable/disable collision on this mesh. If enabled, meshes may collide in the physics simulation.
-->

## mesh_component.Queryable

<!-- engine text:
Enable/disable spatial queries against this mesh. Disabling this field will also disable EntityEnteredEvent/EntityExitedEvent.
-->

## mesh_component.Visible

<!-- engine text:
Enable/disable visibility of this mesh.
-->

## mesh_component.CanAffectNavigation

<!-- engine text:
When enabled, this mesh's collision can contribute to AI navigation. Still requires collision that blocks pawns. Use with care: NPCs will not route around meshes that do not affect navigation. Server-authoritative: this value is not replicated.
-->

## mesh_component.EntityEnteredEvent

<!-- engine text:
Triggered at the beginning of each tick when another entity first overlaps this entity.
-->

## mesh_component.EntityExitedEvent

<!-- engine text:
Triggered at the beginning of each tick when another entity is no longer overlapping this entity
-->

## mesh_component.GetMeshParts

<!-- engine text:
Get mesh_part's on this mesh_component.
-->

## MeshComponent:mesh_component.ToolTip()

<!-- engine text:
Begin Collidable implementation
-->

## MeshComponent:mesh_component.ToolTip()

<!-- engine text:
Begin Queryable implementation
-->

## MeshComponent:mesh_component.ToolTip()

<!-- engine text:
Begin Visible implementation
-->

## MeshComponent:mesh_component.ToolTip()

<!-- engine text:
Begin CanAffectNavigation implementation
-->

## mesh_component.OnPropertyChangedFromVerse

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## MeshComponent:mesh_component.EpicOnly()

<!-- no documentation in the engine source -->

## mesh_component.GetBoundedGlobalBox

<!-- engine text:
Returns the bounded box of this component, in world space.
-->

## mesh_component.GetBoundedLocalBox

<!-- engine text:
Returns the bounded box of this component, in local space.
-->

## mesh_part

<!-- no documentation in the engine source -->

## mesh_part.GetDiagnostic

<!-- no documentation in the engine source -->

## particle_system_component

<!-- engine text:
Used to spawn a `particle_system` at the location of this entity. The `particle_system` will simulate while the `particle_system_component` is in the scene.

Dependencies:
  * `transform_component` on the entity positions the `particle_system`.
-->

## particle_system_component.OnInitializedInternal

<!-- engine text:
component interface
-->

## particle_system_component.OnUninitializingInternal

<!-- no documentation in the engine source -->

## particle_system_component.OnAddedToSceneInternal

<!-- no documentation in the engine source -->

## particle_system_component.OnRemovingFromSceneInternal

<!-- no documentation in the engine source -->

## particle_system_component.OnBeginSimulationInternal

<!-- no documentation in the engine source -->

## particle_system_component.Enable

<!-- engine text:
Enables the simulation and rendering of this `particle_system`.
-->

## particle_system_component.Disable

<!-- engine text:
Disables the simulation and rendering of this `particle_system`.
-->

## particle_system_component.IsEnabled

<!-- engine text:
Succeeds if the component is enabled, fails if it’s disabled.
-->

## particle_system_component.Enabled

<!-- engine text:
Controls if the `particle_system_component` should start enabled.
-->

## particle_system_component.Play

<!-- engine text:
Begin Playable implementation
-->

## particle_system_component.Stop

<!-- no documentation in the engine source -->

## particle_system_component.AutoPlay

<!-- engine text:
Controls if the `particle_system_component` should play the simulation automatically when added to the scene, or when enabled from a disabled state.
-->

## particle_system_component.EpicOnly

<!-- engine text:
Should the niagara component tick pre (default) or post physics?
-->

## particle_system_component.OnPropertyChangedFromVerse

<!-- engine text:
-TODO: property_changed_interface will be removed
-->

## possessable_component

<!-- engine text:
Marks an entity that can be possessed by an agent.
-->

## possessable_component.Agent

<!-- engine text:
Which agent is this entity currently possessed by.
-->

## possessable_component.OnEndSimulation

<!-- no documentation in the engine source -->

## SetPresentableToPlayers

<!-- engine text:
Assign the players that this entity will be presented to. False = presentable to everyone, array = presentable to no one.
-->

## GetPresentableToPlayers

<!-- engine text:
Get the players that this entity is currently be presented to. False = presentable to everyone, array = presentable to no one.
-->

## rect_light_component

<!-- engine text:
A `rect_light_component` emits light into the scene from a rectangular plane with a specified width and height. You can use these
to simulate any kind of light sources that have rectangular areas, such as televisions or monitor screens, overhead lighting
fixtures, or wall sconces.
-->

## rect_light_component.OnAddedToSceneInternal

<!-- engine text:
component interface
-->

## rect_light_component.Intensity

<!-- engine text:
Set the visible light intensity emitted in SI unit Candela.
Specified before ColorFilter (which multiplies each color component after the intensity calculation and can change the effective intensity of the light).
-->

## rect_light_component.AttenuationRadius

<!-- engine text:
The bounds of the light's visible influence, in centimeters. This clamping of the light's influence is not physically correct but very important for performance,
larger lights cost more. The light falloff is based on Inverse Square law. Towards the tail end of the AttenuationRadius,
there is an additional smoothing factor to fade out the light contribution to 0 to avoid a hard cutoff.
-->

## rect_light_component.SourceWidth

<!-- engine text:
The width of the light source rect, in centimeters. Note that light source shapes which intersect shadow casting geometry can cause shadowing artifacts.
-->

## rect_light_component.SourceHeight

<!-- engine text:
The height of the light source rect, in centimeters. Note that light source's shapes which intersect shadow casting geometry can cause shadowing artifacts.
-->

## rect_light_component.BarnDoorAngleDegrees

<!-- engine text:
The angle of the barn door in degrees attached to the light source rect. Clamped between 0.0 and 90.0 degrees.
-->

## rect_light_component.BarnDoorLength

<!-- engine text:
The length of the barn door attached to the light source rect, in centimeters.
-->

## rect_light_component.OnRep__Intensity

<!-- no documentation in the engine source -->

## rect_light_component.OnRep__AttenuationRadius

<!-- no documentation in the engine source -->

## rect_light_component.OnRep__SourceWidth

<!-- no documentation in the engine source -->

## rect_light_component.GetBoundedGlobalBox

<!-- engine text:
Returns the bounded box of this component, in world space.
-->

## rect_light_component.GetBoundedLocalBox

<!-- engine text:
Returns the bounded box of this component, in local space.
-->

## rect_light_component.OnRep__SourceHeight

<!-- no documentation in the engine source -->

## rect_light_component.MinValue

<!-- no documentation in the engine source -->

## rect_light_component.MaxValue

<!-- no documentation in the engine source -->

## rect_light_component.OnRep__BarnDoorAngleDegrees

<!-- no documentation in the engine source -->

## rect_light_component.OnRep__BarnDoorLength

<!-- no documentation in the engine source -->

## sound_component

<!-- no documentation in the engine source -->

## sound_component.OnInitializedInternal

<!-- engine text:
component interface
-->

## sound_component.OnUninitializingInternal

<!-- no documentation in the engine source -->

## sound_component.OnAddedToSceneInternal

<!-- no documentation in the engine source -->

## sound_component.OnRemovingFromSceneInternal

<!-- no documentation in the engine source -->

## sound_component.OnBeginSimulationInternal

<!-- no documentation in the engine source -->

## sound_component.AutoPlay

<!-- engine text:
Begin Playable implementation
-->

## sound_component.Play

<!-- engine text:
Play the sound asset
-->

## sound_component.Stop

<!-- engine text:
Stop the sound asset
-->

## sound_component.Enable

<!-- engine text:
Enable the sound component.
-->

## sound_component.Disable

<!-- engine text:
Disable the sound component.
-->

## sound_component.IsEnabled

<!-- engine text:
Succeeds if the sound component is enabled, fails if it is disabled.
-->

## sound_component.Enabled

<!-- no documentation in the engine source -->

## sound_component.OnPropertyChangedFromVerse

<!-- no documentation in the engine source -->

## sphere_light_component

<!-- engine text:
A `sphere_light_component` emits light in all directions into the scene from a spherical source shape with a specified radius. A radius of 0 makes it a point light. You can use these
to simulate any kind of light sources that emit in all directions, such as a light bulb.
-->

## sphere_light_component.OnAddedToSceneInternal

<!-- engine text:
component interface
-->

## sphere_light_component.Intensity

<!-- engine text:
Set the visible light intensity emitted in SI unit Candela.
Specified before ColorFilter (which multiplies each color component after the intensity calculation and can change the effective intensity of the light).
-->

## sphere_light_component.AttenuationRadius

<!-- engine text:
The bounds of the light's visible influence, in centimeters. This clamping of the light's influence is not physically correct but very important for performance,
larger lights cost more. The light falloff is based on Inverse Square law. Towards the tail end of the AttenuationRadius,
there is an additional smoothing factor to fade out the light contribution to 0 to avoid a hard cutoff.
-->

## sphere_light_component.SourceRadius

<!-- engine text:
Radius of the source shape, in centimeters. Note that light shapes which intersect shadow casting geometry can cause shadowing artifacts.
-->

## sphere_light_component.OnRep__Intensity

<!-- no documentation in the engine source -->

## sphere_light_component.OnRep__AttenuationRadius

<!-- no documentation in the engine source -->

## sphere_light_component.OnRep__SourceRadius

<!-- no documentation in the engine source -->

## sphere_light_component.GetBoundedGlobalBox

<!-- engine text:
Returns the bounded box of this component, in world space.
-->

## sphere_light_component.GetBoundedLocalBox

<!-- engine text:
Returns the bounded box of this component, in local space.
-->

## SphereLightComponent:sphere_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## SphereLightComponent:sphere_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## sphere_light_component.MinValue

<!-- no documentation in the engine source -->

## sphere_light_component.MaxValue

<!-- no documentation in the engine source -->

## spot_light_component

<!-- engine text:
A `spot_light_component` emits light from a single point in a cone shape. The shape of the light is defined by two cones: the `InnerConeAngleDegrees`
and `OuterConeAngleDegrees`. Within the `InnerConeAngleDegrees` the light achieves full brightness. As you go from the extent of the inner radius to the
extents of the `OuterConeAngleDegrees` a falloff takes place, creating a penumbra, or softening around the `spot_light_component`'s disc of
illumination. The Radius of the light defines the length of the cones. More simply, this will work like a flash light or stage can light.
-->

## spot_light_component.OnAddedToSceneInternal

<!-- engine text:
component interface
-->

## spot_light_component.Intensity

<!-- engine text:
Set the visible light intensity emitted in SI unit Candela.
Specified before ColorFilter (which multiplies each color component after the intensity calculation and can change the effective intensity of the light).
-->

## spot_light_component.AttenuationRadius

<!-- engine text:
The bounds of the light's visible influence, in centimeters. This clamping of the light's influence is not physically correct but very important for performance,
larger lights cost more. The light falloff is based on Inverse Square law. Towards the tail end of the AttenuationRadius,
there is an additional smoothing factor to fade out the light contribution to 0 to avoid a hard cutoff.
-->

## spot_light_component.SourceRadius

<!-- engine text:
Radius of the source shape, in centimeters. Note that light shapes which intersect shadow casting geometry can cause shadowing artifacts.
-->

## spot_light_component.InnerConeAngleDegrees

<!-- engine text:
The light's inner cone shaped angle in degrees. Clamped between 0.0 and 80.0.
-->

## spot_light_component.OuterConeAngleDegrees

<!-- engine text:
The light's outer cone shaped angle in degrees. Clamped between 1.0 and 80.0.
-->

## spot_light_component.OnRep__Intensity

<!-- no documentation in the engine source -->

## spot_light_component.OnRep__AttenuationRadius

<!-- no documentation in the engine source -->

## spot_light_component.OnRep__SourceRadius

<!-- no documentation in the engine source -->

## SpotLightComponent:spot_light_component.MinValue()

<!-- no documentation in the engine source -->

## SpotLightComponent:spot_light_component.MaxValue()

<!-- no documentation in the engine source -->

## spot_light_component.OnRep__InnerConeAngleDegrees

<!-- no documentation in the engine source -->

## SpotLightComponent:spot_light_component.MinValue()

<!-- no documentation in the engine source -->

## SpotLightComponent:spot_light_component.MaxValue()

<!-- no documentation in the engine source -->

## spot_light_component.OnRep__OuterConeAngleDegrees

<!-- no documentation in the engine source -->

## spot_light_component.GetBoundedGlobalBox

<!-- engine text:
Returns the bounded box of this component, in world space.
-->

## spot_light_component.GetBoundedLocalBox

<!-- engine text:
Returns the bounded box of this component, in local space.
-->

## SpotLightComponent:spot_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## SpotLightComponent:spot_light_component.EpicOnly()

<!-- no documentation in the engine source -->

## SpotLightComponent:spot_light_component.MinValue()

<!-- no documentation in the engine source -->

## SpotLightComponent:spot_light_component.MaxValue()

<!-- no documentation in the engine source -->

## float_range

<!-- engine text:
A range with a minimum and maximum value. For a value to fall inside of this range, the min value must be less than or equal to the max value.
-->

## float_range.Minimum

<!-- engine text:
The minimum value of the range. Must be less than or equal to Max for values to fall inside the range.
-->

## float_range.Maximum

<!-- engine text:
The maximum value of the range. Must be greater than or equal to Min for values to fall inside the range.
-->

## easing_window

<!-- engine text:
An easing function combined with a relative time window
-->

## easing_window.Easing

<!-- engine text:
Easing function to apply
-->

## easing_window.Duration

<!-- engine text:
Duration of the easing window in seconds
-->

## easing_window.Offset

<!-- engine text:
Offset of the easing window in seconds
The offset allows the window to be moved later or earlier relative to the easing modifier’s internal timeline.
For example, moving the ease-in window later (ie +Offset) would cause the blend to happen later - ie delay it.
For -ve offsets to ease-in and +ve offsets to ease-out, this has the effect of allowing ‘frozen’ states of targets
to be observed (for time-varying targets).
-->

## FindDescendantEntities

<!-- engine text:
Finds all descendant entities including `InEntity` of type `entity_type`.
The order of the returned entities is unspecified and subject to change.
-->

## FindDescendantEntitiesWithComponent

<!-- engine text:
Finds all descendant entities including `InEntity` containing a component of type `component_type`.
The order of the returned entities is unspecified and subject to change.
-->

## FindDescendantComponents

<!-- engine text:
Finds all components attached to descendant entities to and including `InEntity` of type `component_type`.
The order of the returned components is unspecified and subject to change.
-->

## FindAncestorEntities

<!-- engine text:
Finds all ancestor entities to `InEntity` of type `entity_type`.
The order of the returned entities is unspecified and subject to change.
-->

## FindAncestorEntitiesWithComponent

<!-- engine text:
Finds all ancestor entities to `InEntity` containing a component of type `component_type`.
The order of the returned entities is unspecified and subject to change.
-->

## FindAncestorComponents

<!-- engine text:
Finds all components attached to ancestor entities to `InEntity` of type `component_type`.
The order of the returned components is unspecified and subject to change.
-->

## skeletal_animation

<!-- engine text:
A modifier of skeletons, used to animate meshes using skeletal animation
-->

## skeletal_animation.Evaluate

<!-- no documentation in the engine source -->

## skeleton

<!-- engine text:
Skeletons are collections of bones & sets/chains
-->

## entity_streaming_policy

<!-- engine text:
Entity client streaming modes
-->

## entity_streaming_policy.Spatial

<!-- engine text:
Entity will be spatially loaded.
-->

## entity_streaming_policy.NonSpatial

<!-- engine text:
Entity will be non-spatially loaded.
-->

## entity_streaming_policy.Persistent

<!-- engine text:
Entity will be always loaded.
-->

## children_streaming_policy

<!-- engine text:
Child entities client streaming modes
-->

## children_streaming_policy.Atomic

<!-- engine text:
Child entities are loaded atomically with their parent.
-->

## children_streaming_policy.Discrete

<!-- engine text:
Child entities are loaded independently from their parent.
-->

## component

<!-- engine text:
Base class for authoring logic and data in the SceneGraph. Using components you
can author re-usable building blocks of logic and data which can then be added to
entities in the scene.

Components are a very low level building block which can be used in many ways.
For example:
  * Exposing engine level concepts like mesh or sound
  * Adding gameplay capabilities like damage or interaction
  * Storing an inventory for a character in the game

As components are generic there is no specific way that they must be used.
It is up to the needs of your experience if you use one big game component
or if you break up logic into many small components.

Classes deriving from component must also specify `<final_super>` to be added
to entities. This ensures the class will always derive directly from `component`.
Further subclassing of the initial derived component is allowed and does not require
specifying `<final_super>` on the derived classes.

Only one instance of a component from each subclass group can be added to an entity
at a time. For example, given this group of components, only one light_component can
exist on a single entity. To create multiple lights you should use multiple entities.

  light_component             := class<final_super>(component)
  capsule_light_component     := class<final>(light_component)
  directional_light_component := class<final>(light_component)
  spot_light_component        := class<final>(light_component)
  sphere_light_component      := class<final>(light_component)
  rect_light_component        := class<final>(light_component)

==============================================================================
Component Lifetime

  Components move through a series of lifetime functions as they are added
  to entities, added to the scene, and begin running in the simulation. Components
  should override these methods to perform setup and run their simulation.

  As a component shuts down it will then move through shutdown version of these
  functions, giving users the opportunity to clean up any retained state on the
  component before it is disposed
.
  Lifetime Methods:
     OnAddedToScene
       OnBeginSimulation -> OnSimulate<suspends>
       OnEndSimulation
     OnRemovingFromScene
==============================================================================
-->

## component.Entity

<!-- engine text:
The parent entity of this component.
  * Components must have a parent entity pointer provided when being constructed.
  * Components cannot be moved between parents.
-->

## component.RemoveFromEntity

<!-- engine text:
Removes the component from the entity.
  * Removed components are removed from the scene and can only be added back to the same entity.
  * Flows through `OnEndSimulation`-> `OnRemovingFromScene`.
-->

## component.IsInScene

<!-- engine text:
Succeeds if the component is currently in the scene.
  * After `OnAddedToScene` is called this call succeeds.
  * After `OnRemovingFromScene` is called this call fails.
-->

## component.IsSimulating

<!-- engine text:
Succeeds if the component is currently simulating.
  * After `OnBeginSimulation` is called this call succeeds.
  * After `OnEndSimulation` is called this call fails.
-->

## component.SendDown

<!-- engine text:
Send a scene event to this component, invoking OnReceive.  Returns true if any participant consumed the event.
-->

## component.GetDiagnostic

<!-- no documentation in the engine source -->

## scene_event

<!-- engine text:
An event which can be sent through the scene graph.
-->

## entity

<!-- engine text:
Entities are the base object in the SceneGraph.
  * Objects in experiences are constructed of one or more entities.
  * Entities are hierarchical. You can query your parent using `GetParent` and add child entities using `AddEntities`.
  * Behavior is added to entities through `component`s. You can add new components using `AddComponents`.
  * The structure and content of entities is dynamic and be changed at any time through your experience
.
==============================================================================
Deriving from entity

  In the SceneGraph system a class that derives from `entity` is also known as a prefab. Prefabs are useful when you
  want to spawn/re-use a collection of entities and components many times within your game. Primarily prefabs are
  authored through the editor, with their Verse classes generated as part of the build into the projects
  Assets.digest.verse file.

  While you can create base prefabs for common game object types like a vehicle or character, we highly recommended
  that you do not add code directly to the entity class, and instead keep logic in components. Keeping logic and data in
  components allows you to restructure your prefabs throughout production of your experience, without needing to massively
  refactor your class structure.
-->

## entity.GetParent

<!-- engine text:
Returns the parent entity of this entity.
  * The parent entity controls the lifetime of its child entities and components. When an entity
    is removed from the scene, all its child entities and components will be removed as well.
  * Method fails if there is currently no parent entity.
-->

## entity.RemoveFromParent

<!-- engine text:
Removes this entity from its parent. This is used to remove entities from the scene.
  * Components on this entity and its children will run through `OnEndSimulation` -> `OnRemovingFromScene`.
  * Entity can be added back later by using `NewParent.AddEntities`.
-->

## entity.AddEntities

<!-- engine text:
Adds the provided entities as children of this entity.
  * If child entity already has a parent, removes the entity from its current parent and adds it to the new one.
  * Added child entities will move through their lifetime methods until they match the state of the new parent.
-->

## entity.GetEntities

<!-- engine text:
Returns the child entities belonging to this entity which are accessible from the calling context.
  * This method only gets the direct entity children. To query multiple levels down the entity structure use
    the Find* query methods instead.
-->

## entity.GetComponent

<!-- engine text:
Succeeds and returns the child component of type `component_type` if it exists and is accessible from the calling context.
  Note: When called during the AddedToScene or BeginSimulation phase, it will make sure the returned component has achieved the corresponding phase.
  Fails if no component of `component_type` exists or can be accessed.
-->

## entity.GetComponents

<!-- engine text:
Returns the child components belonging to this entity which are accessible from the calling context.
-->

## entity.AddComponents

<!-- engine text:
Adds the provided components to the entity.
  * If a component is not allowed to be added to this entity it is skipped.
  Note: When called during the AddedToScene or BeginSimulation phase, it will make sure the added component has achieved the corresponding phase.
  * Components are added following these rules:
      1. All components are added to the entity child list.
      2. All components have `OnAddedToScene` called (if this entity is in the scene).
      3. All components have `OnBeginSimulation` called (if this entity is simulating).
-->

## entity.GetDiagnostic

<!-- no documentation in the engine source -->

## entity.SendUp

<!-- engine text:
Send a scene event to this entity and then up the hierarchy. First, SendDown/OnReceive will be invoked on each component on this entity. Next, SendUp will be invoked on this entity's parent. Consuming the event at any point will halt propagation. Returns true if any participant consumed the event.
-->

## entity.SendDown

<!-- engine text:
Send a scene event to this entity and then down the hierarchy. First, SendDown/OnReceive will be invoked on each component on this entity. Next, SendDown will be invoked on each child entity.  Consuming the event at any point will halt propagation. Returns true if any participant consumed the event.
-->

## entity.AddTag

<!-- engine text:
Adds a `tag` instance to this entity. Returns a `tag_key` that is uniquely associated with the added instance.
-->

## entity.RemoveTag

<!-- engine text:
Removes the tag instance associated with the `tag_key`, succeeds if an instance was removed, fails otherwise.
-->

## entity.RemoveAllTags

<!-- engine text:
Removes all tag instances of type `tag_type`, succeeds if at least one instance was removed, fails otherwise.
-->

## entity.RemoveAllTagsExcept(castable_subtype(tag))

<!-- engine text:
Removes all tag instances that are not of type `tag_type`, succeeds if at least one instance was removed, fails otherwise.
-->

## entity.RemoveAllTagsExcept([]castable_subtype(tag))

<!-- engine text:
Removes all tag instances that are not of any of the types in `tag_types`, succeeds if at least one instance was removed, fails otherwise.
-->

## entity.ContainsTag

<!-- engine text:
Succeeds if at least one tag of type `tag_type` is found in this container, fails otherwise.
-->

## entity.ContainsAllTags

<!-- engine text:
Fails if at least one type in `tag_types` cannot be found in this container, succeeds otherwise. Note that this means that if `tag_types` is empty this call succeeds.
-->

## entity.ContainsAnyTag

<!-- engine text:
Succeeds if at least of the types in `tag_types` is found in this container, fails otherwise. Note that this means that if `tag_types` is empty this call fails.
-->

## entity_prefab

<!-- engine text:
Reference type to editor defined prefab. Only generated digest code should reference this type.
-->

## FindDescendantEntitiesWithTag

<!-- engine text:
Finds all descendant entities including `InEntity` that has any tags of type `tag_type`.
When querying from the simulation entity, the simulation entity itself is not included in the results.
The order of the returned entities is unspecified and subject to change.
-->

## FindAncestorEntitiesWithTag

<!-- engine text:
Finds all ancestor entities to `InEntity` that has any tags of type `tag_type`.
The order of the returned entities is unspecified and subject to change.
-->

## icon_component

<!-- engine text:
Component that holds an icon for an entity.
-->

## icon_component.Icon

<!-- no documentation in the engine source -->

## icon_component.OnBeginSimulation

<!-- no documentation in the engine source -->

## icon_component.OnEndSimulation

<!-- no documentation in the engine source -->

## rarity

<!-- engine text:
Rarity may be used by gameplay and presentation systems to classify and rank things.
-->

## rarity.Color

<!-- no documentation in the engine source -->

## rarity_component

<!-- engine text:
Component that denotes the rarity of an entity.
-->

## rarity_component.Rarity

<!-- engine text:
The rarity of this entity. An entity can have only one rarity.
-->

## rarity_component.OnBeginSimulation

<!-- no documentation in the engine source -->

## rarity_component.OnEndSimulation

<!-- no documentation in the engine source -->

## GetSimulationEntity

<!-- engine text:
Returns the simulation entity parent for this entity.
  * The simulation entity is the rootmost entity in an experience.
  * Fails if this entity is not currently in the scene.
-->

## stackable_component

<!-- engine text:
A component that when attached to an entity allows for it to merge or 'stack' with other entities with compatible components.
-->

## stackable_component.MinValue

<!-- engine text:
The current amount of this entity held in the stack.
-->

## stackable_component.StackSize

<!-- no documentation in the engine source -->

## stackable_component.MaxStackSize

<!-- engine text:
The maximum amount this component can hold. If unset, it holds an unlimited amount.
-->

## stackable_component.SetStackSize

<!-- engine text:
Sets the stack size of this component. If the provided stack size is invalid, e.g. negative or exceeding MaxStackSize, stack size will not change.
-->

## stackable_component.SetMaxStackSize

<!-- engine text:
Sets the maximum stack size for this component. If NewMaxStackSize is false, stack size is unlimited. If ClampStackSize is true, StackSize will be clamped to NewMaxStackSize.
-->

## stackable_component.Split

<!-- engine text:
Splits the specified amount out of this component’s stack, reducing this component’s stack size in the process. Returns an instance of split_prefab_type with a stack size equal to the amount it was able to take from this entity. If taking the exact (full) amount, the entity itself will be returned instead.
-->

## stackable_component.CanMergeInto

<!-- engine text:
Succeeds if this entity can be merged into the target entity. Merging an entity with itself will always fail. Note that merging should be checked in both directions!
-->

## stackable_component.MergeInto

<!-- engine text:
Attempts to merge this entity into the specified entity. Fails if entities cannot be merged.
 If TargetAmount is specified, only that amount will try to be merged into this entity. By default, the entire stack will try to merge.
 If the specified amount is invalid, the merge will fail.
-->

## stackable_component.ChangeStackSizeEvent

<!-- no documentation in the engine source -->

## stackable_component.ChangeMaxStackSizeEvent

<!-- no documentation in the engine source -->

## stackable_component.OnBeginSimulation

<!-- no documentation in the engine source -->

## stackable_component.OnEndSimulation

<!-- no documentation in the engine source -->

## change_stack_size_result

<!-- no documentation in the engine source -->

## change_stack_size_result.StackableComponent

<!-- no documentation in the engine source -->

## change_stack_size_result.PreviousStackSize

<!-- no documentation in the engine source -->

## change_stack_size_result.CurrentStackSize

<!-- no documentation in the engine source -->

## change_max_stack_size_result

<!-- no documentation in the engine source -->

## change_max_stack_size_result.StackableComponent

<!-- no documentation in the engine source -->

## change_max_stack_size_result.PreviousMaxStackSize

<!-- no documentation in the engine source -->

## change_max_stack_size_result.CurrentMaxStackSize

<!-- no documentation in the engine source -->

## basic_stackable_component

<!-- engine text:
Stackable component which both merges and splits based on a prefab field.
-->

## basic_stackable_component.split_prefab_type

<!-- engine text:
The prefab used when this entity merges with another or when it is split into a new instance.
-->

## basic_stackable_component.Split

<!-- engine text:
Splits the specified amount out of this component’s stack, reducing this components’s stack size in the process. Returns an instance of split_prefab_type with a stack size equal to the amount it was able to take from this entity. If taking the exact (full) amount, the entity itself will be returned instead.
-->

## basic_stackable_component.CanMergeInto

<!-- engine text:
Succeeds if this entity can be merged into the target entity. Merging an entity with itself will always fail.
-->

## tick_events

<!-- engine text:
Describes discrete phases of a frame update. Subscribe to members of the tick_events object to run code before or after the physics system has updated your object, allowing you to affect or react to these updates.
-->

## tick_events.PrePhysics

<!-- engine text:
Listen `PrePhysics` to run your code before the physics system has updated your object this frame.
-->

## tick_events.PostPhysics

<!-- engine text:
Listen `PostPhysics` to run your code after the physics system has updated your object this frame.
-->

## transform_component

<!-- engine text:
Stores the transforms for an entity, which are used to position the entity.
-->

## transform_component.OnInitializedInternal

<!-- engine text:
component interface
-->

## transform_component.OnUninitializingInternal

<!-- no documentation in the engine source -->

## transform_component.GlobalTransform

<!-- engine text:
Current transform of the entity, globally referenced. Any value set at construction will be overrridden with the calculation from the Local Transform
-->

## transform_component.LocalTransform

<!-- engine text:
LocalTransform to its parent/origin
-->

## transform_component.Origin

<!-- engine text:
alternate origin than the default parent entity
-->

## GetGlobalTransform

<!-- engine text:
Returns the global transform of this entity, in the case the entity does not have a transform_component it will return the transform of the first parent that has a transform
-->

## GetLocalTransform

<!-- engine text:
Returns the local transform of this entity, in the case the entity does not have a transform_component it will return identity
-->

## GetOrigin

<!-- engine text:
Returns the origin of the entity in any, in the case the entity does not have a transform_component the method will fail
-->

## SetGlobalTransform

<!-- engine text:
Sets the global transform of this entity, in the case the entity does not have a transform_component it will create one and set its global transform
-->

## SetLocalTransform

<!-- engine text:
Sets the local transform of this entity, in the case the entity does not have a transform_component it will create one and set its local transform
-->

## SetOrigin

<!-- engine text:
Sets the origin of this entity, in the case the entity does not have a transform_component it will create one and set its origin. This method fails if it recognized dependency recursion.
-->

## ResetOrigin

<!-- engine text:
Resets the origin of this entity, which will now default to its parent
-->

## origin

<!-- engine text:
Interface to provide alternative origin to an entity which is defaulted to its parent. See `transform_component`
-->

## origin.GetTransform

<!-- no documentation in the engine source -->

## entity_origin

<!-- engine text:
class to provide alternative origin to the 'transform_component' as an entity
-->

## entity_origin.Entity

<!-- no documentation in the engine source -->

## entity_origin.GetTransform

<!-- no documentation in the engine source -->

## execution_listenable

<!-- engine text:
Users to subscribe to, or await on, a DeltaTime based callback from one of the phases in a component's `TickEvents` object.
-->

## execution_listenable.Await

<!-- engine text:
Suspends the current task until resumed by a matching call to `signalable.Signal`. Returns the event `payload`.
-->

## execution_listenable.Subscribe

<!-- engine text:
Subscribe a callback function to this TickEvent phase. The input parameter to your function (DeltaTime) is the time that has passed between the last update and the current update.
-->

## unique_net_id_internal

<!-- no documentation in the engine source -->

## agent

<!-- no documentation in the engine source -->

## player

<!-- no documentation in the engine source -->

## player.IsActive

<!-- engine text:
Succeeds when this `player` may be used as a module-scoped `var` `weak_map` key. This coincides with the corresponding player having joined the game and not yet left. Using a `player` as a module-scope `var` `weak_map` key when this method fails results in a runtime error.
-->

## session

<!-- engine text:
Type for which there is a single instance per round.  Use `GetSession` to get the current round's `session` instance. May be used with `weak_map` to implement global variables.
Note: may be changed in a future release to a single instance per game. Round-local behavior should not be relied upon.
-->

## GetSession

<!-- engine text:
Returns the `session` corresponding to the current round.  The result can be used with `weak_map` to implement global variables.
Note: may be changed in a future release to return a single instance per game. Round-local behavior should not be relied upon.
-->

## session_environment

<!-- engine text:
Specifies what type of environment the current session is in.
-->

## session_environment.Edit

<!-- engine text:
The current session is in an Edit environment for an experience, such as a session started within UEFN.
-->

## session_environment.Private

<!-- engine text:
The current session is in a Private environment for an experience, such as a playtest.
-->

## session_environment.Live

<!-- engine text:
The current session is in a Live environment for an experience.
-->

## Environment

<!-- no documentation in the engine source -->

## Sleep

<!-- engine text:
Waits specified number of seconds and then resumes. If `Seconds` = 0.0 then it waits until next tick/frame/update. If `Seconds` = Inf then it waits forever and only calls back if canceled - such as via `race`. If `Seconds` < 0.0 then it completes immediately and does not yield to other aysnc expressions.
Waiting until the next update (0.0) is especially useful in a loop of a coroutine that needs to do some work every update and this yields to other coroutines so that it doesn't hog a processor's resources.
Waiting forever (Inf) will have any expression that follows never be evaluated. Occasionally it is desireable to have a task never complete such as the last expression in a `race` subtask where the task must never win the race though it still may be canceled earlier.
Immediately completing (less than 0) is useful when you want programmatic control over whether an expression yields or not.

-->

## GetSimulationElapsedTime

<!-- engine text:
Get the seconds that have elapsed since the world began simulating
-->

## team_base

<!-- no documentation in the engine source -->

## team

<!-- no documentation in the engine source -->

## has_tags

<!-- engine text:
An interface representing a mutable collection of tags.
-->

## has_tags.AddTag

<!-- engine text:
Adds a `tag` instance to this container. Returns a `tag_key` that is uniquely associated with the added instance.
-->

## has_tags.RemoveTag

<!-- engine text:
Removes the tag instance associated with the `tag_key`, succeeds if an instance was removed, fails otherwise.
-->

## has_tags.RemoveAllTags

<!-- engine text:
Removes all tag instances of type `tag_type`, succeeds if at least one instance was removed, fails otherwise.
-->

## has_tags.RemoveAllTagsExcept(castable_subtype(tag))

<!-- engine text:
Removes all tag instances that are not of type `tag_type`, succeeds if at least one instance was removed, fails otherwise.
-->

## has_tags.RemoveAllTagsExcept([]castable_subtype(tag))

<!-- engine text:
Removes all tag instances that are not of any of the types in `tag_types`, succeeds if at least one instance was removed, fails otherwise.
-->

## has_tags.ContainsTag

<!-- engine text:
Succeeds if at least one tag of type `tag_type` is found in this container, fails otherwise.
-->

## has_tags.ContainsAllTags

<!-- engine text:
Fails if at least one type in `tag_types` cannot be found in this container, succeeds otherwise. Note that this means that if `tag_types` is empty this call succeeds.
-->

## has_tags.ContainsAnyTag

<!-- engine text:
Succeeds if at least of the types in `tag_types` is found in this container, fails otherwise. Note that this means that if `tag_types` is empty this call fails.
-->

## tag_base

<!-- no documentation in the engine source -->

## tag

<!-- engine text:
A base type used for tagging objects in order to hierarchically evaluate an objects classification.
-->

## tag_container_base

<!-- no documentation in the engine source -->

## tag_key

<!-- engine text:
A `tag_key` is the return value from adding a `tag` to a container implementing the `has_tags` interface, and is used to selectively remove such an instance from the same container.
-->

## tag_search_sort_type

<!-- no documentation in the engine source -->

## tag_search_sort_type.Unsorted

<!-- no documentation in the engine source -->

## tag_search_sort_type.Sorted

<!-- no documentation in the engine source -->

## tag_search_criteria

<!-- engine text:
Advanced tag search criteria
-->

## tag_search_criteria.RequiredTags

<!-- no documentation in the engine source -->

## tag_search_criteria.PreferredTags

<!-- no documentation in the engine source -->

## tag_search_criteria.ExclusionTags

<!-- no documentation in the engine source -->

## tag_search_criteria.SortType

<!-- no documentation in the engine source -->

## tag_view

<!-- engine text:
A queryable collection of tags.
-->

## tag_view.Has

<!-- engine text:
Determine if TagToCheck is present in this container, also checking against parent tags {"A.1"}.Has("A") will return True, {"A"}.Has("A.1") will return False If TagToCheck is not Valid it will always return False.
-->

## tag_view.HasAny

<!-- engine text:
Checks if this container contains ANY of the tags in the specified container, also checks against parent tags {"A.1"}.HasAny({"A","B"}) will return True, {"A"}.HasAny({"A.1","B"}) will return False If InTags is empty/invalid it will always return False.
-->

## tag_view.HasAll

<!-- engine text:
Checks if this container contains ALL of the tags in the specified container, also checks against parent tags {"A.1","B.1"}.HasAll({"A","B"}) will return True, {"A","B"}.HasAll({"A.1","B.1"}) will return False If InTags is empty/invalid it will always return True, because there were no failed checks.
-->

## Rotation:rotation()

<!-- engine text:
An abstract representation of an orientation change in 3d-space.
-->

## MakeRotationRadians

<!-- engine text:
Makes a `rotation` from `Axis` and `Angle` in radians using a right-handed sign convention (e.g. a positive rotation around Up takes Forward to Left).
-->

## Rotation:MakeRotationFromYawPitchRollDegrees(float,float,float)

<!-- engine text:
Degrees version of `MakeRotationFromYawPitchRollRadians`
-->

## MakeRotationFromEulerRadians

<!-- engine text:
Makes a `rotation` by applying a post-rotation of `LeftAxisAngle` followed by `UpAxisAngle` and then `ForwardAxisAngle `in that order. Right-handed convention (e.g. a positive rotation around Up takes +Forward to Left).
-->

## Rotation:IdentityRotation()

<!-- engine text:
Makes the identity `rotation`.
-->

## Rotation:Distance(rotation,rotation)

<!-- engine text:
Returns the distance between `Rotation1` and `Rotation2`. The result will be between:
 * `0.0`, representing equivalent rotations and
 * `1.0` representing rotations which are 180 degrees apart (i.e., the shortest rotation between them is 180 degrees around some axis).
-->

## AngularDistanceRadians

<!-- engine text:
Returns the smallest angular distance between `Rotation1` and `Rotation2` in radians.
-->

## operator'*'(rotation,rotation)

<!-- engine text:
Apply a `PreRotation` to `PostRotation` as `v * PreRotation * PostRotation`.
-->

## Rotation:GetYawPitchRollDegrees()

<!-- engine text:
Degrees version of `GetYawPitchRollRadians`.
-->

## GetEulerRadians

<!-- engine text:
Makes a `tuple(float, float, float)` with three elements:
 * *left axis* `rotation` in radians
 * *up axis* of `rotation` in radians
 * *forward axis* of `rotation` in radians
using the conventions of `MakeRotationEulerRadians`.
-->

## Rotation:GetAxis()

<!-- engine text:
Makes a `vector3` from the axis of `rotation` for an right-handed angle.
If `rotation` is nearly identity, this will return the +Forward axis. See also `GetAngleRadians`.
-->

## GetAngleRadians

<!-- engine text:
Returns the radians of right-handed `rotation` around the axis of `rotation`. See also `GetAxis`.
-->

## Rotation:MakeShortestRotationBetween(vector3,vector3)

<!-- engine text:
Makes the smallest angular `rotation` from `InitialVector` to `FinalVector` two vectors of arbitrary length such that:
`InitialVector * MakeShortestRotationBetween(InitialVector, FinalVector) = FinalVector` and
`MakeShortestRotationBetween(InitialVector, FinalVector)?.GetAngleRadians()` is as small as possible.
-->

## Rotation:Slerp(rotation,rotation,float)

<!-- engine text:
Used to perform spherical linear interpolation between `From` (when `Ratio = 0.0`) and `To` (when `Ratio = 1.0`). Expects `0.0 <= Ratio <= 1.0`.
-->

## operator'*'(vector3,rotation)

<!-- engine text:
Makes a `vector3` by applying `Rotation` to `Vector`.
-->

## Rotation:Invert()

<!-- engine text:
Makes a `rotation` by inverting `Rotation` such that `ApplyRotation(Rotation, Rotation.Invert())) = IdentityRotation`.
-->

## Rotation:IsFinite()

<!-- engine text:
Returns `Rotation` if it does not contain `NaN`, `Inf` or `-Inf`.
-->

## Transform:transform()

<!-- engine text:
A combination of scale, rotation, and translation, applied in that order.
-->

## Transform:transform.Translation()

<!-- engine text:
The location of this `transform`.
-->

## Transform:transform.Rotation()

<!-- engine text:
The rotation of this `transform`.
-->

## Transform:transform.Scale()

<!-- engine text:
The scale of this `transform`.
-->

## Vector3:vector3()

<!-- engine text:
3-dimensional vector with `float` components.
-->

## vector3.Left

<!-- engine text:
The Left (was -Y) component of this vector.
-->

## vector3.Up

<!-- engine text:
The Up (was Z) component of this vector.
-->

## vector3.Forward

<!-- engine text:
The Forward (was X) component of this vector.
-->

## operator'+'(classifiable_subset(t),classifiable_subset(t))

<!-- engine text:
Returns a new set that is the union of all elements in `InSetL` set and `InSetR`.
-->

## Ceil(float)

<!-- engine text:
Returns the smallest `int` that is greater than or equal to `Val`.
Fails if `not IsFinite(Val)`.
-->

## Floor(float)

<!-- engine text:
Returns the largest `int` that is less than or equal to `Val`.
Fails if `not IsFinite(Val)`.
-->

## day_of_week

<!-- engine text:
Enumerates the days of the week in 7-day calendars.
-->

## day_of_week.Monday

<!-- no documentation in the engine source -->

## day_of_week.Tuesday

<!-- no documentation in the engine source -->

## day_of_week.Wednesday

<!-- no documentation in the engine source -->

## day_of_week.Thursday

<!-- no documentation in the engine source -->

## day_of_week.Friday

<!-- no documentation in the engine source -->

## day_of_week.Saturday

<!-- no documentation in the engine source -->

## day_of_week.Sunday

<!-- no documentation in the engine source -->

## month_of_year

<!-- engine text:
Enumerates the months of the year in 12-month calendars.
-->

## month_of_year.January

<!-- no documentation in the engine source -->

## month_of_year.February

<!-- no documentation in the engine source -->

## month_of_year.March

<!-- no documentation in the engine source -->

## month_of_year.April

<!-- no documentation in the engine source -->

## month_of_year.May

<!-- no documentation in the engine source -->

## month_of_year.June

<!-- no documentation in the engine source -->

## month_of_year.July

<!-- no documentation in the engine source -->

## month_of_year.August

<!-- no documentation in the engine source -->

## month_of_year.September

<!-- no documentation in the engine source -->

## month_of_year.October

<!-- no documentation in the engine source -->

## month_of_year.November

<!-- no documentation in the engine source -->

## month_of_year.December

<!-- no documentation in the engine source -->

## date_time

<!-- no documentation in the engine source -->

## date_time.Ticks

<!-- no documentation in the engine source -->

## CreateDateTime

<!-- no documentation in the engine source -->

## ValidateDateTime

<!-- no documentation in the engine source -->

## DaysInMonth

<!-- engine text:
Return the number of days in the specified month of the specified year
-->

## DaysInYear

<!-- engine text:
Return the number of days in the specified year
-->

## ToString(date_time)

<!-- engine text:
Returns a string representation of the datetime in the following format: yyyy.mm.dd-hh.mm.ss. Assumes Datetime is in UTC.
-->

## UtcNow

<!-- engine text:
Returns the current UTC date_time.
-->

## date_parts

<!-- no documentation in the engine source -->

## date_parts.Year

<!-- no documentation in the engine source -->

## date_parts.Month

<!-- no documentation in the engine source -->

## date_parts.Day

<!-- no documentation in the engine source -->

## time_of_day_parts

<!-- engine text:
TODO: Create a time_space struct and related time_span methods - FORT-416561
-->

## time_of_day_parts.Hours

<!-- no documentation in the engine source -->

## time_of_day_parts.Minutes

<!-- no documentation in the engine source -->

## time_of_day_parts.Seconds

<!-- no documentation in the engine source -->

## time_of_day_parts.Milliseconds

<!-- no documentation in the engine source -->

## time_of_day_parts.Microseconds

<!-- no documentation in the engine source -->

## time_of_day_parts.Nanoseconds

<!-- no documentation in the engine source -->

## GetDate

<!-- no documentation in the engine source -->

## GetTimeOfDay

<!-- no documentation in the engine source -->

## GetYear

<!-- no documentation in the engine source -->

## GetMonth

<!-- no documentation in the engine source -->

## GetDay

<!-- no documentation in the engine source -->

## GetHours(date_time)

<!-- no documentation in the engine source -->

## GetMinutes(date_time)

<!-- no documentation in the engine source -->

## GetSeconds(date_time)

<!-- no documentation in the engine source -->

## GetMilliseconds(date_time)

<!-- no documentation in the engine source -->

## GetMicroseconds(date_time)

<!-- no documentation in the engine source -->

## GetNanoseconds(date_time)

<!-- no documentation in the engine source -->

## GetDayOfWeek

<!-- no documentation in the engine source -->

## GetMonthOfYear

<!-- no documentation in the engine source -->

## time_span

<!-- no documentation in the engine source -->

## time_span.Ticks

<!-- no documentation in the engine source -->

## CreateTimeSpan

<!-- no documentation in the engine source -->

## ToString(time_span)

<!-- engine text:
Returns a string representation of the time span in the following format: yyyy.mm.dd-hh.mm.ss.
-->

## GetDays

<!-- no documentation in the engine source -->

## GetHours(time_span)

<!-- no documentation in the engine source -->

## GetMinutes(time_span)

<!-- no documentation in the engine source -->

## GetSeconds(time_span)

<!-- no documentation in the engine source -->

## GetMilliseconds(time_span)

<!-- no documentation in the engine source -->

## GetMicroseconds(time_span)

<!-- no documentation in the engine source -->

## GetNanoseconds(time_span)

<!-- no documentation in the engine source -->

## GetTotalDays

<!-- no documentation in the engine source -->

## GetTotalHours

<!-- no documentation in the engine source -->

## GetTotalMinutes

<!-- no documentation in the engine source -->

## GetTotalSeconds

<!-- no documentation in the engine source -->

## GetTotalMilliseconds

<!-- no documentation in the engine source -->

## GetTotalMicroseconds

<!-- no documentation in the engine source -->
