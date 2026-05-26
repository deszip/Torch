//
//  SpotlightDemoStore.swift
//  Torch2
//
//  Created by Codex on 26/05/2026.
//

import Combine
import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

struct IndexedTextItem: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var body: String
    var keywords: [String]
    var createdAt: Date
}

struct SpotlightSearchResult: Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
}

struct SpotlightSearchOptions: Equatable {
    var semanticSearchEnabled = true
    var rankedResultsEnabled = true
    var keyboardLanguage = SearchKeyboardLanguage.system
    var maxResultCount = 0
    var maxRankedResultCount = 10
}

enum SearchKeyboardLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case spanish

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .system:
            "System"
        case .english:
            "English"
        case .spanish:
            "Spanish"
        }
    }

    var spotlightValue: String? {
        switch self {
        case .system:
            nil
        case .english:
            "en"
        case .spanish:
            "es"
        }
    }
}

@MainActor
final class SpotlightDemoStore: NSObject, ObservableObject {
    
    @Published private(set) var indexedItems: [IndexedTextItem] = []
    @Published private(set) var searchResults: [SpotlightSearchResult] = []
    @Published var query = ""
    @Published var options = SpotlightSearchOptions()
    @Published private(set) var status = "Ready"
    
    private let index = CSSearchableIndex(name: "Torch2SemanticSearch")
    private let domainIdentifier = "RD.Torch2.semantic-demo"
    private let defaultsKey = "Torch2.IndexedTextItems"
    private var searchTask: Task<Void, Never>?
    private var didPrepareSearch = false
    
    override init() {
        super.init()
        
        self.loadCatalog()
        self.prepareSearch()
    }
    
    func prepareSearch() {
        guard !didPrepareSearch else { return }
        
        didPrepareSearch = true
        status = "Preparing Spotlight semantic search..."
        
        Task {
            CSUserQuery.prepare()
            status = "Spotlight search is ready."
        }
    }
    
    func addItem(title: String, body: String, keywordsText: String) {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else {
            status = "Enter text before adding an item."
            return
        }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = IndexedTextItem(
            id: UUID().uuidString,
            title: trimmedTitle.isEmpty ? String(trimmedBody.prefix(48)) : trimmedTitle,
            body: trimmedBody,
            keywords: parsedKeywords(from: keywordsText),
            createdAt: Date()
        )
        
        index.indexSearchableItems([searchableItem(from: item)]) { error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.status = "Indexing failed: \(error.localizedDescription)"
                    return
                }
                
                self.indexedItems.insert(item, at: 0)
                self.saveCatalog()
                self.status = "Added 1 item to Spotlight."
            }
        }
    }
    
    func addSampleItems() {
        let samples = [
            IndexedTextItem(
                id: UUID().uuidString,
                title: "Sun and moon",
                body: "Sun and moon",
                keywords: ["sun", "moon"],
                createdAt: Date()
            ),
            IndexedTextItem(
                id: UUID().uuidString,
                title: "Sol and luna",
                body: "Sol and luna",
                keywords: ["sol", "luna"],
                createdAt: Date()
            ),
            IndexedTextItem(
                id: UUID().uuidString,
                title: "Solar lunch plan",
                body: "Meet near the sunny terrace for lunch after the design review.",
                keywords: ["food", "meeting", "sun"],
                createdAt: Date()
            ),
            IndexedTextItem(
                id: UUID().uuidString,
                title: "Moonlight reading note",
                body: "A quiet evening note about books, astronomy, and reflected moon light.",
                keywords: ["books", "astronomy", "night"],
                createdAt: Date()
            ),
            IndexedTextItem(
                id: UUID().uuidString,
                title: "Car maintenance reminder",
                body: "Schedule a battery check before the long mountain drive next weekend.",
                keywords: ["vehicle", "battery", "travel"],
                createdAt: Date()
            )
        ]
        
        index.indexSearchableItems(samples.map(searchableItem(from:))) { error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.status = "Sample indexing failed: \(error.localizedDescription)"
                    return
                }
                
                self.indexedItems.insert(contentsOf: samples, at: 0)
                self.saveCatalog()
                self.status = "Added \(samples.count) sample items."
            }
        }
    }
    
    func deleteItem(_ item: IndexedTextItem) {
        index.deleteSearchableItems(withIdentifiers: [item.id]) { error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.status = "Delete failed: \(error.localizedDescription)"
                    return
                }
                
                self.indexedItems.removeAll { $0.id == item.id }
                self.searchResults.removeAll { $0.id == item.id }
                self.saveCatalog()
                self.status = "Deleted item."
            }
        }
    }
    
    func cleanIndex() {
        index.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.status = "Clean failed: \(error.localizedDescription)"
                    return
                }
                
                self.indexedItems.removeAll()
                self.searchResults.removeAll()
                self.saveCatalog()
                self.status = "Cleaned the Torch2 Spotlight index."
            }
        }
    }
    
    func runSearch() {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask?.cancel()
        
        guard !trimmedQuery.isEmpty else {
            searchResults = []
            return
        }
        
        let currentOptions = options
        status = "Searching..."
        
        searchTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                let context = CSUserQueryContext()
                context.fetchAttributes = [
                    "title",
                    "displayName",
                    "contentDescription",
                    "textContent",
                    "keywords"
                ]
                context.keyboardLanguage = currentOptions.keyboardLanguage.spotlightValue
                context.maxResultCount = currentOptions.maxResultCount
                context.enableRankedResults = currentOptions.rankedResultsEnabled
                context.disableSemanticSearch = !currentOptions.semanticSearchEnabled
                context.maxRankedResultCount = currentOptions.maxRankedResultCount
                
                let query = CSUserQuery(userQueryString: trimmedQuery, userQueryContext: context)
                var foundItems: [CSSearchableItem] = []
                
                for try await response in query.responses {
                    try Task.checkCancellation()
                    
                    if case .item(let match) = response {
                        foundItems.append(match.item)
                    }
                }
                
                try Task.checkCancellation()
                let sortedItems = currentOptions.rankedResultsEnabled
                ? foundItems.sorted { $0.compare(byRank: $1) == .orderedAscending }
                : foundItems
                let results = sortedItems.map { searchableItem in
                    let attributes = searchableItem.attributeSet
                    return SpotlightSearchResult(
                        id: searchableItem.uniqueIdentifier,
                        title: attributes.title ?? attributes.displayName ?? "Untitled",
                        body: attributes.textContent ?? attributes.contentDescription ?? ""
                    )
                }
                
                self.searchResults = results
                let language = currentOptions.keyboardLanguage.title
                self.status = "Found \(results.count) result\(results.count == 1 ? "" : "s"). Language: \(language). Semantic: \(currentOptions.semanticSearchEnabled ? "on" : "off")."
            } catch is CancellationError {
                return
            } catch {
                self.searchResults = []
                self.status = "Search failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func searchableItem(from item: IndexedTextItem) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = item.title
        attributes.displayName = item.title
        attributes.contentDescription = item.body
        attributes.textContent = item.body
        attributes.keywords = item.keywords
        
        let searchableItem = CSSearchableItem(
            uniqueIdentifier: item.id,
            domainIdentifier: domainIdentifier,
            attributeSet: attributes
        )
        searchableItem.expirationDate = .distantFuture
        return searchableItem
    }
    
    private func parsedKeywords(from text: String) -> [String] {
        text
            .split { character in
                character == "," || character == "\n"
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func loadCatalog() {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let decoded = try? JSONDecoder().decode([IndexedTextItem].self, from: data)
        else {
            return
        }
        
        indexedItems = decoded
    }
    
    private func saveCatalog() {
        if let data = try? JSONEncoder().encode(indexedItems) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
