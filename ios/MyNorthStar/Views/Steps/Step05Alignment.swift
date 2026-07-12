import SwiftUI

/// Step 5 — Alignment grid: mark where each top-10 value is active.
struct AlignmentStepView: View {
    @Bindable var project: Project
    let goTo: (Step) -> Void

    var body: some View {
        StepContainer(step: .alignment) {
            StepInstruction("Where do your values show up in your life? For each value, mark the life areas where it is currently active and present. Be honest — this reveals alignment and gaps.")

            if project.top10.isEmpty {
                WarningBanner(text: "Choose your top 10 values in Step 3 first — the grid maps those ten values to your life areas.")
            } else {
                categorySummary
                alignmentGrid
            }

            AskClaudeButton(
                title: "Where could my values show up more?",
                acceptLabel: "Done",
                promptBuilder: {
                    """
                    \(PromptContext.alignmentSummary(project))

                    \(PromptContext.answers(project))

                    Looking at this alignment map: which gaps look most consequential, \
                    and which single value-to-life-area pairing would be the highest-\
                    leverage place to start? 3 short bullets.
                    """
                },
                onAccept: { _ in }
            )

            HStack {
                Button("← Back") { goTo(.fiveQuestions) }
                    .buttonStyle(.bordered)
                Button("Reflect on This →") { goTo(.reflect) }
                    .buttonStyle(.borderedProminent)
            }

            DataNote()
        }
    }

    private var categorySummary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 18) {
                ForEach(LifeArea.all) { area in
                    let count = project.valueCount(inArea: area.index)
                    let fraction = project.top10.isEmpty ? 0 : Double(count) / Double(project.top10.count)
                    VStack(spacing: 6) {
                        Text(area.icon)
                            .font(.title3)
                        ProgressView(value: fraction)
                            .frame(width: 72)
                            .tint(.accentColor)
                        Text("\(count)/\(project.top10.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(area.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(width: 90)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var alignmentGrid: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow {
                    Text("Value → Area")
                        .font(.caption.smallCaps())
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(.leading)
                        .frame(minWidth: 170, alignment: .leading)
                    ForEach(LifeArea.all) { area in
                        VStack(spacing: 2) {
                            Text(area.icon)
                            Text(area.label)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 92)
                        .foregroundStyle(.secondary)
                    }
                }
                ForEach(project.top10, id: \.self) { value in
                    GridRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(value)
                                .font(.callout.weight(.medium))
                            let count = project.areaCount(for: value)
                            if count > 0 {
                                Text("\(count) area\(count == 1 ? "" : "s")")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(minWidth: 170, alignment: .leading)
                        ForEach(LifeArea.all) { area in
                            let active = project.isAligned(value, area: area.index)
                            Button {
                                project.toggleAlignment(value, area: area.index)
                            } label: {
                                Circle()
                                    .fill(active ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary.opacity(0.35)))
                                    .frame(width: 18, height: 18)
                                    .frame(width: 92, height: 34)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                            .accessibilityLabel("\(value) → \(area.label)")
                            .accessibilityAddTraits(active ? .isSelected : [])
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
