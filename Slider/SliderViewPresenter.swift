import Combine
import Foundation

@MainActor
@dynamicMemberLookup // state から素通しするプロパティは実装を省略
public final class SliderViewPresenter: ObservableObject {
    public let state: SliderViewState
    
    // Computed property を使わずに republish
    @Published public internal(set) var valueText: String = ""
    private func republishToValueText() {
        state.$value.map { value in
            let formatter: NumberFormatter = .init()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 3
            formatter.maximumFractionDigits = 3
            return formatter.string(from: NSNumber(value: value)) ?? value.description
        }
        .assign(to: &$valueText)
    }
    
    public init(state: SliderViewState) {
        self.state = state
        
        republishToValueText()
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<SliderViewState, T>) -> T {
        state[keyPath: keyPath]
    }
    
    public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<SliderViewState, T>) -> T {
        get { state[keyPath: keyPath] }
        set { state[keyPath: keyPath] = newValue }
    }
}
