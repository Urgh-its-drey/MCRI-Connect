import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = MessagesViewModel()

    var body: some View {
        VStack(spacing: 0) {
            MCRISearchBar(placeholder: "Search conversations", text: $viewModel.query)
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                .padding(.vertical, MCRITheme.Spacing.s3)
                .background(MCRITheme.background)

            ScrollView {
                VStack(spacing: MCRITheme.Spacing.s3) {
                    if viewModel.threads.isEmpty {
                        MCRIEmptyState(symbol: "bubble.left.and.bubble.right",
                                       title: "No conversations yet",
                                       message: "Message an employer from a candidate or role screen and "
                                           + "the thread lands here.")
                            .padding(.top, MCRITheme.Spacing.s6)
                    } else {
                        ForEach(viewModel.threads) { thread in
                            threadRow(thread)
                        }
                    }
                }
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                .padding(.bottom, MCRITheme.Spacing.s6)
            }
            .scrollIndicators(.hidden)
        }
        .mcriScreen(title: "Messages")
        .background(MCRITheme.background.ignoresSafeArea())
    }

    private func threadRow(_ thread: MessageThread) -> some View {
        Button {
            store.markRead(thread.id)
            router.go(.thread(thread.id))
        } label: {
            HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                MCRILogoTile(initials: thread.participantInitials, size: 42)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: MCRITheme.Spacing.s2) {
                        Text(thread.participantName)
                            .font(.mcriCaption.weight(thread.unread > 0 ? .bold : .semibold))
                            .foregroundStyle(MCRITheme.textPrimary)
                        Spacer()
                        if let sent = thread.lastMessage?.sentAt {
                            Text(sent.formatted(.relative(presentation: .named)))
                                .font(.mcriCaption2)
                                .foregroundStyle(MCRITheme.textTertiary)
                        }
                    }

                    Text(thread.context)
                        .font(.mcriCaption2.weight(.semibold))
                        .foregroundStyle(MCRITheme.secondaryAction)
                        .lineLimit(1)

                    Text(thread.lastMessage?.body ?? "No messages yet")
                        .font(.mcriFootnote)
                        .foregroundStyle(thread.unread > 0 ? MCRITheme.textPrimary : MCRITheme.textTertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                if thread.unread > 0 {
                    Text("\(thread.unread)")
                        .font(.mcriCaption2.weight(.bold))
                        .foregroundStyle(MCRITheme.textOnAccent)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(MCRITheme.primaryAction, in: Capsule())
                }
            }
            .padding(MCRITheme.Spacing.s4)
            .background(thread.unread > 0 ? MCRITheme.surface : MCRITheme.sunken, in: cardShape)
            .overlay(cardShape.strokeBorder(thread.unread > 0 ? MCRITheme.border : MCRITheme.hairline,
                                            lineWidth: 1))
        }
        .buttonStyle(MCRIPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(thread.participantName), \(thread.unread) unread")
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MCRITheme.Radius.card, style: .continuous)
    }
}

struct MessageThreadView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var viewModel = MessagesViewModel()

    var threadID: UUID

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: MCRITheme.Spacing.s3) {
                        if let thread = viewModel.thread(threadID) {
                            contextHeader(thread)

                            ForEach(thread.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                    .padding(.vertical, MCRITheme.Spacing.s4)
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    if let last = viewModel.thread(threadID)?.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.thread(threadID)?.messages.count) { _, _ in
                    if let last = viewModel.thread(threadID)?.messages.last {
                        withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            composer
        }
        .mcriScreen()
        .navigationTitle(viewModel.thread(threadID)?.participantName ?? "Message")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.markRead(threadID) }
    }

    private func contextHeader(_ thread: MessageThread) -> some View {
        VStack(spacing: MCRITheme.Spacing.s2) {
            HStack(spacing: MCRITheme.Spacing.s3) {
                MCRILogoTile(initials: thread.participantInitials, size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text(thread.participantName)
                        .font(.mcriCardTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text(thread.context)
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.secondaryAction)
                }
                Spacer()
            }
            Rectangle().fill(MCRITheme.divider).frame(height: 1)
        }
    }

    private var composer: some View {
        HStack(spacing: MCRITheme.Spacing.s2) {
            TextField("Write a message", text: $viewModel.draft, prompt: Text("Write a message").foregroundColor(.mcriCharcoal), axis: .vertical)
                .font(.mcriBody)
                .foregroundStyle(Color.mcriNavy)
                .lineLimit(1...4)
                .tint(MCRITheme.primaryAction)
                .padding(.horizontal, MCRITheme.Spacing.s4)
                .padding(.vertical, MCRITheme.Spacing.s3)
                .background(Color.white, in: composerShape)
                .overlay(composerShape.strokeBorder(MCRITheme.border, lineWidth: 1))

            Button {
                viewModel.send(in: threadID)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MCRITheme.textOnAccent)
                    .frame(width: MCRITheme.Metrics.minTapTarget,
                           height: MCRITheme.Metrics.minTapTarget)
                    .background(canSend ? MCRITheme.primaryAction : MCRITheme.placeholder, in: composerShape)
            }
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        .padding(.vertical, MCRITheme.Spacing.s3)
        .background(MCRITheme.surface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(MCRITheme.hairline).frame(height: 1) }
    }

    private var canSend: Bool {
        !viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var composerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MCRITheme.Radius.control, style: .continuous)
    }
}

private struct MessageBubble: View {
    var message: Message

    var body: some View {
        VStack(alignment: message.fromCurrentUser ? .trailing : .leading, spacing: 3) {
            Text(message.body)
                .font(.mcriBody)
                .foregroundStyle(message.fromCurrentUser ? MCRITheme.textOnAccent : MCRITheme.textPrimary)
                .padding(.horizontal, MCRITheme.Spacing.s4)
                .padding(.vertical, MCRITheme.Spacing.s3)
                .background(message.fromCurrentUser ? MCRITheme.primaryAction : MCRITheme.surface,
                            in: bubble)
                .overlay(bubble.strokeBorder(message.fromCurrentUser ? MCRITheme.primaryAction
                                             : MCRITheme.hairline, lineWidth: 1))
                .frame(maxWidth: 280, alignment: message.fromCurrentUser ? .trailing : .leading)

            Text(message.sentAt.formatted(date: .omitted, time: .shortened))
                .font(.mcriCaption2)
                .foregroundStyle(MCRITheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: message.fromCurrentUser ? .trailing : .leading)
        .accessibilityElement(children: .combine)
    }

    private var bubble: RoundedRectangle {
        RoundedRectangle(cornerRadius: MCRITheme.Radius.control, style: .continuous)
    }
}

private struct MessagesViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen { MessagesView() }
}
}

private struct MessagesViewPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen { MessageThreadView(threadID: SampleData.threads[0].id) }
}
}
