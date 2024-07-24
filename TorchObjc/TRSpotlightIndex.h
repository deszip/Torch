//
//  TRSpotlightIndex.h
//  TorchObjc
//
//  Created by Deszip on 05.07.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TRSpotlightIndex : NSObject

- (void)add:(NSString *)text;
- (void)search:(NSString *)searchQuery;

@end

NS_ASSUME_NONNULL_END
