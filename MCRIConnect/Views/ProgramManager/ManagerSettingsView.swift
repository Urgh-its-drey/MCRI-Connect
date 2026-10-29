import SwiftUI

/// Manager-side controls: what the office gets told about, which workspace this
/// device is in, and where the data actually comes from.
struct ManagerSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var auth: AuthService
    @StateObject private var viewModel = ManagerViewModel()

    @AppStorage("mcri.notify.deadlines") private var notifyDeadlines = true
    @AppStorage("mcri.notify.stalled") private var notifyStalled = true
    @AppStorage("mcri.notify.employer") private var notifyEmployer = true
    @AppStorage("mcri.digest.weekly") private var weeklyDigest = true

    var body: some View {
        MCRIPage {
            identityCard

            MCRISectionHeader(title: "Alerts")
            alertsCard

            MCRISectionHeader(title: "Data")
            dataCard

            MCRISectionHeader(title: "Workspace")
            workspaceCard

            MCRISecondaryButton(title: "Sign out", symbol: "rectangle.portrait.and.arrow.right",
                                isDestructive: true) {
                auth.signOut()
            }
            .padding(.top, MCRITheme.Spacing.s2)
        }
        .mcriScreen(title: "Settings", hidesTitle: false)
    }

    private var identityCard: some View {
        MCRIScreenHero {
            HStack(spacing: MCRITheme.Spacing.s3) {
                MCRILogoTile(initials: auth.session.initials.isEmpty ? "PM" : auth.session.initials, size: 50)
                VStack(alignment: .leading, spacing: 3) {
                    Text(auth.session.displayName)
                        .font(.mcriTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text("Programme manager · MCRI Connect")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                    Text("\(viewModel.advisorLoads.count) advisors · \(viewModel.metrics.totalStudents) students")
                        .font(.mcriCaption2)
                        .foregroundStyle(MCRITheme.textTertiary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var alertsCard: some View {
        MCRICard {
            VStack(spacing: 0) {
                toggleRow("Placement deadlines", "Students within 5 days of a closing role", isOn: $notifyDeadlines)
                divider
                toggleRow("Stalled applications", "No employer response after 5 working days", isOn: $notifyStalled)
                divider
                toggleRow("Employer activity", "A role you approved gets a new applicant", isOn: $notifyEmployer)
                divider
                toggleRow("Weekly digest", "Sunday summary to every advisor", isOn: $weeklyDigest)
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(MCRITheme.divider).frame(height: 1)
    }

    private func toggleRow(_ title: String, _ detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.mcriCaption.weight(.semibold))
                    .foregroundStyle(MCRITheme.textPrimary)
                Text(detail)
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textTertiary)
            }
        }
        .tint(MCRITheme.primaryAction)
        .padding(.vertical, MCRITheme.Spacing.s2)
        .frame(minHeight: MCRITheme.Metrics.minTapTarget)
    }

    private var dataCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                infoRow(symbol: "database.fill", title: "Source",
                        detail: "Local sample store — swap DataService for the Supabase client")
                infoRow(symbol: "arrow.triangle.2.circlepath", title: "Last sync",
                        detail: Date().formatted(date: .abbreviated, time: .shortened))
                infoRow(symbol: "person.crop.circle.badge.checkmark", title: "Records",
                        detail: "\(store.students.count) students · \(store.internships.count) roles · \(store.placements.count) placements")
            }
        }
    }

    private func infoRow(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MCRITheme.secondaryAction)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.mcriCaption.weight(.semibold))
                    .foregroundStyle(MCRITheme.textPrimary)
                Text(detail)
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var workspaceCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                MCRISectionHeader(title: "Open as another role",
                                  subtitle: "The same data, seen from the other side")
                ForEach(UserRole.allCases.filter { $0 != auth.session.role }) { role in
                    Button {
                        auth.switchRole(role)
                    } label: {
                        HStack(spacing: MCRITheme.Spacing.s3) {
                            Image(systemName: role.glyph)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MCRITheme.textSecondary)
                                .frame(width: 24)
                            Text(role.title)
                                .font(.mcriCaption.weight(.semibold))
                                .foregroundStyle(MCRITheme.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MCRITheme.border)
                        }
                        .frame(minHeight: MCRITheme.Metrics.minTapTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open as \(role.title)")
                }
            }
        }
    }
}

private struct ManagerSettingsViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .programManager) { ManagerSettingsView() }
}
}
