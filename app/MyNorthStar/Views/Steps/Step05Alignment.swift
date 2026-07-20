import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Step 5 — Alignment grid: mark where each top-10 value is active.
struct AlignmentStepView: View {
    @Bindable var project: Project
    let goTo: (Step) -> Void

    @State private var gridExport: GridExport?

    var body: some View {
        StepContainer(step: .alignment) {
            StepInstruction("Where do your values show up in your life? For each value, mark the life areas where it is currently active and present. Be honest — this reveals alignment and gaps.")

            if project.top10.isEmpty {
                WarningBanner(text: "Choose your top 10 values in Step 3 first — the grid maps those ten values to your life areas.")
            } else {
                categorySummary
                shareButton
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
        .onAppear(perform: refreshGridExport)
        .onChange(of: project.updatedAt) { refreshGridExport() }
    }

    private var categorySummary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 18) {
                ForEach(LifeArea.all) { area in
                    AreaSummaryColumn(
                        area: area,
                        count: project.valueCount(inArea: area.index),
                        total: project.top10.count
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    /// Secondary action so it does not compete with the step navigation.
    @ViewBuilder
    private var shareButton: some View {
        if let gridExport {
            ShareLink(
                item: gridExport,
                preview: SharePreview("My Values Alignment", image: gridExport.image)
            ) {
                Label("Save or Share Grid", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
        }
    }

    private var gridSummaryText: String {
        "My values alignment — " + LifeArea.all
            .map { "\($0.label): \(project.valueCount(inArea: $0.index))/\(project.top10.count)" }
            .joined(separator: " · ")
    }

    /// Re-renders the shareable image of the summary bars whenever the project changes.
    private func refreshGridExport() {
        guard !project.top10.isEmpty else {
            gridExport = nil
            return
        }
        let snapshot = GridSnapshotView(
            areas: LifeArea.all.map { ($0, project.valueCount(inArea: $0.index)) },
            total: project.top10.count
        )
        let renderer = ImageRenderer(content: snapshot.environment(\.colorScheme, .light))
        renderer.scale = 3
        #if canImport(UIKit)
        guard let image = renderer.uiImage, let data = image.pngData() else { return }
        #elseif canImport(AppKit)
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else { return }
        #endif
        gridExport = GridExport(pngData: data, summaryText: gridSummaryText)
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

/// One life area's summary bar — used on screen and in the exported image.
private struct AreaSummaryColumn: View {
    let area: LifeArea
    let count: Int
    let total: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(area.icon)
                .font(.title3)
            ProgressView(value: total == 0 ? 0 : Double(count) / Double(total))
                .frame(width: 72)
                .tint(.accentColor)
            Text("\(count)/\(total)")
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

/// The fixed-size view rendered to a PNG for "Save or Share Grid".
private struct GridSnapshotView: View {
    let areas: [(area: LifeArea, count: Int)]
    let total: Int

    var body: some View {
        VStack(spacing: 16) {
            Text("My Values Alignment")
                .font(.headline)
            HStack(alignment: .top, spacing: 18) {
                ForEach(areas, id: \.area) { entry in
                    AreaSummaryColumn(area: entry.area, count: entry.count, total: total)
                }
            }
            Text("MyNorthStar")
                .font(.caption.smallCaps().weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .background(Color.white)
    }
}

/// Share item: a PNG of the summary bars with a plain-text fallback.
struct GridExport: Transferable {
    let pngData: Data
    let summaryText: String

    var image: Image {
        #if canImport(UIKit)
        UIImage(data: pngData).map(Image.init(uiImage:)) ?? Image(systemName: "chart.bar")
        #else
        NSImage(data: pngData).map(Image.init(nsImage:)) ?? Image(systemName: "chart.bar")
        #endif
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { $0.pngData }
            .suggestedFileName("mynorthstar-alignment-grid.png")
        ProxyRepresentation(exporting: \.summaryText)
    }
}
