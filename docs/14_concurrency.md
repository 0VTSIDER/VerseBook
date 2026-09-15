# Concurrency

Concurrency in Verse is part of the language rather than a library. An
async expression can suspend and resume across simulation updates, and
a set of constructs (`sync`, `race`, `rush`, `branch`, `spawn`)
combines async work under defined rules for completion and
cancellation.

A game scene runs many things at once: NPCs follow their routes, timers
count down, music crossfades between tracks. These constructs let that
be written as ordinary nested code, with the compiler tracking which
functions can suspend through the `<suspends>` effect.

## Core Concepts

### Immediate vs Async Expressions

Every expression falls into one of two categories: immediate or
async. Understanding this distinction is crucial for working with
Verse's concurrency model.

Immediate expressions evaluate with no delay, completing entirely
within the current simulation update or frame. These include most
basic operations you'd expect to happen instantly: arithmetic
calculations, variable access, simple function calls, and data
structure manipulation. When you write `X := 5 + 3`, the addition
happens immediately, the assignment completes instantly, and execution
moves to the next statement without any possibility of interruption.

Async expressions, on the other hand, have the possibility of taking
time to evaluate, potentially spanning multiple simulation
updates. They represent operations that inherently take time in the
game world: animations playing out, timers counting down, network
requests completing, or simply waiting for the next frame. An async
expression might complete immediately if its conditions are already
met, or it might suspend execution, allowing other code to run while
it waits for the right moment to resume.

### Simulation Updates

A simulation update (or tick) represents one step of the game's
simulation. Simulation and rendering are **independent** — they run
at separate rates and are decoupled from each other in modern engines.

Each tick processes input, updates game logic, runs physics, and
advances the game state. Verse's concurrency model lets you think
in terms of logical time flow — async expressions suspend at tick
boundaries and resume in future ticks when their conditions are met.

Async expressions naturally align with this update cycle. When an
async expression suspends, it yields control back to the game engine,
which continues processing other tasks and rendering frames. The
suspended expression resumes in a future update when its conditions
are met, seamlessly continuing from where it left off. This
cooperative model ensures that long-running operations do not block the
game's responsiveness.

### The `suspends` Effect

Concurrent operations require the `<suspends>` effect specifier (see
[Effects](13_effects.md)). Functions marked with `<suspends>` can use
concurrency expressions, call other suspending functions, and
cooperatively yield execution:

<!--versetest
assert_semantic_error(3512):
    Nap(:float)<transacts><suspends>:void = {}
    G1():void =
        Nap(1.0)
-->
<!-- 01 -->
```verse
# Marked suspends, so it may call Sleep
Announce()<suspends>:void =
    Sleep(1.0)
    Print("One second later!")

# No suspends, so Sleep(1.0) here would be an error
AnnounceNow():void =
    Print("This happens immediately")
```

The `<suspends>` effect propagates through the call chain—any function
calling a suspending function must itself be marked `<suspends>`.

## Structured Concurrency

Structured concurrency represents one of Verse's most elegant design
decisions. Rather than spawning threads or tasks that live
independently and require manual lifecycle management, structured
concurrency expressions have lifespans naturally bound to their
enclosing scope. When you enter a structured concurrency block, you
know that all concurrent operations within it will be properly managed
and cleaned up when the block exits, preventing resource leaks and
making code easier to reason about.

This approach mirrors how we think about sequential code. Just as a
block of sequential statements has a clear beginning and end,
structured concurrent operations have a defined lifetime. You can nest
them, compose them, and reason about them using the same mental model
you use for regular code blocks.

### Effect Requirements

All structured concurrency expressions (`sync`, `race`, `rush`, and
`branch`) require the `<suspends>` effect. You cannot use these
constructs in immediate (non-suspending) functions:

<!--versetest
Operation1<public>()<suspends>:void = {}
Operation2<public>()<suspends>:void = {}
assert_semantic_error(3512):
    Op2()<suspends>:void = {}
    G2():void =
        sync:
            Op2()
            Op2()
-->
<!-- 02 -->
```verse
ProcessConcurrently()<suspends>:void =
    sync:
        Operation1()
        Operation2()

# Dropping <suspends> from the signature above is an error:
# the sync calls Operation1 and Operation2, which suspend.
```

### The sync Expression

The `sync` expression embodies the simplest concurrent pattern: doing
multiple things at once and waiting for all of them to finish. When
you have independent operations that can benefit from parallel
execution, `sync` provides a clean way to express this parallelism
while maintaining deterministic behavior.

<!--versetest
cell<public> := class:
    var Ids:tuple(int, int, int) = (0, 0, 0)
FetchTextures()<suspends>:int =
    Sleep(0.0)
    1
FetchSounds()<suspends>:int =
    Sleep(0.0)
    2
FetchModels()<suspends>:int =
    Sleep(0.0)
    3
-->
<!-- 03 -->
```verse
# All three arms start together; sync waits for every one of them
LoadAssets()<suspends>:tuple(int, int, int) =
    sync:
        FetchTextures()
        FetchSounds()
        FetchModels()
```
<!--versetest
Loaded := cell{}
RunLoad()<suspends>:void =
    set Loaded.Ids = LoadAssets()
spawn{RunLoad()}
# Results arrive in the order the arms were written, not the order they finished.
Loaded.Ids = (1, 2, 3)
-->

Inside a `sync` block, all subexpressions begin execution at
essentially the same moment. The sync expression then waits patiently
for every single subexpression to complete, regardless of how long
each takes individually. If one operation finishes in milliseconds
while another takes several seconds, sync continues waiting until that
last operation completes. Only then does execution continue past the
sync block.

The beauty of sync lies in its predictability. You always get results
from all subexpressions, always in the same order you wrote them,
packaged neatly in a tuple. This makes sync perfect for scenarios
where you need multiple pieces of data or need to ensure multiple
systems are ready before proceeding. Loading game assets in parallel,
initializing multiple subsystems simultaneously, or gathering data
from multiple sources all benefit from sync's all-or-nothing approach.

Consider a more sophisticated example that demonstrates sync's composability:

<!--versetest
LoadTexture()<suspends>:void={}
ApplyTexture()<suspends>:void={}
LoadSound()<suspends>:void={}
PlaySound()<suspends>:void={}
LoadModel():void={}
ProcessData(:int,:int,:int):void={}
FetchDataA()<suspends>:int=1
FetchDataB()<suspends>:int=1
FetchDataC():int=1
assert_semantic_error(3538):
    OnlyAsyncArm()<suspends>:void = {}
    ImmediateArm():void = {}
    TooFewAsync()<suspends>:void =
        sync:
            OnlyAsyncArm()
            ImmediateArm()
-->
<!-- 04 -->
```verse
# An arm can be a block of steps that run in order
PrepareScene()<suspends>:void =
    sync:
        block:
            LoadTexture()
            ApplyTexture()
        block:
            LoadSound()
            PlaySound()
        LoadModel()      # Immediate, so this arm just runs

# A sync can be used directly as an argument list
Gather()<suspends>:void =
    ProcessData(sync:
        FetchDataA()
        FetchDataB()
        FetchDataC()
    )
```

An arm does not have to be async. `LoadModel` and `FetchDataC` above are
ordinary immediate functions, and a `sync` is happy to include them: they
simply run to completion at once and contribute their value to the result
tuple. What the compiler does insist on is that at least two of the arms be
async. A `sync` in which only one arm can suspend has nothing to overlap, so
the compiler rejects it and suggests writing the arms in
sequence instead.

### The race Expression

Where `sync` embodies cooperation, `race` represents competition. The
race expression starts multiple async operations simultaneously, but
only cares about the first one to cross the finish line. As soon as
one subexpression completes, race immediately cancels all the others
and continues with the winner's result. This winner-takes-all
semantics makes race perfect for timeout patterns, fallback
mechanisms, and any situation where you want the fastest possible
response.

<!--versetest
cell<public> := class:
    var Winner:int = 0
SlowOperation()<suspends>:int =
    NextTick()
    1
FastOperation()<suspends>:int =
    Sleep(0.0)
    2
MediumOperation()<suspends>:int =
    NextTick()
    3
-->
<!-- 05 -->
```verse
# First to complete wins; the other two are cancelled
Fastest()<suspends>:int =
    race:
        SlowOperation()     # 1, slowest
        FastOperation()     # 2, finishes first and wins
        MediumOperation()   # 3, in between
```
<!--versetest
Race := cell{}
RunRace()<suspends>:void =
    set Race.Winner = Fastest()
spawn{RunRace()}
Race.Winner = 2
-->

The power of race becomes apparent when you consider real game
scenarios. Imagine querying multiple servers for data, where you want
to use whichever responds first. Or implementing a player action with
a timeout, where either the player completes the action or time runs
out. Race elegantly expresses these patterns without complex state
management or manual cancellation logic.

Cancellation in race is immediate and thorough. The moment a winner
emerges, all losing subexpressions receive a cancellation signal and
begin cleanup. This is not just an optimization; it is crucial for
resource management and preventing unwanted side effects from
operations that are no longer needed.

#### The Result Type of a race

The type system handles race elegantly. Since only one subexpression's
result will be returned, the result type of a race is the most
specific common supertype of all the subexpressions. This ensures type
safety while maintaining flexibility in what kinds of operations you
can race against each other:

<!--versetest
cell<public> := class:
    var Sides:int = 0
-->
<!-- 06 -->
```verse
shape := class:
    Sides:int

triangle := class(shape):
    Sides<override>:int = 3

square := class(shape):
    Sides<override>:int = 4

GetTriangle()<suspends>:triangle =
    NextTick()              # Never finishes here
    triangle{}

GetSquare()<suspends>:square =
    Sleep(0.0)
    square{}

# Two different arm types, so the result is their common supertype
PickShape()<suspends>:shape =
    race:
        GetTriangle()
        GetSquare()
```
<!--versetest
Picked := cell{}
RunPick()<suspends>:void =
    set Picked.Sides = PickShape().Sides
spawn{RunPick()}
# The square won, and the shape-typed result really is the square.
Picked.Sides = 4
-->

The rule degenerates pleasantly in the common case. When every arm already has
the same type, the most specific common supertype of that set is the type
itself, so racing two arms that both produce an `int` gives you an `int` with
no widening and no casting at the other end.

A pattern involves adding identifiers to determine which subexpression won:

<!--versetest
cell<public> := class:
    var Id:int = 0
SlowOperation()<suspends>:void = NextTick()
FastOperation()<suspends>:void = Sleep(0.0)
Forever()<suspends>:void = loop { NextTick() }
-->
<!-- 07 -->
```verse
# Tag each arm so the winner identifies itself
WhoWon()<suspends>:int =
    race:
        block:
            SlowOperation()
            1
        block:
            FastOperation()
            2
        block:
            Forever()
            3       # Unreachable
```
<!--versetest
Won := cell{}
RunWho()<suspends>:void =
    set Won.Id = WhoWon()
spawn{RunWho()}
Won.Id = 2
-->

#### Resolution Stops Unstarted Arms

`race` starts its arms in order. If the race resolves before every arm has
started — which happens when one arm completes without ever suspending — the
remaining arms never start at all. Their side effects do not run.

<!--versetest
cell<public> := class:
    var ArmThreeRan:logic = false
    var Winner:int = 0
SlowStart()<suspends>:void = NextTick()
-->
<!-- 08 -->
```verse
Trace := cell{}

RaceThree()<suspends>:int =
    race:
        block:
            SlowStart()                  # Suspends, so it cannot win
            1
        block:
            Sleep(0.0)                   # Completes at once, and wins
            2
        block:
            set Trace.ArmThreeRan = true  # Never evaluated
            Sleep(0.0)
            3
```
<!--versetest
RunThree()<suspends>:void =
    set Trace.Winner = RaceThree()
spawn{RunThree()}
Trace.Winner = 2
Trace.ArmThreeRan = false
-->

Arm two wins on the first pass through the arm list, before arm three has been
entered even once, so the assignment in arm three never happens.

An arm that is already executing when the race resolves is not cut off
mid-statement: it continues to its next suspension point and is then cancelled
along with the other leftover arms.

When more than one arm could complete during that first pass, the first
completer wins.

!!! note
    Earlier BPVM builds did start the later arms, running their side effects up
    to their first suspension point before cancelling them. Both VMs now agree
    that those arms never begin.

### The rush Expression

The `rush` expression occupies a unique middle ground between `sync`
and `race`. Like race, it completes as soon as the first subexpression
finishes. Unlike race, it does not cancel the losers. This creates an
interesting pattern where you can start multiple operations, proceed
as soon as one provides a result, while allowing the others to
continue their work in the background.

The difference is worth seeing as a single keyword change. In the pair below,
the first arm parks on an event that nobody has signalled yet, so the second
arm wins. What happens to the first arm afterwards is decided entirely by
whether the expression is `rush` or `race`:

<!--versetest
cell<public> := class:
    var Trace:int = 0
-->
<!-- 09 -->
```verse
Trail := cell{}
Gate := event(int){}

FirstOneWins()<suspends>:int =
    Winner := rush:              # Swap in `race` and the +100 never happens
        block:
            Gate.Await()         # Parked: cannot win
            set Trail.Trace += 100
            1
        block:
            Sleep(0.0)           # Wins at once
            2
    Gate.Signal(0)               # Wake the losing arm, if it is still alive
    Sleep(0.0)
    Winner
```
<!--versetest
RunRush()<suspends>:void =
    set Trail.Trace += FirstOneWins()
spawn{RunRush()}
# rush: arm two returned 2, and the loser resumed and added 100.
Trail.Trace = 102
# The same code with `race`: the loser is cancelled, so the +100 never happens.
RaceLog := cell{}
RaceGate := event(int){}
RaceVersion()<suspends>:int =
    Winner := race:
        block:
            RaceGate.Await()
            set RaceLog.Trace += 100
            1
        block:
            Sleep(0.0)
            2
    RaceGate.Signal(0)
    Sleep(0.0)
    Winner
RunRaceVersion()<suspends>:void =
    set RaceLog.Trace += RaceVersion()
spawn{RunRaceVersion()}
RaceLog.Trace = 2
-->

Rush shines in scenarios where you want to be responsive while still
completing all operations eventually. Consider preloading game assets:
you might start loading multiple levels simultaneously, begin gameplay
as soon as the current level loads, while continuing to cache the
other levels in the background. Or think about achievement checking,
where you want to notify the player as soon as one achievement unlocks
while continuing to check for others.

The non-canceling nature of rush requires careful consideration. Those
background tasks continue consuming resources and performing their
operations even after rush completes. They'll keep running until they
naturally complete or until their enclosing async context ends. This
makes rush powerful but also potentially dangerous if misused with
operations that might never complete or that consume significant
resources.

There's an important technical restriction to be aware of: rush cannot
be used directly in the body of iteration expressions like `loop` or
`for`. The interaction between rush's background tasks and iteration
could lead to resource accumulation. If you need rush-like behavior in
a loop, wrap it in an async function and call that function from your
iteration.

### Returning from Concurrent Arms

A `return` statement written directly inside a `sync`, `race`, or `rush` arm
causes the enclosing *function* to return, not just the arm. The structured
concurrency expression is abandoned, defers in arms that have already
started execute, and arms that have not yet started are simply
skipped.

<!--versetest
cell<public> := class:
    var ArmTwoRan:int = 0
    var PastSync:int = 0
    var Result:int = 0
-->
<!-- 10 -->
```verse
Trace := cell{}

Abandon()<suspends>:int =
    sync:
        block:
            Sleep(0.0)
            return 5                  # Returns from Abandon, not from this arm
        block:
            Sleep(0.0)
            set Trace.ArmTwoRan = 1
    set Trace.PastSync = 1
    0
```
<!--versetest
RunAbandon()<suspends>:void =
    set Trace.Result = Abandon()
spawn{RunAbandon()}
# Arm two never got to run, the code after the sync never ran, and 5 came out.
Trace.ArmTwoRan = 0
Trace.PastSync = 0
Trace.Result = 5
-->

What matters is where the `return` is *written*, not where it eventually
executes. A `return` inside a function that an arm merely *calls* belongs to
that function and stops there. The call hands a value back to the arm, the arm
completes in the ordinary way, and the `sync` carries on waiting for its
siblings as though nothing unusual had happened:

<!--versetest
cell<public> := class:
    var ArmTwoRan:int = 0
    var PastSync:int = 0
    var Result:int = 0
-->
<!-- 11 -->
```verse
Steps := cell{}

Finish()<suspends>:int =
    Sleep(0.0)
    return 5                          # Returns from Finish only

KeepWaiting()<suspends>:int =
    R := sync:
        Finish()
        block:
            Sleep(0.0)
            set Steps.ArmTwoRan = 1
            2
    set Steps.PastSync = 1
    R(0)
```
<!--versetest
RunKeep()<suspends>:void =
    set Steps.Result = KeepWaiting()
spawn{RunKeep()}
# This time both arms finished and execution continued past the sync.
Steps.ArmTwoRan = 1
Steps.PastSync = 1
Steps.Result = 5
-->

Wrapping a `return` in a helper function is therefore a way to *keep* the
concurrency expression alive rather than a way to escape it, which is the
opposite of what the shape of the code suggests at a glance.

#### Detached Bodies Cannot Return

The behaviour above applies to `sync`, `race` and `rush` arms, which run as part
of the enclosing function's frame. `spawn`, `branch` and `defer` bodies are
*detached* from that frame, so there is nothing for a `return` to return from,
and the compiler rejects it, with a separate diagnostic for each of the three:

<!--versetest
assert_semantic_error(3551):
    Wait51()<suspends>:void = {}
    Spawner()<suspends>:void =
        spawn:
            Wait51()
            return
assert_semantic_error(3556):
    Wait56()<suspends>:void = {}
    Brancher()<suspends>:void =
        branch:
            Wait56()
            return
assert_semantic_error(3566):
    Deferrer():void =
        defer:
            return
        return
<#
-->
<!-- 12 -->
```verse
Spawner()<suspends>:void =
    spawn:
        Wait()
        return       # ERROR - cannot return out of spawn

Brancher()<suspends>:void =
    branch:
        Wait()
        return       # ERROR - cannot return out of branch

Deferrer():void =
    defer:
        return       # ERROR - cannot return out of defer
    return
```
<!-- #> -->

The same applies inside a class or archetype body block. To end a detached body
early, use `break` in a loop or restructure with a failable expression.

| Construct | `return` behaviour |
|---|---|
| `sync`, `race`, `rush` arm | Returns from the enclosing function; the expression is abandoned |
| Function *called by* an arm | Returns from that function only; the arm and the expression continue |
| `spawn`, `branch`, `defer`, class / archetype body block | Rejected at compile time |

### The branch Expression

The `branch` expression represents fire-and-forget concurrency within
a structured context. When you encounter a branch, it immediately
starts executing its body as a background task and then, without any
pause or hesitation, continues with the next expression. There's no
waiting, no result collection, just a task spinning off to do its work
while the main flow proceeds unimpeded.

<!--versetest
cell<public> := class:
    var MainFlowContinued:int = 0
    var BodyFinished:int = 0
    var CleanedUp:int = 0
-->
<!-- 13 -->
```verse
Trace := cell{}

FireAndForget()<suspends>:void =
    branch:
        defer { set Trace.CleanedUp = 1 }
        NextTick()
        set Trace.BodyFinished = 1     # Never reached
    set Trace.MainFlowContinued = 1    # Reached without waiting
```
<!--versetest
RunFire()<suspends>:void =
    FireAndForget()
spawn{RunFire()}
# The main flow did not wait for the branch. And when FireAndForget returned,
# the branch was cancelled: its defer ran, but its last line never did.
Trace.MainFlowContinued = 1
Trace.BodyFinished = 0
Trace.CleanedUp = 1
-->


Branch excels at handling side effects that shouldn't interrupt the
main game flow but that are acceptable to lose if the enclosing scope
ends. Think about triggering particle effects that play out over time,
starting background music that fades in gradually, or pre-loading
assets that might be needed soon. These operations need to happen, but
there's no reason to make the player wait for them to complete. Branch
lets you express this "start it and move on" pattern directly.

The critical semantic of branch is its **cancellation behavior**: a
branch task is automatically canceled when execution leaves the
enclosing function scope, whether that happens through normal
completion, failure, or cancellation from above. This is the
structured concurrency guarantee at work—branches cannot outlive their
parent context, which prevents orphaned tasks from accumulating. But
it also means branch is the wrong choice for work that *must*
complete, like logging analytics events or saving player progress. For
those tasks, use `spawn` instead, which runs independently of its
creating scope.

Like rush, branch faces restrictions with iteration expressions. You
cannot use branch directly inside a loop or for body, as this could
lead to an unbounded number of background tasks. The workaround
remains the same: encapsulate the branch in an async function and call
that function from your iteration.

## Unstructured Concurrency

### The spawn Expression

While structured concurrency handles most concurrent programming needs
elegantly, sometimes you need to break free from the hierarchical task
structure. The `spawn` expression is Verse's single concession to
unstructured concurrency, allowing you to start an async operation
that lives independently of its creating scope. Think of spawn as an
emergency escape hatch—powerful when needed, but not your first choice
for typical concurrent patterns.

<!--versetest
LongRunningTask()  <suspends> :int=0
-->
<!-- 14 -->
```verse
# spawn returns a task(t) you can hold on to
BackgroundTask:task(int) = spawn{LongRunningTask()}

# Or fire and forget, discarding the task
spawn{LongRunningTask()}
```

What makes spawn unique is its ability to work anywhere. Unlike all
the structured concurrency expressions that require an async context,
spawn works in immediate functions, class constructors, module
initialization—anywhere you can write code. This universality comes
with responsibility. The task you spawn becomes a free agent,
continuing its work regardless of what happens to the code that
created it. There's no automatic cleanup, no parent-child
relationship, just an independent task pursuing its goal.

The spawned function must have the `<suspends>` effect. You **cannot**
spawn functions with the `<decides>` effect:

<!--versetest
assert_semantic_error(3511, 3538):
    FailableWork12()<decides>:void =
        false?
    G12()<suspends>:void =
        spawn{FailableWork12()}
-->
<!-- 15 -->
```verse
AsyncWork()<suspends>:void =
    Sleep(1.0)
    Print("Background work complete")

spawn{AsyncWork()}      # Valid

# A <decides> function here is rejected twice over:
# the call needs square brackets, and spawn needs an async body.
```

This restriction exists because spawned tasks run independently
without a parent to handle their failure. Since `<suspends>` and
`<decides>` cannot be combined on the same function, and spawn needs
`<suspends>`, functions with `<decides>` cannot be spawned. If you
need to spawn failable work, wrap it in a suspends function that
handles the failure internally:

<!--versetest
FailableWork<public>()<computes><decides>:void = {}
-->
<!-- 16 -->
```verse
SafeFailableWork()<suspends>:void =
    if (FailableWork[]):
        Print("Work succeeded")
    else:
        Print("Work failed, but handled gracefully")

spawn{SafeFailableWork()}  # Valid - failure handled inside
```

Spawn finds its place in specific architectural patterns. Global
background services that monitor game state throughout the entire
session, cleanup tasks that must complete even if the triggering
context ends, or integration points where immediate code needs to
trigger async operations—these scenarios justify reaching for spawn
over the structured alternatives.

The contrast with branch illuminates the design philosophy. Branch
gives you structured fire-and-forget concurrency, but its tasks are
canceled when the enclosing scope exits. Spawn gives you tasks that
outlive their creating scope—use it when the work *must* complete
regardless of what happens to the code that started it. Choose branch
when cancellation is acceptable; choose spawn when it is not.

Set side by side, the two differ in one line and in nothing else. Replacing
the `branch` of the previous example with a `spawn` of the same work leaves
the background task running after its creator has returned, so the `defer`
that fired under `branch` has not fired here:

<!--versetest
cell<public> := class:
    var MainFlowContinued:int = 0
    var BodyFinished:int = 0
    var CleanedUp:int = 0
-->
<!-- 17 -->
```verse
Trace := cell{}

Background()<suspends>:void =
    defer { set Trace.CleanedUp = 1 }
    NextTick()
    set Trace.BodyFinished = 1

FireAndForget()<suspends>:void =
    spawn{Background()}
    set Trace.MainFlowContinued = 1
```
<!--versetest
RunFire()<suspends>:void =
    FireAndForget()
spawn{RunFire()}
# Still suspended at the NextTick, neither finished nor cleaned up: alive.
Trace.MainFlowContinued = 1
Trace.BodyFinished = 0
Trace.CleanedUp = 0
-->

The `spawn` expression returns a `task(t)` object where `t` is the
return type of the spawned function. This task object provides methods
to control and query the spawned operation—you can cancel it, wait for
it to complete, or check its current state. While spawn creates
independent tasks that do not require management, having access to the
task object gives you the power to intervene when needed. See the "The
task(t) Type" section below for complete details on task objects and
their capabilities.

## The task(t) Type

The `task(t)` type represents a handle to an executing async
operation, where `t` is the return type of the operation. While Verse
creates tasks automatically behind the scenes for all async
expressions, only `spawn` gives you direct access to a task object
that you can control and query. The annotated form in the previous section,
`BackgroundTask:task(int) = spawn{LongRunningTask()}`, is that handle: the
`int` comes from the return type of the function being spawned.

Task objects provide a rich interface for managing async operations:
you can cancel them, wait for their completion, and query their
current state. This control is essential for implementing robust
concurrent systems where you need to coordinate multiple independent
operations.

A task moves through several distinct states during its lifetime. It is
*active* while it is running or suspended but has not yet finished, still
doing work or waiting to resume. It is *completed* once it has finished
successfully and returned a result; completion is terminal, and a completed
task never changes state again. It is *canceled* if it was stopped before it
could complete, which is likewise terminal — canceled tasks cannot resume.

Two further words name unions of those states rather than states of their own.
A task is *settled* if it has reached either the completed or the canceled
state, which is to say that it is no longer executing. It is *uninterrupted*
if it completed successfully without being canceled, and *interrupted* if it
was canceled; these last two are simply aliases for completed and canceled.

### Task.Cancel()

!!! note "Unreleased Feature"
    The Cancel() method has not been released at this time.
	
The `Cancel()` method requests cancellation of a task. This is a safe
operation that can be called on any task in any state. It does carry the
`<suspends>` effect itself, though, so it can only be called from a suspending
context — an immediate function cannot cancel a task, and trying is rejected:

<!--versetest
cell<public> := class:
    var CleanedUp:int = 0
-->
<!-- 18 -->
```verse
Trace := cell{}

Watcher()<suspends>:void =
    defer { set Trace.CleanedUp = 1 }
    NextTick()

StopWatching()<suspends>:void =
    LongTask:task(void) = spawn{Watcher()}
    LongTask.Cancel()
    LongTask.Cancel()      # Safe: cancelling twice is not an error
```
<!--versetest
RunStop()<suspends>:void =
    StopWatching()
spawn{RunStop()}
# The cancelled task unwound, so its defer ran.
Trace.CleanedUp = 1
-->

Cancellation is cooperative—the task does not stop
immediately. Instead, it receives a cancellation signal that is
checked at the next suspension point. The task then unwinds
gracefully, allowing cleanup code to run. See "Suspension Points and
Cancellation" below for details on when cancellation takes effect.

Calling `Cancel()` on an already completed task is safe and has no
effect. This means you can cancel tasks without worrying about race
conditions between completion and cancellation.

### Task.Await()

The `Await()` method suspends the calling context until the task
completes, then returns the task's result:

Four behaviours are worth holding on to. `Await()` blocks until completion: if
the task is still running, it suspends until the task finishes. It returns
immediately if the task is already complete, handing back the cached result
instantly — the result is sticky. It can therefore be called multiple times,
and awaiting the same task repeatedly always gives the same result. And it
propagates cancellation: if the awaited task was canceled, `Await()` passes
that cancellation on to the caller.

<!--versetest
BackgroundWork()<computes><suspends>:int=42
-->
<!-- 19 -->
```verse
AwaitTwice()<suspends>:tuple(int, int) =
    ComputeTask:task(int) = spawn{BackgroundWork()}
    First := ComputeTask.Await()     # Suspends until the task finishes
    Second := ComputeTask.Await()    # Returns the cached result at once
    (First, Second)
```
<!--versetest
var Pair:tuple(int, int) = (0, 0)
RunAwait()<suspends>:void =
    set Pair = AwaitTwice()
spawn{RunAwait()}
Pair(0) = 42
Pair(0) = Pair(1)
-->

### Common Task Patterns

A task can be given a deadline by awaiting it in one arm of a `race` and
cancelling it from the other:

<!--versetest
ProcessData()<suspends>:void={}
-->
<!-- 20 -->
```verse
StartTask()<suspends>:void =
    DataTask:task(void) = spawn{ProcessData()}

    race:
        block:
            DataTask.Await()
            Print("Task completed")
        block:
            Sleep(5.0)
            DataTask.Cancel()
            Print("Task timed out and was canceled")
```

Several independent tasks can be joined back together by awaiting all of them
inside a single `sync`:

<!--versetest
cell<public> := class:
    var Ids:tuple(int, int, int) = (0, 0, 0)
Task1()<suspends>:int=1
Task2()<suspends>:int=2
Task3()<suspends>:int=3
-->
<!-- 21 -->
```verse
AwaitAll()<suspends>:tuple(int, int, int) =
    T1 := spawn{Task1()}
    T2 := spawn{Task2()}
    T3 := spawn{Task3()}
    sync:
        T1.Await()
        T2.Await()
        T3.Await()
```
<!--versetest
Joined := cell{}
RunAll()<suspends>:void =
    set Joined.Ids = AwaitAll()
spawn{RunAll()}
Joined.Ids = (1, 2, 3)
-->


### Suspension Points and Cancellation

Task cancellation in Verse follows a cooperative model. Rather than
forcefully terminating tasks, which could leave resources in
inconsistent states, Verse sends cancellation signals that tasks check
at **suspension points**. When a task receives a cancellation signal,
it has the opportunity to clean up resources before terminating. This
cooperative approach prevents data corruption while ensuring
responsive cancellation.

Suspension points are the specific locations where async tasks can
pause and resume. These are the only places where:

- A task can be suspended to allow other tasks to run
- Cancellation signals are checked and processed
- The runtime can switch between concurrent tasks

There are four kinds of them. The timing operations `Sleep` and `NextTick`
suspend — for a duration and for one simulation update respectively — and
check for cancellation when they resume. A call to any suspending function is
a suspension point at the call itself. A structured concurrency expression
suspends both when it is entered and when it completes. And a task operation
such as `Await()` suspends for as long as it is waiting.

<!--versetest
ComputeValue<public>()<suspends>:int = 42
Op1()<suspends>:void = {}
Op2()<suspends>:void = {}
-->
<!-- 22 -->
```verse
EveryKind()<suspends>:int =
    Sleep(1.0)                          # Timing
    NextTick()                          # Timing
    Op1()                               # Call to a suspending function
    sync:                               # Entering and leaving the sync
        Op1()
        Op2()
    MyTask:task(int) = spawn{ComputeValue()}
    MyTask.Await()                      # Task operation
```

Immediate code between suspension points runs without interruption. If you
write a long computation loop without any suspension points, that task cannot
be canceled until it reaches the next suspension point:

<!--versetest
cell<public> := class:
    var Steps:int = 0
-->
<!-- 23 -->
```verse
Counted := cell{}

# No suspension point in the loop, so cancellation cannot land inside it
LongComputation()<suspends>:void =
    for (I := 0..9):
        set Counted.Steps += 1
    NextTick()                # First cancellation check happens here

CancelEarly()<suspends>:void =
    Task := spawn{LongComputation()}
    Task.Cancel()
```
<!--versetest
RunCancel()<suspends>:void =
    CancelEarly()
spawn{RunCancel()}
# All ten iterations ran despite the cancellation arriving immediately.
Counted.Steps = 10
-->

If you need to make long-running computations cancellable, insert
periodic suspension points using `Sleep(0.0)` or `NextTick()`, which
yield control without actual delay but allow cancellation checking.
Moving the suspension point inside the loop changes the outcome
completely — the task is now cancelled after its first iteration:

<!--versetest
cell<public> := class:
    var Steps:int = 0
-->
<!-- 24 -->
```verse
Counted := cell{}

ResponsiveComputation()<suspends>:void =
    for (I := 0..9):
        set Counted.Steps += 1
        NextTick()            # Cancellation checked every iteration

CancelEarly()<suspends>:void =
    Task := spawn{ResponsiveComputation()}
    Task.Cancel()
```
<!--versetest
RunCancel()<suspends>:void =
    CancelEarly()
spawn{RunCancel()}
Counted.Steps = 1
-->

Cancellation cascades through the task hierarchy. When a parent task
is canceled, all its child tasks receive cancellation signals
too. This cascading behavior maintains the invariant that child tasks
do not outlive their parents in structured concurrency, preventing
resource leaks and ensuring predictable cleanup. In a race expression,
for example, when the winner completes, the race task sends
cancellation signals to all losing subtasks, which then cascade to any
tasks those losers might have created.

## Cleanup and Resource Management

### The defer: Block

The `defer:` block provides guaranteed cleanup code that executes when
its enclosing scope exits — whether through normal completion, failure,
or cancellation. For the full description of `defer` semantics,
including execution order, scope rules, and restrictions, see
[Defer Statements](07_control.md#defer-statements).

This section focuses on how `defer` interacts with concurrency.

#### defer with Cancellation

When a concurrent task is canceled (e.g., a losing `race` arm or a
cancelled `spawn`), defer blocks execute as the stack unwinds from the
cancellation point. This makes `defer` essential for resource cleanup
in concurrent code:

<!--versetest
cell<public> := class:
    var Released:int = 0
-->
<!-- 25 -->
```verse
Trace := cell{}

AcquireResource()<computes>:int = 42
ReleaseResource(R:int):void = set Trace.Released = R
LongRunningTask(:int)<suspends>:void = loop { NextTick() }

ProcessWithTimeout()<suspends>:void =
    race:
        block:
            Resource := AcquireResource()
            defer:
                ReleaseResource(Resource)  # Runs when this arm is cancelled
            LongRunningTask(Resource)
        Sleep(10.0)                        # Timeout arm
```
<!--versetest
RunTimeout()<suspends>:void =
    ProcessWithTimeout()
spawn{RunTimeout()}
# The timeout won, the first arm was cancelled, and the resource came back.
Trace.Released = 42
-->

#### No Suspending in defer

defer blocks cannot contain suspending operations. This ensures
cleanup happens immediately without delay. Each suspending call inside a
`defer` is reported separately:

<!--versetest
ValidDefer()<suspends>:void =
    defer:
        Print("Cleanup happens immediately")
    Sleep(1.0)
assert_semantic_error(3512, 3512):
    Nap(:float)<transacts><suspends>:void = {}
    Tick()<transacts><suspends>:void = {}
    BadDefer()<suspends>:void =
        defer:
            Nap(1.0)
            Tick()
        Nap(2.0)
<#
-->
<!-- 26 -->
```verse
BadDefer()<suspends>:void =
    defer:
        Sleep(1.0)      # ERROR - a defer cannot suspend
        NextTick()      # ERROR - nor can it wait a tick
    Sleep(2.0)
```
<!-- #> -->

This restriction is essential — if defer blocks could suspend, cleanup
could be delayed indefinitely, defeating their purpose as guaranteed
finalization. However, defer blocks *can* use `spawn` for
fire-and-forget async operations.

## Timing Functions

The fundamental timing function suspends execution for a specified duration:

<!--versetest
ExpensiveOperation(:int):void={}
-->
<!-- 27 -->
```verse
Pace()<suspends>:void =
    Sleep(1.0)      # One second
    Sleep(0.0)      # One frame, the smallest possible delay
```

The `Sleep(0.0)` pattern deserves special attention. While it does not
add actual delay, it serves two critical purposes. It creates a suspension
point, which is where cancellation gets checked, and it yields control to
other concurrent tasks, so that no single task can monopolize execution.
Insert it into long-running loops to keep tasks responsive to cancellation
and to share execution time fairly with other concurrent operations, exactly
as in the cancellable-loop example above.

### NextTick()

!!! note "Unreleased Feature"
    NextTick() has not yet been released. 

The `NextTick()` function suspends execution until the next simulation
update (tick). Unlike `Sleep(0.0)` which yields control and may resume
in the same tick if no other work is pending, `NextTick()` guarantees
that at least one simulation update will occur before resuming. It is
essential for game logic that needs to be synchronized with simulation
updates:

<!--versetest
ProcessGameLogic():void={}
UpdatePhysics():void={}
CheckCollisions():void={}
PerformAction():void={}
-->
<!-- 28 -->
```verse
# Process game logic every tick
GameLoop()<suspends>:void =
    loop:
        ProcessGameLogic()
        UpdatePhysics()
        CheckCollisions()
        NextTick()      # Wait for the next simulation update

# Delay an action by a specific number of ticks
DelayByTicks(TickCount:int)<suspends>:void =
    for (I := 1..TickCount):
        NextTick()

ActAfterFiveTicks()<suspends>:void =
    DelayByTicks(5)
    PerformAction()
```

The two yielding calls promise different things, and the difference
matters as soon as a piece of code has to line up with the simulation
clock rather than merely get out of the way:

| Feature   | Sleep(0.0)              | NextTick() |
|---------  |------------             |------------|
| Timing    | May resume in same tick | Always waits for next tick |
| Use case  | Yield for cancellation checks | Synchronize with simulation updates |
| Guarantee | Creates suspension point | Guarantees tick boundary |

Both create suspension points for cancellation, but `NextTick()`
provides stronger timing guarantees when you need to align with the
simulation clock.

Three timing patterns cover most of what gameplay code needs — acting after
a delay, running a loop until it is told to stop, and stepping an animation
one frame at a time:

<!--versetest
DoAction():void={}
ProcessFrame()<computes>:logic=false
Float(:int)<computes>:float=0.0
SetPosition(:float):void={}
-->
<!-- 29 -->
```verse
PerformDelayedAction()<suspends>:void =
    Sleep(2.0)
    DoAction()

TickBasedLoop()<suspends>:void =
    loop:
        if (ProcessFrame() = false):
            break
        NextTick()      # Once per simulation tick

AnimateMovement(Start:float, End:float)<suspends>:void =
    for (T := 0..10):
        SetPosition(Lerp(Start, End, Float(T) / 10.0))
        Sleep(0.0)      # One frame per step
```

### Getting Current Time: GetSecondsSinceEpoch

The `GetSecondsSinceEpoch()` function returns the current Unix
timestamp—the number of seconds elapsed since January 1, 1970,
00:00:00 UTC. This function is essential for timestamping events,
measuring durations, and synchronizing with external systems that use
Unix time.

<!-- 30 -->
```verse
LogEvent(Message:string)<transacts>:void =
    Timestamp := GetSecondsSinceEpoch()
    Print("[{Timestamp}] {Message}")
```
<!--versetest
LogEvent("match started")
GetSecondsSinceEpoch() > 0.0
-->

#### Time Is Frozen Within a Transaction

Within a single transaction, `GetSecondsSinceEpoch()` returns the same
value every time it is called. This ensures deterministic behavior and
prevents time-related race conditions. Two readings taken either side
of an arbitrary amount of work therefore always differ by zero:

<!--versetest
DoExpensiveWork()<transacts>:void = {}
PerformDatabaseUpdates()<transacts>:void = {}
-->
<!-- 31 -->
```verse
MeasureTransactionTime()<transacts>:float =
    StartTime := GetSecondsSinceEpoch()

    DoExpensiveWork()
    PerformDatabaseUpdates()

    EndTime := GetSecondsSinceEpoch()
    EndTime - StartTime            # Always 0.0
```
<!--versetest
MeasureTransactionTime() = 0.0
-->

This transactional consistency is intentional—it prevents
non-deterministic behavior where transaction retry could produce
different results due to time progression. If the transaction fails
and is retried, all calls to `GetSecondsSinceEpoch()` in the retried
attempt will return a new consistent timestamp.

The timestamp is useful anywhere real-world time has to be recorded
rather than measured: logging and debugging, session tracking, rate
limiting, and absolute timestamps handed to external systems,
databases, or APIs that speak Unix time. Session tracking is the
simplest of these—stamp the object on creation and subtract later:

<!--versetest-->
<!-- 32 -->
```verse
player_session := class:
    LoginTime:float

MakeSession()<transacts>:player_session =
    player_session{LoginTime := GetSecondsSinceEpoch()}

GetSessionDuration(S:player_session)<transacts>:float =
    GetSecondsSinceEpoch() - S.LoginTime
```
<!--versetest
GetSessionDuration(MakeSession()) = 0.0
-->

Rate limiting is the same idea with a comparison attached. Because the
clock does not move inside a transaction, a limiter consulted twice in
the same transaction always refuses the second request:

<!--versetest
PerformAction()<transacts>:void={}
ShowCooldownMessage()<transacts>:void={}
-->
<!-- 33 -->
```verse
rate_limiter := class:
    var LastAction:float = 0.0
    Cooldown:float = 5.0            # Five second cooldown

    CanAct()<transacts><decides>:void =
        Now := GetSecondsSinceEpoch()
        Now - LastAction >= Cooldown
        set LastAction = Now

TryAct(Limiter:rate_limiter)<transacts>:void =
    if (Limiter.CanAct[]):
        PerformAction()
    else:
        ShowCooldownMessage()
```
<!--versetest
Gate := rate_limiter{}
Gate.CanAct[]
not Gate.CanAct[]
-->

A few properties of the function are worth remembering. It returns a
`float` of seconds, which may have fractional parts for millisecond
precision. It lives in the `/Verse.org/Verse` module, so reaching it
needs `using { /Verse.org/Verse }`. It is not affected by `Sleep()` or
by any other suspension, because it measures real-world time. It is
consistent within a transaction for determinism, and each new
transaction gets a fresh timestamp.

Combined with `Sleep`, it gives you wall-clock scheduling: poll the
real time from a loop that yields, and act once the deadline passes.

<!--versetest
PerformAction<public>()<suspends>:void = {}
-->
<!-- 34 -->
```verse
# Wait until a specific time
WaitUntil(TargetTime:float)<suspends>:void =
    loop:
        if (GetSecondsSinceEpoch() >= TargetTime) then:
            break
        Sleep(0.1)  # Check every 100ms

# Schedule an action for the future
ScheduleDelayedAction(DelaySeconds:float)<suspends>:void =
    TargetTime := GetSecondsSinceEpoch() + DelaySeconds
    WaitUntil(TargetTime)
    PerformAction()
```

Note that the transactional consistency means you cannot use
`GetSecondsSinceEpoch()` to measure time within a single
transaction. For measuring execution time of operations that do not
span transactions, use profiling tools or external timing mechanisms.

## Events and Synchronization

Events provide synchronization primitives for coordinating between
concurrent tasks. They implement producer-consumer and observer
patterns, allowing tasks to signal each other and wait for specific
conditions. Events bridge the gap between independent concurrent
operations, enabling communication without shared mutable state.

### Basic Events

The `event(t)` type creates a communication channel where producers
signal values and consumers await them. Each signal delivers one value
to each awaiting task:

<!--versetest
cell<public> := class:
    var Received:int = 0
-->
<!-- 35 -->
```verse
Consumed := cell{}
GameEvent := event(int){}          # A channel carrying integers

# Consumer: awaits values from the event
ConsumerTask()<suspends>:void =
    set Consumed.Received = GameEvent.Await()

# Producer: signals values to the event
ProducerTask()<suspends>:void =
    Sleep(1.0)
    GameEvent.Signal(42)

Exchange()<suspends>:void =
    sync:
        ConsumerTask()
        ProducerTask()
```
<!--versetest
Run()<suspends>:void =
    Exchange()
spawn{Run()}
Consumed.Received = 42
-->

When `Await()` is called on an event, the calling task suspends until
another task calls `Signal()` with a value. The signaled value is
delivered to one waiting task, and execution resumes. If multiple
tasks await the same event, each `Signal()` wakes exactly one
awaiter—signals and awaits pair up one-to-one.

The pairing is strictly one-way in time: a `Signal()` that arrives
while nobody is waiting is discarded rather than queued. A basic event
is a rendezvous, not a mailbox, which is why the consumer above is
started first and the producer only signals after a delay.

This one-to-one matching makes events perfect for task
coordination. Think of a player action system: the input handler
signals button presses while the gameplay system awaits them. Or
consider an AI pathfinding request: the game logic signals destination
requests while the pathfinding system awaits and processes them.

Events work naturally with structured concurrency. You can use them
within `sync` blocks to coordinate parallel operations, or combine
them with `race` to implement timeouts on event waiting:

<!--versetest
cell<public> := class:
    var Got:?int = false
-->
<!-- 36 -->
```verse
Outcome := cell{}
GameEvent := event(int){}

AwaitWithTimeout()<suspends>:?int =
    race:
        block:
            Value := GameEvent.Await()
            option{Value}
        block:
            Sleep(5.0)
            false                    # Timed out, no value received
```
<!--versetest
Run()<suspends>:void =
    set Outcome.Got = AwaitWithTimeout()
spawn{Run()}
not Outcome.Got?
-->

Declaring the result type as `?int` is what makes the two arms agree:
one yields `option{Value}` and the other yields the empty option
`false`. Without that declaration the inferred common supertype widens
all the way to `comparable`, and unwrapping the result with `?` is
rejected with "No overload of the function `operator'?'`
matches the provided arguments (:comparable)".

### Sticky Events

!!! note "Unreleased Feature"
    Sticky Events have not yet been released and is not currently available.

While basic events deliver each signal to exactly one awaiter,
`sticky_event(t)` remembers the last signaled value and delivers it to
all subsequent awaits until a new value is signaled:

<!--NoCompile-->
<!-- 37 -->
```verse
StateEvent := sticky_event(int){}

# Signal once
StateEvent.Signal(100)

# Multiple awaits all receive the same value
Value1 := StateEvent.Await()  # Gets 100
Value2 := StateEvent.Await()  # Gets 100 again
Value3 := StateEvent.Await()  # Still gets 100

# New signal updates the sticky value
StateEvent.Signal(200)
Value4 := StateEvent.Await()  # Gets 200
Value5 := StateEvent.Await()  # Also gets 200
```

Sticky events excel at representing state changes that multiple
consumers need to observe. Unlike basic events where each signal
disappears after one await, sticky events maintain the current
state. Consider a game phase system: when the phase changes from
"Lobby" to "Playing", every system that checks the phase should see
"Playing", not have one system consume the signal while others miss
it.

The sticky behavior creates a form of eventually consistent state. If
a task awaits a sticky event, it is guaranteed to see the most recent
signal, even if that signal occurred before the await. This makes
sticky events ideal for configuration updates, mode switches, or any
scenario where "what's the current state?" matters more than "what
just changed?".

### Subscribable Events

!!! note "Unreleased Feature"
    Subscribable Events have not yet been released and is not currently available.

The `subscribable_event` type implements the observer pattern,
allowing multiple handlers to react to each signal. Unlike events
where awaiting tasks explicitly wait, subscribable events let you
register callback functions that execute automatically when values are
signaled:

<!--NoCompile-->
<!-- 38 -->
```verse
LogScore(:int):void={}
UpdateUI(:int):void={}
CheckAchievements(:int):void={}

ScoreEvent := subscribable_event(int){}

# Subscribe multiple handlers
Logger := ScoreEvent.Subscribe(LogScore)
UIUpdater := ScoreEvent.Subscribe(UpdateUI)
AchievementChecker := ScoreEvent.Subscribe(CheckAchievements)

# Signal invokes all subscribed handlers
ScoreEvent.Signal(1000)  # Calls LogScore(1000), UpdateUI(1000), CheckAchievements(1000)

# Unsubscribe to stop receiving signals
Logger.Cancel()
ScoreEvent.Signal(2000)  # Only calls UpdateUI and CheckAchievements
```

Each subscription returns a `cancelable` object that lets you
unsubscribe by calling `Cancel()`. Once canceled, that handler stops
receiving signals. This provides fine-grained control over handler
lifetimes, essential for systems that come and go during gameplay.

Subscribable events shine in broadcast scenarios where multiple
independent systems need to react to the same occurrence. When a
player scores points, the UI needs to update, the audio system needs
to play a sound, the achievement system needs to check for unlocks,
and the analytics system needs to log the event. With subscribable
events, each system registers its handler independently, and every
signal reaches all interested parties.

### The awaitable and signalable Interfaces

Events are built on two fundamental interfaces that you can use to
create custom synchronization types. Both already exist in
`/Verse.org/Concurrency`, so the declarations below are shown for
reference rather than written out again — repeating them in your own
code is rejected as an ambiguous definition:

<!--NoCompile-->
<!-- 39 -->
```verse
awaitable(t:type) := interface:
    Await()<suspends>:t

signalable(t:type) := interface:
    Signal(Value:t):void
```

The `awaitable` interface represents anything that can be waited on,
while `signalable` represents anything that can send signals. By
separating these capabilities, Verse enables precise control over who
can produce values versus who can consume them.

You can pass `awaitable` parameters to functions that should only read
from an event, preventing accidental signals:

<!--versetest
ProcessValue(:int):void={}
assert_semantic_error(3506):
    G65a(Source:awaitable(int))<suspends>:void =
        Source.Signal(123)
assert_semantic_error(3506):
    G65b(Target:signalable(int))<suspends>:void =
        Value := Target.Await()
-->
<!-- 40 -->
```verse
# This function can only await, not signal
ConsumerFunction(Source:awaitable(int))<suspends>:void =
    Value := Source.Await()
    ProcessValue(Value)
    # Source.Signal(123)  is an error: awaitable has no Signal

# This function can only signal, not await
ProducerFunction(Target:signalable(int)):void =
    Target.Signal(42)
    # Value := Target.Await()  is an error: signalable has no Await
```
<!--versetest
Channel := event(int){}
Reader:awaitable(int) = Channel      # event(t) implements both
Writer:signalable(int) = Channel
ProducerFunction(Writer)
-->

This separation creates clear interfaces for producer-consumer
relationships. A queue implementation might expose an `awaitable`
interface to consumers for reading and a `signalable` interface to
producers for writing, ensuring neither side can accidentally use the
wrong operation.

### Transactional Behavior

Event subscriptions participate in Verse's transactional system. If a
transaction containing a `Subscribe()` call fails and rolls back, the
subscription never takes effect:

Similarly, `Cancel()` operations are transactional. If you cancel a
subscription within a transaction that later fails, the subscription
remains active. Both directions are visible in the same fragment:

<!--NoCompile-->
<!-- 41 -->
```verse
Handler(:int):void={}

MyEvent := subscribable_event(int){}

if:
    Sub := MyEvent.Subscribe(Handler)
    false?                  # Transaction fails, so the subscribe is undone
MyEvent.Signal(100)         # Handler is not called

Live := MyEvent.Subscribe(Handler)
if:
    Live.Cancel()
    false?                  # Transaction fails, so the cancel is undone
MyEvent.Signal(100)         # Handler is called after all
```

This transactional integration ensures that event subscriptions
maintain consistency with other transactional operations. If you are
setting up a complex system where subscribing to events is part of a
larger initialization that might fail, the transaction system
guarantees that either all initialization succeeds or none of it does,
preventing partial setups that could cause subtle bugs.

### Event Patterns and Use Cases

Basic events implement request-response patterns between systems. A
service loops on a request channel and answers on a reply channel,
while the caller does the mirror image. The one detail that has to be
right is the order: because a signal with no awaiter is dropped, the
caller must already be parked on `PathResponse` before it signals
`PathRequest`. Spawning the await first arranges exactly that, since a
spawned body runs up to its first suspension point immediately:

<!--versetest
FindPath(Start:int, Goal:int)<computes>:int = Start * 10 + Goal
cell<public> := class:
    var Path:int = 0
-->
<!-- 42 -->
```verse
Found := cell{}
PathRequest := event(tuple(int, int)){}   # (start, goal)
PathResponse := event(int){}              # Path result

PathfindingService()<suspends>:void =
    loop:
        Request := PathRequest.Await()
        PathResponse.Signal(FindPath(Request(0), Request(1)))

RequestPath(Start:int, Goal:int)<suspends>:int =
    Reply:task(int) = spawn{PathResponse.Await()}   # Park first
    PathRequest.Signal((Start, Goal))
    Reply.Await()
```
<!--versetest
Ask()<suspends>:void =
    set Found.Path = RequestPath(3, 7)
spawn{PathfindingService()}
spawn{Ask()}
Found.Path = 37
-->

Signalling before parking loses the answer and the caller waits
forever. Sticky events avoid that hazard entirely, which is what makes
them the right choice for state that several systems need to observe:
every system that awaits the phase sees the current one, whether it
started awaiting before or after the change was signalled.

<!--NoCompile-->
<!-- 43 -->
```verse
PhaseChange := sticky_event(game_phase){}

# Both systems see the current phase, whenever they start awaiting
UISystem()<suspends>:void =
    loop:
        UIUpdate(PhaseChange.Await())

AISystem()<suspends>:void =
    loop:
        AIUpdate(PhaseChange.Await())
```

Subscribable events cover the remaining case, where many systems must
react to the same occurrence without any of them awaiting: each
registers a handler with `Subscribe`, as in the inventory, audio,
achievement and logging systems of the earlier example, and a single
`Signal` reaches all of them.

Events complement structured concurrency by providing communication
channels that outlive individual concurrent operations. While `sync`,
`race`, `rush`, and `branch` organize how tasks execute relative to
each other, events organize how tasks share information and coordinate
their actions.

## Common Patterns and Best Practices

Implement operations with timeouts using `race`:

<!--versetest
ActualOperation()<suspends>:void={}
-->
<!-- 44 -->
```verse
PerformWithTimeout()<suspends>:logic =
    race:
        block:
            ActualOperation()
            true  # Success
        block:
            Sleep(5.0)  # 5 second timeout
            false  # Timeout
```

Initialize multiple systems concurrently:

<!--versetest
LoadAssets()<suspends>:void={}
ConnectToServer()<suspends>:void={}
InitializeUI()<suspends>:void={}
PrepareAudio()<suspends>:void={}
-->
<!-- 45 -->
```verse
InitializeGame()<suspends>:void =
    sync:
        LoadAssets()
        ConnectToServer()
        InitializeUI()
        PrepareAudio()
    Print("Game ready!")
```

Start background tasks that do not block gameplay:

<!--versetest
MonitorPlayerStats()<suspends>:void={}
UpdateLeaderboards()<suspends>:void={}
ProcessAchievements()<suspends>:void={}
-->
<!-- 46 -->
```verse
StartBackgroundSystems()<suspends>:void =
    branch:
        MonitorPlayerStats()
    branch:
        UpdateLeaderboards()
    branch:
        ProcessAchievements()
    # Main game continues while background tasks run
```

Spawn entities with delays:

<!--versetest
enemy_class := class {     Spawn()<suspends>:void={} }
-->
<!-- 47 -->
```verse
SpawnWave(Enemies:[]enemy_class)<suspends>:void =
    for (Enemy : Enemies):
        spawn{Enemy.Spawn()}
        Sleep(0.5)  # Half second between spawns
```

## Limitations and Considerations

### Iteration Restrictions

The interaction between iteration and certain concurrency expressions
requires careful consideration. Rush and branch cannot be used
directly inside loop or for bodies, a restriction that prevents
unbounded task accumulation. When you write a loop that might execute
hundreds or thousands of times, allowing rush or branch directly would
create that many background tasks, potentially overwhelming the
system.

<!--versetest
Operation1()<suspends>:void = {}
Operation2()<suspends>:void = {}

ProcessWithRush(I:int)<suspends>:void =
    rush:
        Operation1()
        Operation2()

M()<suspends>:void =
    for (I := 0..10):
        ProcessWithRush(I)
assert_semantic_error(3552):
    Op76()<suspends>:void = {}
    G76()<suspends>:void =
        for (I := 0..10):
            rush:
                Op76()
                Op76()
<#
-->
<!-- 48 -->
```verse
for (I := 0..10):
    rush:                    # ERROR: rush is not allowed in a loop
        Operation1()
        Operation2()

# Wrapping the rush in a function is the way round it
ProcessWithRush(I:int)<suspends>:void =
    rush:
        Operation1()
        Operation2()

for (I := 0..10):
    ProcessWithRush(I)
```
<!-- #> -->

This restriction forces you to be intentional about creating
background tasks in iterations. By wrapping the concurrent operation
in a function, you acknowledge the task creation and make it explicit
in your code structure. This small friction prevents accidental
resource exhaustion while maintaining the flexibility to use these
patterns when genuinely needed.

### Abstraction Over Implementation

Verse deliberately abstracts away the underlying threading and
scheduling mechanisms. You will not find thread creation APIs,
thread-local storage, or explicit synchronization primitives like
mutexes or semaphores. This is not a limitation but a design
philosophy. By working with higher-level task abstractions, Verse
eliminates entire categories of bugs—no data races, no deadlocks from
incorrect lock ordering, no forgotten unlock calls.

The concurrency model is cooperative rather than preemptive. Tasks
voluntarily yield control at suspension points rather than being
forcibly interrupted by a scheduler. This cooperative nature makes
reasoning about concurrent code easier since you know exactly where
task switches can occur. It also integrates naturally with game
engines' frame-based execution models, where predictable timing is
crucial.

### Effect Interactions

The effect system that makes Verse's concurrency safe also introduces
some restrictions. The `decides` effect, which marks functions that
can fail, cannot be combined with the `suspends` effect; writing both
on one signature reports "The suspends and decides effects are
mutually exclusive and may not be used together." This separation
keeps the failure model and the concurrency model orthogonal,
preventing complex interactions that would be difficult to reason
about. The remedy is to split the two halves apart, deciding in one
function and suspending in another:

<!--versetest
assert_semantic_error(3656):
    Nap(:float)<transacts><suspends>:void = {}
    G80(Count:int)<decides><suspends>:void =
        Nap(1.0)
        Count > 0
-->
<!-- 49 -->
```verse
HasAmmo(Count:int)<transacts><decides>:void =
    Count > 0

ReloadWeapon()<suspends>:void =
    Sleep(2.0)

FireOrReload(Count:int)<suspends>:void =
    if (HasAmmo[Count]):
        Print("Bang")
    else:
        ReloadWeapon()
```

Transactional operations and certain device-specific operations may
also have restrictions when used in concurrent contexts, ensuring that
operations that must be atomic remain so.
