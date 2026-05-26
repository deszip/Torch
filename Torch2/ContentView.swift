//
//  ContentView.swift
//  Torch2
//
//  Created by Deszip on 26/05/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = SpotlightDemoStore()

    var body: some View {
        TabView {
            SearchScreen(store: store)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            IndexedItemsScreen(store: store)
                .tabItem {
                    Label("Index", systemImage: "tray.full")
                }
        }
    }
}

private struct SearchScreen: View {
    @ObservedObject var store: SpotlightDemoStore

    @State private var title = ""
    @State private var bodyText = ""
    @State private var keywords = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Add Text") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.sentences)

                    TextEditor(text: $bodyText)
                        .frame(minHeight: 116)
                        .overlay(alignment: .topLeading) {
                            if bodyText.isEmpty {
                                Text("Text")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                        }

                    TextField("Keywords, comma separated", text: $keywords)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    HStack {
                        Button {
                            store.addItem(title: title, body: bodyText, keywordsText: keywords)
                            title = ""
                            bodyText = ""
                            keywords = ""
                        } label: {
                            Label("Add", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button {
                            store.addSampleItems()
                        } label: {
                            Label("Samples", systemImage: "sparkles")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Section("Search") {
                    TextField("Query", text: $store.query)
                        .textInputAutocapitalization(.sentences)
                        .onSubmit {
                            store.runSearch()
                        }
                        .onChange(of: store.query) {
                            store.runSearch()
                        }

                    Toggle(isOn: $store.options.semanticSearchEnabled) {
                        Label("Semantic", systemImage: "brain.head.profile")
                    }
                    .onChange(of: store.options.semanticSearchEnabled) {
                        store.runSearch()
                    }

                    Toggle(isOn: $store.options.rankedResultsEnabled) {
                        Label("Ranked", systemImage: "list.number")
                    }
                    .onChange(of: store.options.rankedResultsEnabled) {
                        store.runSearch()
                    }

                    Picker(selection: $store.options.keyboardLanguage) {
                        ForEach(SearchKeyboardLanguage.allCases) { language in
                            Text(language.title)
                                .tag(language)
                        }
                    } label: {
                        Label("Language", systemImage: "keyboard")
                    }
                    .onChange(of: store.options.keyboardLanguage) {
                        store.runSearch()
                    }

                    Stepper(value: $store.options.maxResultCount, in: 0...100) {
                        Label(maxResultCountTitle, systemImage: "text.badge.checkmark")
                    }
                    .onChange(of: store.options.maxResultCount) {
                        store.runSearch()
                    }

                    Stepper(value: $store.options.maxRankedResultCount, in: 1...50) {
                        Label("\(store.options.maxRankedResultCount) ranked", systemImage: "number")
                    }
                    .onChange(of: store.options.maxRankedResultCount) {
                        store.runSearch()
                    }
                }

                Section("Results") {
                    if store.searchResults.isEmpty {
                        ContentUnavailableView("No Results", systemImage: "magnifyingglass")
                    } else {
                        ForEach(store.searchResults) { result in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(result.title)
                                    .font(.headline)
                                Text(result.body)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(4)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Torch2")
            .safeAreaInset(edge: .bottom) {
                StatusBar(text: store.status, itemCount: store.indexedItems.count)
            }
            .onAppear {
                store.prepareSearch()
            }
        }
    }

    private var maxResultCountTitle: String {
        store.options.maxResultCount == 0
            ? "All results"
            : "\(store.options.maxResultCount) results"
    }
}

private struct IndexedItemsScreen: View {
    @ObservedObject var store: SpotlightDemoStore

    var body: some View {
        NavigationStack {
            List {
                if store.indexedItems.isEmpty {
                    ContentUnavailableView("No Indexed Items", systemImage: "tray")
                } else {
                    ForEach(store.indexedItems) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(item.title)
                                    .font(.headline)

                                Spacer()

                                Text(item.createdAt, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(item.body)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(5)

                            if !item.keywords.isEmpty {
                                ViewThatFits(in: .horizontal) {
                                    HStack {
                                        ForEach(item.keywords, id: \.self) { keyword in
                                            KeywordBadge(keyword)
                                        }
                                    }

                                    VStack(alignment: .leading) {
                                        ForEach(item.keywords, id: \.self) { keyword in
                                            KeywordBadge(keyword)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button(role: .destructive) {
                                store.deleteItem(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Index")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        store.cleanIndex()
                    } label: {
                        Label("Clean", systemImage: "trash")
                    }
                    .disabled(store.indexedItems.isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                StatusBar(text: store.status, itemCount: store.indexedItems.count)
            }
        }
    }
}

private struct KeywordBadge: View {
    let keyword: String

    init(_ keyword: String) {
        self.keyword = keyword
    }

    var body: some View {
        Text(keyword)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.secondary.opacity(0.12), in: Capsule())
    }
}

private struct StatusBar: View {
    let text: String
    let itemCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Label("\(itemCount)", systemImage: "tray.full")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

#Preview {
    ContentView()
}
