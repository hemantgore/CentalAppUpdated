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

@interface SmartBLEManager ()<MelodyManagerDelegate,MelodySmartDelegate>
{
     MelodyManager *melodyManager;
     NSMutableArray *_objects;
}
@property (strong, nonatomic) MelodySmart *melodySmart;
@property (strong, nonatomic) NSData                    *dataToSend;
@property (nonatomic, readwrite) NSInteger              sendDataIndex;

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

- (id)init {
    if (self = [super init]) {
        //Melody Manager
        melodyManager = [MelodyManager new];
        [melodyManager setForService:nil andDataCharacterisitc:nil andPioReportCharacteristic:nil andPioSettingCharacteristic:nil];
        melodyManager.delegate = self;
    }
    return self;
}
- (void)scanSmartHelmet:(void(^)(NSError *error)) scanBlock {
    __scanBlock = scanBlock;
    [self clearObjects];
    [melodyManager scanForMelody];
    [self performSelector:@selector(stop) withObject:nil afterDelay:CONNECTION_TIMEOUT];
    [NSTimer scheduledTimerWithTimeInterval:CONNECTION_TIMEOUT+0.2 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
}
- (void)connectToDefaultSmartHelmet:(void(^)(NSError *error))connectBlock {
    __connectBlock = connectBlock;
    
   self.melodySmart.delegate = self;
    [self.melodySmart connect];
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
        __scanBlock(nil);
        
    }else{
        
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

    if(__connectBlock){
        NSError *err = result ? [NSError errorWithDomain:@"" code:-1001 userInfo:[NSDictionary dictionaryWithObject:@"Not able to connect to Smart Helmet" forKey:NSLocalizedDescriptionKey]] : nil;
        __connectBlock(err);
    }
//    if (str == nil) {
//        str = [NSMutableString stringWithFormat:@"Connected to %@\n",self.melodySmart.name];
//    } else {
//        [str appendFormat:@"Connected to %@\n",self.melodySmart.name];
//    }
//    self.degubInfoTextView.text =str;
}
-(void)melodySmartDidDisconnectFromMelody:(MelodySmart *)melody {
    NSLog(@"didDisconnectFromMelody");
    if(__disconnectBlock){
        NSError *err = melody.isConnected ? [NSError errorWithDomain:@"" code:-1001 userInfo:[NSDictionary dictionaryWithObject:@"Not able to disconnect from Smart Helmet" forKey:NSLocalizedDescriptionKey]] : nil;
        __disconnectBlock(err);
    }
//    if (str == nil) {
//        str = [NSMutableString stringWithFormat:@"Disconnected \n"];
//    } else {
//        [str appendFormat:@"Disconnected\n"];
//    }
//    self.degubInfoTextView.text =str;
    
}
-(void)melodySmart:(MelodySmart *)melody didReceiveData:(NSData *)data {
    NSString *temp =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"didReceivedData::%@",temp);
//    if (str == nil) {
//        str = [NSMutableString stringWithFormat:@"Recieved: %@\n", temp];
//    } else {
//        [str appendFormat:@"Recieved: %@\n", temp];
//    }
//    self.degubInfoTextView.text =str;
    
}
- (void)melodySmart:(MelodySmart *)melody didReceiveCommandReply:(NSData *)data {
    NSString *temp =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"didReceiveCommandReply::%@",temp);
//    if (str == nil) {
//        str = [NSMutableString stringWithFormat:@"%@\n", temp];
//    } else {
//        [str appendFormat:@"%@\n", temp];
//    }
//    self.degubInfoTextView.text =str;
}

#pragma mark MelodyManager delegate

-(void)melodyManagerDiscoveryDidRefresh:(MelodyManager *)manager {
    //    NSLog(@"discoveryDidRefresh");
    for (NSInteger i = _objects.count; i < [MelodyManager numberOfFoundDevices]; i++) {
        [self insertNewObject:[MelodyManager foundDeviceAtIndex:i]];
    }
    
}
- (void) melodyManagerDiscoveryStatePoweredOff:(MelodyManager*)manager{
    
}
- (void) melodyManagerConnectedListChanged{
    
}
#pragma mark - Send data to BLE -
-(void)sendDataToMelody{
    
    if (self.sendDataIndex >= self.dataToSend.length) {
        // No data left.  Do nothing
        return;
    }
    
    // Work out how big it should be
    NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
    
    // Can't be longer than 20 bytes
    if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
    
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
        return;
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
-(NSString*)getcurrentHexTimestamp{
    time_t unixTime = (time_t) [[NSDate date] timeIntervalSince1970];
    NSString *hexTimeStamp = [NSString stringWithFormat:@"0x%lX",
                              (unsigned long)unixTime];
    NSLog(@"%@", hexTimeStamp);
    return hexTimeStamp;
}
@end
