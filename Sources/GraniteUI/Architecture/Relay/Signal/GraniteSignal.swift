//
//  GraniteSignal.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import Foundation
import SwiftUI
import Combine

public typealias GraniteSignalPublisher = Publishers.ReceiveOn<NotificationCenter.Publisher, RunLoop>

// MARK: GraniteSignal
// A GraniteSignal can be global notification set
// where observes whom are not attached to this relay
// can still update accordingly.
//
// Should be used sparingly
//
public struct GraniteSignal {
    var event: GraniteEvent
}

extension GraniteSignal {
    public var id: Notification.Name {
        Notification.Name("\(String(describing: self))")
    }
    
    public var signal: GraniteSignalPublisher {
        NotificationCenter.default
            .publisher(for: id, object: nil).receive(on: RunLoop.main)
    }
    
    public func notify() {
        NotificationCenter.default.post(
            name: id,
            object: nil)
    }
}

// Wrap an event into a Signal to apply the above
// notification easily, for global broadcasts
//
// Should be used sparingly
//
extension GraniteEvent {
    public var relay: GraniteSignal {
        .init(event: self)
    }
}

// MARK: SignalSubscription
// A more controlled form, that expects a PassthroughSubject
// subscribing and publishing data isolated towards whom require
// it.
//
// Generally requires a pairing via a `.share(relay)` in the `body: some View`
// of components in a Component itself.
//
// Primary methodology for setting up GraniteSatellite and GraniteBeam connections.
//
struct SignalSubscription {
    let subscription: AnyCancellable?
    let signalSubject: GraniteSignalSubject
    let subscriber: SignalSubscriber = .init()
    
    init(_ subject: GraniteSignalSubject,
         completion: @escaping ((Subscribers.Completion<GraniteSignalError>) -> Void),
         receive: @escaping ((GraniteEvent) -> Void)) {
        
        subject.subscribe(subscriber)
        subscription = subject.sink(receiveCompletion: completion, receiveValue: receive)
        signalSubject = subject
    }
}

// MARK: SignalSubscriber
// Custom subscriber to handle a SignalSubscription's `sink`
//
final class SignalSubscriber: Subscriber {
    typealias Input = GraniteEvent
    typealias Failure = GraniteSignalError

   
    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }
    
    func receive(_ input: Input) -> Subscribers.Demand {
      return .unlimited
    }
  
    func receive(completion: Subscribers.Completion<GraniteSignalError>) {
        GraniteLogger.info("received - self: \(String(describing: self))", .signal)
    }
}

// MARK: Work in Progress
//
public struct MyScheduler: Scheduler {
    var runLoop: RunLoop
    var modes: [RunLoop.Mode] = [.default]

    public func schedule(after date: RunLoop.SchedulerTimeType, interval: RunLoop.SchedulerTimeType.Stride,
                    tolerance: RunLoop.SchedulerTimeType.Stride, options: Never?,
                    _ action: @escaping () -> Void) -> Cancellable {
        let timer = Timer(fire: date.date, interval: interval.magnitude, repeats: true) { timer in
            action()
        }
        for mode in modes {
            runLoop.add(timer, forMode: mode)
        }
        return AnyCancellable {
            timer.invalidate()
        }
    }

    public func schedule(after date: RunLoop.SchedulerTimeType, tolerance: RunLoop.SchedulerTimeType.Stride,
                    options: Never?, _ action: @escaping () -> Void) {
        let timer = Timer(fire: date.date, interval: 0, repeats: false) { timer in
            timer.invalidate()
            action()
        }
        for mode in modes {
            runLoop.add(timer, forMode: mode)
        }
    }

    public func schedule(options: Never?, _ action: @escaping () -> Void) {
        runLoop.perform(inModes: modes, block: action)
    }

    public var now: RunLoop.SchedulerTimeType { RunLoop.SchedulerTimeType(Date()) }
    public var minimumTolerance: RunLoop.SchedulerTimeType.Stride { RunLoop.SchedulerTimeType.Stride(0.1) }

    public typealias SchedulerTimeType = RunLoop.SchedulerTimeType
    public typealias SchedulerOptions = Never
}
