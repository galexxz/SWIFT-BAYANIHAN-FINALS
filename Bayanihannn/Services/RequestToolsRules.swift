import Foundation

// MARK: - Phase 6: Request Tools (bookmarks, reporting, sharing)
//
// Pure Foundation logic (unit-testable, reusable with Firebase) behind the
// existing Request Details buttons: the bookmark icon, "Report Request" and
// "Copy Link" / Share. Ownership uses stable account ids only.


// MARK: - Errors

enum ReportError: LocalizedError, Equatable {

    case notSignedIn
    case requestNotFound
    case ownRequest
    case alreadyReported

    var errorDescription: String? {

        switch self {

        case .notSignedIn:
            return "Please log in again."

        case .requestNotFound:
            return "This request could not be found."

        case .ownRequest:
            return "You can't report your own request."

        case .alreadyReported:
            return "You have already reported this request. Thank you for keeping the community safe."
        }
    }
}


// MARK: - Bookmarks

enum BookmarkRules {

    static func isBookmarked(
        _ requestID: UUID,
        by userID: UUID?,
        in bookmarks: [RequestBookmark]
    ) -> Bool {

        guard let userID else {
            return false
        }

        return bookmarks.contains {
            $0.userID == userID && $0.requestID == requestID
        }
    }

    /// Adds the bookmark if missing, removes it if present — for ONE
    /// account only. Other accounts' bookmarks are never changed.
    /// - Returns: true when the request is now bookmarked.
    @discardableResult
    static func toggle(
        _ requestID: UUID,
        for userID: UUID,
        in bookmarks: inout [RequestBookmark],
        now: Date
    ) -> Bool {

        if let index = bookmarks.firstIndex(where: {
            $0.userID == userID && $0.requestID == requestID
        }) {
            bookmarks.remove(at: index)
            return false
        }

        bookmarks.append(
            RequestBookmark(userID: userID, requestID: requestID, createdAt: now)
        )

        return true
    }
}


// MARK: - Reporting

enum ReportingRules {

    static func hasReported(
        _ requestID: UUID,
        by userID: UUID?,
        in reports: [RequestReport]
    ) -> Bool {

        guard let userID else {
            return false
        }

        return reports.contains {
            $0.reporterID == userID && $0.requestID == requestID
        }
    }

    /// Throws unless `reporterID` may report `request`: signed in, not the
    /// requester, and not already reported by this account.
    static func validate(
        reporterID: UUID?,
        request: CommunityRequest?,
        existingReports: [RequestReport]
    ) throws {

        guard let reporterID else {
            throw ReportError.notSignedIn
        }

        guard let request else {
            throw ReportError.requestNotFound
        }

        guard request.requesterID != reporterID else {
            throw ReportError.ownRequest
        }

        guard !hasReported(request.id, by: reporterID, in: existingReports) else {
            throw ReportError.alreadyReported
        }
    }
}


// MARK: - Sharing

enum RequestSharing {

    /// The text used by the Share button and by "Copy Link" (there is no
    /// public web link in the local version).
    static func shareText(
        for request: CommunityRequest
    ) -> String {
        "\(request.title) — \(request.location). Help needed via Bayanihan."
    }
}
