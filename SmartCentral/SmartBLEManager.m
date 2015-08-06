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
        NSError *err = [NSError errorWithDomain:@"" code:-1001 userInfo:[NSDictionary dictionaryWithObject:@"No SmartHelmet found. Check if SmartHelmet is Power ON and search again." forKey:NSLocalizedDescriptionKey]];
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
- (void) sendCommandToHelmet:(CMD_TYPE)cmd completion:(void(^) (NSError *error))cmdCompletion
{
    __commandCompletionBlock = cmdCompletion;
    if(!_isPowerOn){
        NSError *err = [NSError errorWithDomain:@"" code:-1001 userInfo:[NSDictionary dictionaryWithObject:@"Check if SmartHelmet is Power ON and try again." forKey:NSLocalizedDescriptionKey]];
        __commandCompletionBlock(err);
        return;
    }
    NSString *cmdData;
    switch (cmd) {
        case CMD_SET_CYCLING_MODE://Cycling
        {
            cmdData = [NSString stringWithFormat:@"0x0001 0xB0 0xFD 0xC3 0x0A 0xEC 0x0101040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_MOTOSPORT_MODE://Motosport
        {
            cmdData = [NSString stringWithFormat:@"0x0002 0xB0 0xFD 0xC3 0x0A 0xEC 0x0102040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_WINTERSPORT_MODE://Wintersport
        {
            cmdData = [NSString stringWithFormat:@"0x0003 0xB0 0xFD 0xC3 0x0A 0xEC 0x0103040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_LONGBOARDING_MODE://Longboarding
        {
            cmdData = [NSString stringWithFormat:@"0x0004 0xB0 0xFD 0xC3 0x0A 0xEC 0x0104040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_DEBUG_MODE://Debug
        {
            cmdData = [NSString stringWithFormat:@"0x0005 0xB0 0xFD 0xC3 0x0A 0xEC 0x0105040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_STUNT_MODE://Stunt
        {
            cmdData = [NSString stringWithFormat:@"0x0006 0xB0 0xFD 0xC3 0x0A 0xEB 0x0101040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_RACE_MODE://Race
        {
            cmdData = [NSString stringWithFormat:@"0x0007 0xB0 0xFD 0xC3 0x0A 0xEB 0x0102040404 0x01 %@",[self getcurrentHexTimestamp]];
            break;
        }
        case CMD_SET_COMMUTE_MODE://Commute
        {
            cmdData = [NSString stringWithFormat:@"0x0008 0xB0 0xFD 0xC3 0x0A 0xEB 0x0103040404 0x01 %@",[self getcurrentHexTimestamp]];
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
    time_t unixTime = (time_t) [[NSDate date] timeIntervalSince1970];
    NSString *hexTimeStamp = [NSString stringWithFormat:@"0x%lX",
                              (unsigned long)unixTime];
    NSLog(@"%@", hexTimeStamp);
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
@end
