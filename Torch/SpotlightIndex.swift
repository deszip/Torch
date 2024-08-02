//
//  SpotlightIndex.swift
//  Torch
//
//  Created by Deszip on 05.07.2024.
//

import CoreSpotlight

typealias SearchResult = ([String]) -> Void

class SpotlightIndex: NSObject, CSSearchableIndexDelegate {
    private let index: CSSearchableIndex

    var logHandler: ((String) -> Void)?

    init(_ logHandler: ((String) -> Void)?) {
        self.logHandler = logHandler
        self.index = CSSearchableIndex(name: "TorchIndex")

        super.init()

        self.index.indexDelegate = self
        self.index.deleteAllSearchableItems() { error in
            self.logHandler?("Dropped indexed items, error: \(error.debugDescription)")
        }
    }

    func add(chunks: [String]) {
        var items: [CSSearchableItem] = []
        for chunk in chunks {
            let attr = CSSearchableItemAttributeSet(contentType: .text)
            attr.textContent = chunk
            attr.title = chunk
            attr.keywords = chunk.components(separatedBy: " ").filter { $0.count > 0 }

            let item = CSSearchableItem(uniqueIdentifier: "\(chunk.hash)", domainIdentifier: "com.torch", attributeSet: attr)
            items.append(item)
        }

        self.index.fetchLastClientState { state, error in
            if state == nil {
//                self.index.beginBatch()
                self.index.indexSearchableItems(items) { error in
                    self.logHandler?("\(items.count) items indexed, error: \(error.debugDescription)")
                }
                // wtf is newState?
//                self.index.endIndexBatch(expectedClientState: nil, newClientState: state ) { error in
//                    print("Batch indexing finished, error: \(error.debugDescription)")
//                }
            }
        }
    }

    func search(_ query: String, resultHandler: @escaping SearchResult) {
        CSUserQuery.prepare()

        let c = CSUserQueryContext()
        c.fetchAttributes = ["title", "contentDescription", "textContent"]
        c.enableRankedResults = true
        c.maxRankedResultCount = 2
//        c.disableSemanticSearch = true
        let q = CSUserQuery(userQueryString: query, userQueryContext: c)

        runQuery_new(query: q, handler: resultHandler)
//        runQuery_old(query: q, handler: resultHandler)
    }

    func runQuery_new(query: CSUserQuery, handler: @escaping SearchResult) {
        Task {
            var responses: [String] = []
            for try await element in query.responses {
                self.logHandler?("Got response element: \(element)")
                switch element {
                case .item(let item):
                    responses.append(item.item.attributeSet.textContent ?? "")
                default: ()
                }
            }

            handler(responses)
        }
    }

    func runQuery_old(query: CSUserQuery, handler: @escaping SearchResult) {
        var foundItems: [CSSearchableItem] = []
        query.foundItemsHandler = { items in
            self.logHandler?("Found: \(items)")
            foundItems.append(contentsOf: items)
        }
        query.completionHandler = { error in
            self.logHandler?("Search finished, error: \(error.debugDescription)")
            handler(foundItems.map { $0.attributeSet.textContent ?? "" })
        }

        query.start()
    }

    // MARK: - CSSearchableIndexDelegate

    func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
        self.logHandler?("reindexAllSearchableItemsWithAcknowledgementHandler called")
        acknowledgementHandler()
    }

    func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
        self.logHandler?("wreindexAllSearchableItemsWithAcknowledgementHandler  called")
        acknowledgementHandler()
    }
}
