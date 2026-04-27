import UIKit

enum RideLifecycle {
    enum Stage {
        case requestPending
        case requestDeclined
        case requestCancelled
        case acceptingRequests
        case confirmedUpcoming
        case startsSoon
        case inProgress
        case completed
        case cancelled
    }

    struct Presentation {
        let stage: Stage
        let title: String
        let nextStep: String
        let actionTitle: String?
        let color: UIColor
        let iconSystemName: String
    }

    static func presentation(for trip: RideDataModel.MyTrip, now: Date = Date()) -> Presentation {
        if trip.ride.status == .cancelled {
            return Presentation(
                stage: .cancelled,
                title: "Cancelled",
                nextStep: "This ride is no longer active.",
                actionTitle: nil,
                color: AppDesign.Color.textTertiary,
                iconSystemName: "xmark.circle.fill"
            )
        }

        if trip.ride.status == .completed {
            return Presentation(
                stage: .completed,
                title: "Completed",
                nextStep: "Rate your ride to help classmates choose confidently.",
                actionTitle: "Rate Ride",
                color: AppDesign.Color.success,
                iconSystemName: "checkmark.circle.fill"
            )
        }

        if trip.ride.status == .ongoing {
            return Presentation(
                stage: .inProgress,
                title: "In Progress",
                nextStep: trip.role == .hosting
                    ? "Share live progress and end the ride after drop-off."
                    : "Track the ride and stay in touch with your driver.",
                actionTitle: trip.role == .hosting ? "End Ride" : "Track Ride",
                color: AppDesign.Color.primary,
                iconSystemName: "location.fill"
            )
        }

        if trip.role == .passenger {
            switch trip.requestStatus {
            case .pending:
                return Presentation(
                    stage: .requestPending,
                    title: "Request Pending",
                    nextStep: "Waiting for the driver to approve your seat.",
                    actionTitle: "Cancel Request",
                    color: AppDesign.Color.warning,
                    iconSystemName: "clock.fill"
                )
            case .denied:
                return Presentation(
                    stage: .requestDeclined,
                    title: "Request Declined",
                    nextStep: "Try another ride on the same route.",
                    actionTitle: "Find Another Ride",
                    color: AppDesign.Color.destructive,
                    iconSystemName: "xmark.circle.fill"
                )
            case .cancelled:
                return Presentation(
                    stage: .requestCancelled,
                    title: "Request Cancelled",
                    nextStep: "You can search again whenever your plans change.",
                    actionTitle: nil,
                    color: AppDesign.Color.textTertiary,
                    iconSystemName: "minus.circle.fill"
                )
            default:
                break
            }
        }

        let secondsUntilDeparture = trip.ride.departureTime.timeIntervalSince(now)
        if secondsUntilDeparture <= 30 * 60 {
            return Presentation(
                stage: .startsSoon,
                title: "Starts Soon",
                nextStep: trip.role == .hosting
                    ? "Start the ride when passengers are ready."
                    : "Be at pickup and keep chat open.",
                actionTitle: trip.role == .hosting ? "Start Ride" : "Open Chat",
                color: AppDesign.Color.warning,
                iconSystemName: "bell.fill"
            )
        }

        if trip.role == .hosting {
            return Presentation(
                stage: .acceptingRequests,
                title: "Accepting Requests",
                nextStep: "Review pending requests and start the ride at pickup time.",
                actionTitle: "View Requests",
                color: AppDesign.Color.success,
                iconSystemName: "person.crop.circle.badge.plus"
            )
        }

        return Presentation(
            stage: .confirmedUpcoming,
            title: "Confirmed",
            nextStep: "Your seat is confirmed. You can chat with the driver before pickup.",
            actionTitle: "Open Chat",
            color: AppDesign.Color.success,
            iconSystemName: "checkmark.seal.fill"
        )
    }
}
