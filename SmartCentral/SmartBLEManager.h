//
//  SmartBLEManager.h
//  SmartCentral
//
//  Copyright (c) 2015 H. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SmartBLEManager : NSObject

+ (id)sharedManager;
- (void)scanSmartHelmet:(void(^)(NSError *error)) scanBlock;
- (void)connectToDefaultSmartHelmet:(void(^)(NSError *error))connectBlock;
@end
