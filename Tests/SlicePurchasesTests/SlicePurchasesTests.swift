import Foundation
import SliceUI
import Testing

@testable import SlicePurchases

private enum Placement: String, PaywallPlacementType {
    case scan, export
}

// MARK: Keys and config

@Test func infoPlistKeysNeedThePrefixAndAValue() {
    #expect(AppKey.value("appl_AbCdEfGh123", prefix: "appl_") == "appl_AbCdEfGh123")
    #expect(AppKey.value("  appl_AbCdEfGh123 ", prefix: "appl_") == "appl_AbCdEfGh123")
    #expect(AppKey.value("$(REVENUECAT_KEY)", prefix: "appl_") == nil)
    #expect(AppKey.value("appl_", prefix: "appl_") == nil)
    #expect(AppKey.value("", prefix: "pk_") == nil)
    #expect(AppKey.value(nil, prefix: "pk_") == nil)
    #expect(AppKey.value("test_abcdefgh", prefix: "appl_") == nil)
}

@Test func placementNamesComeFromTheRawValue() {
    #expect(Placement.scan.placementName == "scan")
}

// MARK: Plans

@Test func plansFollowTheAppsProductOrder() {
    let ids = ["yearly", "monthly"]
    #expect(PurchaseManager.Plan.ordered(["monthly", "other", "yearly"], by: ids) { $0 } == ["yearly", "monthly", "other"])
    #expect(PurchaseManager.Plan.ordered(["b", "a"], by: []) { $0 } == ["b", "a"])
}

@Test func periodsAndTrialDays() {
    typealias P = PurchaseManager.Plan
    #expect(P.days(unit: .day, value: 3) == 3)
    #expect(P.days(unit: .week, value: 1) == 7)
    #expect(P.days(unit: .month, value: 1) == 30)
    #expect(P.days(unit: .year, value: 1) == 365)
    #expect(P.period(unit: .year, value: 1) == .year)
    #expect(P.period(unit: .week, value: 1) == .week)
    #expect(P.period(unit: .month, value: 3) == .days(90))
    #expect(P(id: "y", period: .year, price: "£59.99").isYearly)
    #expect(!P(id: "w", period: .week, price: "£2.99").isYearly)
}

@Test func appleEntitlementNeedsAnUnrevokedUnexpiredAppProduct() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let products = ["yearly", "monthly", "lifetime"]
    #expect(PurchaseManager.isActive(productID: "yearly", revoked: false, expires: now.addingTimeInterval(60), products: products, now: now))
    #expect(PurchaseManager.isActive(productID: "lifetime", revoked: false, expires: nil, products: products, now: now))
    #expect(!PurchaseManager.isActive(productID: "yearly", revoked: false, expires: now.addingTimeInterval(-60), products: products, now: now))
    #expect(!PurchaseManager.isActive(productID: "yearly", revoked: true, expires: nil, products: products, now: now))
    #expect(!PurchaseManager.isActive(productID: "someone-elses", revoked: false, expires: nil, products: products, now: now))
}

// MARK: Gate (no Superwall: the app's own paywall)

@MainActor
private func reset(premium: Bool) {
    PurchaseManager.shared.forcedPremium = premium
    PurchaseManager.shared.recompute()
    PaywallService.shared.nativePaywall = nil
    PaywallService.shared.onPaywallShown = nil
}

@Suite(.serialized) @MainActor struct GateTests {
    @Test func premiumRunsTheActionStraightAway() {
        reset(premium: true)
        var ran = false, finished = false
        PaywallService.shared.gate(Placement.scan, onFinished: { finished = true }) { ran = true }
        #expect(ran && finished)
        #expect(PaywallService.shared.nativePaywall == nil)
        reset(premium: false)
    }

    @Test func freeUsersSeeTheAppsPaywallAndTheActionContinuesAfterBuying() throws {
        reset(premium: false)
        var shown: [String] = []
        PaywallService.shared.onPaywallShown = { shown.append("\($0)/\($1)") }
        var ran = false, finished = false
        PaywallService.shared.gate(Placement.export, onFinished: { finished = true }) { ran = true }
        let request = try #require(PaywallService.shared.nativePaywall)
        #expect(request.placementName == "export")
        #expect((request.placement as? Placement) == .export)
        #expect(shown == ["export/native"])
        #expect(!ran && !finished)
        request.onUnlock()  // bought
        #expect(ran)
        request.onClose()
        #expect(finished)
        reset(premium: false)
    }

    @Test func closingWithoutBuyingDoesntRunTheAction() throws {
        reset(premium: false)
        var ran = false, finished = 0
        PaywallService.shared.gate(Placement.scan, onFinished: { finished += 1 }) { ran = true }
        let request = try #require(PaywallService.shared.nativePaywall)
        request.onClose()
        request.onClose()
        #expect(!ran)
        #expect(finished == 1)  // onFinished runs once
        reset(premium: false)
    }

    @Test func aSecondTapWhileAPaywallIsOpenFinishesStraightAway() throws {
        reset(premium: false)
        PaywallService.shared.gate(Placement.scan) {}
        let first = try #require(PaywallService.shared.nativePaywall)
        var finished = false, ran = false
        PaywallService.shared.gate(Placement.export, onFinished: { finished = true }) { ran = true }
        #expect(finished && !ran)
        #expect(PaywallService.shared.nativePaywall?.id == first.id)
        reset(premium: false)
    }

    @Test func aSkippedSuperwallPlacementFallsBackToTheAppsPaywall() throws {
        reset(premium: false)
        let attempt = PaywallService.GateAttempt()
        var ran = false
        PaywallService.shared.unlockOrShowNative(Placement.scan, { ran = true }, attempt: attempt)
        #expect(!ran)
        #expect(PaywallService.shared.nativePaywall?.placementName == "scan")
        // Superwall can call back twice for one tap; only the first counts.
        PaywallService.shared.nativePaywall = nil
        PaywallService.shared.unlockOrShowNative(Placement.scan, { ran = true }, attempt: attempt)
        #expect(PaywallService.shared.nativePaywall == nil)
        reset(premium: false)
    }

    @Test func aPurchaseInsideSuperwallRunsTheActionOnce() {
        reset(premium: true)
        let attempt = PaywallService.GateAttempt()
        attempt.presented = true
        var runs = 0, finished = false
        attempt.onFinished = { finished = true }
        PaywallService.shared.unlockOrShowNative(Placement.scan, { runs += 1 }, attempt: attempt)
        PaywallService.shared.unlockOrShowNative(Placement.scan, { runs += 1 }, attempt: attempt)
        #expect(runs == 1)
        #expect(!finished)  // Superwall's dismiss finishes it
        attempt.finish()
        #expect(finished)
        reset(premium: false)
    }
}

// MARK: Paywall template wiring

@Test func plansBecomePaywallPlans() {
    typealias P = PurchaseManager.Plan
    let y = P(id: "y", period: .year, price: "£29.99", monthlyPrice: "£2.50", trialDays: 3).paywallInfo
    #expect(y.period == .year && y.price == "£29.99" && y.monthlyPrice == "£2.50" && y.trialDays == 3)
    #expect(P(id: "w", period: .week, price: "£1").paywallInfo.period == .week)
    #expect(P(id: "l", period: .lifetime, price: "£9").paywallInfo.period == .lifetime)
    #expect(P(id: "q", period: .days(90), price: "£9").paywallInfo.period == .year)
    #expect(P(id: "d", period: .days(3), price: "£9").paywallInfo.period == .week)
}

@Test func outcomesMapToThePaywall() {
    #expect(PurchaseManager.PurchaseOutcome.purchased.paywallOutcome == .purchased)
    #expect(PurchaseManager.PurchaseOutcome.failed("x").paywallOutcome == .failed)
    #expect(PurchaseManager.PurchaseOutcome.pending.paywallOutcome == .pending)
}

@Test @MainActor func firebaseLinkIsIgnoredWithoutRevenueCat() {
    let manager = PurchaseManager()
    #expect(!manager.usesRevenueCat)
    manager.setFirebaseAppInstanceID("abc")  // no RevenueCat: does nothing, doesn't crash
    manager.setFirebaseAppInstanceID(nil)
}
