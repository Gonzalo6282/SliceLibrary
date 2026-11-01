# SliceRating

Asks for an App Store rating at spaced happy moments, from a schedule the app
gives. Never twice in one app version; after the last step it stops. iOS also
limits Apple's pop-up to 3 a year and skips it once the user has rated.

## Use

```swift
import SliceRating

extension RatingMoment {
    static let scanSaved = RatingMoment("scanSaved")
}

let rating = RatingPrompt(steps: [
    RatingStep(after: .scanSaved, count: 3),                          // ask 1: 3rd scan saved
    RatingStep(after: .scanSaved, count: 20, daysSinceLastAsk: 60),   // ask 2: 20th scan, 60+ days later
])

// After the happy moment (on the main actor):
rating.ask(after: .scanSaved)   // records it; shows Apple's pop-up 1 s later when it's time
```

## API

| Call | What it does |
|---|---|
| `RatingMoment("id")` | A happy moment the app defines |
| `RatingStep(after:count:daysSinceLastAsk:)` | One ask: the moment, how many times it must have happened (default 1), days since the previous ask (default 0; ignored for the first) |
| `RatingPrompt(steps:keyPrefix:defaults:version:)` | The schedule. `keyPrefix` (default `"sliceRating"`) names the saved values; never change it after release. `version` defaults to the app's version. |
| `rating.ask(after:delay:)` (iOS, main actor) | Records the moment and shows the pop-up after `delay` (default 1 s) when it's time |
| `rating.record(_:now:) -> Bool` | Records the moment; true when it's time to ask (use it to show your own UI, or in tests) |
| `RatingPrompt.requestReview()` (iOS) | Apple's pop-up now, in the active window |
| `askCount`, `lastAskDate`, `lastAskVersion`, `count(of:)`, `setCount(_:of:)` | The saved values, for moving from older rating code |

Saved in `UserDefaults`: `<prefix>Count`, `<prefix>LastDate`,
`<prefix>LastVersion` and one `<prefix><Moment>Count` per moment.

Used by: Duly (`keyPrefix: "reviewPrompt"`; first send, first marked paid
30+ days later, 10th send 90+ days later).
