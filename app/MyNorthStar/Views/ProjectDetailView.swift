import SwiftUI
import SwiftData

/// Detail pane: the 7-step Know Your Values stepper for the selected project.
struct ProjectDetailView: View {
    @Bindable var project: Project

    @State private var step: Step = .selectValues
    @State private var gateMessage: String?
    @State private var confirmingStartOver = false
    @State private var showSavedBadge = false
    @State private var savedBadgeToken = 0

    var body: some View {
        VStack(spacing: 0) {
            stepper
            Divider()
            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                #if !os(macOS)
                .overlay(alignment: .top) {
                    if showSavedBadge {
                        SavedBadge()
                    }
                }
                #endif
        }
        .navigationTitle($project.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .status) {
                if showSavedBadge {
                    Label("Progress saved", systemImage: "checkmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }
            #endif
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    goToAdjacentStep(offset: -1)
                } label: {
                    Label("Previous Step", systemImage: "chevron.left")
                }
                .disabled(step == Step.allCases.first)

                Button {
                    goToAdjacentStep(offset: 1)
                } label: {
                    Label("Next Step", systemImage: "chevron.right")
                }
                .disabled(step == Step.allCases.last)
            }
        }
        .onAppear {
            // Restore the saved position, as the reference app does on load.
            if let saved = Step(rawValue: project.currentStep), project.canEnter(saved) {
                step = saved
            }
        }
        .alert(
            "Not Yet",
            isPresented: Binding(
                get: { gateMessage != nil },
                set: { if !$0 { gateMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(gateMessage ?? "")
        }
        .confirmationDialog(
            "Start over? This will clear all your work.",
            isPresented: $confirmingStartOver,
            titleVisibility: .visible
        ) {
            Button("Start Over", role: .destructive) {
                project.reset()
                step = .selectValues
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var stepper: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Step.allCases) { candidate in
                        StepChip(
                            step: candidate,
                            isCurrent: candidate == step,
                            isCompleted: candidate.rawValue < step.rawValue
                        ) {
                            go(to: candidate)
                        }
                        .id(candidate)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .onChange(of: step) {
                withAnimation {
                    proxy.scrollTo(step, anchor: .center)
                }
            }
        }
        .background(.background.secondary)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .selectValues:
            SelectValuesStepView(project: project, goTo: go(to:))
        case .group:
            GroupStepView(project: project, goTo: go(to:))
        case .topTen:
            TopTenStepView(project: project, goTo: go(to:))
        case .fiveQuestions:
            FiveQuestionsStepView(project: project, goTo: go(to:))
        case .alignment:
            AlignmentStepView(project: project, goTo: go(to:))
        case .reflect:
            ReflectStepView(project: project, goTo: go(to:), onStartOver: { confirmingStartOver = true })
        case .constitution:
            ConstitutionStepView(project: project, goTo: go(to:), onStartOver: { confirmingStartOver = true })
        }
    }

    /// Navigation with the reference app's gates.
    private func go(to target: Step) {
        guard project.canEnter(target) else {
            switch target {
            case .group, .topTen:
                gateMessage = "Please select at least 10 values before continuing."
            case .reflect:
                gateMessage = "Please answer all five questions before continuing."
            default:
                break
            }
            return
        }
        // SwiftData has already auto-saved; the badge is a trust signal, shown
        // on forward moves only — never on initial load or going back.
        if target.rawValue > step.rawValue {
            flashSavedBadge()
        }
        step = target
        project.currentStep = target.rawValue
        project.touch()
    }

    private func goToAdjacentStep(offset: Int) {
        guard let target = Step(rawValue: step.rawValue + offset) else { return }
        go(to: target)
    }

    private func flashSavedBadge() {
        savedBadgeToken += 1
        let token = savedBadgeToken
        withAnimation(.easeOut(duration: 0.2)) { showSavedBadge = true }
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            guard token == savedBadgeToken else { return }
            withAnimation(.easeIn(duration: 0.3)) { showSavedBadge = false }
        }
    }
}

/// Muted "Progress saved" confirmation shown briefly at the top of the step
/// content on iOS/iPadOS (macOS uses a toolbar status label instead).
private struct SavedBadge: View {
    var body: some View {
        Label("Progress saved", systemImage: "checkmark.circle.fill")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.quaternary))
            .padding(.top, 12)
            .transition(.move(edge: .top).combined(with: .opacity))
            .allowsHitTesting(false)
    }
}

private struct StepChip: View {
    let step: Step
    let isCurrent: Bool
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : step.systemImage)
                    .font(.caption)
                Text("\(step.rawValue). \(step.title)")
                    .font(.callout)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isCurrent ? AnyShapeStyle(Color.accentColor.opacity(0.18)) : AnyShapeStyle(.clear),
                in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(isCurrent ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary))
            )
            .foregroundStyle(isCurrent ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }
}
