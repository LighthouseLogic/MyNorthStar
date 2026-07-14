import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Step 2 — Group: cluster related values under theme names.
struct GroupStepView: View {
    @Bindable var project: Project
    let goTo: (Step) -> Void

    @AppStorage("hasSeenGroupDragHint") private var hasSeenGroupDragHint = false
    @State private var showDragHint = false

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
            presentDragHintIfNeeded()
        }
        #if os(iOS)
        .overlay {
            if showDragHint {
                DragHintOverlay(sampleValue: project.ungroupedValues.first ?? "Courage")
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }
        }
        #endif
    }

    /// Dragging a card on iPhone needs a press-and-hold that nothing on screen
    /// suggests, so the first visit gets a one-time, self-dismissing coach mark.
    /// iPad and macOS drags work without a long press — no hint there.
    private func presentDragHintIfNeeded() {
        #if os(iOS)
        guard UIDevice.current.userInterfaceIdiom == .phone, !hasSeenGroupDragHint else { return }
        hasSeenGroupDragHint = true
        withAnimation(.easeOut(duration: 0.3)) { showDragHint = true }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeIn(duration: 0.4)) { showDragHint = false }
        }
        #endif
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

#if os(iOS)
/// One-time coach mark for iPhone: a fingertip presses and holds a value card,
/// the card lifts with a shadow, then slides into a group container.
private struct DragHintOverlay: View {
    let sampleValue: String

    @State private var pressed = false
    @State private var slid = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .top) {
                VStack(spacing: 22) {
                    Color.clear.frame(height: 36)
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.accentColor.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .frame(width: 170, height: 48)
                        .overlay {
                            Text("Group")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                }

                Text(sampleValue)
                    .font(.callout)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.accentColor.opacity(0.18), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.accentColor))
                    .foregroundStyle(Color.accentColor)
                    .scaleEffect(pressed ? 1.08 : 1)
                    .shadow(color: .black.opacity(pressed ? 0.3 : 0), radius: 6, y: 4)
                    .offset(y: slid ? 60 : 0)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .offset(x: 16, y: slid ? 76 : 16)
                            .opacity(pressed ? 1 : 0)
                    }
            }
            .frame(height: 110)

            Text("Press and hold a value to drag it into a group.")
                .font(.callout)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.quaternary))
        .shadow(color: .black.opacity(0.2), radius: 18, y: 8)
        .padding(.horizontal, 32)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.35).delay(0.4)) { pressed = true }
            withAnimation(.easeInOut(duration: 0.7).delay(1.1)) { slid = true }
        }
    }
}
#endif

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
