import Foundation

// MARK: - Phase 3: Request Lifecycle Rules
//
// Single source of truth for WHO may do WHAT at each status. Pure
// Foundation logic (no SwiftUI/SwiftData) so it can be unit-tested and
// reused unchanged when Firebase is added (e.g. mirrored in security
// rules / Cloud Functions).
//
//   OPEN ──I Can Help (any other account)──▶ IN DISCUSSION
//   IN DISCUSSION: create agreement (requester or helper, once)
//                  confirm agreement (each party separately)
//              ──both confirmed──▶ CONFIRMED
//   CONFIRMED ──Start Help (helper)──▶ IN PROGRESS
//   IN PROGRESS ──Mark as Completed (requester)──▶ COMPLETED
//                 (helper receives the completion reward, once)


// MARK: - Role

/// The signed-in account's relationship to one request.
enum RequestRole: Equatable {

    case requester
    case helper
    /// Signed in, but not part of this request.
    case viewer
    case signedOut

    var isParticipant: Bool {
        self == .requester || self == .helper
    }
}


// MARK: - Action

enum RequestAction: Equatable {

    case offerHelp
    case createAgreement
    case confirmAgreement
    case markPaid
    case startHelp
    case completeHelp
    case sendMessage
    /// Phase 4: retrieving / reading a request's conversation.
    case readMessages
}


// MARK: - Errors

enum LifecycleError: LocalizedError, Equatable {

    case notSignedIn
    case requestNotFound
    case notAuthorized
    case invalidStatus(CommunityRequestStatus)
    case helperAlreadyAssigned
    case agreementAlreadyExists
    case agreementMissing
    case alreadyConfirmed
    case agreementNotConfirmed
    case paymentNotApplicable
    case alreadyPaid
    case rewardAlreadyGranted

    var errorDescription: String? {

        switch self {

        case .notSignedIn:
            return "Please log in again."

        case .requestNotFound:
            return "This request could not be found."

        case .notAuthorized:
            return "You are not allowed to do this for this request."

        case .invalidStatus(let status):
            return "This action is not available while the request is \(status.rawValue.capitalized)."

        case .helperAlreadyAssigned:
            return "Someone is already helping with this request."

        case .agreementAlreadyExists:
            return "A help agreement already exists for this request."

        case .agreementMissing:
            return "Create a help agreement first."

        case .alreadyConfirmed:
            return "You have already confirmed this agreement."

        case .agreementNotConfirmed:
            return "Both people must confirm the agreement first."

        case .paymentNotApplicable:
            return "This agreement has no payment."

        case .alreadyPaid:
            return "This agreement is already marked as paid."

        case .rewardAlreadyGranted:
            return "This request has already been completed."
        }
    }
}


// MARK: - Lifecycle

enum RequestLifecycle {

    /// Points the helper earns when a request they helped with is
    /// completed.
    static let pointsPerCompletedHelp = 3

    /// The only allowed status order.
    static let statusOrder: [CommunityRequestStatus] = [
        .open,
        .inDiscussion,
        .confirmed,
        .inProgress,
        .completed
    ]

    static func nextStatus(
        after status: CommunityRequestStatus
    ) -> CommunityRequestStatus? {

        guard let index = statusOrder.firstIndex(of: status),
              index + 1 < statusOrder.count
        else {
            return nil
        }

        return statusOrder[index + 1]
    }

    /// True only for a single step forward in `statusOrder`.
    static func isValidTransition(
        from current: CommunityRequestStatus,
        to next: CommunityRequestStatus
    ) -> Bool {
        nextStatus(after: current) == next
    }

    static func role(
        of userID: UUID?,
        in request: CommunityRequest
    ) -> RequestRole {

        guard let userID else {
            return .signedOut
        }

        if request.requesterID == userID {
            return .requester
        }

        if request.helperID == userID {
            return .helper
        }

        return .viewer
    }

    /// Throws the reason an action is not allowed; returns normally when it
    /// is allowed.
    static func validate(
        _ action: RequestAction,
        role: RequestRole,
        request: CommunityRequest,
        agreement: HelpAgreement?
    ) throws {

        guard role != .signedOut else {
            throw LifecycleError.notSignedIn
        }

        switch action {

        case .offerHelp:

            guard role == .viewer else {
                throw LifecycleError.notAuthorized
            }

            guard request.status == .open else {
                throw LifecycleError.invalidStatus(request.status)
            }

            guard request.helperID == nil else {
                throw LifecycleError.helperAlreadyAssigned
            }

            // Phase 7 (Option A): a request whose requester has no account
            // can never be confirmed or completed, so nobody may start
            // helping with it (prevents a permanent IN DISCUSSION dead end).
            guard request.requesterID != nil else {
                throw LifecycleError.notAuthorized
            }

        case .createAgreement:

            guard role.isParticipant else {
                throw LifecycleError.notAuthorized
            }

            guard request.status == .inDiscussion,
                  request.helperID != nil
            else {
                throw LifecycleError.invalidStatus(request.status)
            }

            guard agreement == nil else {
                throw LifecycleError.agreementAlreadyExists
            }

        case .confirmAgreement:

            guard role.isParticipant else {
                throw LifecycleError.notAuthorized
            }

            guard request.status == .inDiscussion else {
                throw LifecycleError.invalidStatus(request.status)
            }

            guard let agreement else {
                throw LifecycleError.agreementMissing
            }

            let alreadyConfirmed = role == .requester
                ? agreement.isConfirmedByRequester
                : agreement.isConfirmedByHelper

            guard !alreadyConfirmed else {
                throw LifecycleError.alreadyConfirmed
            }

        case .markPaid:

            guard role == .requester else {
                throw LifecycleError.notAuthorized
            }

            guard let agreement else {
                throw LifecycleError.agreementMissing
            }

            guard agreement.isConfirmed else {
                throw LifecycleError.agreementNotConfirmed
            }

            guard agreement.exchangeType != .noPayment else {
                throw LifecycleError.paymentNotApplicable
            }

            guard agreement.paymentStatus == .pending else {
                throw LifecycleError.alreadyPaid
            }

        case .startHelp:

            guard role == .helper else {
                throw LifecycleError.notAuthorized
            }

            guard request.status == .confirmed else {
                throw LifecycleError.invalidStatus(request.status)
            }

            guard agreement?.isConfirmed == true else {
                throw LifecycleError.agreementNotConfirmed
            }

        case .completeHelp:

            guard role == .requester else {
                throw LifecycleError.notAuthorized
            }

            guard !request.completionRewardGranted else {
                throw LifecycleError.rewardAlreadyGranted
            }

            guard request.status == .inProgress,
                  request.helperID != nil
            else {
                throw LifecycleError.invalidStatus(request.status)
            }

        case .sendMessage:

            guard role.isParticipant else {
                throw LifecycleError.notAuthorized
            }

            guard request.status != .open else {
                throw LifecycleError.invalidStatus(request.status)
            }

        case .readMessages:

            // Phase 4: only the requester and helper may read the
            // conversation, at any status (history stays readable after
            // completion).
            guard role.isParticipant else {
                throw LifecycleError.notAuthorized
            }
        }
    }

    /// Convenience for views: is the action allowed right now?
    static func isAllowed(
        _ action: RequestAction,
        role: RequestRole,
        request: CommunityRequest,
        agreement: HelpAgreement?
    ) -> Bool {
        (try? validate(action, role: role, request: request, agreement: agreement)) != nil
    }
}
