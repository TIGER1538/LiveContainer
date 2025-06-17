import SwiftUI

final class LCFileListViewModel: ObservableObject {
    let directoryURL: URL
    @Published var files: [URL] = []
    @Published var selectedFiles: Set<URL> = []
    
    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }
    
    func loadFiles() {
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
            DispatchQueue.main.async { [weak self] in
                self?.files = fileURLs
            }
        } catch {
            print("Error reading directory: \(error)")
        }
    }
}

struct LCFileListView: View {
    @StateObject private var viewModel: LCFileListViewModel

    init(directoryURL: URL) {
        _viewModel = StateObject(wrappedValue: LCFileListViewModel(directoryURL: directoryURL))
    }
    
    var body: some View {
        NavigationView {
            List(viewModel.files, id: \.self) { file in
                HStack {
                    Text(file.lastPathComponent)
                    Spacer()
                    if viewModel.selectedFiles.contains(file) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                // Remove the default hit-testing area and cover full row.
                .contentShape(Rectangle())
                .onTapGesture {
                    if viewModel.selectedFiles.contains(file) {
                        viewModel.selectedFiles.remove(file)
                    } else {
                        viewModel.selectedFiles.insert(file)
                    }
                }
            }
            .navigationTitle("Files")
            .toolbar {
                // Display selected count in the toolbar.
                ToolbarItem(placement: .automatic) {
                    Text("選択中: \(viewModel.selectedFiles.count)")
                }
            }
            .onAppear {
                viewModel.loadFiles()
            }
        }
    }
}

struct LCFileListView_Previews: PreviewProvider {
    static var previews: some View {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        LCFileListView(directoryURL: documentsURL)
    }
}