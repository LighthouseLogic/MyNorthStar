import SwiftUI

/// Step 4 — Five psychometric questions.
struct FiveQuestionsStepView: View {
    @Bindable var project: Project
    let goTo: (Step) -> Void

    var body: some View {
        StepContainer(step: .fiveQuestions) {
            VStack(alignment: .center, spacing: 8) {
                Text("🧭")
                    .font(.largeTitle)
                Text("Five Questions")
                    .font(.title2.bold())
                Text("These questions help us understand how you think and decide — so the wisdom we surface speaks directly to how your mind actually works. There are no right answers.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            // Progress pips
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { number in
                    Circle()
                        .fill(project.psychAnswers.count >= number ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(width: 10, height: 10)
                }
            }
            .frame(maxWidth: .infinity)

            ForEach(PsychQuestion.all) { question in
                QuestionBlock(project: project, question: question)
            }

            AskClaudeButton(
                title: "What do my answers suggest?",
                acceptLabel: "Done",
                promptBuilder: {
                    """
                    \(PromptContext.answers(project))

                    \(PromptContext.topTen(project))

                    In 3 short observations, what do these answers suggest about how I \
                    make decisions and where I tend to get stuck? Be direct and specific; \
                    no flattery.
                    """
                },
                onAccept: { _ in }
            )

            HStack {
                Button("← Back") { goTo(.topTen) }
                    .buttonStyle(.bordered)
                if project.psychAnswers.count >= 5 {
                    Button("Map My Alignment →") { goTo(.alignment) }
                        .buttonStyle(.borderedProminent)
                }
            }

            DataNote()
        }
    }
}

private struct QuestionBlock: View {
    @Bindable var project: Project
    let question: PsychQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(format: "Question %02d of 05", question.number))
                .font(.caption.smallCaps())
                .foregroundStyle(.secondary)
            Text(question.text)
                .font(.headline)
            Text(question.targets)
                .font(.caption)
                .foregroundStyle(.tertiary)

            ForEach(question.options, id: \.letter) { option in
                let isSelected = project.psychAnswers[question.number] == option.letter
                Button {
                    project.psychAnswers[question.number] = option.letter
                    project.touch()
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(option.letter.uppercased())
                            .font(.subheadline.bold())
                            .frame(width: 28, height: 28)
                            .background(
                                isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary.opacity(0.4)),
                                in: Circle()
                            )
                            .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        Text(option.text)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        isSelected ? AnyShapeStyle(Color.accentColor.opacity(0.12)) : AnyShapeStyle(.background.secondary),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.background.secondary.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
    }
}
