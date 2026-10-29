import Foundation
import Combine

@MainActor
final class MessagesViewModel: ObservableObject {
    @Published var query = ""
    @Published var draft = ""

    private let store: AppStore

    convenience init() {
        self.init(store: AppStore.shared)
    }

    init(store: AppStore) {
        self.store = store
    }

    var threads: [MessageThread] {
        let matched: [MessageThread]
        if query.isEmpty {
            matched = store.threads
        } else {
            matched = store.threads.filter {
                $0.participantName.localizedCaseInsensitiveContains(query)
                    || $0.context.localizedCaseInsensitiveContains(query)
                    || ($0.lastMessage?.body.localizedCaseInsensitiveContains(query) ?? false)
            }
        }
        return matched.sorted { a, b in
            if (a.unread > 0) != (b.unread > 0) { return a.unread > 0 }
            return (a.lastMessage?.sentAt ?? .distantPast) > (b.lastMessage?.sentAt ?? .distantPast)
        }
    }

    var unreadTotal: Int { store.unreadMessages }

    func thread(_ id: UUID) -> MessageThread? {
        store.threads.first { $0.id == id }
    }

    func send(in threadID: UUID) {
        let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        store.send(body, in: threadID)
        draft = ""
    }
}
