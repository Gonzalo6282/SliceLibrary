import Foundation

#if canImport(UIKit) && canImport(StoreKit)
import StoreKit
import UIKit
#endif

/// A happy moment in the app after which a rating could be asked for
/// (a document sent, a scan saved, a workout finished). The app makes its own.
public struct RatingMoment: Hashable, Sendable {
    /// Short identifier, also used in the saved counter's key
    /// (`"sent"` → `"<keyPrefix>SentCount"`).
    public let id: String

    public init(_ id: String) { self.id = id }
}

/// One rating ask in the schedule: which moment triggers it, how many times
/// that moment must have happened, and how long after the previous ask.
public struct RatingStep: Sendable, Equatable {
    public var moment: RatingMoment
    /// Times `moment` must have happened, counting this one (1 = the first time).
    public var minimumCount: Int
    /// Days since the previous ask (ignored for the first ask).
    public var minimumDaysSinceLastAsk: Double

    public init(after moment: RatingMoment, count minimumCount: Int = 1, daysSinceLastAsk: Double = 0) {
        self.moment = moment
        self.minimumCount = minimumCount
        self.minimumDaysSinceLastAsk = daysSinceLastAsk
    }
}

/// Asks for an App Store rating at spaced happy moments.
///
/// The app gives a schedule (ask 1 uses step 1, ask 2 uses step 2, …); after
/// the last step it never asks again. It never asks twice in one app version.
/// iOS also limits the pop-up to 3 a year and skips it once the user has rated.
///
/// ```swift
/// let rating = RatingPrompt(steps: [
///     RatingStep(after: .init("scanSaved"), count: 3),
///     RatingStep(after: .init("scanSaved"), count: 20, daysSinceLastAsk: 60),
/// ])
/// rating.ask(after: .init("scanSaved"))
/// ```
public struct RatingPrompt {
    public let steps: [RatingStep]
    public let keyPrefix: String
    public let defaults: UserDefaults
    public let version: String

    /// - Parameters:
    ///   - steps: The asks, in order.
    ///   - keyPrefix: Prefix for the saved values in `defaults`. Keep it the same
    ///     forever once the app is live, or the schedule starts over.
    ///   - defaults: Where the counters live (pass a suite in tests).
    ///   - version: The app version; defaults to `CFBundleShortVersionString`.
    public init(
        steps: [RatingStep], keyPrefix: String = "sliceRating", defaults: UserDefaults = .standard,
        version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    ) {
        self.steps = steps
        self.keyPrefix = keyPrefix
        self.defaults = defaults
        self.version = version
    }

    // MARK: Saved values

    /// How many times the rating has been asked for.
    public var askCount: Int {
        get { defaults.integer(forKey: keyPrefix + "Count") }
        nonmutating set { defaults.set(newValue, forKey: keyPrefix + "Count") }
    }

    /// When the rating was last asked for.
    public var lastAskDate: Date? {
        get { defaults.object(forKey: keyPrefix + "LastDate") as? Date }
        nonmutating set { defaults.set(newValue, forKey: keyPrefix + "LastDate") }
    }

    /// The app version of the last ask.
    public var lastAskVersion: String? {
        get { defaults.string(forKey: keyPrefix + "LastVersion") }
        nonmutating set { defaults.set(newValue, forKey: keyPrefix + "LastVersion") }
    }

    /// How many times `moment` has happened.
    public func count(of moment: RatingMoment) -> Int {
        defaults.integer(forKey: counterKey(moment))
    }

    /// Sets the counters directly, for an app moving from its own older rating code.
    public func setCount(_ value: Int, of moment: RatingMoment) {
        defaults.set(value, forKey: counterKey(moment))
    }

    public func counterKey(_ moment: RatingMoment) -> String {
        keyPrefix + moment.id.prefix(1).uppercased() + moment.id.dropFirst() + "Count"
    }

    // MARK: Asking

    /// Records that `moment` happened and returns true when the rating pop-up
    /// should show now (and records the ask).
    @discardableResult
    public func record(_ moment: RatingMoment, now: Date = .now) -> Bool {
        let happened = count(of: moment) + 1
        setCount(happened, of: moment)
        let asked = askCount
        guard asked < steps.count, lastAskVersion != version else { return false }
        let step = steps[asked]
        let days = lastAskDate.map { now.timeIntervalSince($0) / 86_400 } ?? .infinity
        guard step.moment == moment, happened >= step.minimumCount,
            asked == 0 || days >= step.minimumDaysSinceLastAsk
        else { return false }
        askCount = asked + 1
        lastAskDate = now
        lastAskVersion = version
        return true
    }

    #if canImport(UIKit) && canImport(StoreKit)
    /// Records `moment` and, when it's time, shows Apple's rating pop-up after
    /// `delay` (so a closing sheet doesn't hide it).
    @MainActor
    public func ask(after moment: RatingMoment, delay: Duration = .seconds(1)) {
        guard record(moment) else { return }
        Task { @MainActor in
            try? await Task.sleep(for: delay)
            Self.requestReview()
        }
    }

    /// Shows Apple's rating pop-up now, in the active window.
    @MainActor
    public static func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        AppStore.requestReview(in: scene)
    }
    #endif
}
