import Foundation
import RevenueCat
import StoreKit

extension PurchaseManager {
    /// A plan the user can buy, for the app's own (native) paywall.
    public struct Plan: Identifiable, Equatable {
        public enum Period: Sendable, Hashable {
            case week, month, year, lifetime
            /// Any other length, in days.
            case days(Int)
        }

        /// The product ID.
        public let id: String
        public let period: Period
        /// Localised price, e.g. "£59.99".
        public let price: String
        /// Price per month, for yearly plans ("£5.00 a month").
        public let monthlyPrice: String?
        /// Free-trial length in days, when the plan has one.
        public let trialDays: Int?

        let rcPackage: RevenueCat.Package?
        let skProduct: StoreKit.Product?

        public var isYearly: Bool { period == .year }

        /// A plan without a store product (previews and tests).
        public init(id: String, period: Period, price: String, monthlyPrice: String? = nil, trialDays: Int? = nil) {
            self.init(id: id, period: period, price: price, monthlyPrice: monthlyPrice, trialDays: trialDays, rcPackage: nil, skProduct: nil)
        }

        init(
            id: String, period: Period, price: String, monthlyPrice: String?, trialDays: Int?, rcPackage: RevenueCat.Package?,
            skProduct: StoreKit.Product?
        ) {
            self.id = id
            self.period = period
            self.price = price
            self.monthlyPrice = monthlyPrice
            self.trialDays = trialDays
            self.rcPackage = rcPackage
            self.skProduct = skProduct
        }

        public static func == (a: Plan, b: Plan) -> Bool { a.id == b.id && a.price == b.price }

        /// Sorts by the app's product order; unknown products go last, in their original order.
        static func ordered<T>(_ items: [T], by productIDs: [String], id: (T) -> String) -> [T] {
            items.enumerated().sorted { a, b in
                let ia = productIDs.firstIndex(of: id(a.element)) ?? Int.max
                let ib = productIDs.firstIndex(of: id(b.element)) ?? Int.max
                return ia == ib ? a.offset < b.offset : ia < ib
            }.map(\.element)
        }

        /// Days in a subscription period (months as 30, years as 365), for trial lengths.
        static func days(unit: PeriodUnit, value: Int) -> Int {
            switch unit {
            case .day: value
            case .week: value * 7
            case .month: value * 30
            case .year: value * 365
            }
        }

        enum PeriodUnit { case day, week, month, year }

        static func period(unit: PeriodUnit, value: Int) -> Period {
            switch (unit, value) {
            case (.week, 1): .week
            case (.month, 1): .month
            case (.year, 1): .year
            default: .days(days(unit: unit, value: value))
            }
        }
    }
}

extension RevenueCat.SubscriptionPeriod {
    var planUnit: PurchaseManager.Plan.PeriodUnit {
        switch unit {
        case .day: .day
        case .week: .week
        case .month: .month
        case .year: .year
        @unknown default: .day
        }
    }
}

extension StoreKit.Product.SubscriptionPeriod {
    var planUnit: PurchaseManager.Plan.PeriodUnit {
        switch unit {
        case .day: .day
        case .week: .week
        case .month: .month
        case .year: .year
        @unknown default: .day
        }
    }
}
