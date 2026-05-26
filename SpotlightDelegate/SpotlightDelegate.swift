//
//  SpotlightDelegate.swift
//  SpotlightDelegate
//
//  Created by Deszip on 24.07.2024.
//

import CoreSpotlight

class SpotlightDelegate: CSIndexExtensionRequestHandler {

    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
        
        print("Index delegate: reindex all...")
        
        acknowledgementHandler()
    }

    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
        
        print("Index delegate: reindex: \(identifiers)")
        
        acknowledgementHandler()
    }

    override func data(for searchableIndex: CSSearchableIndex, itemIdentifier: String, typeIdentifier: String) throws -> Data {
        
        print("Index delegate: Data for item (\(typeIdentifier)): \(itemIdentifier)")
        
        return Data()
    }

    override func fileURL(for searchableIndex: CSSearchableIndex, itemIdentifier: String, typeIdentifier: String, inPlace: Bool) throws -> URL {
        
        print("Index delegate: URL for index \(searchableIndex): item - \(itemIdentifier), type - \(typeIdentifier)")
        
        return URL(fileURLWithPath: "")
    }
    
    override func searchableIndexDidThrottle(_ searchableIndex: CSSearchableIndex) {
        print("Index delegate: did throttle...")
    }

    override func searchableIndexDidFinishThrottle(_ searchableIndex: CSSearchableIndex) {
        print("Index delegate: did finish throttle...")
    }
}
