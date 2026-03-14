import Foundation

// MARK: - Step

enum ProfileCompletionStep: CaseIterable {
    case photo
    case phone
    case vehicle

    var title: String {
        switch self {
        case .photo:   return "Add a profile photo"
        case .phone:   return "Add your phone number"
        case .vehicle: return "Add vehicle info"
        }
    }

    var subtitle: String {
        switch self {
        case .photo:   return "Help others recognise you"
        case .phone:   return "So the driver can contact you"
        case .vehicle: return "Required to offer rides"
        }
    }

    var systemImage: String {
        switch self {
        case .photo:   return "person.crop.circle.badge.plus"
        case .phone:   return "phone.badge.plus"
        case .vehicle: return "car.badge.plus"
        }
    }
}

// MARK: - Result

struct ProfileCompletion {
    let steps: [ProfileCompletionStep]
    let completedSteps: [ProfileCompletionStep]

    var percentage: Int {
        guard !steps.isEmpty else { return 100 }
        return Int(Double(completedSteps.count) / Double(steps.count) * 100)
    }

    var missingSteps: [ProfileCompletionStep] {
        steps.filter { !completedSteps.contains($0) }
    }

    var isComplete: Bool { missingSteps.isEmpty }
    var completedFraction: String { "\(completedSteps.count) of \(steps.count)" }
}

// MARK: - Calculator

enum ProfileCompletionCalculator {
    static func compute(for user: UserProfile) -> ProfileCompletion {
        let steps = ProfileCompletionStep.allCases
        let done  = steps.filter { isStepComplete($0, user: user) }
        return ProfileCompletion(steps: steps, completedSteps: done)
    }

    private static func isStepComplete(_ step: ProfileCompletionStep, user: UserProfile) -> Bool {
        switch step {
        case .photo:   return user.photoURL != nil
        case .phone:   return !(user.phone ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        case .vehicle: return !(user.vehicles ?? []).isEmpty
        }
    }
}
