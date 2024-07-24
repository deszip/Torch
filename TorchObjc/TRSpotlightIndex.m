//
//  TRSpotlightIndex.m
//  TorchObjc
//
//  Created by Deszip on 05.07.2024.
//

#import "TRSpotlightIndex.h"

#import <CoreSpotlight/CoreSpotlight.h>

@interface TRSpotlightIndex ()

@property (strong, nonatomic) CSSearchableIndex *index;

@end

@implementation TRSpotlightIndex

- (instancetype)init {
    if (self = [super init]) {
        _index = [[CSSearchableIndex alloc] initWithName:@"TorchIndexObjc"];
        [_index deleteAllSearchableItemsWithCompletionHandler:^(NSError *error) {
            NSLog(@"[Spotlight]: dropped searchable items, error: %@", error);
        }];
    }

    return self;
}

- (void)add:(NSString *)text {
    CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithContentType:UTTypeText];
    attributeSet.title = text;
    attributeSet.textContent = text;
    attributeSet.keywords = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:[NSString stringWithFormat:@"%lu", (unsigned long)text.hash]
                                                               domainIdentifier:@"com.torch"
                                                                   attributeSet:attributeSet];
    [self.index fetchLastClientStateWithCompletionHandler:^(NSData *clientState, NSError *error) {
        [self.index indexSearchableItems:@[item] completionHandler:^(NSError *error) {
            NSLog(@"[Spotlight]: Indexing text chunk: \n%@\n, error: %@", text, error);
        }];
    }];
}

- (void)search:(NSString *)searchQuery {
    [CSUserQuery prepare];
    CSUserQueryContext *c = [CSUserQueryContext userQueryContext];
    c.fetchAttributes = @[@"title", @"displayName", @"keywords", @"contentType", @"path", @"contentURL", @"textContent"];
//    c.disableSemanticSearch = YES;
    CSUserQuery *query = [[CSUserQuery alloc] initWithUserQueryString:searchQuery userQueryContext:c];
    
    __block NSMutableArray <CSSearchableItem *> *results = [@[] mutableCopy];
    [query setFoundItemsHandler:^(NSArray<CSSearchableItem *> *items) {
        NSLog(@"Found items: %@", items);
        [items enumerateObjectsUsingBlock:^(CSSearchableItem *obj, NSUInteger idx, BOOL *stop) {
            [results addObject:obj];
        }];
    }];

    [query setCompletionHandler:^(NSError *error) {
        if (error == nil) {
            NSLog(@"[Spotlight]: Search finished: query: %@, results: %@", searchQuery, results);
        } else {
            NSLog(@"[Spotlight]: Search failed: %@", error);
        }
    }];

    [query start];
}

@end
