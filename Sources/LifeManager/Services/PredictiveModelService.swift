//
// PredictiveModelService.swift
// LifeManager
//
// Learning feedback loop for predictive window sizing and optimization
//

import Foundation

class PredictiveModelService: ObservableObject {
    static let shared = PredictiveModelService()
    
    private let logger = Logger.shared
    
    // Model data
    private var predictions: [PredictionRecord] = []
    private var model: PredictiveModel
    
    private init() {
        self.model = PredictiveModel.load() ?? PredictiveModel()
        logger.info("PREDICTIVE: Model initialized with accuracy: \(String(format: "%.1f", model.accuracy * 100))%")
    }
    
    /// Update model with actual vs predicted values
    func updatePredictiveModel(actual: Int, predicted: Int, context: PredictionContext) {
        let accuracy = 1.0 - (abs(Double(actual - predicted)) / max(Double(predicted), 1.0))
        
        // Record prediction
        let record = PredictionRecord(
            timestamp: Date(),
            predicted: predicted,
            actual: actual,
            accuracy: accuracy,
            context: context
        )
        predictions.append(record)
        
        // Keep only recent predictions
        if predictions.count > 1000 {
            predictions.removeFirst(predictions.count - 1000)
        }
        
        // Update model weights
        model.updateWeights(for: context, accuracy: accuracy)
        
        // Auto-tune after every 100 predictions
        if model.predictionCount % 100 == 0 {
            retrain()
        }
        
        // Log significant deviations
        if accuracy < 0.5 {
            logger.warning("PREDICTIVE: Large deviation - Predicted: \(predicted), Actual: \(actual), Context: \(context.description)")
        }
    }
    
    /// Retrain model based on recent predictions
    private func retrain() {
        logger.info("PREDICTIVE: Retraining model with \(predictions.count) samples")
        
        let oldAccuracy = model.accuracy
        model.retrain(with: predictions)
        
        let improvement = (model.accuracy - oldAccuracy) * 100
        if improvement > 0 {
            logger.success("PREDICTIVE: Model improved by \(String(format: "%.1f", improvement))% - New accuracy: \(String(format: "%.1f", model.accuracy * 100))%")
        } else if improvement < -5 {
            logger.warning("PREDICTIVE: Model degraded by \(String(format: "%.1f", abs(improvement)))% - Rolling back")
            model.rollback()
        }
        
        model.save()
    }
    
    /// Predict optimal window size based on context
    func predictWindowSize(for context: PredictionContext) -> Int {
        return model.predict(for: context)
    }
    
    /// Get model performance metrics
    func getPerformanceMetrics() -> ModelMetrics {
        let recentAccuracy = predictions.suffix(100).map { $0.accuracy }.reduce(0, +) / Double(min(predictions.count, 100))
        
        return ModelMetrics(
            overallAccuracy: model.accuracy,
            recentAccuracy: recentAccuracy,
            predictionCount: model.predictionCount,
            lastRetrained: model.lastRetrainedDate
        )
    }
}

// MARK: - Supporting Types

struct PredictionContext: Codable {
    let hourOfDay: Int
    let dayOfWeek: Int
    let activityLevel: String
    let recentTrend: Double
    let memoryPressure: Double
    
    var description: String {
        return "Hour: \(hourOfDay), Day: \(dayOfWeek), Activity: \(activityLevel)"
    }
}

struct PredictionRecord {
    let timestamp: Date
    let predicted: Int
    let actual: Int
    let accuracy: Double
    let context: PredictionContext
}

struct ModelMetrics {
    let overallAccuracy: Double
    let recentAccuracy: Double
    let predictionCount: Int
    let lastRetrained: Date?
}

// MARK: - Predictive Model

class PredictiveModel: Codable {
    var weights: [String: Double] = [:]
    var accuracy: Double = 0.5
    var predictionCount: Int = 0
    var lastRetrainedDate: Date?
    private var previousWeights: [String: Double]?
    
    func predict(for context: PredictionContext) -> Int {
        // Simple weighted prediction based on context
        var score = 100.0 // Base window size
        
        // Hour of day weight
        let hourWeight = weights["hour_\(context.hourOfDay)"] ?? 1.0
        score *= hourWeight
        
        // Day of week weight
        let dayWeight = weights["day_\(context.dayOfWeek)"] ?? 1.0
        score *= dayWeight
        
        // Activity level adjustment
        switch context.activityLevel {
        case "low":
            score *= weights["activity_low"] ?? 0.5
        case "high":
            score *= weights["activity_high"] ?? 2.0
        default:
            score *= weights["activity_medium"] ?? 1.0
        }
        
        // Trend adjustment
        if context.recentTrend > 1.2 {
            score *= weights["trend_up"] ?? 1.1
        } else if context.recentTrend < 0.8 {
            score *= weights["trend_down"] ?? 0.9
        }
        
        // Memory pressure adjustment
        if context.memoryPressure > 0.8 {
            score *= weights["memory_high"] ?? 0.8
        }
        
        // Clamp to valid range
        return min(200, max(50, Int(score)))
    }
    
    func updateWeights(for context: PredictionContext, accuracy: Double) {
        // Update specific weights based on accuracy
        let learningRate = 0.1
        let adjustment = (accuracy - 0.5) * learningRate
        
        // Update hour weight
        let hourKey = "hour_\(context.hourOfDay)"
        weights[hourKey] = (weights[hourKey] ?? 1.0) + adjustment
        
        // Update day weight
        let dayKey = "day_\(context.dayOfWeek)"
        weights[dayKey] = (weights[dayKey] ?? 1.0) + adjustment
        
        // Update activity weight
        let activityKey = "activity_\(context.activityLevel)"
        weights[activityKey] = (weights[activityKey] ?? 1.0) + adjustment
        
        predictionCount += 1
        
        // Update overall accuracy (exponential moving average)
        self.accuracy = self.accuracy * 0.95 + accuracy * 0.05
    }
    
    func retrain(with records: [PredictionRecord]) {
        // Save current weights for rollback
        previousWeights = weights
        
        // Reset and retrain
        weights = [:]
        accuracy = 0.5
        
        // Learn from all records
        for record in records {
            updateWeights(for: record.context, accuracy: record.accuracy)
        }
        
        lastRetrainedDate = Date()
    }
    
    func rollback() {
        if let previous = previousWeights {
            weights = previous
            Logger.shared.info("PREDICTIVE: Rolled back to previous weights")
        }
    }
    
    func save() {
        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "predictive_model")
        }
    }
    
    static func load() -> PredictiveModel? {
        guard let data = UserDefaults.standard.data(forKey: "predictive_model"),
              let model = try? JSONDecoder().decode(PredictiveModel.self, from: data) else {
            return nil
        }
        return model
    }
}