---
title: Anatomy of a file
description: What a component file holds, part by part, and what each part is for.
---

Every component is one Swift file, and two when it draws with a Metal shader.
They are all built from the same parts, so once you know one, you know what to
look for in any of them. This page walks through
[Dissolve Shader Transition](/catalog/transitions/dissolve-shader-transition/),
which has every part, the shader included.

```text
DissolveShaderTransition.swift
├─ License header
├─ Supporting types        DissolveShaderTransitionMath
├─ Documentation comment
├─ The component           DissolveShaderTransition
├─ How you call it         .transition(.dissolveShader)
├─ Supporting types        DissolveShaderTransitionEffect
├─ The demo                DissolveShaderTransitionDemo
└─ The preview             #Preview
DissolveShaderTransition.metal
```

## License header

```swift
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors
```

The first two lines of every file. Keep them when you copy it: the MIT license
asks for its notice to travel with the code. A component adapted from another
project names its own license here, and its page says where it came from.

## Documentation comment

```swift
/// A transition that dissolves a view through noise, with a glowing edge where it burns away,
/// drawn by a Metal shader. Use it as `.transition(.dissolveShader)`.
///
/// - Important: Copy two files into the same target: `DissolveShaderTransition.swift` and `DissolveShaderTransition.metal`.
///
/// With Reduce Motion on, the view fades instead.
```

It sits above the main type. It opens with one sentence on what the component
is, then says what changes with Reduce Motion or in a right-to-left layout, and
marks with `- Important:` what you must not miss. Xcode shows it in Quick Help,
when you Option-click the name, and this site builds the description of each
page from it.

## The component

```swift
struct DissolveShaderTransition: Transition {
    /// The color of the edge that burns.
    var edge: Color = .orange
    /// The size of the patches of noise, in points.
    var grain: Double = 44

    func body(content: Content, phase: TransitionPhase) -> some View { … }
}
```

The type you use. What you can change is a property with a default; what the
component needs from you has none. Each property here has its own `///`
comment, which becomes its row in the API reference of the page. The type is
internal, never public, because it lands inside your app. A component that
needs iOS 26 or 27 marks its types with `@available`, and its page says so.

## How you call it

```swift
extension Transition where Self == DissolveShaderTransition {
    static var dissolveShader: DissolveShaderTransition { DissolveShaderTransition() }
}
```

Some components add a shorthand, like `.transition(.dissolveShader)` here. One
that you apply as a modifier is a function in `extension View`, and that
function carries the documentation instead of a type.

## Supporting types

```swift
nonisolated enum DissolveShaderTransitionMath { … }

private struct DissolveShaderTransitionEffect: ViewModifier, Animatable { … }
```

Helpers start with the name of the component or are private, so two components
in the same target never clash. A helper that runs off the main actor, like the
math a shader reads, is marked `nonisolated`: the file then compiles whether or
not your project isolates to the main actor by default.

## The demo

```swift
// MARK: - Demo

struct DissolveShaderTransitionDemo: View { … }
```

The component at work with sample data. Read it to see how the component is
used. Some demos play by themselves until you touch them. Delete it once the
component is in place.

## The preview

```swift
#Preview {
    DissolveShaderTransitionDemo()
}
```

Every file ends with exactly these three lines. Xcode's canvas shows the demo
without running your app, and an agent that downloads the file checks them to
know it arrived whole.

## The shader, when there is one

```cpp title="DissolveShaderTransition.metal"
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

[[ stitchable ]] half4 DissolveShaderTransitionBurn(…) { … }
```

SwiftUI loads only compiled Metal, so a component drawn by a shader brings a
second file. Add it to the same target as the Swift file. Every function in it
starts with the name of the component, because Xcode compiles all the `.metal`
files of a target into one library, where two functions with the same name
would collide.

## What a file never has

- An `import` of another component, a package or an asset: one file is enough.
- `ObservableObject`, `@StateObject` or `@Published`: state uses `@Observable`.
- Anything public or deprecated.

[The rules every component keeps](/rules/) has the full list.
