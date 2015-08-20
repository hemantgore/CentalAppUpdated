//
//  SmartBLEManager.h
//  SmartCentral
//
//  Copyright (c) 2015 H. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum {
    CMD_SET_SYS_MAIN_MODE=0,
    CMD_SET_DEBUG_PASS,
    CMD_SET_SYS_SUB_MODE,
    CMD_SET_NAV_VCS_ON_OFF,
    CMD_SET_IMGINFO_VCS_ON_OFF,
    CMD_SET_ELEINFO_VCS_ON_OFF,
    CMD_SET_CORE_FAN_SPEED,
    CMD_SET_LED_BRIGHTNESS,
    CMD_SET_LED_AUTO_ON_OFF,
    CMD_SET_LED_BLINK_RATE,
    CMD_SET_HAZARD_LIGHT_ON_OFF,
    CMD_SET_STANDBY_ON_OFF,
    CMD_SET_PWR_ON_OFF,
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
    CMD_SET_CONN_USER_TO_ID,
    CMD_GET_CURRENT_SPEED,
    CMD_GET_CURRENT_DATE,
    CMD_GET_CURRENT_TIME,
    CMD_GET_DIRECTION,
    CMD_GET_LOCATION,
    CMD_GET_ESTIMATED_TRAVEL_TIME,
    CMD_GET_ACCELRATION,
    CMD_GET_ANGULAR_VELOCITY,
    CMD_GET_PITCH_ANGLE,
    CMD_GET_ROLL_ANGLE,
    CMD_GET_YAW_ANGLE,
    CMD_GET_BATTERY_LIFE,
    CMD_ACTION_CAL_TEMP_SNR,
    CMD_ACTION_RUN_DIAG_REP,
    CMD_ACTION_RUN_DATA_REP,
    CMD_ACTION_OPEN_DEBUG_PORL
    
}CMD_TYPE;

typedef enum{
    CYCLING = 1,
    MOTOSPORT,
    WINTERSPORT,
    LONGBOARDING,
    DEBUG_MODE
    
}SYS_MAIN_MODE;

typedef enum{
    STUNT = 1,
    RACE,
    COMMUTE
}SYS_SUB_MODE;

typedef enum{
    OFF = 0,
    ON
}STATE;

typedef enum{
    STILL = 1,
    VIDEO
}CAM_MODE;

typedef enum{
    VGA = 1,
    SVGA,
    XGA,
    SXGA,
    QVGA,
    P720,
    P1080,
    NTSC,
    PAL,
    USER_DEFINE
    
}CAM_RESOLUTION;

typedef enum{
    SLOW = 1,
    MEDIUM,
    FAST,
    FASTEST
}LED_BLINK_RATE;

typedef enum{
    Hz15 = 1,
    Hz30,
    Hz60,
    Hz120
}CAM_FRM_RATE;

typedef enum{
    ACC_X = 1,
    ACC_Y,
    ACC_Z
}ACCELRATION;

typedef enum{
    ANG_X = 4,
    ANG_Y,
    ANG_Z
}ANGULAR_VELOCITY;

@interface SmartBLEManager : NSObject

+ (id)sharedManager;
- (BOOL)isConnected;
- (NSString*)name;
- (void)scanSmartHelmet:(void(^)(NSError *error))scanBlock;
- (void)connectToDefaultSmartHelmet:(void(^)(NSError *error))connectBlock;
- (void)disconnectSmartHelmet:(void(^)(NSError *error))disconnectBlock;
- (void)sendCommandToHelmet:(CMD_TYPE)cmd params:(NSDictionary*)params completion:(void(^) (NSError *error))cmdCompletion;
@end
