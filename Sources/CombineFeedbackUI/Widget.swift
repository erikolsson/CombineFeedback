import Combine
import CombineFeedback
import SwiftUI

public struct Widget<State, Event, Content: View>: View {
    private let view: SwiftUI.State<Content>
    private let viewPublisher: AnyPublisher<Content, Never>

    public init(
        viewModel: ViewModel<State, Event>,
        @ViewBuilder render: @escaping (Context<State, Event>) -> Content
    ) {
        self.view = SwiftUI.State(
            initialValue: render(
                Context(
                    state: viewModel.initial,
                    send: viewModel.send(event:),
                    mutate: viewModel.mutate(with:)
                )
            )
        )
        self.viewPublisher = viewModel.state
            .map {
                render(
                    Context(
                        state: $0,
                        send: viewModel.send(event:),
                        mutate: viewModel.mutate(with:)
                    )
                )
            }
            .eraseToAnyPublisher()
    }

    public var body: some View {
        return view.wrappedValue.bind(viewPublisher, to: view.projectedValue)
    }
}

extension View {
    func bind<P: Publisher, Value>(
        _ publisher: P,
        to binding: Binding<Value>
    ) -> some View where P.Failure == Never, P.Output == Value {
        return onReceive(publisher) { value in
            binding.wrappedValue = value
        }
    }
}
