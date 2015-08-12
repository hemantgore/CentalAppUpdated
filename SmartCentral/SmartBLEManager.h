//
//  SmartBLEManager.h
//  SmartCentral
//
//  Copyright (c) 2015 H. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum {
    CMD_SET_CYCLING_MODE,
    CMD_SET_MOTOSPORT_MODE,
    CMD_SET_WINTERSPORT_MODE,
    CMD_SET_LONGBOARDING_MODE,
    CMD_SET_DEBUG_MODE,
    CMD_SET_STUNT_MODE,
    CMD_SET_RACE_MODE,
    CMD_SET_COMMUTE_MODE,
    CMD_SET_LED_BRIGHTNESS,
    CMD_SET_LED_AUTO_ON_OFF,
    CMD_SET_LED_BLINK_RATE
    
    
}CMD_TYPE;
@interface SmartBLEManager : NSObject

+ (id)sharedManager;
- (BOOL)isConnected;
- (NSString*)name;
- (void)scanSmartHelmet:(void(^)(NSError *error))scanBlock;
- (void)connectToDefaultSmartHelmet:(void(^)(NSError *error))connectBlock;
- (void)disconnectSmartHelmet:(void(^)(NSError *error))disconnectBlock;
- (void)sendCommandToHelmet:(CMD_TYPE)cmd value:(NSString*)value completion:(void(^) (NSError *error))cmdCompletion;
@end
