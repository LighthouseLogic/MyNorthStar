import SwiftUI

/// Step 1 — Select 25: choose the values that resonate.
struct SelectValuesStepView: View {
    @Bindable var project: Project
    let goTo: (Step) -> Void

    @State private var searchText = ""
    @State private var customText = ""

    private var filteredValues: [String] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return project.allSelectableValues }
        return project.allSelectableValues.filter { $0.lowercased().contains(query) }
    }

    var body: some View {
        StepContainer(step: .selectValues) {
            HStack(alignment: .center) {
                CounterBar(
                    count: project.selected.count,
                    target: ValuesCatalog.selectionTarget,
                    label: "values selected"
                )
                if project.selected.count >= ValuesCatalog.minimumSelection {
                    Button {
                        goTo(.group)
                    } label: {
                        Text("Continue to Grouping →")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            StepInstruction("Select exactly 25 values that resonate with who you are or who you want to be. Don't overthink it — your first instinct is often the truest.")

            TextField("Search values…", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 420)

            if !project.selected.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Selected Values")
                        .font(.headline)
                    FlowLayout(spacing: 8) {
                        ForEach(project.selected, id: \.self) { value in
                            ValueChip(value: "\(value)  ×", isSelected: true) {
                                toggle(value)
                            }
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            }

            FlowLayout(spacing: 8) {
                ForEach(filteredValues, id: \.self) { value in
                    let isSelected = project.selected.contains(value)
                    ValueChip(
                        value: value,
                        isSelected: isSelected,
                        isDisabled: !isSelected && project.selected.count >= ValuesCatalog.selectionTarget
                    ) {
                        toggle(value)
                    }
                }
            }

            Divider()

            StepInstruction("Don't see a value that matters to you? Add it below.")
            HStack {
                TextField("Type a value and press Add…", text: $customText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)
                    .onSubmit { addCustomValue() }
                Button("Add") { addCustomValue() }
                    .buttonStyle(.bordered)
                    .disabled(customText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            AskClaudeButton(
                title: "Suggest values I might be missing",
                acceptLabel: "Add as Custom Values",
                promptBuilder: {
                    """
                    \(PromptContext.selectedValues(project))

                    Suggest up to 8 additional values from adjacent themes I may be \
                    overlooking, based on the pattern in my selections. Reply with one \
                    value name per line (1–3 words each), no commentary and no bullets.
                    """
                },
                onAccept: { response in
                    for line in response.split(separator: "\n") {
                        let value = line.trimmingCharacters(in: CharacterSet(charactersIn: "•-– "))
                            .trimmingCharacters(in: .whitespaces)
                        guard !value.isEmpty, value.count <= 50,
                              !project.allSelectableValues.contains(value) else { continue }
                        project.custom.append(value)
                        if project.selected.count < ValuesCatalog.selectionTarget {
                            project.selected.append(value)
                        }
                    }
                    project.touch()
                }
            )

            DataNote()
        }
    }

    private func toggle(_ value: String) {
        if let index = project.selected.firstIndex(of: value) {
            project.selected.remove(at: index)
        } else {
            guard project.selected.count < ValuesCatalog.selectionTarget else { return }
            project.selected.append(value)
        }
        project.touch()
    }

    private func addCustomValue() {
        let value = customText.trimmingCharacters(in: .whitespaces)
        customText = ""
        guard !value.isEmpty, value.count <= 50, !project.allSelectableValues.contains(value) else { return }
        project.custom.append(value)
        if project.selected.count < ValuesCatalog.selectionTarget {
            project.selected.append(value)
        }
        project.touch()
    }
}
