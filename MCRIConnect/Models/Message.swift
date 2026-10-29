import Foundation

struct Message: Identifiable, Codable, Hashable {
    let id: UUID
    var threadID: UUID
    var body: String
    var sentAt: Date
    var fromCurrentUser: Bool

    init(id: UUID = UUID(), threadID: UUID, body: String, sentAt: Date, fromCurrentUser: Bool) {
        self.id = id
        self.threadID = threadID
        self.body = body
        self.sentAt = sentAt
        self.fromCurrentUser = fromCurrentUser
    }
}

struct MessageThread: Identifiable, Codable, Hashable {
    let id: UUID
    var participantName: String
    var participantInitials: String
    var context: String
    var messages: [Message]
    var unread: Int

    init(id: UUID = UUID(), participantName: String, participantInitials: String, context: String,
         messages: [Message], unread: Int = 0) {
        self.id = id
        self.participantName = participantName
        self.participantInitials = participantInitials
        self.context = context
        self.messages = messages
        self.unread = unread
    }

    var lastMessage: Message? { messages.max(by: { $0.sentAt < $1.sentAt }) }
}
