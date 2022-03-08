# GraniteUI - v0.0 - WIP

![Travis CI Build](https://app.travis-ci.com/0xZala/GraniteUI.svg?branch=main)
[![Swift 5.3](https://img.shields.io/badge/swift-5.5-brightgreen.svg)](https://github.com/apple/swift)
[![xcode-version](https://img.shields.io/badge/xcode-12.5-brightgreen)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-BSD_2--Clause-orange.svg)](https://opensource.org/licenses/BSD-2-Clause)

A powerful **SwiftUI Architecture** that merges Redux event handling and state management with functional programming. While bringing powerful workflows to streamline CoreML/Metal work and to interact with ground-breaking services like *IPFS*.

The Granite architecture provides:

- Testability and Isolation. Routing, business, view logic, have independant classes/protocols to be inherited. Each component is positioned to be decoupled and independant from eachother.
- Tooling for developer productivity. Granite comes with pre-built components to streamline Metal, CoreML integration as well as UserDefault-backed local storage solutions.
- View Library. Granite comes with a comprehensive view library that can speed up development, offering thought out button templates and other UX solutions.
- IPFS capability, any media type you handle with Granite's framework can be pinned and distributed from IPFS with ease. Based on: https://github.com/ipfs-shipyard/swift-ipfs-http-client

# High Level Overview

> The `Docs` folder has usage examples for each file. Some are still WIP.

- GraniteComponent **(80%)**
	- GraniteCommand **(50%)**
		- GraniteCenter **(50%)**
			- GraniteState **(90%)**
		- GraniteExpedition (Reducers) **(90%)**
- GraniteRelay **(80%)**
	- GraniteService **(50%)**
		- GraniteCenter **(50%)**
			- GraniteState **(90%)**
		- GraniteExpedition (Reducers) **(90%)**
- GraniteEvent **(80%)**
	- GraniteBeam **(80%)**
	- GraniteBeamType **(80%)**
- [GraniteIPFS **(25%)**](#GraniteIPFS)
- GraniteMetal/MarbleKit **(0%)**
- Types **(3%)**
	- GraniteConnection **(0%)**
		- GraniteSatellite **(0%)**
		- GraniteAdAstra **(10%)**
	- GraniteDock **(0%)**
	- GraniteLaunch **(0%)**

> Documentation is a work in progress. Reference the above for progress. It is to show the main types one may experience when using the architecture. An example Application is provided to speed-up bootstrapping an application with Granite until Documentation is updated further.

![High Level Overview](https://0xZala.s3.us-west-1.amazonaws.com/docs/graniteui/high_level_overview.png)

Every SwiftUI View is a `GraniteComponent` with business logic handled in reducer like design standards (`Expeditions`) with distinct state files to hold mutable data. 

`GraniteRelays` are modular `Services` lightweight components that can handle non UI dependant actions updating data globally to any components hosting them. The `GraniteCenter` distinctly defines your rules of `Services` which are known as `GraniteRelays` allowed to be accessed. `GraniteCenters` also allow the definition of Reducers and Dependencies the component requires. It is the `cornerstone` of a `GraniteComponent`.

## GraniteComponent & GraniteRelay

![GraniteComponent Data Path](https://0xZala.s3.us-west-1.amazonaws.com/docs/graniteui/granite_component_datapath.png)

### GraniteComponent
```swift
import GraniteUI

public struct MainComponent: GraniteComponent {
    @ObservedObject
    public var command: GraniteCommand<MainCenter, MainState> = .init()
    
    public init() {}
    
    public var body: some View {}
}
```

Base GraniteComponent classes resemble SwiftUI View classes, but have the ability to modularize object states, events, and business logic. Let the View class only be UI/UX, divide responsibility of code, to make it easier to develop complex experiences.

```swift
@ObservedObject
public var command: GraniteCommand<MainCenter, MainState> = .init()
```
The `ObservedObject` is crucial for a component to *see* it's relevant State file and Center file. Centers handle the pre-loading and linking of reducers, services and constants a View class would need to access, while helping the State be available for Reducers to mutate and be read from a View file for UX based decisions on state data.


### GraniteRelay
```swift
public struct MarqueRelay: GraniteRelay {
    @ObservedObject
    public var command: GraniteService<MarqueCenter, MarqueState> = .init()
    
    public init() {}
    
    public func setup() {}
    
    public func clean() {}
    
    public func cancel() {}
}
```

GraniteRelays resemble *microservices* floating specialized logic that can attach to host components to deliver specific tasks.

![GraniteRelay Event Behavior](https://0xZala.s3.us-west-1.amazonaws.com/docs/graniteui/granite_relay_event_behavior.png)

In a functional datapath, re-draws are expensive when data updates within Components. We can *control* this with distinct enum flags when sending updates to a relay's or a component's own expeditions. 

> In an app that is displaying realtime financial data of stocks or securities. It's cheaper and more effecient to have a singular service to contact a back-end service to retrieve updates **once**. The challenge to update all components in an application to handle these updated changes can be handled via a GraniteRelay and `broadcasting`.

## GraniteCenter & GraniteState
```swift
public enum ListenStage {
    case listening
    case none
}

public class ListenState: GraniteState {
    var exhibitionStage: ExhibitionStage
    var stage: ListenStage = .none
    var intent: ExhibitionIntent
    var wantsToListen: Bool = false
    
    public init(stage: ExhibitionStage, intent: ExhibitionIntent) {
        self.exhibitionStage = stage
        self.intent = intent
    }
    
    public required init() {
        self.exhibitionStage = .none
        self.intent = .none
    }
}

public class ListenCenter: GraniteCenter<ListenState> {
    @GraniteDependency
    var envDependency: EnvironmentDependency
    
    public override var expeditions: [GraniteBaseExpedition] {
        [
            ListenStageExpedition.Discovery(),
            ListenPermissionsExpedition.Discovery(),
            RadioExpedition.Discovery(),
            StopExpedition.Discovery()
        ]
    }
    
    public override var links: [GraniteLink] {
        [
            .onAppear(ListenEvents.Prepare(), .dependant)
        ]
    }
    
    public override var behavior: GraniteEventBehavior {
        .broadcastable
    }
}

```

A basic state file contains both the `Center` and `State` classes, one could seperate them, but they are together for maintaining easy context of defined expeditions in a `Center` and state variables required within each.

This file is referencing a component called `ListenComponent` a view that handles a music player.

```swift
@GraniteDependency
var envDependency: EnvironmentDependency
```

We will dive into this later in the README, but defining a usable dependency for easy access of shareable mutable data of multiple components. Can be updated directly from a view with a specialized setter, with a preference to update within expeditions exclusively.

```swift
public override var expeditions: [GraniteBaseExpedition] {
    [
        ListenStageExpedition.Discovery(),
        ListenPermissionsExpedition.Discovery(),
        RadioExpedition.Discovery(),
        StopExpedition.Discovery()
    ]
}
```
Expeditions are Granite's *Reducers*, they need to become executable `.Discovery()` does this making them available in the frameworks' back-end when being searched for. An `associatedtype` of a relevant `Event` is used to link a expedition with it's calling function. We'll get into this in the `GraniteExpedition` section of the README.

```swift
public override var links: [GraniteLink] {
    [
        .onAppear(ListenEvents.Prepare(), .dependant)
    ]
}
```
Bringing `viewDidAppear`'s handling in `UIKit` to SwiftUI. Fire events on a components appear, setting flags like `dependant` which runs the event only once `@GraniteDependency` wrapped deps are linked to the component or `.always` firing the event every time a component loads/re-draws.

```swift
public override var behavior: GraniteEventBehavior {
    .broadcastable
}
```

Components can use `GraniteEventBehaviors` as well. When referencing the last visual, a `broadcastable` allows this component to be searched for `expeditions` to execute based on a parent or this component's services update. Other options like `.quiet (default)` allow it to be skipped to improve performance.


## GraniteEvent

```swift
GraniteButtonComponent(state: .init("♫_le_Verre",
	                            textColor: Brand.Colors.white,
	                            colors: [Brand.Colors.yellow, Brand.Colors.purple],
	                            padding: .init(Brand.Padding.medium,
	                                           Brand.Padding.small,
	                                           Brand.Padding.medium,
	                                           Brand.Padding.small),
	                            action: {
	                                sendEvent(ListenEvents.Radio.Begin()) // <---
	                            }))
```

Events are easy to send from a View's action handler in a component.

```swift
struct ListenEvents {
    public struct Listen: GraniteEvent {
        public struct Permissions: GraniteEvent {
            public var behavior: GraniteEventBehavior {
                .quiet
            }
        }
    }
}
``` 
Defined in a seperate file. Events can come with pre-defined `behaviors` without specifying a `GraniteBeamType` in the `sendEvent` action.

```swift
sendEvent(ListenEvents.Radio.Begin(), haptic: .light)
```
Easily setup haptic responses with an additional parameter.

```swift
public enum GraniteHaptic {
    case light
    case none // default
}
```
Currently supported haptic types, more to be added.        

## GraniteExpedition

```swift
import GraniteUI
import Combine
import MarbleKit
import Foundation

struct ListenPermissionsExpedition: GraniteExpedition {
    typealias ExpeditionEvent = ListenEvents.Listen.Permissions
    typealias ExpeditionState = ListenState
    
    func reduce(
        event: ExpeditionEvent,
        state: ExpeditionState,
        connection: GraniteConnection,
        publisher: inout AnyPublisher<GraniteEvent, Never>) {
        
        if GlobalDefaults.Permissions.Listen.canListen {
            connection.request(ExhibitionEvents.Glass.Listen(), .contact)
            state.wantsToListen = false
            state.stage = .listening
        } else {
            #if os(macOS)
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    storage.update(GlobalDefaults.Permissions.Listen.on)
                } else {
                    storage.update(GlobalDefaults.Permissions.Listen.off)
                }
            }
            #else
            let audioSession = AVAudioSession.sharedInstance()
            
            audioSession.requestRecordPermission { granted in
                if granted {
                    storage.update(GlobalDefaults.Permissions.Listen.on)
                } else {
                    storage.update(GlobalDefaults.Permissions.Listen.off)
                }
            }
            #endif
        }
    }
}
```         
This is Granite's reducers. An event is fired to check and request permissions for a devices mic.

```swift
typealias ExpeditionEvent = ListenEvents.Listen.Permissions
typealias ExpeditionState = ListenState
```
These are two key types that need to match the component that linked this expedition from it's center:

```swift
public override var expeditions: [GraniteBaseExpedition] {
    [
        ListenStageExpedition.Discovery(),
        ListenPermissionsExpedition.Discovery(), // <---
        RadioExpedition.Discovery(),
        StopExpedition.Discovery()
    ]
}
```
## GraniteDependency
```swift
public class ListenCenter: GraniteCenter<ListenState> {
    @GraniteDependency
    var envDependency: EnvironmentDependency
}

```
GraniteDependencies are powerful static files that can hold mutable data in **one place** while communicating data to other components. Updated and retrieved from `Expeditions` they can maintain important data like `profile/user custom types` that may affect UI/UX behaviors across an applications' diverse component tree.

```swift
class EnvironmentDependency: GraniteDependable {
    var home: Home = .init()
    
    var user: User = .init()
    
    var exhibition: Exhibition = .init()
    
    var envSettings: EnvironmentStyle.Settings = .init()
}
```
A dependency is simply a class object that inherits from `GraniteDependable`. Building a dependency with a component is as easy as 2 lines within it's center.

```swift
@GraniteDependency
var envDependency: EnvironmentDependency
```
No extra steps or initialization required.

### Retrieving Data from a Dep in a Expedition

```swift
func reduce(event: ExpeditionEvent,
	        state: ExpeditionState,
	        connection: GraniteConnection,
	        publisher: inout AnyPublisher<GraniteEvent, Never>) {
        
    guard let envSettings = connection.retrieve(\EnvironmentDependency.envSettings) {
        return
    }
    
}
```

### Updating Data in a Dep in a Expedition

```swift
func reduce(event: ExpeditionEvent,
	        state: ExpeditionState,
	        connection: GraniteConnection,
	        publisher: inout AnyPublisher<GraniteEvent, Never>) {
        
    connection.update(\RouterDependency.authState, value: .authenticated)
    
}
```

### Updating Dep Behaviors
```swift
connection.update(\RouterDependency.authState, value: .authenticated, .here)
```
Dependencies can be updated with targeted re-draws, in case a UI element's state or UX is dependant on a dependency's variable. `.here` only redraws the called component, child components will not re-draw to maintain performance.

```swift
connection.update(\RouterDependency.authState, value: .authenticated, .target(ChildCenter.self))
```
One can target a child component, preventing any other components in a chain from re-drawing maintaining performance.

```swift
public enum GraniteLander {
    case target(GraniteAdAstra.Type)
    case home
    case quiet
    case none
}
```
The type used is called `GraniteLander` similar to `GraniteBeamType` and `GraniteEventBehavior`. `GraniteAdAstra` is a base generic protocol GraniteCenters inherit.

## GraniteAttach & GraniteListen

![GraniteAttach & Listen Datapath](https://0xZala.s3.us-west-1.amazonaws.com/docs/graniteui/granite_attach_listen.png)

```swift
public struct ExhibitionComponent: GraniteComponent {
    @ObservedObject
    public var command: GraniteCommand<ExhibitionCenter, ExhibitionState> = .init()
    
    public init() {}
    
    public var body: some View {
        InstallationComponent(state: .init(state.installations, isShowcase: true))
        	.attach(to: command) // <---
        	.listen(to: command) // <---
    }
}
```  

### Attach

`Attaching` child components to a parent's `GraniteCommand` allows a child to call a parent's hosted events and thus, its expeditions.

```swift
struct GenerateSiteResultMarqueExpedition: GraniteExpedition {
    typealias ExpeditionEvent = MarqueEvents.Pin.Site.Result
    typealias ExpeditionState = LaMarqueState

    func reduce(
        event: ExpeditionEvent,
        state: ExpeditionState,
        connection: GraniteConnection,
        publisher: inout AnyPublisher<GraniteEvent, Never>) {
        
        connection.request(ExhibitionEvents.Get(), .contact) // <---
    }
}
```
When sending an event from a Component's view's action handler or requesting an event from an Expedition a `.contact` GraniteBeamType must be provided for the event handling to channel this to it's relevant parent component.

### Listen

`Listening` allows a child's hosted events/expeditions to be called from a parent.

```swift
struct ShowcaseInstallationExpedition: GraniteExpedition {
    typealias ExpeditionEvent = InstallationEvents.Advance
    typealias ExpeditionState = InstallationState
    
    func reduce(
        event: ExpeditionEvent,
        state: ExpeditionState,
        connection: GraniteConnection,
        publisher: inout AnyPublisher<GraniteEvent, Never>) {
        guard state.installations.isNotEmpty else { return }
        
        let installation = state.installations[state.showcaseIndex]
        state.installation = installation
        state.originalImage = installation.originalImage
        
        let nextIndex = state.showcaseIndex + 1
        if nextIndex < state.installations.count {
            state.showcaseIndex = nextIndex
        } else {
            state.showcaseIndex = 0
        }
        
        connection.hear(event: CanvasEvents.Prepare.init(installation: installation)) // <---
    }
}
```
One must call `connection.hear` for the event handling to recognize a child should respond to this call.

# GraniteIPFS

```swift
let client: GraniteIPFS?
    
public init() {
    client = try? GraniteIPFS.init(host: "ipfs.infura.io", port: 5001, ssl: true)
}
```

Granite is bundled with the necessary tools to utilize IPFS right away to store and share data on the distributed web. Also allowing one to pin content.

### Adding data to IPFS

```swift
if let data = result.data.pngData() {
    do {
        try state.service.client?.add(data) { nodes in // Adding data to IPFS
            connection.request(MarqueEvents.Pin(nodes: nodes, encodedData: data)) // Sending a PIN request
        }
    } catch let error {
        GraniteLogger.info("error adding new image:\n\(error)", .expedition, focus: true)
    }
}

```

Convert any type of object into a `Data` type to prepare for adding.

### Pinning data to IPFS

```swift
do {
	if let addHash = event.nodes.first?.hash { // the `nodes` from the closure of the previous code example
		try state.service.client?.pin.add(addHash) { pinHash in
			let hash = b58String(pinHash) // IPFS public hash gateway for the pinned content
		}
	}
} catch let error {
    GraniteLogger.info("error pinning:\n\(error)", .expedition, focus: true)
}
                
```

In the future, Granite will have extensions such as `let hash = image.pin()` to handle all of the above in 1 line (aside from client init).

# Q/A, Suggestions, Want to contribute?

discord: https://discord.gg/fyXRsDEd
