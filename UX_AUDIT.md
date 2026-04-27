# UniRide UX Audit: Uber/Ola-Level Polish Roadmap

This audit focuses on making UniRide feel like a mature ride-hailing product: confident, fast, map-aware, status-driven, and hard to get lost in.

## Highest Impact

1. Make ride search map-first.
   - Add a compact map preview above available rides.
   - Show pickup/drop-off pins and route direction before listing drivers.
   - Keep the route summary pinned while scrolling results.

2. Treat empty states as recovery flows.
   - When no rides are available, let users offer the same route without re-entering it.
   - Show clear actions like `Offer This Route`, `Change Time`, and `Widen Search`.
   - Avoid empty screens that only explain the problem.

3. Add real ride status language everywhere.
   - Use status chips: `Request pending`, `Driver approved`, `Ride starts soon`, `On trip`, `Completed`.
   - Make My Rides the single source of truth after a request or offer.
   - Add visible next-step text under each status.

4. Improve trust signals.
   - Show driver rating, vehicle model, plate, and verification status consistently on cards and detail pages.
   - Add profile completeness prompts only where trust affects the next action.
   - Add safety affordances: emergency contact, share ride, report/block, and support entry points.

5. Reduce booking friction.
   - Disable primary CTAs until required selections are confirmed.
   - Preserve route/date/time between Find Ride and Offer Ride.
   - Add route swap, saved places, recent searches, and quick campus/home chips.

## Screen Notes

### Home
- Good: greeting, quick actions, upcoming ride, nearby rides, events.
- Improve next: add a compact "Where to?" route search surface, show active ride/request status first, and keep the two ride actions visually equal.

### Find Ride
- Good: route card, date/time controls, autocomplete.
- Improve next: add current location, route swap, recent locations, and inline validation instead of alerts.
- Implemented now: Find button waits for confirmed suggestions; selected route details are passed forward.

### Available Rides
- Good: search/filter, result count, empty state.
- Improve next: add map preview, sort by ETA/fare/rating, and show applied route context at the top.
- Implemented now: route summary appears above results; "Offer This Route" carries route/date/time into Offer Ride.

### Ride Detail
- Good: map, driver card, fare/seats/date chips, fixed request CTA.
- Improve next: add ETA/distance summary above the CTA, pickup instructions, cancellation policy, and chat entry after request approval.

### Offer Ride
- Good: route, map, route alternatives, vehicle, seats, suggested fare, review step.
- Improve next: make it step-progressive with a visible progress indicator; add route swap, recent routes, and better empty vehicle recovery.
- Implemented now: can receive prefilled route/date/time from the no-results flow.

### My Rides
- Good: upcoming/past separation, driver requests, chat/map/tracking actions.
- Improve next: make status timeline clearer and surface the single most important action per ride.

### Profile and Trust
- Good: profile, vehicles, settings.
- Improve next: add verification badges, document/profile completion progress, emergency contacts, and visible safety controls.

## Product Features Needed To Feel Truly Comparable

1. Live trip lifecycle: request, accept, pickup arriving, on trip, completed.
2. Driver/passenger chat tied to each ride.
3. Share live ride and emergency contact.
4. Push notifications for request accepted, ride starting soon, driver messages, cancellations.
5. Reliable real backend data, not local/mock fallbacks for core marketplace screens.
6. Ratings and reviews visible before booking.
7. Route-aware matching that considers pickup and drop-off, not only nearby source distance.
8. Price transparency: per-seat fare, estimated total, cancellation/refund copy.
9. Strong loading/offline/error states across every networked screen.
10. Analytics funnel: home action taps, search started, no-result recovery, request sent, ride completed.

## Visual Polish Checklist

- Use one primary CTA per screen, except co-equal home actions.
- Keep bottom CTAs fixed on high-stakes flows.
- Use consistent card radius, shadow, spacing, and typography from `AppDesign`.
- Prefer icon buttons/chips for compact actions.
- Avoid alert-heavy validation; show inline guidance near the field.
- Ensure every empty state has a useful action.
- Verify every screen at small and large iPhone sizes.
