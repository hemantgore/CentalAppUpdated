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
    CMD_SET_LED_BLINK_RATE,
    CMD_SET_FRONT_CAM_ON_OFF,
    CMD_SET_REAR_CAM_ON_OFF,
    CMD_SET_FRONT_CAM_MODE,
    CMD_SET_FRONT_CAM_RESOLUTION,
    CMD_SET_FRONT_CAM_FRM_RATE,
    CMD_SET_REAR_CAM_MODE,
    CMD_SET_REAR_CAM_RESOLUTION,
    CMD_SET_REAR_CAM_FRM_RATE,
    CMD_SET_VISOR_TRANS_AUTO_ON_OFF,
    CMD_SET_VISOR_TRANS,
    CMD_SET_INTELLIGENT_NOISE_CANCELATION_ON_OFF,
    CMD_SET_LAUD_SPK_ON_OFF,
    CMD_SET_AMBIENT_NOISE_ON_OFF,
    CMD_SET_SIREN_HORN_RECON_ON_OFF,
    CMD_SET_OPEN_CHANNEL_ON_OFF,
    CMD_SET_SEARCH_OPEN_CHANNEL_ON_OFF,
    CMD_SET_CONN_USER_TO_ID
    
}CMD_TYPE;
@interface SmartBLEManager : NSObject

+ (id)sharedManager;
- (BOOL)isConnected;
- (NSString*)name;
- (void)scanSmartHelmet:(void(^)(NSError *error))scanBlock;
- (void)connectToDefaultSmartHelmet:(void(^)(NSError *error))connectBlock;
- (void)disconnectSmartHelmet:(void(^)(NSError *error))disconnectBlock;
- (void)sendCommandToHelmet:(CMD_TYPE)cmd params:(NSDictionary*)params completion:(void(^) (NSError *error))cmdCompletion;
@end
