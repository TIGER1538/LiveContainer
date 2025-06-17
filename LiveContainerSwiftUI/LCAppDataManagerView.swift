//
//  LCAppDataManagementView.swift
//  LiveContainer
//
//  Created by Taiga Yoda on 2025/05/16.
//

import SwiftUI

class LCAppDataContent: ObservableObject, Identifiable, Hashable, Equatable {
    let id = UUID()
    let contentURL: URL
    let isDirectory: Bool
    @Published var childNode: [LCAppDataContent]? = nil
    @Published var isExpanded: Bool = false
    @Published var errorInfo: Error? = nil

    init(contentURL: URL, isDirectory: Bool) {
        self.contentURL = contentURL
        self.isDirectory = isDirectory
    }

    func loadChildNode() {
        guard isDirectory else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            var tmpAppDataContens: [LCAppDataContent] = []
            let fm = FileManager()
            do {
                let contents = try fm.contentsOfDirectory(atPath: self.contentURL.path)
                for content in contents {
                    let contentURLtmp = self.contentURL.appendingPathComponent(content)
                    var isDirectory: ObjCBool = false
                    fm.fileExists(atPath: contentURLtmp.path, isDirectory: &isDirectory)
                    tmpAppDataContens.append(
                        LCAppDataContent(
                            contentURL: contentURLtmp, isDirectory: isDirectory.boolValue))
                }
                DispatchQueue.main.async {
                    self.childNode = tmpAppDataContens
                }
            } catch {
                self.errorInfo = error
            }
        }
    }

    static func == (lhs: LCAppDataContent, rhs: LCAppDataContent) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FileListView: View {
    @ObservedObject var node: LCAppDataContent

    var body: some View {
        if !node.isDirectory {
            Label(node.contentURL.lastPathComponent, systemImage: "document.fill")
        } else {
            DisclosureGroup(isExpanded: $node.isExpanded) {
                if let children = node.childNode {
                    ForEach(children) { child in
                        if child.errorInfo != nil {
                            Label(
                                "Error: \(child.errorInfo!.localizedDescription)",
                                systemImage: "exclamationmark.circle.fill"
                            )
                            .foregroundStyle(.red)
                        } else {
                            FileListView(node: child)
                        }
                    }
                } else {
                    ProgressView()
                }
            } label: {
                Label(node.contentURL.lastPathComponent, systemImage: "folder")
            }
            .onChange(of: node.isExpanded) { isExpanded in
                if isExpanded {
                    node.loadChildNode()
                }
            }
        }
    }
}

struct LCAppDataManagerView: View {
    @State var appInfo: LCAppInfo
    //@State private var AppDataContents: [LCAppDataContent]
    @State private var errorShow = false
    @State private var errorInfo = ""
    @State private var createSymlinkInsteadOfCopyingThem: Bool = false

    @ObservedObject var model: LCAppModel

    @StateObject var rootNode: LCAppDataContent  // = LCAppDataContent(contentURL: <#URL#>, isDirectory: <#Bool#>)
    @State private var nodeSelected: Set<LCAppDataContent> = []

    @Binding private var customDisplayName: String

    @EnvironmentObject private var sharedModel: SharedModel
    
    private let baseURL: URL
    private let baseDataFolder: String
    private let distinationDataFolders: String

    init(
        appModel: LCAppModel, appName: Binding<String>, baseDataFolder: String,
        distinationDataFolder: String
    ) {
        _appInfo = State(wrappedValue: appModel.appInfo)

        _model = ObservedObject(wrappedValue: appModel)

        _customDisplayName = appName

        self.baseURL = URL(
            fileURLWithPath: "\(LCPath.docPath.path)/Data/Application/\(baseDataFolder)")
        self.baseDataFolder = baseDataFolder
        self.distinationDataFolders = distinationDataFolder

        let tmpNode = LCAppDataContent(contentURL: baseURL, isDirectory: true)
        let fm = FileManager()
        do {
            let _ = try fm.contentsOfDirectory(atPath: baseURL.path)
        } catch {
            _errorShow = State(wrappedValue: true)
            _errorInfo = State(wrappedValue: error.localizedDescription)
            tmpNode.errorInfo = error
        }
        _rootNode = StateObject(wrappedValue: tmpNode)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(baseDataFolder)
                    Image(systemName: "arrow.down")
                    Text(distinationDataFolders.split(separator: "/").last!)
                }
                .padding(.top, 8)

                if errorShow {
                    Text("Error: \(errorInfo)")
                        .foregroundStyle(.red)
                        .padding()
                } else {
                    List(selection: $nodeSelected) {
                        FileListView(node: rootNode)
                    }
                    .environment(\.editMode, .constant(.active))
                    .onAppear {
                        rootNode.loadChildNode()
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.6)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                GroupBox(label: Text("Options")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $createSymlinkInsteadOfCopyingThem) {
                            Text("Create symlink")
                        }

                        Text(
                            "If enabled, symlinks will be created instead of copying files. This is useful for large files or directories."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)

                GroupBox(label: Text("Selection")) {
                    ScrollView {
                        Text(
                            "Selected Nodes: \(nodeSelected.map { $0.contentURL.lastPathComponent }.joined(separator: ", "))"
                        )
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 60)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .navigationTitle(customDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {

                } label: {
                    if createSymlinkInsteadOfCopyingThem {
                        Label("Create Symlink", systemImage: "link")
                    } else {
                        Label("Create Copy", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }

    /*
    private func drowChildNode(nodes: [LCAppDataContent]?) -> some View {
        ForEach(nodes ?? [], id: \.self) { content in
            Label(content.contentURL.lastPathComponent, systemImage: content.isDirectory ? "folder" : "document")
        }
    }
    
    
    private func searchDirectory(url: URL) -> [LCAppDataContent]? {
        var tmpAppDataContens: [LCAppDataContent] = []
        let fm = FileManager()
        do {
            let contents = try fm.contentsOfDirectory(atPath: url.path)
            for content in contents {
                let contentURL = url.appendingPathComponent(content)
                var isDirectory: ObjCBool = false
                fm.fileExists(atPath: contentURL.path, isDirectory: &isDirectory)
                tmpAppDataContens.append(
                    LCAppDataContent(contentURL: contentURL, isDirectory: isDirectory.boolValue))
            }
            return tmpAppDataContens
        } catch {
            errorInfo = error.localizedDescription
            return nil
        }
    }
    */
}
