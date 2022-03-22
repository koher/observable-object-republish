import SwiftUI

@MainActor
struct SliderView: View {
    @StateObject private var presenter: SliderViewPresenter
    
    init(presenter: (() -> SliderViewPresenter)? = nil) {
        self._presenter = .init(wrappedValue: presenter?() ?? .init(state: .init()))
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text(presenter.valueText)
                .font(.system(size: 36))
                .monospacedDigit()
            // $presenter.value を Binding として利用可能
            Slider(value: $presenter.value, in: SliderViewState.valueRange)
            Button {
                presenter.state.reset()
            } label: {
                Text("Reset")
            }
            Spacer()
        }
        .padding(20)
    }
}

struct SliderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SliderView()
                .preferredColorScheme(.light)
            .previewDisplayName("Light mode")
            
            SliderView()
                .preferredColorScheme(.dark)
            .previewDisplayName("Dark mode")
            
            SliderView {
                let presenter: SliderViewPresenter = .init(state: .init())
                presenter.value = SliderViewState.valueRange.lowerBound
                return presenter
            }
            .previewDisplayName("Min value")
            
            SliderView {                let presenter: SliderViewPresenter = .init(state: .init())
                presenter.value = SliderViewState.valueRange.upperBound
                return presenter
            }
            .previewDisplayName("Max value")
            
            SliderView().previewDevice("iPhone 13 mini")
            .previewDisplayName("iPhone 13 mini")
            
            SliderView().previewDevice("iPhone 13 Pro Max")
            .previewDisplayName("iPhone 13 Pro Max")
        }
    }
}
