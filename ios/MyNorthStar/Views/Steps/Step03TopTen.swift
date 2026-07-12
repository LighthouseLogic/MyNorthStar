import SwiftUI

/// Step 3 — Top 10: choose the ten most important values.
struct TopTenStepView: View {
    @Bindable var project: Project
    let goTo: (Step) -> Void

    var body: some View {
        StepContainer(step: .topTen) {
            CounterBar(
                count: project.top10.count,
                target: ValuesCatalog.topCount,
                label: "values chosen as your top 10"
            )

            StepInstruction("Select your 10 most important values from your grouped list.")

            VStack(spacing: 8) {
                ForEach(project.selected, id: \.self) { value in
                    RankingRow(
                        value: value,
                        groupName: project.groupName(for: value),
                        rank: project.top10.firstIndex(of: value).map { $0 + 1 },
                        isDisabled: !project.top10.contains(value) && project.top10.count >= ValuesCatalog.topCount
                    ) {
                        toggle(value)
                    }
                }
            }

            AskClaudeButton(
                title: "Help me choose my top 10",
                acceptLabel: "Done",
                promptBuilder: {
                    """
                    \(PromptContext.selectedValues(project))

                    \(PromptContext.groups(project))

                    \(PromptContext.topTen(project))

                    I need to narrow my selection to my 10 most important values. \
                    Ask me 3 sharp questions that would help me distinguish core values \
                    from aspirational ones, and point out any of my values that seem to \
                    overlap enough that one could stand in for the other. Do not pick \
                    the 10 for me.
                    """
                },
                onAccept: { _ in }
            )

            HStack {
                Button("← Back") { goTo(.group) }
                    .buttonStyle(.bordered)
                if project.top10.count == ValuesCatalog.topCount {
                    Button("Answer 5 Questions →") { goTo(.fiveQuestions) }
                        .buttonStyle(.borderedProminent)
                }
            }

            DataNote()
        }
        .onAppear {
            // With 10 or fewer selected, the whole list is the starting top 10.
            if project.selected.count <= ValuesCatalog.topCount && project.top10.isEmpty {
                project.top10 = project.selected
            }
        }
    }

    private func toggle(_ value: String) {
        if let index = project.top10.firstIndex(of: value) {
            project.top10.remove(at: index)
        } else {
            guard project.top10.count < ValuesCatalog.topCount else { return }
            project.top10.append(value)
        }
        project.touch()
    }
}

private struct RankingRow: View {
    let value: String
    let groupName: String?
    let rank: Int?
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(rank.map(String.init) ?? "—")
                    .font(.headline.monospacedDigit())
                    .frame(width: 34, height: 34)
                    .background(
                        rank != nil ? AnyShapeStyle(Color.accentColor.opacity(0.18)) : AnyShapeStyle(.quaternary.opacity(0.4)),
                        in: Circle()
                    )
                    .foregroundStyle(rank != nil ? Color.accentColor : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.body)
                    if let groupName {
                        Text(groupName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: rank != nil ? "star.fill" : "star")
                    .foregroundStyle(rank != nil ? Color.accentColor : Color.secondary)
                    .opacity(isDisabled ? 0.3 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(rank != nil ? AnyShapeStyle(Color.accentColor.opacity(0.5)) : AnyShapeStyle(.quaternary))
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
