import UIKit
import Combine

@MainActor
public final class SliderViewController: UIViewController {
    private let presenter: SliderViewPresenter = .init(state: .init())
    
    private var cancellables: Set<AnyCancellable> = []
    
    @MainActor
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // layout
        let vStack: UIStackView = .init()
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.alignment = .trailing
        vStack.spacing = 10
        view.addSubview(vStack)
        
        let label: UILabel = .init()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .monospacedDigitSystemFont(ofSize: 36, weight: .regular)
        vStack.addArrangedSubview(label)
        
        let slider: UISlider = .init()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.value = 0
        slider.minimumValue = SliderViewState.valueRange.lowerBound
        slider.maximumValue = SliderViewState.valueRange.upperBound
        slider.addAction(.init { [weak self] _ in
            self?.presenter.value = slider.value
        }, for: .valueChanged)
        vStack.addArrangedSubview(slider)
        
        let resetButton: UIButton = .init(type: .system)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        resetButton.addAction(.init { [weak self] _ in
            self?.presenter.state.reset()
        }, for: .touchUpInside)
        vStack.addArrangedSubview(resetButton)

        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            vStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: vStack.trailingAnchor, constant: 20),
            slider.widthAnchor.constraint(equalTo: vStack.widthAnchor),
        ])
        
        // binding
        presenter.$valueText
            .map { $0 as String? }
            .assign(to: \.text, on: label)
            .store(in: &cancellables)
        
        // $presenter.$value を Publisher として利用可能
        presenter.$value
            .assign(to: \.value, on: slider)
            .store(in: &cancellables)
    }
}
