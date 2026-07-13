import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]

    @State private var selection: Project?
    @State private var showingNewProject = false
    @State private var newProjectTitle = ""
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let selection {
                ProjectDetailView(project: selection)
                    .id(selection.persistentModelID)
            } else {
                DashboardView(
                    projects: projects,
                    onOpen: { selection = $0 },
                    onNew: { showingNewProject = true }
                )
            }
        }
        .onAppear {
            #if DEBUG
            // Runtime smoke test only — activated by an env var, never in normal
            // use. Exercises the derived logic on a throwaway, unpersisted project.
            if let outPath = ProcessInfo.processInfo.environment["LL2_AUTOTEST_OUT"] {
                let project = Project(title: "Autotest Project")
                project.selected = Array(ValuesCatalog.allValues.prefix(25))
                project.top10 = Array(project.selected.prefix(10))
                project.psychAnswers = [1: "c", 2: "a", 3: "a", 4: "d", 5: "b"]
                for (offset, value) in project.top10.enumerated() where offset % 2 == 0 {
                    project.toggleAlignment(value, area: offset % 7)
                }
                var report = "AUTOTEST: catalog = \(ValuesCatalog.allValues.count) values"
                report += ", corpus passages = \(Corpus.shared?.passages.count ?? -1)"
                if let corpus = Corpus.shared {
                    let picks = CorpusSelection.selectPassages(from: corpus, for: project)
                    report += ", selected passages = \(picks.count) [\(picks.map(\.id).joined(separator: ","))]"
                    report += ", traditions = \(Set(picks.map(\.tradition)).count)"
                }
                report += ", prompts = \(project.reflectionPrompts.count)"
                report += ", stuck = \(project.stuckLabel)"
                report += ", purpose seed = \(project.constitutionSeeds.lifePurpose)"
                report += ", guidelines = \(project.constitutionSeeds.guidelines.filter { !$0.isEmpty }.count)"
                report += ", report chars = \(project.reportText.count), constitution chars = \(project.constitutionText.count)"
                try? report.write(toFile: outPath, atomically: true, encoding: .utf8)
            }
            #endif
        }
        .alert("New Project", isPresented: $showingNewProject) {
            TextField("Project title", text: $newProjectTitle)
            Button("Create") { createProject() }
            Button("Cancel", role: .cancel) { newProjectTitle = "" }
        } message: {
            Text("Name this run of the exercise — for example, a year or a season of life.")
        }
        #if os(iOS)
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingSettings = false }
                        }
                    }
            }
        }
        #endif
    }

    private var sidebar: some View {
        List(selection: $selection) {
            Section("Projects") {
                ForEach(projects) { project in
                    NavigationLink(value: project) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.title.isEmpty ? "Untitled Project" : project.title)
                                .font(.body)
                                .lineLimit(2)
                            Text(project.updatedAt, format: .dateTime.day().month().year())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteProjects)
            }
        }
        .navigationTitle("MyNorthStar")
        .toolbar {
            ToolbarItem {
                Button {
                    showingNewProject = true
                } label: {
                    Label("New Project", systemImage: "plus")
                }
            }
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            #endif
        }
        .overlay {
            if projects.isEmpty {
                ContentUnavailableView(
                    "No Projects",
                    systemImage: "heart.text.square",
                    description: Text("Create a project to start the Know Your Values exercise.")
                )
            }
        }
    }

    private func createProject() {
        let title = newProjectTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        newProjectTitle = ""
        let project = Project(title: title.isEmpty ? "Untitled Project" : title)
        context.insert(project)
        selection = project
    }

    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            if selection == project { selection = nil }
            context.delete(project)
        }
    }
}
