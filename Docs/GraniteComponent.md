# GraniteComponent

```swift
public struct MainComponent: GraniteComponent {
    @ObservedObject
    public var command: GraniteCommand<MainCenter, MainState> = .init()
    
    public init() {}
    
    public var body: some View {}
}
```

A **GraniteComponent** is a powerful `View` alternative. A corner-stone behind Granite's ability to communicate state and events between other components, reducers, actions linked to a component.

```swift
public var body: some View {
	MainComponent() // Initialize with a default state.
	MainComponent(state: MainState.init(...)) // Initialize with the component state's available. 
}
```

![Example Folder Structure for a Granite Component](https://0xZala.s3.us-west-1.amazonaws.com/docs/graniteui/GraniteComponent/folder_structure.png)

A standard `GraniteComponent` template spawns a folder structure similar to above. `Expeditions` are added later to handle specific business logic this Component is expecting. In this case User Authentication and Routing to other views upon success.

### GraniteState
```swift
public class MainState: GraniteState {}

public class MainCenter: GraniteCenter<MainState> {
    @GraniteDependency
    var routerDependency: RouterDependency // Example Dependency
    
    public override var expeditions: [GraniteBaseExpedition] {}
    
    public override var links: [GraniteLink] {}
}
```

A state file consists of two important classes. The `State` and the `Center` that are used to initialize the `GraniteCommand` `ObservedObject` we saw in the beginning of this page. 

```swift
public struct MainComponent: GraniteComponent {
    @ObservedObject
    public var command: GraniteCommand<MainCenter, MainState> = .init()
```

The resulting `Command Center` is the core internal event routing and processor for a components' reducers. Reducers or `Expeditions` are linked in a `GraniteCenter` using `GraniteEvents` to trigger, which are fired from a GraniteComponent's view body.

State changes from with an `Expedition` are observed and trigger the GraniteComponent's view to re-draw. Rendering **CAN BE CONTROLLED** with the use of `GraniteBehaviors`. One would like to control the behavior of this, for components that are handling high through-put of data, such as **Metal Textures** that need to rendered at high frame rates from either a camera source or internal texture generative source/engine.

### State Injection
State's can be initialized into Components in 2 distinct ways depending on intended *availability*. 

```swift
public var body: some View {
	MainComponent(state: .init(...)) // Passed in state initialization
	MainComponent() // Default initialization
}
```
The normal process of maintaining availability and data consistency for the life of the component itself.

```swift
public var body: some View {
	MainComponent(state: inject(\.routerDependency,
                                               target: \.router.mainState))
}
```
Or via *injection*. A dependency is a `GraniteDependable` that is defined within a component's Center. It is instantly discoverable within a Component's view body, allowing for injection into state initializations to maintain  a state's availability outside of the component's lifecycle. `UserData` or `AuthenticationData` would be an example use case. A Component to be pre-filled with personalized experiences that can be modified by other components simultaneously to affect experiences prepared. When a Component is removed from the view hierarchy the data passed in persists until the next time the target components are required for viewing.

### GraniteEvent

```swift
public var body: some View {
	GraniteButtonComponent(state: .init(...,
	                                    action: {
	                                        sendEvent(MainEvents.User())
	                                    }))
}
```

Events can be sen't from within a GraniteComponent's view body. When an event is sen't it will be heard by `Expeditions` that are attached in the Component's Center class.

```swift
struct UserExpedition: GraniteExpedition {
    typealias ExpeditionEvent = MainEvents.User
    typealias ExpeditionState = MainState
    
    func reduce(
        event: ExpeditionEvent,
        state: ExpeditionState,
        connection: GraniteConnection,
        publisher: inout AnyPublisher<GraniteEvent, Never>) {}
}
```

The business logic of relevant events, are contained within a familiar reducer structure like above. Allowing the state to be observed and event payloads.

HTTP(S) requests and other publisher events can be used to position side effects to call other Expeditions after the calling Expedition completes.

The GraniteComponent itself is passed into Expeditions via it's inherited Protocol `GraniteConnection` allowing for certain *safe* actions to take place upon the Component within the Expedition itself.

### Event Bubbling
```swift
ChildComponent(state: .init(...))
		            .attach(to: command)
		            .listen(to: command)
```
Components have to ability to trigger expeditions in Child components, through `attach` and `listen`.

```swift
struct PingExpedition: GraniteExpedition {
    typealias ExpeditionEvent = MainEvents.Ping
    typealias ExpeditionState = MainState
    
    func reduce(
        event: ExpeditionEvent,
        state: ExpeditionState,
        connection: GraniteConnection,
        publisher: inout AnyPublisher<GraniteEvent, Never>) {
        
        connection.hear(event: ChildEvents.Ping())
    }
}
```

The Expedition of the Parent Component can apply a `hear` effect on the GraniteConnection passed in. This can **BUBBLE EVENTS DOWNWARDS** until the last GraniteComponent that applies a `listen` call to its Command.

```swift
public var body: some View {
	GraniteButtonComponent(state: .init(...,
	                                    action: {
	                                        sendEvent(MainEvents.Pong(), .contact)
	                                    }))
}
```
A child component contacting a parent event from the view body, via a button tap without the use of an Expedition.

```swift
struct PingExpedition: GraniteExpedition {
    typealias ExpeditionEvent = ChildEvents.Ping
    typealias ExpeditionState = ChildState
    
    func reduce(
        event: ExpeditionEvent,
        state: ExpeditionState,
        connection: GraniteConnection,
        publisher: inout AnyPublisher<GraniteEvent, Never>) {
        
        connection.request(MainEvents.Pong(), .contact)
    }
}
```
Due to the `attach` call, child components can **BUBBLE EVENTS UPWARDS** to the **PARENT** of the last component that applied the `attach` call to its Command.

### GraniteLink

```swift
public class MainCenter: GraniteCenter<MainState> {
    @GraniteDependency
    var routerDependency: RouterDependency // Example dependendcy
    
    public override var expeditions: [GraniteBaseExpedition] {}
    
    public override var links: [GraniteLink] {
        [
            .onAppear(MainEvents.User.Prepare(), .dependant)
        ]
    }
```
Links are wrapped events that can trigger in special instances, targeting Expeditions attached to the GraniteComponent.

```swift
public enum GraniteLink: ID {
    public enum When {
        case dependant
        case onAppear
        case always
    }
```
When a Component's dependencies are loaded, when the Component appears, or any time the Component loads/re-renders: a Linked GraniteEvent can fire depending on a user-defined setting. 
