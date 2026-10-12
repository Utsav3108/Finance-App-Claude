import SwiftUI

/// The only place that switches over `LoadState`. Empty and error states are wrapped in a
/// full-height ScrollView so `.refreshable` attached outside still works in every state.
struct StateContainer<Value, Content: View, Placeholder: View>: View {
    let state: LoadState<Value>
    let empty: EmptyStateConfig
    let retry: () -> Void
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let content: (Value) -> Content

    init(
        state: LoadState<Value>,
        empty: EmptyStateConfig,
        retry: @escaping () -> Void,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.empty = empty
        self.retry = retry
        self.placeholder = placeholder
        self.content = content
    }

    var body: some View {
        switch state {
        case .idle, .loading:
            placeholder()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Loading")
        case .loaded(let value):
            content(value)
        case .empty:
            centered { EmptyStateView(config: empty) }
        case .error(let error):
            centered { ErrorStateView(title: error.title, message: error.message, isRetryable: error.isRetryable, retry: retry) }
        }
    }

    private func centered<V: View>(@ViewBuilder _ view: () -> V) -> some View {
        ScrollView {
            view().containerRelativeFrame(.vertical, alignment: .center)
        }
    }
}

extension StateContainer where Placeholder == LoadingPlaceholder {
    /// Uses a plain centered spinner as the loading placeholder.
    init(
        state: LoadState<Value>,
        empty: EmptyStateConfig,
        retry: @escaping () -> Void,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.init(state: state, empty: empty, retry: retry, placeholder: { LoadingPlaceholder() }, content: content)
    }
}

struct LoadingPlaceholder: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("StateContainer states") {
    let cfg = EmptyStateConfig(title: "No transactions", message: "Nothing to show yet.")
    return TabView {
        StateContainer(state: LoadState<[String]>.loading, empty: cfg, retry: {}) { items in
            Text("\(items.count) items")
        }.tabItem { Text("Loading") }
        StateContainer(state: LoadState<[String]>.loaded(["a", "b"]), empty: cfg, retry: {}) { items in
            Text("\(items.count) items")
        }.tabItem { Text("Loaded") }
        StateContainer(state: LoadState<[String]>.empty, empty: cfg, retry: {}) { items in
            Text("\(items.count) items")
        }.tabItem { Text("Empty") }
        StateContainer(state: LoadState<[String]>.error(UserFacingError(TransactionServiceError.loadFailed)), empty: cfg, retry: {}) { items in
            Text("\(items.count) items")
        }.tabItem { Text("Error") }
    }
}
