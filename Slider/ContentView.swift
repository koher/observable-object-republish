import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    SliderView()
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarTitle("SwiftUI")
                } label: {
                    Text("SwiftUI")
                }
                
                NavigationLink {
                    UIViewControllerRepresentableView(SliderViewController())
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarTitle("UIKit")
                } label: {
                    Text("UIKit")
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct UIViewControllerRepresentableView<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: () -> ViewController
                        
    init(_ viewController: @escaping @autoclosure () -> ViewController) {
        self.viewController = viewController
    }
    
    func makeUIViewController(context: Context) -> ViewController {
        viewController()
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
    }
}
