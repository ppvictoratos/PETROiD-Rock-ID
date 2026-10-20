//
//  ImageClassifierClient.swift
//  PETROiD-Rock-ID
//

import ComposableArchitecture
import Foundation
import Vision

/// What the photo appears to show. Person and scissors are easter eggs; `notARock` is rejected.
enum ImageClassification: Equatable, Sendable {
    case rock
    case person
    case scissors
    case notARock
}

/// Wraps Apple Vision's built-in classifier. It can say "this is a rock" but not which kind, so the
/// species still comes from `RockCatalogClient` until a custom Core ML model is added (that model can
/// run through Vision too, replacing the species lookup without touching the reducer's shape).
struct ImageClassifierClient: Sendable {
    var classify: @Sendable (Data) async -> ImageClassification
}

extension ImageClassifierClient: DependencyKey {
    static let liveValue = ImageClassifierClient(classify: { data in
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(data: data)
        // Vision work is synchronous and heavy; keep it off the cooperative pool's main actor.
        let observations: [VNClassificationObservation] = await Task.detached {
            (try? handler.perform([request])).flatMap { _ in request.results } ?? []
        }.value
        return ImageClassification(observations: observations.map { ($0.identifier, Double($0.confidence)) })
    })

    static let testValue = ImageClassifierClient(classify: { _ in
        reportIssue("ImageClassifierClient.classify is unimplemented")
        return .rock
    })
}

extension ImageClassification {
    static let personLabels: Set<String> = ["people", "adult"]
    static let scissorsLabels: Set<String> = ["scissors"]
    /// Generic Vision labels that rocks tend to land under (it has no per-rock-type labels).
    static let rockLabels: Set<String> = ["rocks", "cliff", "canyon", "cave", "mountain", "hill", "sand", "sand_dune", "lava", "volcano"]
    static let personThreshold = 0.5
    static let scissorsThreshold = 0.4
    /// Deliberately lenient: a false rejection of a real rock photo is worse than letting an odd one through.
    static let rockThreshold = 0.1

    /// Pure mapping from Vision's (identifier, confidence) pairs so it can be tested without Vision.
    /// The strongest matching category wins, so a person holding a rock only counts as a person
    /// if the person label is the more confident one.
    init(observations: [(identifier: String, confidence: Double)]) {
        func best(_ labels: Set<String>) -> Double {
            observations.filter { labels.contains($0.identifier) }.map(\.confidence).max() ?? 0
        }
        let person = best(Self.personLabels)
        let scissors = best(Self.scissorsLabels)
        let rock = best(Self.rockLabels)

        let candidates: [(ImageClassification, Double)] = [
            (.person, person >= Self.personThreshold ? person : 0),
            (.scissors, scissors >= Self.scissorsThreshold ? scissors : 0),
            (.rock, rock >= Self.rockThreshold ? rock : 0),
        ]
        if let winner = candidates.max(by: { $0.1 < $1.1 }), winner.1 > 0 {
            self = winner.0
        } else {
            self = .notARock
        }
    }
}

extension DependencyValues {
    var imageClassifier: ImageClassifierClient {
        get { self[ImageClassifierClient.self] }
        set { self[ImageClassifierClient.self] = newValue }
    }
}
