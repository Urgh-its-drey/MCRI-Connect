import SwiftUI

/// Labelled input with the blue focus border. Email, password and single-line answers.
struct MCRIField: View {
    var label: String
    var placeholder: String = ""
    var symbol: String? = nil
    var text: Binding<String>
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    var isSecure: Bool = false
    var errorMessage: String? = nil
    var onSubmit: () -> Void = {}

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).mcriLabelStyle()

            Group {
                if isSecure && !revealed {
                    SecureField(placeholder, text: text, prompt: Text(placeholder).foregroundColor(MCRITheme.placeholder))
                } else {
                    TextField(placeholder, text: text, prompt: Text(placeholder).foregroundColor(MCRITheme.placeholder))
                        .keyboardType(keyboard)
                }
            }
            .font(.mcriBody)
            .foregroundStyle(Color.mcriNavy)
            .textInputAutocapitalization(autocapitalization)
            .tint(MCRITheme.secondaryAction)
            .focused($focused)
            .onSubmit(onSubmit)
            .padding(.horizontal, MCRITheme.Spacing.s4)
            .frame(height: MCRITheme.Metrics.controlHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: shape)
            .overlay(shape.strokeBorder(focused ? MCRITheme.borderStrong : MCRITheme.hairline,
                                       lineWidth: focused ? 1.5 : 1))
            .overlay(alignment: .trailing) {
                HStack(spacing: 6) {
                    if isSecure {
                        Button {
                            revealed.toggle()
                        } label: {
                            Image(systemName: revealed ? "eye.slash" : "eye")
                                .font(.system(size: 14))
                                .foregroundStyle(MCRITheme.placeholder)
                                .frame(width: 40, height: 40)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel(revealed ? "Hide password" : "Show password")
                    }
                    if focused, let symbol {
                        Image(systemName: symbol)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MCRITheme.secondaryAction)
                            .padding(.trailing, MCRITheme.Spacing.s4)
                    }
                }
            }

            if let errorMessage {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.circle.fill").font(.caption2)
                    Text(errorMessage).font(.mcriCaption2)
                }
                .foregroundStyle(MCRITheme.blocked)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @State private var revealed = false

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MCRITheme.Radius.control, style: .continuous)
    }
}

/// Multi-line answer used for bios, project summaries and role descriptions.
struct MCRITextArea: View {
    var label: String
    var placeholder: String
    var text: Binding<String>
    var minLines: Int = 3
    var counter: Int? = nil

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).mcriLabelStyle()
                Spacer()
                if let counter {
                    Text("\(text.wrappedValue.count)/\(counter)")
                        .font(.mcriCaption2)
                        .foregroundStyle(text.wrappedValue.count > counter ? MCRITheme.blocked : MCRITheme.textTertiary)
                }
            }

            TextEditor(text: text)
                .font(.mcriBody)
                .foregroundStyle(Color.mcriNavy)
                .scrollContentBackground(.hidden)
                .frame(minHeight: CGFloat(minLines) * 24)
                .padding(MCRITheme.Spacing.s2)
                .background(Color.white, in: shape)
                .overlay(shape.strokeBorder(focused ? MCRITheme.borderStrong : MCRITheme.hairline,
                                           lineWidth: focused ? 1.5 : 1))
                .focused($focused)
                .overlay(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .font(.mcriBody)
                            .foregroundStyle(MCRITheme.placeholder)
                            .padding(.leading, MCRITheme.Spacing.s4)
                            .padding(.top, MCRITheme.Spacing.s4)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MCRITheme.Radius.control, style: .continuous)
    }
}

/// Segmented choice row for onboarding answers: one tile per option, orange when active.
struct MCRISegmentPicker<T: Hashable & Identifiable>: View {
    var title: String
    var options: [T]
    @Binding var selection: T
    var label: (T) -> String
    var symbol: (T) -> String? = { _ in nil }

    var body: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
            Text(title).mcriLabelStyle()
            HStack(spacing: MCRITheme.Spacing.s2) {
                ForEach(options) { option in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) { selection = option }
                    } label: {
                        VStack(spacing: 5) {
                            if let symbol = symbol(option) {
                                Image(systemName: symbol).font(.system(size: 15, weight: .semibold))
                            }
                            Text(label(option)).font(.mcriCaption2.weight(.semibold))
                        }
                        .foregroundStyle(selection == option ? MCRITheme.textOnAccent : MCRITheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: MCRITheme.Metrics.minTapTarget)
                        .background(selection == option ? MCRITheme.primaryAction : MCRITheme.surface,
                                    in: RoundedRectangle(cornerRadius: MCRITheme.Radius.chip, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: MCRITheme.Radius.chip, style: .continuous)
                                .strokeBorder(selection == option ? MCRITheme.primaryAction : MCRITheme.border,
                                              lineWidth: 1)
                        )
                    }
                    .buttonStyle(MCRIPressStyle())
                    .accessibilityAddTraits(selection == option ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }
}

/// Step counter for the multi-step flows (onboarding, posting a role).
struct MCRIStepIndicator: View {
    var steps: [String]
    var index: Int

    var body: some View {
        VStack(spacing: MCRITheme.Spacing.s2) {
            HStack(spacing: 5) {
                ForEach(0..<steps.count, id: \.self) { step in
                    Capsule()
                        .fill(step <= index ? MCRITheme.primaryAction : MCRITheme.surfaceHi)
                        .frame(width: step == index ? 26 : 14, height: 4)
                }
            }
            Text("\(steps[safe: index] ?? "") · \(index + 1) of \(steps.count)")
                .font(.mcriCaption2.weight(.semibold))
                .foregroundStyle(MCRITheme.textTertiary)
        }
        .accessibilityElement(children: .combine)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct MCRIFieldPreviewHost: View {
    @State private var title = ""
    @State private var city = "Cape Town"
    @State private var stipend = "R15 000 / month"
    @State private var password = "mcri2026"
    @State private var notes = ""
    @State private var workMode: WorkMode = .hybrid
    @State private var year: OnboardingViewModel.StudyYear = .second

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                MCRIField(label: "Role title", placeholder: "Product Design Intern",
                          symbol: "briefcase", text: $title)
                MCRIField(label: "City", text: $city)
                MCRIField(label: "Stipend", symbol: "banknote", text: $stipend,
                          errorMessage: "Enter an amount or write \"Unpaid\".")
                MCRIField(label: "Password", text: $password, isSecure: true)
                MCRITextArea(label: "What the intern actually does",
                             placeholder: "Shadow the guild lead, then own one small feature…",
                             text: $notes, counter: 280)
                MCRISegmentPicker(title: "Preferred work mode", options: WorkMode.allCases,
                                  selection: $workMode, label: { $0.label })
                MCRISegmentPicker(title: "Year of study",
                                  options: OnboardingViewModel.StudyYear.allCases,
                                  selection: $year, label: { $0.rawValue })
                MCRIStepIndicator(steps: ["Profile", "Skills", "Interests", "Review"], index: 2)
            }
            .padding(MCRITheme.Spacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: MCRIPhoneWidth.compact)
        .frame(maxHeight: .infinity)
        .background(MCRITheme.background)
    }
}

private struct MCRIFieldPreview1: PreviewProvider {
    static var previews: some View {
    MCRIFieldPreviewHost()
}
}

private struct MCRIFieldNarrowHost: View {
    @State private var query = "Interaction Design"

    var body: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
            MCRIField(label: "Programme of study", placeholder: "Interaction Design",
                      symbol: "graduationcap", text: $query)
            MCRIStepIndicator(steps: ["About you", "Skills", "Goals"], index: 0)
        }
        .padding(MCRITheme.Spacing.s4)
        .mcriPinned(to: MCRIPhoneWidth.small)
    }
}

private struct MCRIFieldPreview2: PreviewProvider {
    static var previews: some View {
    MCRIFieldNarrowHost()
}
}
