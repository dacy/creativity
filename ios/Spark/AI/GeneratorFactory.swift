import Foundation

enum GeneratorFactory {
    /// Prefer the on-device Apple Intelligence model; fall back to the mock
    /// generator on the simulator or unsupported devices.
    static func make() -> any IdeaGenerating {
        if FoundationModelGenerator.isAvailable {
            return FoundationModelGenerator()
        }
        return MockIdeaGenerator()
    }
}
