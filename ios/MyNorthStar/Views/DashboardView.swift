import SwiftUI

/// Entry-point dashboard shown when no project is selected.
struct DashboardView: View {
    let projects: [Project]
    let onOpen: (Project) -> Void
    let onNew: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 240), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Know Your Values")
                        .font(.largeTitle.bold())
                    Text("Clarity about what you value most is the foundation of every good decision. Work through this exercise at your own pace — select 25 values, group them, choose your top 10, answer five questions, map your alignment, reflect, and draft your personal constitution.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 640, alignment: .leading)
                    Label("Your data never leaves this device. AI requests are sent only when you explicitly trigger them.", systemImage: "lock.shield")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                Button(action: onNew) {
                    Label("New Project", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)

                if !projects.isEmpty {
                    Text("Recent Projects")
                        .font(.title2.bold())
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                        ForEach(projects) { project in
                            Button {
                                onOpen(project)
                            } label: {
                                ProjectCard(project: project)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 1000, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Dashboard")
    }
}

private struct ProjectCard: View {
    let project: Project

    private var progressSummary: String {
        let step = Step(rawValue: project.currentStep) ?? .selectValues
        return "Step \(step.rawValue) of \(Step.allCases.count) — \(step.title)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.title.isEmpty ? "Untitled Project" : project.title)
                .font(.headline)
                .lineLimit(2)
            Text(progressSummary)
                .font(.callout)
                .foregroundStyle(.secondary)
            if !project.top10.isEmpty {
                Text(project.top10.prefix(3).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            } else if !project.selected.isEmpty {
                Text("\(project.selected.count) values selected")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            HStack {
                Text("Updated \(project.updatedAt, format: .dateTime.day().month())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(minHeight: 120, alignment: .topLeading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))
    }
}
