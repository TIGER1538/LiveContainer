//
//  LCAppDataManagementView.swift
//  LiveContainer
//
//  Created by Taiga Yoda on 2025/05/16.
//

import SwiftUI

class LCAppDataContent: ObservableObject, Identifiable {
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
                    tmpAppDataContens.append(LCAppDataContent(contentURL: contentURLtmp, isDirectory: isDirectory.boolValue))
                }
                DispatchQueue.main.async {
                    self.childNode = tmpAppDataContens
                }
            } catch {
                self.errorInfo = error
            }
        }
    }
}

struct FileListView: View {
    @ObservedObject var node: LCAppDataContent
    
    var body: some View {
        DisclosureGroup(isExpanded: $node.isExpanded) {
            if let children = node.childNode {
                ForEach(children) { child in
                    FileListView(node: child)
                }
            } else {
                ProgressView()
            }
        } label: {
            Label(node.contentURL.lastPathComponent, systemImage: node.isDirectory ? "folder" : "document")
        }
        .onChange(of: node.isExpanded) { isExpanded in
            if isExpanded {
                node.loadChildNode()
            }
        }
    }
}

struct LCAppDataManagerView: View {
    @State var appInfo: LCAppInfo
    //@State private var AppDataContents: [LCAppDataContent]
    @State private var errorShow = false
    @State private var additionalErrorShow = false
    @State private var errorInfo = ""
    
    @ObservedObject var model : LCAppModel
    @StateObject var rootNode: LCAppDataContent// = LCAppDataContent(contentURL: <#URL#>, isDirectory: <#Bool#>)
    
    @Binding private var customDisplayName: String
    
    @EnvironmentObject private var sharedModel : SharedModel

    private let baseURL: URL
    private let baseDataFolder: String
    private let distinationDataFolders: String
    
    init(appModel: LCAppModel, appName: Binding<String>, baseDataFolder: String, distinationDataFolder: String) {
        _appInfo = State(wrappedValue: appModel.appInfo)
        
        _model = ObservedObject(wrappedValue: appModel)

        _customDisplayName = appName
        
        self.baseURL = URL(fileURLWithPath: "\(LCPath.docPath.path)/Data/Application/\(baseDataFolder)")
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
        VStack {
            VStack(spacing: 8) {
                Text(baseDataFolder)
                Image(systemName: "arrow.down")
                Text(distinationDataFolders.split(separator: "/").last!)
            }
            
            if errorShow {
                Spacer()
                Text("Error: \(errorInfo)")
                    .foregroundStyle(.red)
            } else {
                List {
                    FileListView(node: rootNode)
                    /*
                    ForEach(AppDataContents, id: \.self) { content in
                        if content.isDirectory {
                            DisclosureGroup {
                                if let children = content.childNode
                            } label: {
                                Label(AppDataContents[index].contentURL.lastPathComponent, systemImage: "folder")
                                Spacer()
                            }
                            
                        } else {
                            Label(AppDataContents[index].contentURL.lastPathComponent, systemImage: "document.fill")
                            //HStack {
                            //    Image(systemName: "document")
                            //    Text(content.contentURL.lastPathComponent)
                            //}
                        }
                    }
                     */
                }
                .onAppear {
                    rootNode.loadChildNode()
                }
            }
            
            if additionalErrorShow {
                DisclosureGroup {
                    Text("Additional Error: \(errorInfo)")
                } label: {
                    Text("Additional Error")
                }
            }
        }
        .navigationTitle(customDisplayName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /*
    private func drowChildNode(nodes: [LCAppDataContent]?) -> some View {
        ForEach(nodes ?? [], id: \.self) { content in
            Label(content.contentURL.lastPathComponent, systemImage: content.isDirectory ? "folder" : "document")
        }
    }
     */
    
    private func searchDirectory(url: URL) -> Optional<[LCAppDataContent]> {
        var tmpAppDataContens: [LCAppDataContent] = []
        let fm = FileManager()
        do {
            let contents = try fm.contentsOfDirectory(atPath: url.path)
            for content in contents {
                let contentURL = url.appendingPathComponent(content)
                var isDirectory: ObjCBool = false
                fm.fileExists(atPath: contentURL.path, isDirectory: &isDirectory)
                tmpAppDataContens.append(LCAppDataContent(contentURL: contentURL, isDirectory: isDirectory.boolValue))
            }
            return tmpAppDataContens
        } catch {
            errorInfo = error.localizedDescription
            return nil
        }
    }
}

