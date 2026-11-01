import Foundation

#if canImport(UIKit)
import SwiftUI
import UIKit

/// The iOS share sheet for files, text or URLs (works as a popover on iPad).
/// Present it in `.sheet`; `completion` says whether something was shared and how.
public struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var completion: ((_ completed: Bool, _ activity: UIActivity.ActivityType?) -> Void)?

    public init(items: [Any], completion: ((_ completed: Bool, _ activity: UIActivity.ActivityType?) -> Void)? = nil) {
        self.items = items
        self.completion = completion
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { activity, completed, _, _ in completion?(completed, activity) }
        return controller
    }

    public func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#endif

/// Wraps a file URL so `.sheet(item:)` can present it.
public struct SharedFile: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let url: URL

    public init(url: URL) { self.url = url }
}
