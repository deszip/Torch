//
//  SpotlightIndex.swift
//  Torch
//
//  Created by Deszip on 05.07.2024.
//

import CoreSpotlight

class SpotlightIndex {

    private let index: CSSearchableIndex

    init() {
        self.index = CSSearchableIndex(name: "TorchIndex")
        self.index.deleteAllSearchableItems()
    }

    func add(text: String) {
        let attr = CSSearchableItemAttributeSet(contentType: .text)
        attr.textContent = text
        attr.title = text
        attr.keywords = text.components(separatedBy: " ").filter { $0.count > 0 }

        let item = CSSearchableItem(uniqueIdentifier: "\(text.hash)", domainIdentifier: "com.torch", attributeSet: attr)
        self.index.indexSearchableItems([item]) { error in
            print("Item indexed, error: \(error.debugDescription)")
        }
    }

    func search(_ query: String, resultHandler: @escaping ([String]) -> Void) {
        CSUserQuery.prepare()

        let c = CSUserQueryContext()
        c.fetchAttributes = ["title", "contentDescription"]
        c.disableSemanticSearch = true
        let q = CSUserQuery(queryString: query, queryContext: c)

        var foundItems: [CSSearchableItem] = []
        q.foundItemsHandler = { items in
            print("Found: \(items)")
            foundItems.append(contentsOf: items)
        }
        q.completionHandler = { error in
            print("Search finished, error: \(error.debugDescription)")
            resultHandler(foundItems.map { $0.attributeSet.textContent ?? "" })
        }
        
        q.start()

//        Task {
//            var responses: [String] = []
//            for try await element in q.responses {
//                print("Got response element: \(element)")
//                switch element {
//                case .item(let item):
//                    responses.append(item.item.attributeSet.textContent ?? "")
//                default: ()
//                }
//            }
//
//            resultHandler(responses)
//        }
    }

    func runQuery() {

    }
}
