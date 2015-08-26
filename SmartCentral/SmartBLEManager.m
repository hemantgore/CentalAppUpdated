//
//  SmartBLEManager.m
//  SmartCentral
//
//  Copyright (c) 2015 H. All rights reserved.
//

#import "SmartBLEManager.h"
#import "MelodyManager.h"

#define NOTIFY_MTU      20
#define CONNECTION_TIMEOUT  3.0
static void (^__scanBlock)(NSError *error);
static void (^__connectBlock)(NSError *error);
static void (^__disconnectBlock)(NSError *error);
static void (^__commandCompletionBlock)(NSError *error);

@interface SmartBLEManager ()<MelodyManagerDelegate,MelodySmartDelegate>
{
     MelodyManager *melodyManager;
     NSMutableArray *_objects;
    NSDateFormatter *dateFormatter;
}
@property (strong,    nonatomic)    MelodySmart  *melodySmart;
@property (strong,    nonatomic)    NSData       *dataToSend;
@property (nonatomic, readwrite)    NSInteger    sendDataIndex;
@property (nonatomic, assign)       BOOL         isPowerOn;
@property (nonatomic, assign,getter=isConnected)       BOOL         connected;
@end
@implementation SmartBLEManager
#pragma mark - Singleton Methods -

+ (id)sharedManager {
    static SmartBLEManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}
- (NSString*)name{
    return self.melodySmart.name
    ;
}
- (BOOL)isConnected{
    return self.melodySmart.isConnected;
}
- (id)init {
    if (self = [super init]) {
        //Melody Manager
        melodyManager = [MelodyManager new];
        [melodyManager setForService:nil andDataCharacterisitc:nil andPioReportCharacteristic:nil andPioSettingCharacteristic:nil];
        melodyManager.delegate = self;
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    return self;
}
- (void)stopScanningMelody{
   [self.melodySmart disconnect];
}

- (void)scanSmartHelmet:(void(^)(NSError *error))scanBlock {
    __scanBlock = scanBlock;
    [self clearObjects];
    [melodyManager scanForMelody];
    [self performSelector:@selector(stopScanningMelody) withObject:nil afterDelay:CONNECTION_TIMEOUT];
    [NSTimer scheduledTimerWithTimeInterval:3.5 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
}
- (void)connectToDefaultSmartHelmet:(void(^)(NSError *error))connectBlock {
    __connectBlock = connectBlock;
    
    self.melodySmart = [_objects count]?_objects[0]:nil;
    if(self.melodySmart!=nil){
        self.melodySmart.delegate = self;
        [self.melodySmart connect];
    }
}
- (void)disconnectSmartHelmet:(void(^)(NSError *error))disconnectBlock
{
    __disconnectBlock = disconnectBlock;
    [self.melodySmart disconnect];
}
-(void)connectionTimer:(NSTimer *)timer
{
    self.melodySmart = [_objects count]?_objects[0]:nil;
    
    if(self.melodySmart!=nil)
    {
        if(__scanBlock) __scanBlock(nil);
        
    }else{
        NSError *err = [NSError errorWithDomain:@"" code:-1001 userInfo:[NSDictionary dictionaryWithObject:@"No SmartHelmet found. Check if SmartHelmet is Powered ON and search again." forKey:NSLocalizedDescriptionKey]];
        if(__scanBlock) __scanBlock(err);
        
//        if (str == nil) {
//            str = [NSMutableString stringWithFormat:@"No BLE found \n"];
//        } else {
//            [str appendFormat:@"No BLE found \n"];
//        }
//        self.degubInfoTextView.text =str;
    }
}

- (void)clearObjects {
    if(_objects) [_objects removeAllObjects];
}
- (void)insertNewObject:(MelodySmart*)device
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects addObject:device];
}

#pragma mark - Smart Melody Delegates -
-(void)melodySmart:(MelodySmart *)melody didSendData:(NSError *)error {
    [self sendDataToMelody];
}
- (void)melodySmart:(MelodySmart *)melody didConnectToMelody:(BOOL)result {
    NSLog(@"didConnectToMelody");
    _isPowerOn = YES;
    if(__connectBlock){
        NSError *err = !result ? [NSError errorWithDomain:@"" code:-1001 userInfo:[NSDictionary dictionaryWithObject:@"Not able to connect to SmartHelmet" forKey:NSLocalizedDescriptionKey]] : nil;
        __connectBlock(err);
    }
}
-(void)melodySmartDidDisconnectFromMelody:(MelodySmart *)melody {
    NSLog(@"didDisconnectFromMelody");
    if(__disconnectBlock){
        NSError *err = melody.isConnected ? [NSError errorWithDomain:@"" code:-1001 userInfo:[NSDictionary dictionaryWithObject:@"Not able to disconnect from SmartHelmet" forKey:NSLocalizedDescriptionKey]] : nil;
        __disconnectBlock(err);
    }
}
-(void)melodySmart:(MelodySmart *)melody didReceiveData:(NSData *)data {
    NSString *temp =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"didReceivedData::%@",temp);
    
}
- (void)melodySmart:(MelodySmart *)melody didReceiveCommandReply:(NSData *)data {
    NSString *temp =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"didReceiveCommandReply::%@",temp);
}

#pragma mark - MelodyManager delegate -

-(void)melodyManagerDiscoveryDidRefresh:(MelodyManager *)manager {
    //    NSLog(@"discoveryDidRefresh");
    for (NSInteger i = _objects.count; i < [MelodyManager numberOfFoundDevices]; i++) {
        [self insertNewObject:[MelodyManager foundDeviceAtIndex:i]];
    }
    
}
- (void) melodyManagerDiscoveryStatePoweredOff:(MelodyManager*)manager{
    _isPowerOn = NO;
    //TODO: In PwrDwn: 0xBB, set it YES/NO accordingly

}
- (BOOL)isPowerOn{
    return _isPowerOn;
}
- (void) melodyManagerConnectedListChanged{
    
}
#pragma mark - Send data to BLE -
- (void) sendCommandToHelmet:(CMD_TYPE)cmd params:(NSDictionary*)params  completion:(void(^) (NSError *error))cmdCompletion
{
    __commandCompletionBlock = cmdCompletion;
    if(!_isPowerOn){
        NSError *err = [NSError errorWithDomain:@"" code:-1001 userInfo:[NSDictionary dictionaryWithObject:@"Check if SmartHelmet is Powered ON and try again." forKey:NSLocalizedDescriptionKey]];
        __commandCompletionBlock(err);
        return;
    }
    NSString *cmdData;
    switch (cmd) {
        case CMD_SET_SYS_MAIN_MODE://Main Mode
        {
            cmdData = [NSString stringWithFormat:@"0x0001 0xB0 0xFD 0xC3 0xA0 0xEC 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_DEBUG_PASS:
        {
            /*ActDebugMod: 0xE6 ,This command activates “Debug Mode” and is accompanied by a six character password. These six values act as the commands parameters,
             Values: The password value is 335687942
             */
            
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC3 0xA0 0xE6 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_SYS_SUB_MODE://Sub Mode
        {
            cmdData = [NSString stringWithFormat:@"0x0002 0xB0 0xFD 0xC3 0xA0 0xEB 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_NAV_VCS_ON_OFF:
        {
            /*SetNavInfoStat: 0xEE ,    The command activates/deactivates the navigation VCS’ informational messages logging routine. Only allowed in debug mode
             Value: on/off
             */
            cmdData = [NSString stringWithFormat:@"0x0002 0xB0 0xFD 0xC3 0xA0 0xEE 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_IMGINFO_VCS_ON_OFF:
        {
            /*SetImgInfoStat: 0xEA ,    The command activates/deactivates the navigation VCS’ informational messages logging routine. Only allowed in debug mode
             Value: on/off
             */
            cmdData = [NSString stringWithFormat:@"0x0002 0xB0 0xFD 0xC3 0xA0 0xEA 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_ELEINFO_VCS_ON_OFF:
        {
            /*SetEleInfoStat: 0xEF ,    The command activates/deactivates the navigation VCS’ informational messages logging routine. Only allowed in debug mode 
             Value: on/off
             */
            cmdData = [NSString stringWithFormat:@"0x0002 0xB0 0xFD 0xC3 0xA0 0xEF 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_ACTION_RUN_DIAG_REP:
        {
            /*RunDiagRep: 0xDE ,    This Command initiates the run diagnostic report routine. The file data will be returned in an acknowledgement message in the MSGRESP field. Only allowed in debug mode
             */
            cmdData = [NSString stringWithFormat:@"0x0002 0xB0 0xFD 0xC3 0xA2 0xDE 0x0101040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_ACTION_RUN_DATA_REP:
        {
            /*RunDataRep: 0xDF ,    This Command initiates the run data report routine. The file data will be returned in an acknowledgement message in the MSGRESP field. Only allowed in debug mode
             */
            cmdData = [NSString stringWithFormat:@"0x0002 0xB0 0xFD 0xC3 0xA2 0xDF 0x0101040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_ACTION_OPEN_DEBUG_PORL:
        {
            /*RunDataRep: 0xDF ,    This Command initiates the run data report routine. The file data will be returned in an acknowledgement message in the MSGRESP field. Only allowed in debug mode
             */
            cmdData = [NSString stringWithFormat:@"0x0002 0xB0 0xFD 0xC3 0xA2 0xDF 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_CORE_FAN_SPEED:
        {
            /*OpnDebugPor: 0xE0 ,This command activates the debug portal in the embedded system. It is only allowed in debug mode
             Values: 1. 0x0A
                          2. 0x00-0xFF         
             */
            cmdData = [NSString stringWithFormat:@"0x0009 0xB0 0xFD 0xC1 0xA0 0x1B 0x02%@%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self stringToHex:[params valueForKey:@"2"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_LED_BRIGHTNESS:
        {
        /*SetLedBriht 0x02 The command sets the Smart Helmet’s LED brightness level.
        Values: 0x00 – 0xFF         */
            cmdData = [NSString stringWithFormat:@"0x0009 0xB0 0xFD 0xC1 0xA0 0x02 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_LED_AUTO_ON_OFF:
        {
            /*ActAutoLits 0x09 The command switches the Autonomous lighting system on or off.
             Values: On/Off i.e 0x01 or 0x00         */
            cmdData = [NSString stringWithFormat:@"0x000A 0xB0 0xFD 0xC1 0xA0 0x09 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_LED_BLINK_RATE:
        {
            /*SetBlnkRat 0x03 This command sets the LED blink rate for turn signals, emergency braking and hazard lights.
             Values: 0x01 - Slow 0x02 - Medium 0x03 - Fast 0x04 - Fastest       */
            cmdData = [NSString stringWithFormat:@"0x000B 0xB0 0xFD 0xC1 0xA0 0x03 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_HAZARD_LIGHT_ON_OFF:
        {
            /*ActHazLits: 0x07 This command switches the hazard light function on or off
            Values: 0x00 - OFF, 0x01 - ON       
             */
            cmdData = [NSString stringWithFormat:@"0x000B 0xB0 0xFD 0xC1 0xA0 0x07 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_STANDBY_ON_OFF:
        {
            /*Standby: 0xAB This command puts the Smart Helmet into Power Save Mode
             Values: 0x00 - OFF, 0x01 - ON
             */
            cmdData = [NSString stringWithFormat:@"0x000B 0xB0 0xFD 0xC1 0xA0 0xAB 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_PWR_ON_OFF:
        {
            /*PwrDwn: 0xBB This command turns the Smart Helmet’s power on or off
             Values: 0x00 - OFF, 0x01 - ON
             */
            cmdData = [NSString stringWithFormat:@"0x000B 0xB0 0xFD 0xC1 0xA0 0xBB 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_FRONT_CAM_ON_OFF:
        {
            /*Set_ftcam_act: 0x0C
             VAlues: on/off */
            cmdData = [NSString stringWithFormat:@"0x000C 0xB0 0xFD 0xC2 0xA0 0x0C 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_REAR_CAM_ON_OFF:
        {
            /*Set_rrcam_act:0x0D*/
            cmdData = [NSString stringWithFormat:@"0x000D 0xB0 0xFD 0xC2 0xA0 0x0D 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_FRONT_CAM_MODE:
        {
            /*Set_ftcam_mod::  0x03
             values: 0x01 Stills 0x02 Video*/
            cmdData = [NSString stringWithFormat:@"0x000E 0xB0 0xFD 0xC2 0xA0 0x03 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_FRONT_CAM_RESOLUTION:
        {
            /*Set_rrcam_res: 0x01
             Values: 0x01 VGA 0x02 SVGA 0x03 XGA 0x04 SXGA 0x05 QVGA 0x06 720P 0x07 1080P 0x08 NTSC 0x09 PAL 0x0A User Defined
             P2. P3
             Note: The option for “User Defined” resolution can only be chosen in debug mode and if “User Defined” is the chosen, the command must be accompanied by two additional parameters. P2. Res.Horz P3. Res.Vertical
             */
            if([[params valueForKey:@"1"] integerValue]==10){
                cmdData = [NSString stringWithFormat:@"0x000F 0xB0 0xFD 0xC1 0xA0 0x01 0x02%@%@%lX040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self stringToHex:[params valueForKey:@"2"]],(long)[params valueForKey:@"3"],[self getcurrentHexTimestamp]];
            }else{
                cmdData = [NSString stringWithFormat:@"0x000F 0xB0 0xFD 0xC1 0xA0 0x02 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            }
            break;
        }
        case CMD_SET_FRONT_CAM_FRM_RATE:
        {
            /*Set_ftcam_fps::  0x09
             values: 0x01 15Hz 0x02 30Hz 0x03 60Hz 0x04 120Hz*/
            
             cmdData = [NSString stringWithFormat:@"0x0010 0xB0 0xFD 0xC2 0xA0 0x09 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_REAR_CAM_MODE:
        {
            /*Set_rrcam_mod::  0x04
             values: 0x01 Stills 0x02 Video*/
            cmdData = [NSString stringWithFormat:@"0x0011 0xB0 0xFD 0xC2 0xA0 0x04 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_REAR_CAM_RESOLUTION:
        {
            /*Set_rrcam_res: 0x02
             Values: 0x01 VGA 0x02 SVGA 0x03 XGA 0x04 SXGA 0x05 QVGA 0x06 720P 0x07 1080P 0x08 NTSC 0x09 PAL 0x0A User Defined
             P2. P3
             Note: The option for “User Defined” resolution can only be chosen in debug mode and if “User Defined” is the chosen, the command must be accompanied by two additional parameters. P2. Res.Horz P3. Res.Vertical
             */
            if([[params valueForKey:@"1"] integerValue]==10){
                cmdData = [NSString stringWithFormat:@"0x0012 0xB0 0xFD 0xC1 0xA0 0x02 0x02%@%@%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self stringToHex:[params valueForKey:@"2"]],[self stringToHex:[params valueForKey:@"3"]],[self getcurrentHexTimestamp]];
            }else{
                cmdData = [NSString stringWithFormat:@"0x0012 0xB0 0xFD 0xC1 0xA0 0x02 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            }
            break;
        }
        case CMD_SET_REAR_CAM_FRM_RATE:
        {
            /*Set_rrcam_fps::  0x09
             values: 0x01 15Hz 0x02 30Hz 0x03 60Hz 0x04 120Hz*/
            
            cmdData = [NSString stringWithFormat:@"0x0013 0xB0 0xFD 0xC2 0xA0 0x09 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_VISOR_TRANS:
        {
            /*Set_Visr_Tranc::  0x05
             values: 0x00-0xFF */
            
            cmdData = [NSString stringWithFormat:@"0x0014 0xB0 0xFD 0xC2 0xA0 0x05 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_VISOR_TRANS_AUTO_ON_OFF:
        {
            /*Set_Visr_Atrans: 0x0D ,
             Values: On/Off */
            
            cmdData = [NSString stringWithFormat:@"0x0015 0xB0 0xFD 0xC2 0xA0 0x0D 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_INTELLIGENT_NOISE_CANCELATION_ON_OFF:
        {
            /*EnNosSupp: 0x01 ,switches the Ambient Noise Suppression feature on and off,
             Values: On/Off */
            
            cmdData = [NSString stringWithFormat:@"0x0016 0xB0 0xFD 0xC2 0xA0 0x01 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_LAUD_SPK_ON_OFF:
        {
            /*EnLouSpk: 0x02 ,This command switches the Loud Speaker on and off,
             Values: On/Off */
            
            cmdData = [NSString stringWithFormat:@"0x0017 0xB0 0xFD 0xC2 0xA0 0x02 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_AMBIENT_NOISE_ON_OFF:
        {
            /*EnAmbNosFi: 0x03 ,This command switches the Ambient Noise on and Off,
             Values: On/Off */
            
            cmdData = [NSString stringWithFormat:@"0x0018 0xB0 0xFD 0xC2 0xA0 0x03 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_SIREN_HORN_RECON_ON_OFF:
        {
            /*EnHorReq: 0x04 ,This command switches the siren and car horn recognition feature on and off,
             Values: On/Off */
            
            cmdData = [NSString stringWithFormat:@"0x0019 0xB0 0xFD 0xC2 0xA0 0x04 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_OPEN_CHANNEL_ON_OFF:
        {
            /*OpnChan: 0xAB ,This command allows the user to open a channel to other helmet wearers,
             Values: On/Off */
            
            cmdData = [NSString stringWithFormat:@"0x001A 0xB0 0xFD 0xC2 0xA0 0xAB 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_SEARCH_OPEN_CHANNEL_ON_OFF:
        {
            /*SrchChan: 0xAC ,This command allows the user to search for open channels by other helmet wearers,
             Values: On/Off */
            
            cmdData = [NSString stringWithFormat:@"0x001B 0xB0 0xFD 0xC2 0xA0 0xAC 0x01%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_CONN_USER_TO_ID:
        {
            /*CntUsr: 0xAF ,This command allows the user to connect or disconnect to other users on open channels. Parameter 1 is used to either connect or disconnect to a user. While parameter 2 is a 4 byte field used to identify the user,
             Values: 1: On/Off 
                          2: UserID
             */
            
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC2 0xA0 0xAF 0x02%@%@040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self stringToHex:[params valueForKey:@"2"]],[self getcurrentHexTimestamp]];
            break;
        }
        
        case CMD_GET_CURRENT_SPEED:
        {
            /*GetSpd: 0x11 ,Get current speed of the Smart Helmet,
             Values:
             */
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC0 0xA1 0x11 0x0000040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_GET_CURRENT_DATE:
        {
            /*GetDate: 0x0A ,Get current Date of the Smart Helmet's Navigation VCS,
             Values:
             */
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC0 0xA1 0x1A 0x0000040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_GET_CURRENT_TIME:
        {
            /*GetTime: 0x0B ,Get current Time of the Smart Helmet's Navigation VCS,
             Values:
             */
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC0 0xA1 0x1B 0x0000040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_GET_DIRECTION:
        {
            /*GetDir: 0x0C ,Get current Direction of the Smart Helmet's Navigation VCS,
             Values:
             */
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC0 0xA1 0x1C 0x0000040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_GET_LOCATION:
        {
            /*GetLoc: 0x0D ,Get current Location of the Smart Helmet's Navigation VCS,
             Values:
             */
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC0 0xA1 0x1D 0x0000040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_GET_ESTIMATED_TRAVEL_TIME:
        {
            /*GetETT: 0x0E ,This command retrieves the current Estimated Travel Time. This time value is computed using the current distance to the target waypoint and the current speed,
             Values:
             */
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC0 0xA1 0x1D 0x0000040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_GET_ACCELRATION:
        {
            /*GAccel: 0x01-0x03 ,This command retrieves the vehicles acceleration along Given Axis, and returns the value in ft/s
             Values: ACCELRATION
             */
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC0 0xA1 0x%@ 0x0000040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_GET_ANGULAR_VELOCITY:
        {
            /*GAnguV: 0x04-0x06 ,This command retrieves the vehicles angular velocity along the X axis, and returns the value in degs/s
             Values: ANGULAR_VELOCITY
             */
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC0 0xA1 0x%@ 0x0000040404 0x01 %@",[self stringToHex:[params valueForKey:@"1"]],[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_GET_PITCH_ANGLE:
        {
            /*GPitch: 0x07 ,This command retrieves the vehicle’s pitch angle, and returns the value in degrees
             Values:
             */
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC0 0xA1 0x07 0x0000040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_GET_ROLL_ANGLE:
        {
            /*GRoll: 0x08 ,This command retrieves the vehicle’s roll angle, and returns the value in degrees
             Values:
             */
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC0 0xA1 0x08 0x0000040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_GET_YAW_ANGLE:
        {
            /*GYaw: 0x09,This command retrieves the vehicle’s yaw angle, and returns the value in degree.
             Values:
             */
            cmdData = [NSString stringWithFormat:@"0x001C 0xB0 0xFD 0xC0 0xA1 0x09 0x0000040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_GET_BATTERY_LIFE:
        {
            /*GetBatLif: 0x01 ,This command retrieves the Battery life from the Electrical VCS
             Values:          */
            cmdData = [NSString stringWithFormat:@"0x0009 0xB0 0xFD 0xC1 0xA2 0x01 0x0000040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_ACTION_CAL_TEMP_SNR:
        {
            /*CalTemSnr 0x1A ,Action, This command calibrates the ambient temperature sensor. Only allowed in debug mode
             Values:          */
            cmdData = [NSString stringWithFormat:@"0x0009 0xB0 0xFD 0xC1 0xA2 0x1A 0x0000040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        
        default:
            break;
    }
    cmdData = [cmdData stringByReplacingOccurrencesOfString:@" " withString:@""];
//    cmdData = [NSString stringWithFormat:@"SEND %@",cmdData];
    self.dataToSend = [self dataFromHexString:cmdData];// [cmdData dataUsingEncoding:NSUTF8StringEncoding];
    //    self.commandTextField.text = cmdData;
    self.sendDataIndex = 0;
    
    [self sendDataToMelody];
    
}
-(void)sendDataToMelody{
    
    if (self.sendDataIndex >= self.dataToSend.length) {
        // No data left.  Do nothing
        return;
    }
    BOOL canCallCompletion = NO;
    // Work out how big it should be
    NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
    
    // Can't be longer than 20 bytes
    if (amountToSend > NOTIFY_MTU){
        amountToSend = NOTIFY_MTU;
        canCallCompletion = NO;
    }else{
        canCallCompletion = YES;
    }
    
    // Copy out the data we want
    NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
    BOOL didSend = [self.melodySmart sendData:chunk];
    
    // If it didn't work, drop out and wait for the callback
    if(!didSend){
//        if (str == nil) {
//            str = [NSMutableString stringWithFormat:@"%@\n", @"Not sent"];
//        } else {
//            [str appendFormat:@"%@\n", @"Not sent"];
//        }
//        self.degubInfoTextView.text =str;
        //CallCompletion with Fail status
        if(canCallCompletion && __commandCompletionBlock){
            NSError *err=[NSError errorWithDomain:@"" code:-1001 userInfo:[NSDictionary dictionaryWithObject:@"Command not sent" forKey:NSLocalizedDescriptionKey]];
            __commandCompletionBlock(err);
        }
        return;
    }else{
            //CallCompletion with Fail status
        if(canCallCompletion && __commandCompletionBlock){
            __commandCompletionBlock(nil);
        }
    }
    self.sendDataIndex += amountToSend;
    NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
    NSLog(@"Sent: %@", stringFromData);
//    if (str == nil) {
//        str = [NSMutableString stringWithFormat:@"%@\n", stringFromData];
//    } else {
//        [str appendFormat:@"%@\n", stringFromData];
//    }
//    self.degubInfoTextView.text =str;
    // It did send, so update our index
    
    
}
#pragma mark - Utility -
-(NSString*)getcurrentHexTimestamp{
//    time_t unixTime = (time_t) [[NSDate date] timeIntervalSince1970];
//    NSString * timeInMS = [NSString stringWithFormat:@"%lld", [@(floor([[NSDate date] timeIntervalSince1970] * 1000)) longLongValue]];
//    NSString *hexTimeStamp1 = [NSString stringWithFormat:@"0x%lX",
//                              (unsigned long)unixTime];
//    NSString *hexTimeStamp = [NSString stringWithFormat:@"0x%llX",
//                              (unsigned long long)timeInMS];
//    
//    
//    NSLog(@"%@", timeInMS);
//    NSLog(@"%@", hexTimeStamp);
//    NSLog(@"%@", hexTimeStamp1);
    [dateFormatter setDateFormat:@"HH:mm:ss:SS"];
    
    NSDate *date = [NSDate date];
    
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    NSLog(@"formattedDateString: %@", formattedDateString);
    NSArray *timeArray = [formattedDateString componentsSeparatedByString:@":"];
    NSString *hexTimeStamp = [NSString stringWithFormat:@"0x%02lX%02lX%02lX%02lX",
                              (long)[[timeArray objectAtIndex:0] integerValue],(long)[[timeArray objectAtIndex:1] integerValue],(long)[[timeArray objectAtIndex:2] integerValue],(long)[[timeArray objectAtIndex:3] integerValue]];
    NSLog(@"hexTimeStamp:%@", hexTimeStamp);
    return hexTimeStamp;
}

- (NSData *)dataFromHexString:(NSString*)hexString
{
    NSString * cleanString = [self cleanNonHexCharsFromHexString:hexString];
    if (cleanString == nil) {
        return nil;
    }
    
    NSMutableData *result = [[NSMutableData alloc] init];
    
    int i = 0;
    for (i = 0; i+2 <= cleanString.length; i+=2) {
        NSRange range = NSMakeRange(i, 2);
        NSString* hexStr = [cleanString substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        unsigned char uc = (unsigned char) intValue;
        [result appendBytes:&uc length:1];
    }
    NSData * data = [NSData dataWithData:result];
    return data;
}

/* Clean a hex string by removing spaces and 0x chars.
 . The hex string can be separated by space or not.
 . sample input: 23 3A F1; 233AF1; 0x23 0x3A 0xf1
 */

- (NSString *)cleanNonHexCharsFromHexString:(NSString *)input
{
    if (input == nil) {
        return nil;
    }
    
    NSString * output = [input stringByReplacingOccurrencesOfString:@"0x" withString:@""
                                                            options:NSCaseInsensitiveSearch range:NSMakeRange(0, input.length)];
    NSString * hexChars = @"0123456789abcdefABCDEF";
    NSCharacterSet *hexc = [NSCharacterSet characterSetWithCharactersInString:hexChars];
    NSCharacterSet *invalidHexc = [hexc invertedSet];
    NSString * allHex = [[output componentsSeparatedByCharactersInSet:invalidHexc] componentsJoinedByString:@""];
    return allHex;
}
- (NSString *)stringToHex:(NSString *)stringInput
{
    NSString *hexString = [NSString stringWithFormat:@"%02lX",
                              (long)[stringInput integerValue]];
    return hexString;
}

#pragma mark - Save/get user preference/settings -
//TODO: Secure-NSUserDefaults
- (void) savePreference:(NSString*)value forKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

- (id) getPreference:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id value = [defaults objectForKey:key];
    [defaults synchronize];

    return value?value:@"";
}
@end
