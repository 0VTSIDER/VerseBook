# Talks, Lectures, and Tutorials

A curated collection of presentations about the Verse programming language, from language design and theory to practical game development.

---

## Language Design

Talks covering Verse's core design as a functional logic language, its type system, and its formal foundations.

**[The Verse Programming Language](https://www.youtube.com/watch?v=5prkKOIilJg)**
:   Official introduction to Verse as a universal programming language for building interconnected virtual worlds and the metaverse.

**Beyond Functional Programming: A Taste of Verse** -- Simon Peyton Jones (& Tim Sweeney)
:   Introduces Verse as a functional logic language with existential variables, unification, and expressions that yield multiple values. Given at multiple venues in 2023:
:   [Lambda Days](https://www.youtube.com/watch?v=OJv8rFap0Nw) (with Sweeney) | [ZuriHac](https://www.youtube.com/watch?v=9B5p9T4A2fY) | [Wheeler Lecture, Cambridge](https://www.youtube.com/watch?v=xNaaP8BKr7Y) | [IRIF Paris](https://www.youtube.com/watch?v=q1-KQ3QDe0U) | [other](https://www.youtube.com/watch?v=832JF1o7Ck8)

**Verse: A New Functional Logic Language** -- Lennart Augustsson
:   What functional logic programming is about, what it looks like to program in Verse, and how meaning is given to programs using rewrite rules. Given at multiple venues:
:   [GOTO Copenhagen 2023](https://www.youtube.com/watch?v=8CXhiSddjAI) | [REBASE, SPLASH 2024](https://www.youtube.com/watch?v=F1n7bBanKYQ) | [Lambda World 2025](https://www.youtube.com/watch?v=iVfY1jxqS70)

**[On Creating a Virtual Machine for Verse](https://conf.researchr.org/details/icfp-splash-2025/rebase-2025-papers/4/On-creating-a-virtual-machine-for-Verse-a-language-for-programming-in-a-shared-real-)**
:   Saam Barati | REBASE, SPLASH 2025 (Singapore)
:   Covers AutoRTFM and a bespoke VM designed from scratch for Verse's runtime, object model, and bytecode interpreter.

**[Another Taste of Verse](https://www.youtube.com/watch?v=QIiU-QGzcqc)**
:   Simon Peyton Jones | ZuriHac 2026
:   Sequel to the 2023 talk, focusing on types, patterns, and denotational semantics. How Verse unifies expressions, patterns, and types into the same thing.

---

## Research

Academic papers and their conference presentations.

**[The Verse Calculus: A Core Calculus for Deterministic Functional Logic Programming](https://www.youtube.com/watch?v=5P2pz1Xtjww)**
:   Augustsson, Breitner, Claessen, Jhala, Peyton Jones, Shivers, Sweeney, Steele | ICFP 2023 (**Distinguished Paper**)
:   Presents the Verse Calculus with a small-step rewrite semantics, confluent for well-behaved terms, enabling lambda-calculus-style reasoning about functional logic programs.

---

## Lectures

In-depth lecture series for learning Verse's theoretical foundations.

**The Verse Language: Types, Semantics, and Verification**
:   Simon Peyton Jones | OPLSS 2026 (Oregon Programming Languages Summer School)
:   Four lectures covering Verse's type system, rewrite semantics, denotational semantics, and verification.
:   Code: [augustss/verse-semantics](https://github.com/augustss/verse-semantics)

| Lecture | Topic | Video | Slides | Notes |
|---------|-------|-------|--------|-------|
| 1 | Introduction | [mp4](https://www.cs.uoregon.edu/research/summerschool/summer26/_videos/Peyton-Jones1.mp4) | [pptx](https://www.cs.uoregon.edu/research/summerschool/summer26/_lectures/SPJ_Verse.pptx) | [pdf](https://www.cs.uoregon.edu/research/summerschool/summer26/_lectures/SPJ_lecture1_Notes.pdf) |
| 2 | Rewrite Semantics | [mp4](https://www.cs.uoregon.edu/research/summerschool/summer26/_videos/Peyton-Jones2.mp4) | [pptx](https://www.cs.uoregon.edu/research/summerschool/summer26/_lectures/SPJ_Verse_rewrite_semantics.pptx) | [pdf](https://www.cs.uoregon.edu/research/summerschool/summer26/_lectures/SPJ_lecture2_Notes.pdf) |
| 3 | Denotational Semantics | [mp4](https://www.cs.uoregon.edu/research/summerschool/summer26/_videos/Peyton-Jones3.mp4) | [pptx](https://www.cs.uoregon.edu/research/summerschool/summer26/_lectures/SPJ_Verse_denotational_semantics.pptx) | [pdf](https://www.cs.uoregon.edu/research/summerschool/summer26/_lectures/SPJ_lecture3_Notes.pdf) |
| 4 | Verification | [mp4](https://www.cs.uoregon.edu/research/summerschool/summer26/_videos/Peyton-Jones4.mp4) | [pptx](https://www.cs.uoregon.edu/research/summerschool/summer26/_lectures/SPJ_Verse_verification.pptx) | [pdf](https://www.cs.uoregon.edu/research/summerschool/summer26/_lectures/SPJ_lecture4_Notes.pdf) |

[Supporting Figures (pdf)](https://www.cs.uoregon.edu/research/summerschool/summer26/_lectures/SPJ_Verse-figures.pdf)

---

## Interviews and Discussions

Longer-form conversations about Verse's design philosophy and its place in the programming language landscape.

**[Exploring Verse, Haskell, Language Design and Teaching](https://www.youtube.com/watch?v=UBgam9XUHs0)**
:   Simon Peyton Jones, interviewed by Kris Jenkins | Developer Voices, Jan 2024
:   SPJ's history with Haskell, formalizing functional logic programming with Verse, building languages from a small tightly-designed core, and computing education.

**[Haskell, Verse, Strong Type Systems and Tasteful Abstractions](https://www.youtube.com/watch?v=xv-WApd-pSY)**
:   Simon Peyton Jones | Rock the Code, Apr 2026
:   Type classes, GADTs, Verse's types-as-functions and expressions-as-patterns, subtyping vs parametric polymorphism, and LLM-generated code verification.

---

## Unreal Fest

**[Verse Concurrency -- Time Flow: Everything, Everywhere in UEFN, All at Once](https://www.youtube.com/watch?v=B3WiSgKXsrg)**
:   Conan Reis (Principal Engineer, Epic Games) | Unreal Fest 2023
:   How Verse concurrency makes it easy to author sophisticated time-based behavior. Covers each of Verse's concurrency expressions and related API constructs.

**[Powering Up Your Projects With Scene Graph and Verse](https://www.youtube.com/watch?v=IW8HjoO-Uj0)**
:   Epic Games | Unreal Fest Orlando 2025
:   Building games in UEFN with Scene Graph and Verse: creating reusable prefabs and custom Verse components with side-by-side comparisons.

---

## Tutorials

**[Coding with Verse](https://www.youtube.com/watch?v=VGbqxnBPQqk)**
:   Multi-part series covering Verse from the ground up inside UEFN.

**[UEFN Verse For Beginners Free Course](https://www.youtube.com/playlist?list=PLRDkUKkyMRU_Kr2yncnDV_HkP-5r07yDW)**
:   Multi-lesson course covering variables, functions, and building your first game with Verse.

---

## Third-Party Overviews

**[Chapter and Verse: An Outsider's Overview](https://www.youtube.com/watch?v=VBT0j14rn5c)**
:   Paul Snively | LambdaConf 2025
:   Verse's influences (Ontic, Icon, Curry), relationship to existing Epic languages (UnrealScript, Blueprints), the Verse Calculus, and its Curry-style type system. 