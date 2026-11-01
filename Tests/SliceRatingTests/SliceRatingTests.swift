import Foundation
import SliceRating
import Testing

private let sent = RatingMoment("sent")
private let paid = RatingMoment("markedPaid")
private let day0 = Date(timeIntervalSince1970: 1_800_000_000)
private func day(_ n: Double) -> Date { day0.addingTimeInterval(n * 86_400) }

private func freshDefaults() throws -> UserDefaults {
    try #require(UserDefaults(suiteName: "slice-rating-\(UUID().uuidString)"))
}

/// Three asks: first send; first marked paid 30+ days later; 10th send 90+ days later.
private let threeSteps = [
    RatingStep(after: sent),
    RatingStep(after: paid, daysSinceLastAsk: 30),
    RatingStep(after: sent, count: 10, daysSinceLastAsk: 90),
]

@Test func asksAtSpacedHappyMoments() throws {
    let defaults = try freshDefaults()
    func ask(_ m: RatingMoment, _ d: Double, _ v: String) -> Bool {
        RatingPrompt(steps: threeSteps, keyPrefix: "reviewPrompt", defaults: defaults, version: v).record(m, now: day(d))
    }
    #expect(!ask(paid, 0, "1.0.1"))  // ask 1 is the first send
    #expect(ask(sent, 0, "1.0.1"))  // 1st sent
    #expect(!ask(sent, 1, "1.0.1"))
    #expect(!ask(paid, 40, "1.0.1"))  // same version
    #expect(!ask(paid, 20, "1.0.2"))  // under 30 days
    #expect(!ask(sent, 40, "1.0.2"))  // ask 2 is marked paid
    #expect(ask(paid, 40, "1.0.2"))
    for d in 0..<6 { #expect(!ask(sent, 50 + Double(d), "1.1")) }  // 4th–9th sent, under 90 days
    #expect(!ask(sent, 100, "1.1"))  // 10th sent but only 60 days after ask 2
    #expect(ask(sent, 140, "1.1"))  // 11th sent, 100 days
    #expect(!ask(sent, 400, "1.2"))  // the schedule has three asks
    #expect(!ask(paid, 400, "1.2"))
}

@Test func savesUnderThePrefix() throws {
    let defaults = try freshDefaults()
    let rating = RatingPrompt(steps: threeSteps, keyPrefix: "reviewPrompt", defaults: defaults, version: "2.0")
    #expect(rating.record(sent, now: day0))
    #expect(defaults.integer(forKey: "reviewPromptCount") == 1)
    #expect(defaults.integer(forKey: "reviewPromptSentCount") == 1)
    #expect(defaults.string(forKey: "reviewPromptLastVersion") == "2.0")
    #expect(defaults.object(forKey: "reviewPromptLastDate") as? Date == day0)
    #expect(rating.counterKey(paid) == "reviewPromptMarkedPaidCount")
}

@Test func countsEveryMoment() throws {
    let rating = RatingPrompt(steps: [RatingStep(after: sent, count: 3)], defaults: try freshDefaults(), version: "1")
    #expect(!rating.record(sent))
    #expect(!rating.record(paid))
    #expect(!rating.record(sent))
    #expect(rating.record(sent))  // 3rd send
    #expect(rating.count(of: sent) == 3)
    #expect(rating.count(of: paid) == 1)
    #expect(rating.askCount == 1)
}

@Test func continuesFromCountersSetByTheApp() throws {
    // An app moving from older rating code: one ask already made 10 days ago.
    let rating = RatingPrompt(steps: threeSteps, defaults: try freshDefaults(), version: "1.1")
    rating.askCount = 1
    rating.lastAskDate = day0
    rating.setCount(1, of: sent)
    #expect(!rating.record(sent, now: day(10)))
    #expect(!rating.record(paid, now: day(10)))
    #expect(rating.record(paid, now: day(31)))
}

@Test func emptyScheduleNeverAsks() throws {
    let rating = RatingPrompt(steps: [], defaults: try freshDefaults(), version: "1")
    #expect(!rating.record(sent))
}
