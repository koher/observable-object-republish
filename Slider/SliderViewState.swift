import Combine

@MainActor
public final class SliderViewState: ObservableObject {
    public static let valueRange: ClosedRange<Float> = 0 ... 1000000
    
    public init() {}
    
    @Published public var value: Float = 0 {
        didSet {
            if value < Self.valueRange.lowerBound { value = Self.valueRange.lowerBound}
            if value > Self.valueRange.upperBound { value = Self.valueRange.upperBound}
        }
    }
    
    public func reset() {
        value = 0
    }
}
