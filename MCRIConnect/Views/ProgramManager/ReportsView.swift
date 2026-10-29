import SwiftUI

/// The exception list: everything in the programme that will not resolve on its
/// own, each with the one action that resolves it.
struct ReportsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = ManagerViewModel()
    @State private var kindFilter: ReportAlert.Kind?

    var body: some View {
        MCRIPage {
            summaryCard

            MCRISectionHeader(title: "Needs action",
                              subtitle: "\(filtered.count) of \(store.alerts.count) flagged items")
            filterStrip

            if filtered.isEmpty {
                MCRIEmptyState(symbol: "checkmark.seal",
                               title: store.alerts.isEmpty ? "Queue is clear" : "Nothing in this filter",
                               message: store.alerts.isEmpty
                                   ? "Every flagged cohort has had an action sent. New alerts appear daily at 07:00."
                                   : "Switch filters to see the rest of the queue.",
                               actionTitle: store.alerts.isEmpty ? nil : "Clear filter") {
                    kindFilter = nil
                }
            } else {
                ForEach(filtered) { alert in
                    AlertRow(alert: alert) { viewModel.nudge(alert) }
                }
            }

            MCRISectionHeader(title: "Cycle evidence")
            exportCard
        }
        .mcriScreen(title: "Reports", hidesTitle: false)
        .refreshable { await store.load() }
    }

    private var filtered: [ReportAlert] {
        guard let kindFilter else { return store.alerts }
        return store.alerts.filter { $0.kind == kindFilter }
    }

    private var summaryCard: some View {
        MCRIScreenHero {
            HStack(alignment: .top, spacing: MCRITheme.Spacing.s5) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This cycle").mcriLabelStyle()
                    Text("\(viewModel.metrics.successfulPlacements) placed")
                        .font(.mcriTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text("\(viewModel.metrics.totalStudents) students · \(viewModel.placementRate)% placement rate")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                }
                Spacer(minLength: MCRITheme.Spacing.s2)
                MCRIStrengthRing(value: viewModel.placementRate, caption: "placed", size: 70)
            }

            HStack(spacing: MCRITheme.Spacing.s2) {
                pill(value: "\(viewModel.metrics.activeApplications)", label: "applications")
                pill(value: "\(viewModel.metrics.unmatchedStudents)", label: "unmatched")
                pill(value: "\(store.alerts.count)", label: "open alerts")
            }
        }
    }

    private func pill(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.mcriNumeric)
                .monospacedDigit()
                .foregroundStyle(MCRITheme.textPrimary)
            Text(label)
                .font(.mcriCaption2)
                .foregroundStyle(MCRITheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MCRITheme.Spacing.s2) {
                MCRIFilterChip(title: "Everything", isSelected: kindFilter == nil,
                               trailingCount: store.alerts.count) {
                    kindFilter = nil
                }
                ForEach(ReportAlert.Kind.allCases) { kind in
                    MCRIFilterChip(title: kind.label, symbol: kind.symbol,
                                   isSelected: kindFilter == kind) {
                        kindFilter = kind
                    }
                }
            }
            .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        }
        .frame(height: MCRITheme.Metrics.minTapTarget)
    }

    private var exportCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Take the numbers with you",
                                  subtitle: "Generated from exactly what is on these screens")
                Button {
                    store.toast = .info("Weekly digest queued", "Goes to every advisor on Sunday at 17:00.")
                } label: {
                    exportRow(symbol: "envelope.fill", title: "Weekly digest to advisors",
                              detail: "\(viewModel.advisors.count) recipients")
                }
                .buttonStyle(.plain)

                Rectangle().fill(MCRITheme.divider).frame(height: 1)

                Button {
                    store.toast = .info("Report exported", "Placement CSV ready in your Downloads folder.")
                } label: {
                    exportRow(symbol: "square.and.arrow.up.fill", title: "Export placement report",
                              detail: "Per-student stage, readiness and employer")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func exportRow(symbol: String, title: String, detail: String) -> some View {
        HStack(spacing: MCRITheme.Spacing.s3) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MCRITheme.secondaryAction)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.mcriCaption.weight(.semibold))
                    .foregroundStyle(MCRITheme.textPrimary)
                Text(detail)
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textTertiary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(MCRITheme.border)
        }
        .frame(minHeight: MCRITheme.Metrics.minTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// One flagged cohort and the action that clears it. Shared with the overview screen.
struct AlertRow: View {
    var alert: ReportAlert
    var onAction: () -> Void

    private var tone: MCRIStatusTone {
        switch alert.kind {
        case .deadlineSoon, .missingDocumentation: return .blocked
        case .noApplications, .incompleteProfile: return .attention
        case .awaitingEmployer: return .information
        }
    }

    var body: some View {
        MCRICard(edge: alert.kind == .deadlineSoon ? .red : .none) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                    Image(systemName: alert.kind.symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(tone.label)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.title)
                            .font(.mcriCardTitle)
                            .foregroundStyle(MCRITheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(alert.detail)
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: MCRITheme.Spacing.s2)

                    Text("\(alert.studentCount)")
                        .font(.mcriNumeric)
                        .monospacedDigit()
                        .foregroundStyle(tone.label)
                }

                MCRIButton(title: alert.action, symbol: "paperplane.fill", fullWidth: false,
                           isDisabled: alert.studentCount == 0) {
                    onAction()
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(alert.title). \(alert.detail). \(alert.studentCount) students affected.")
    }
}

private struct ReportsViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .programManager) { ReportsView() }
}
}
