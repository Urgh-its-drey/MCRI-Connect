import SwiftUI

/// The four-stage pipeline drawn across each application card.
struct MCRIStageStepper: View {
    var stages: [ApplicationStage]
    var currentIndex: Int

    private var clampedIndex: Int { min(max(currentIndex, 0), stages.count - 1) }

    var body: some View {
        GeometryReader { proxy in
            let step = proxy.size.width / CGFloat(stages.count - 1)
            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(MCRITheme.surfaceHi)
                    .frame(width: proxy.size.width, height: 3)
                    .position(x: proxy.size.width / 2, y: 6)

                Capsule()
                    .fill(MCRITheme.primaryAction)
                    .frame(width: max(0, step * CGFloat(clampedIndex)), height: 3)
                    .position(x: step * CGFloat(clampedIndex) / 2, y: 6)

                ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                    let reached = index <= clampedIndex
                    VStack(spacing: 4) {
                        Circle()
                            .fill(reached ? MCRITheme.primaryAction : MCRITheme.sunken)
                            .overlay(Circle().strokeBorder(reached ? MCRITheme.primaryAction : MCRITheme.border,
                                                           lineWidth: 1.5))
                            .frame(width: 11, height: 11)
                        Text(stage.label)
                            .font(.system(size: 8.5, weight: reached ? .bold : .medium))
                            .foregroundStyle(reached ? MCRITheme.textPrimary : MCRITheme.textTertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(width: step)
                    .position(x: step * CGFloat(index), y: 8)
                }
            }
        }
        .frame(height: 34)
        .accessibilityElement()
        .accessibilityLabel("Stage \(clampedIndex + 1) of \(stages.count): \(stages[clampedIndex].label)")
    }
}

/// Dated audit trail of one application, so the student always knows what happened last.
struct MCRIApplicationTimeline: View {
    var events: [TimelineEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(event.isDone ? MCRITheme.secondaryAction : MCRITheme.surface)
                            .overlay(Circle().strokeBorder(event.isDone ? MCRITheme.secondaryAction : MCRITheme.border,
                                                           lineWidth: 1.5))
                            .frame(width: 10, height: 10)
                            .padding(.top, 4)

                        if index < events.count - 1 {
                            Rectangle()
                                .fill(MCRITheme.divider)
                                .frame(width: 1.5)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.mcriCaption.weight(event.isDone ? .semibold : .regular))
                            .foregroundStyle(event.isDone ? MCRITheme.textPrimary : MCRITheme.textSecondary)
                        if let detail = event.detail {
                            Text(detail)
                                .font(.mcriFootnote)
                                .foregroundStyle(MCRITheme.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Text(event.date, format: .dateTime.day().month(.abbreviated).hour().minute())
                            .font(.mcriCaption2)
                            .foregroundStyle(MCRITheme.textTertiary.opacity(0.8))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.bottom, index == events.count - 1 ? 0 : MCRITheme.Spacing.s3)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct MCRIApplicationTimelinePreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRIStageStepper") {
        ForEach(0..<ApplicationStage.trackerStages.count, id: \.self) { index in
            MCRICard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Stage \(index + 1) · \(ApplicationStage.trackerStages[index].label)")
                        .font(.mcriCaption2)
                        .foregroundStyle(MCRITheme.textTertiary)
                    MCRIStageStepper(stages: ApplicationStage.trackerStages, currentIndex: index)
                }
            }
        }
        MCRICard {
            MCRIStageStepper(stages: ApplicationStage.pipelineStages, currentIndex: 3)
        }
    }
}
}

private struct MCRIApplicationTimelinePreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRIApplicationTimeline") {
        MCRICard {
            MCRIApplicationTimeline(events: SampleData.applications[0].timeline)
        }
        MCRICard {
            MCRIApplicationTimeline(events: [
                TimelineEvent(title: "Interview scheduled",
                              detail: "Thursday · 30 min · Teams",
                              date: SampleData.days(3), isDone: false),
            ])
        }
    }
}
}
