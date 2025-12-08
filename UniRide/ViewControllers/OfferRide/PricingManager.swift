//
//  PricingManager.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 08/12/25.
//


import Foundation

final class PricingManager {

    static let shared = PricingManager()

    private init() {}

    /// Calculates suggested fare per seat based on:
    /// - distance
    /// - vehicle type
    /// - price floors
    /// - smoothing multipliers
    func suggestedFare(distanceMeters: Double, seats: Int, vehicle: String) -> Int {

        let distanceKm = max(distanceMeters / 1000, 1)   // never less than 1 km

        // Base rate
        var ratePerKm: Double = 6      // default bike price

        if vehicle.lowercased() == "car" {
            ratePerKm = 9.5            // higher cost for car
        }

        // Raw fare
        var total = distanceKm * ratePerKm

        // Minimums
        if vehicle.lowercased() == "car" {
            total = max(total, 40)     // minimum car fare
        } else {
            total = max(total, 25)     // minimum bike fare
        }

        // Per-seat price (divide fairly)
        let perSeat = total / Double(max(seats, 1))

        // Add rounding (to nearest 5 rupees)
        let rounded = Int((perSeat / 5).rounded() * 5)

        return rounded
    }
}
