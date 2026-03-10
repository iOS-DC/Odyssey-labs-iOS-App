import Foundation

final class BackendSyncCoordinator {
    static let shared = BackendSyncCoordinator()

    private init() {}

    /// Pulls home-feed data from Supabase and hydrates local data models.
    func refreshHomeFeedIfEnabled() async {
        async let ridesTask: Void = syncRides()
        async let eventsTask: Void = syncEvents()

        _ = await (ridesTask, eventsTask)
    }

    private func syncRides() async {
        do {
            let rides = try await RideRepository.shared.fetchPublishedRides()
            await MainActor.run {
                RideDataModel.shared.mergeRemoteRides(rides)
                UserDataModel.shared.ensureDriverProfiles(for: rides.map { $0.driverUserID })
            }
        } catch {
            print("Supabase ride sync failed: \(error.localizedDescription)")
        }
    }

    private func syncEvents() async {
        do {
            let events = try await EventsAPI.shared.fetchTopEvents(limit: 8)
            EventDataModel.shared.replaceEventsFromBackend(events)
        } catch {
            print("Backend event sync failed: \(error.localizedDescription)")
        }
    }
}
