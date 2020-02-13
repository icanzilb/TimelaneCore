# Timelane Core

The core logging package for [Timelane](https://timelane.tools)

You would usually use a higher level package which provides helpers to use with certain libraries like [TimelaneCombine](https://github.com/icanzilb/TimelaneCombine).

In case you would like to report events directly to Timelane or you'd like to add Timelane support for a new library, this is the package to consider.

## Logging subscriptions

To plot a lane for a subscription called "My Subscription":

```swift
// Subscription begin
let subscription = Timelane.Subscription(name: "My Subscription")
subscription.begin(source: "MyFile.swift:120")

// Successfully end subscription
subscription.end(state: .completed)

// End with failure
subscription.end(state: .error("Error Message"))
```

## Logging events

To plot a lane with the values and events for a subscription called "My Subscription":

```swift
let subscription = Timelane.Subscription(name: "My Subscription")

subscription.event(value: .value(String(describing: 10)), source: "MyFile.swift:120")
subscription.event(value: .value(String(describing: 20)), source: "MyFile.swift:120")

subscription.end(state: .completed)
// or
subscription.end(state: .error("My Error"))
```
