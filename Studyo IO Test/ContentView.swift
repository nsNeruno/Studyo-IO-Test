//
//  ContentView.swift
//  Studyo IO Test
//
//  Created by Nanan Setiady on 04/08/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Query private var items: [Item]
//
//    var body: some View {
//        NavigationSplitView {
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
//                    } label: {
//                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//        } detail: {
//            Text("Select an item")
//        }
//    }
//
//    private func addItem() {
//        withAnimation {
//            let newItem = Item(timestamp: Date())
//            modelContext.insert(newItem)
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            for index in offsets {
//                modelContext.delete(items[index])
//            }
//        }
//    }
    
    var body: some View {
        NavigationSplitView {
            VStack {
                Spacer()
                NavigationLink(
                    destination: {
                        FrameExtractionScreen()
                    },
                    label: {
                        Text("Frame Extraction")
                    }
                )
                Spacer()
                NavigationLink(
                    destination: {
                        VideoPlayerScreen()
                    },
                    label: {
                        Text("Video Player")
                    }
                )
                Spacer()
                NavigationLink(
                    destination: {
                        VideoSwipeFeatureScreen()
                    },
                    label: {
                        Text("Video Swipe Feature")
                    }
                )
                Spacer()
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle(Text("Studyo Test App"))
        } detail: {
            Text("Select a Feature")
        }
    }
}

//#Preview {
//    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
//}

#Preview {
    ContentView()
}
