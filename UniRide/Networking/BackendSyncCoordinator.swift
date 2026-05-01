import Foundation

final class BackendSyncCoordinator {
    static let shared = BackendSyncCoordinator()

    private init() {}

    /// Pulls home-feed data from Supabase and hydrates local data models.
    func refreshHomeFeedIfEnabled() async {
        async let ridesTask: Void = syncRides()
        async let eventsTask: Void = syncEvents()
        async let tripsTask: Void = syncTrips()
        async let myHistoryTask: Void = syncMyHistory()

        _ = await (ridesTask, eventsTask, tripsTask, myHistoryTask)
    }

    private func syncMyHistory() async {
        guard let user = UserDataModel.shared.getCurrentUser() else { return }
        await RideDataModel.shared.syncMyFullHistoryAsync(userID: user.id)
    }

    private func syncRides() async {
        do {
            let rides = try await RideRepository.shared.fetchPublishedRides()
            await MainActor.run {
                RideDataModel.shared.mergeRemoteRides(rides)
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

    private func syncTrips() async {
        do {
            let trips = try await TripsAPI.shared.fetchTrips()
            if !trips.isEmpty {
                TripDataModel.shared.replaceTripsFromBackend(trips)
            }
        } catch {
            print("Backend trip sync failed: \(error.localizedDescription)")
        }
    }
}
