import SwiftUI

/// Step 2 — Group: cluster related values under theme names.
struct GroupStepView: View {
    @Bindable var project: Project
    let goTo: (Step) -> Void

    var body: some View {
        StepContainer(step: .group) {
            StepInstruction("Group values that feel related to each other. Name each group with a theme. Drag values between groups, or tap × to return them to the pool.")

            VStack(alignment: .leading, spacing: 8) {
                Text("Ungrouped Values — drag into a group below")
                    .font(.headline)
                if project.ungroupedValues.isEmpty && !project.selected.isEmpty {
                    Text("All values grouped ✓")
                        .font(.callout)
                        .italic()
                        .foregroundStyle(.secondary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(project.ungroupedValues, id: \.self) { value in
                            ValueChip(value: value) {
                                assignToFirstGroup(value)
                            }
                            .draggable(value)
                        }
                    }
                    Text("Tip: tap a value to send it to the first group, or drag it onto any group.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))

            Divider()

            ForEach($project.groups) { $group in
                GroupCard(project: project, group: $group) {
                    remove(group: group)
                }
            }

            AddRowButton(title: "Add a Group") {
                project.groups.append(ValueGroup())
                project.touch()
            }

            Divider()

            HStack {
                Button("← Back") { goTo(.selectValues) }
                    .buttonStyle(.bordered)
                Button("Continue to Top 10 →") { goTo(.topTen) }
                    .buttonStyle(.borderedProminent)
            }

            DataNote()
        }
        .onAppear {
            // Drop values deselected in Step 1; ensure at least one group exists.
            for index in project.groups.indices {
                project.groups[index].values.removeAll { !project.selected.contains($0) }
            }
            if project.groups.isEmpty {
                project.groups.append(ValueGroup())
            }
        }
    }

    private func assignToFirstGroup(_ value: String) {
        if project.groups.isEmpty {
            project.groups.append(ValueGroup())
        }
        guard !project.groups[0].values.contains(value) else { return }
        project.groups[0].values.append(value)
        project.touch()
    }

    private func remove(group: ValueGroup) {
        project.groups.removeAll { $0.id == group.id }
        project.touch()
    }
}

private struct GroupCard: View {
    @Bindable var project: Project
    @Binding var group: ValueGroup
    let onDelete: () -> Void

    @State private var isDropTarget = false

    private var groupNumber: Int {
        (project.groups.firstIndex { $0.id == group.id } ?? 0) + 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Group \(groupNumber) — give it a theme name", text: $group.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.headline)
                AskClaudeButton(
                    title: "Suggest a theme name",
                    acceptLabel: "Use as Group Name",
                    promptBuilder: {
                        """
                        Here is a group of related personal values: \
                        \(group.values.isEmpty ? "(empty group)" : group.values.joined(separator: ", ")).

                        \(PromptContext.groups(project))

                        Suggest a short theme name (2–4 words) that captures what unites \
                        the first group listed above. Reply with the name only.
                        """
                    },
                    onAccept: { response in
                        let name = response
                            .split(separator: "\n").first.map(String.init)?
                            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        guard !name.isEmpty else { return }
                        group.name = name
                        project.touch()
                    }
                )
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if group.values.isEmpty {
                Text("Drag values here or tap values in the pool")
                    .font(.callout)
                    .italic()
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(group.values, id: \.self) { value in
                        ValueChip(value: "\(value)  ×", isSelected: true) {
                            group.values.removeAll { $0 == value }
                            project.touch()
                        }
                        .draggable(value)
                    }
                }
            }
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isDropTarget ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary))
        )
        .dropDestination(for: String.self) { values, _ in
            var accepted = false
            for value in values where project.selected.contains(value) {
                for index in project.groups.indices {
                    project.groups[index].values.removeAll { $0 == value }
                }
                if !group.values.contains(value) {
                    group.values.append(value)
                }
                accepted = true
            }
            if accepted { project.touch() }
            return accepted
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
    }
}
