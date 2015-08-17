//
//  ViewController.m
//  SmartCentral
//
//  Created on 24/06/15.
//  Copyright (c) 2015 H. All rights reserved.
//

#import "ViewController.h"
#import "MelodyManager.h"
#import "SmartBLEManager.h"

#define NOTIFY_MTU      20

@interface ViewController () <MelodyManagerDelegate,MelodySmartDelegate,UITextFieldDelegate>{
    MelodyManager *melodyManager;
    NSMutableArray *_objects;
    SmartBLEManager *smartManager;
}
@property (weak, nonatomic) IBOutlet UIView *ledBrightnessView;
@property (weak, nonatomic) IBOutlet UIButton *scanBtn;
@property (strong, nonatomic) IBOutlet UIView *cyclingModeBtn;
@property (weak, nonatomic) IBOutlet UITextView *degubInfoTextView;
@property (weak, nonatomic) IBOutlet UITextField *commandTextField;
@property (strong, nonatomic) MelodySmart *melodySmart;
@property (strong, nonatomic) NSData                    *dataToSend;
@property (nonatomic, readwrite) NSInteger              sendDataIndex;
@property (weak, nonatomic) IBOutlet UILabel *ledBrightnessValue;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.degubInfoTextView.text=@"";
//    bleShield = [[BLE alloc] init];
//    [bleShield controlSetup];
//    bleShield.delegate = self;
    
    //Melody Manager
//    melodyManager = [MelodyManager new];
//    [melodyManager setForService:nil andDataCharacterisitc:nil andPioReportCharacteristic:nil andPioSettingCharacteristic:nil];
//    melodyManager.delegate = self;
    
    
}
- (void)viewDidAppear:(BOOL)animated {
//    [self scan];
}

- (void)viewDidDisappear:(BOOL)animated {
//    [melodyManager stopScanning];
}
- (void)scan {
    //    [self clearObjects];
    //    [melodyManager scanForMelody];
    //    [self performSelector:@selector(stop) withObject:nil afterDelay:3.0];
    //    [NSTimer scheduledTimerWithTimeInterval:(float)3.2 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    [[SmartBLEManager sharedManager] scanSmartHelmet:^(NSError *error) {
        if(error){
            
        }else{
            [[SmartBLEManager sharedManager] connectToDefaultSmartHelmet:^(NSError *error) {
                if(error){
                    //Alert user with error description
                    NSLog(@"error connectToDefaultSmartHelmet::%@",error);
                }else{
                    NSLog(@"connectToDefaultSmartHelmet");
                    [self.scanBtn setTitle:@"Disconnect" forState:UIControlStateNormal];
                    if (str == nil) {
                        str = [NSMutableString stringWithFormat:@"Connected to %@\n",[[SmartBLEManager sharedManager] name]];
                    } else {
                        [str appendFormat:@"Connected to %@\n",[[SmartBLEManager sharedManager] name]];
                    }
                    self.degubInfoTextView.text =str;
                }
            }];
            
        }
    }];
}
- (void)stop{
//    [self.melodySmart disconnect];
    [[SmartBLEManager sharedManager] disconnectSmartHelmet:^(NSError *error) {
        if(error){
            //Alert user with error description
            NSLog(@"error disconnectSmartHelmet::%@",error);
        }else{
            NSLog(@"disconnectSmartHelmet");
            [self.scanBtn setTitle:@"Connect" forState:UIControlStateNormal];
            if (str == nil) {
                str = [NSMutableString stringWithFormat:@"Disconnected \n"];
            } else {
                [str appendFormat:@"Disconnected\n"];
            }
            self.degubInfoTextView.text =str;
        }
    }];
}
- (void)clearObjects {
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (int i = 0; i < _objects.count; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    [_objects removeAllObjects];
}
- (void)insertNewObject:(MelodySmart*)device
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects addObject:device];
}
-(void) connectionTimer:(NSTimer *)timer
{
    self.melodySmart = [_objects count]?_objects[0]:nil;
    
    if(self.melodySmart!=nil)
    {
        self.melodySmart.delegate = self;
        [self.melodySmart connect];
    }else{
        if (str == nil) {
            str = [NSMutableString stringWithFormat:@"No BLE found \n"];
        } else {
            [str appendFormat:@"No BLE found \n"];
        }
        self.degubInfoTextView.text =str;
    }
    
    
//    if(bleShield.peripherals.count > 0)
//    {
//        [bleShield connectPeripheral:[bleShield.peripherals objectAtIndex:0]];
//    }
//    else
//    {
////        [activityIndicator stopAnimating];
//    }
}
#pragma mark - Smart Melody Delegates-
-(void)melodySmart:(MelodySmart *)melody didSendData:(NSError *)error {
    [self sendDataToMelody];
}
- (void)melodySmart:(MelodySmart *)melody didConnectToMelody:(BOOL)result {
    NSLog(@"didConnectToMelody");
    [self.scanBtn setTitle:@"Disconnect" forState:UIControlStateNormal];
    if (str == nil) {
        str = [NSMutableString stringWithFormat:@"Connected to %@\n",self.melodySmart.name];
    } else {
        [str appendFormat:@"Connected to %@\n",self.melodySmart.name];
    }
    self.degubInfoTextView.text =str;
}
-(void)melodySmartDidDisconnectFromMelody:(MelodySmart *)melody {
    NSLog(@"didDisconnectFromMelody");
    [self.scanBtn setTitle:@"Connect" forState:UIControlStateNormal];
    if (str == nil) {
        str = [NSMutableString stringWithFormat:@"Disconnected \n"];
    } else {
        [str appendFormat:@"Disconnected\n"];
    }
    self.degubInfoTextView.text =str;
    
}
-(void)melodySmart:(MelodySmart *)melody didReceiveData:(NSData *)data {
    NSString *temp =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (str == nil) {
        str = [NSMutableString stringWithFormat:@"Recieved: %@\n", temp];
    } else {
        [str appendFormat:@"Recieved: %@\n", temp];
    }
    self.degubInfoTextView.text =str;
    
}
- (void)melodySmart:(MelodySmart *)melody didReceiveCommandReply:(NSData *)data {
    NSString *temp =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (str == nil) {
        str = [NSMutableString stringWithFormat:@"%@\n", temp];
    } else {
        [str appendFormat:@"%@\n", temp];
    }
    self.degubInfoTextView.text =str;
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
//    [_melodySmart sendRemoteCommand:self.commandTextField.text];
    
//    self.dataToSend = [textField.text dataUsingEncoding:NSUTF8StringEncoding];
    self.dataToSend = [self dataFromHexString:textField.text];
//    self.commandTextField.text = cmdData;
    self.sendDataIndex = 0;
    [self.commandTextField resignFirstResponder];
    [self sendDataToMelody];
    
//    NSData* data = [self.commandTextField.text dataUsingEncoding:NSUTF8StringEncoding];
//    if([self.melodySmart sendData:data]){
//        if (str == nil) {
//            str = [NSMutableString stringWithFormat:@"%@\n", self.commandTextField.text];
//        } else {
//            [str appendFormat:@"%@\n", self.commandTextField.text];
//        }
//    }else{
//        if (str == nil) {
//            str = [NSMutableString stringWithFormat:@"Error in sending data\n"];
//        } else {
//            [str appendFormat:@"Error in sending data\n"];
//        }
//    }
//    
//    [self.commandTextField resignFirstResponder];
//    
//    
//    self.degubInfoTextView.text =str;
    return YES;
}


#pragma mark MelodyManager delegate

-(void)melodyManagerDiscoveryDidRefresh:(MelodyManager *)manager {
    //    NSLog(@"discoveryDidRefresh");
    for (NSInteger i = _objects.count; i < [MelodyManager numberOfFoundDevices]; i++) {
        [self insertNewObject:[MelodyManager foundDeviceAtIndex:i]];
    }

}
- (IBAction)ScanForBLE:(id)sender
{
    if([[SmartBLEManager sharedManager] isConnected]){
        [self stop];
    }else{
        [self scan];
    }
//    if(self.melodySmart.isConnected){
//        [self stop];
//    }else{
//        [self scan];
//    }
//    if (bleShield.activePeripheral)
//        if(bleShield.activePeripheral.state == CBPeripheralStateConnected)
//        {
//            [[bleShield CM] cancelPeripheralConnection:[bleShield activePeripheral]];
//            return;
//        }
//    
//    if (bleShield.peripherals)
//        bleShield.peripherals = nil;
//    
//    [bleShield findBLEPeripherals:3];
//    
//    [NSTimer scheduledTimerWithTimeInterval:(float)3.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
//    
}
-(void) bleResponse:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"bleResponse::%@",error);
}
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    
    NSMutableString *bleData = [NSMutableString string ];
    
    for (int i=0; i<length; i++)
        [bleData  appendFormat:@"%02x", data[i]];
    
    [bleData appendFormat:@"\n"];
    
    switch (data[1]) {
        case 0xB0:
        {
            NSLog(@"System msg");
            break;
        }
        case 0xB1:
        {
            NSLog(@"H/W msg");
        }
        case 0xB2:
        {
            NSLog(@"Info msg");
        }
        case 0xB3:
        {
            NSLog(@"Ackn msg");
        }
        default:
            break;
    }
    
    NSData *d = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    NSLog(@"%@", s);

}

NSTimer *rssiTimer;

-(void) readRSSITimer:(NSTimer *)timer
{
    [bleShield readRSSI];
}

- (void) bleDidDisconnect
{
    NSLog(@"bleDidDisconnect");
    [self.scanBtn setTitle:@"Connect" forState:UIControlStateNormal];
    
    
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

-(void) bleDidConnect
{
    [self.scanBtn setTitle:@"Disconnect" forState:UIControlStateNormal];

    
    NSLog(@"bleDidConnect");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(int) decimalIntoHex:(char) number
{
    char ge  =number/10*16;
    char shi =number%10;
    int total =ge +shi;
    return total;
}
//- (IBAction)setCyclingMode:(id)sender{
//    
//    uint8_t send[] = {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
//    /*
//     4.3.1 System Message Format
//     MSGID|MSGTYP|NODEID|VCSID|CMDTYP||CMD||CMDPKT|PRI|TIMSTMP
//     */
//    //    uint8_t send[20];
//
//     NSString *hxStr = [self stringToHex:@"SEND"];
//    send[0] =[hxStr intValue];//[[NSString stringWithFormat:@"%ld", strtoul([@"send" UTF8String],0,16)] intValue];
//    send[1]=[self decimalIntoHex:1];
//    send[2]=0xB0;//MSG Type-0xB0:Sys, 0xB1:HW,0xB2:info, 0xB3:ACT
//    send[3]=0x00;//5 bit, used for H/w msg type: 0xFD
//    send[4]=0xC3;
//    send[5]=0xA0;//CMD type, 0xA0:SET, 0xA1:GET, 0xA2:ACT
//    send[6]=0xA0;//CMD,e,g: SetSysMod:0xEC
//    send[7]=0x01; // 0x01:Cycling
//    send[8]=0x01;//Priority: (0x01)in HEX==1 in Decimal
//    send[9]=[self decimalIntoHex:[[NSDate date] timeIntervalSince1970]];// Get Sencond in since, convert ot HEX
//    send[10] ='\r';//[self decimalIntoHex:[[NSString stringWithFormat:@"%ld", strtoul([@"\r" UTF8String],0,16)] intValue]];
//    NSData *data = [[NSData alloc] initWithBytes:send length:11];
//    if (bleShield.activePeripheral.state == CBPeripheralStateConnected) {
//        [bleShield write:data];
//        NSMutableString *temp = [[NSMutableString alloc] init];
//        for (int i = 0; i < 11; i++) {
//            
////            NSString *strTmp = [NSString stringWithFormat:@"%x",send[i]];
////            if([strTmp length]<2)
////                [temp appendFormat:@" 0x0%x ", send[i]];
////            else
////            if(i==0){
////                NSString *hexStr = [self ];
////            }
//            
//                [temp appendFormat:@" 0x%0.2hhx ", send[i]];
//        }
//        if (str == nil) {
//            str = [NSMutableString stringWithFormat:@"%@\n", temp];
//        } else {
//            [str appendFormat:@"%@\n", temp];
//        }
//        self.degubInfoTextView.text =str;
//    }
//}
- (IBAction)setLED:(UISwitch*)sender{
    
    uint32_t send[] = {0x00001,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x0000000001};
    /*
     4.3.1 System Message Format
     MSGID|MSGTYP|NODEID|VCSID|CMDTYP||CMD||CMDPKT|PRI|TIMSTMP
     */
    //    uint8_t send[20];
    send[0]=[self decimalIntoHex:1];
    send[1]=0xB0;//MSG Type-0xB0:Sys, 0xB1:HW,0xB2:info, 0xB3:ACT
    send[2]=0x00;//5 bit, used for H/w msg type: 0xFD
    send[3]=0xC3;
    send[4]=0xA0;//CMD type, 0xA0:SET, 0xA1:GET, 0xA2:ACT
    send[5]=0xA0;//CMD,e,g: SetSysMod:0xEC
    send[6]=0x01; // 0x01:Cycling
    send[7]=0x01;//Priority: (0x01)in HEX==1 in Decimal
    send[8]=[self decimalIntoHex:[[NSDate date] timeIntervalSince1970]];// Get Sencond in since, convert ot HEX
    NSData *data = [[NSData alloc] initWithBytes:send length:9];
    if (bleShield.activePeripheral.state == CBPeripheralStateConnected) {
        [bleShield write:data];
    }
}
- (NSString *)stringToHex:(NSString *)stringInput
{
    NSUInteger len = [stringInput length];
    unichar *chars = malloc(len * sizeof(unichar));
    [stringInput getCharacters:chars];
    
    NSMutableString *hexString = [[NSMutableString alloc] init];
    
    for(NSUInteger i = 0; i < len; i++ )
    {
        // [hexString [NSString stringWithFormat:@"%02x", chars[i]]]; /*previous input*/
        [hexString appendFormat:@"%02x", chars[i]]; /*EDITED PER COMMENT BELOW*/
    }
    free(chars);
    
    return hexString;
}
- (NSString *) stringFromHex:(NSString *)stringInput
{
    NSMutableData *stringData = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [stringInput length] / 2; i++) {
        byte_chars[0] = [stringInput characterAtIndex:i*2];
        byte_chars[1] = [stringInput characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [stringData appendBytes:&whole_byte length:1];
    }
    
    return [[NSString alloc] initWithData:stringData encoding:NSASCIIStringEncoding];
}
/*
 NAV_VCS: 0xC0
 ELE_VCS: 0xC1
 IMGP_VCS: 0xC2
 SYSC_VSC: 0xC3
 ---
 NDFRMN_1: 0xFD
 ----
 SYS_MSG: 0xB0
 HDWR_MSG: 0xB1
 INFO_MSG: 0xB2
 ￼ACT_MSG: 0xB3
 --------
 SET: 0xA0
 GET: 0xA1
 ACT: 0xA2
 -----
 4.3.1 System Message Format
 Sys msg format: MSGID| MSGTYP|￼NODEID|VCSID|CMDTYP|CMD|CMDPKT|￼￼PRI|TIMSTMP
 
 4.3.2 Hardware Message Format
 H/w meg format: MSGID|MSGTYP| ￼NODEID|HRWDID|CMDTYPE|CMD|CMDPKT|￼PRI|TIMSTMP
 
 4.3.3 Informational Message Format
 MSGID
 MSGTYP
 VCSID
 STATMSG
 PRI
 TIMSTMP
 
 4.3.4 Acknowledge Message Format
 MSGID
 MSGTYPE ￼
 ACKTYP
 ￼￼MSGRESP
 PRI
 TIMSTMP
 
 
 */
- (IBAction)getDateNavVCS:(id)sender {
    /*
    GetDate:0x0A
    Desc: This command retrieves the current date for the Navigation VCS
    Type:  Get

     Sys msg format: MSGID| MSGTYP|￼NODEID|VCSID|CMDTYP|CMD|CMDPKT|￼￼PRI|TIMSTMP
    */
    
    NSString *cmdData = [NSString stringWithFormat:@"SEND 0x0001 0xA1 0xFD 0xC0 0x0A 0x0101040404 0x01%@",[self getcurrentHexTimestamp]];
    self.dataToSend = [cmdData dataUsingEncoding:NSUTF8StringEncoding];
    self.commandTextField.text = cmdData;
    self.sendDataIndex = 0;
    [self.commandTextField resignFirstResponder];
    [self sendDataToMelody];
}
- (IBAction)setHeadLightON:(id)sender {
    /*
     ActHdLit:0x06
     The command sets the Smart Helmet’s Head Lights on/off option.
     Head Lights On/Off
     Type: Set
     */
}
- (IBAction)setHeadLightOFF:(id)sender {
}
- (IBAction)setFrontCamModeVideo:(id)sender {
    /*Set_ftcam_mod: 0x03
     This command sets the front camera’s mode. This command contains a single parameter which identifies the camera mode.
         0x01-Stills, 0x02-Video
    Type: Set
    */
}
- (IBAction)setFrontCamModeStill:(id)sender {
}
//System msgs
- (IBAction)setSysMode:(id)sender {
    UIButton *btn = (UIButton*)sender;
    NSString *cmdData;// = [NSString stringWithFormat:@"SEND 0x0001 0xB0 0xFD 0xC0 0x0A 0x0101040404 0x01%@",[self getcurrentHexTimestamp]];
    switch (btn.tag) {
        case 301://Cycling
        {
//            cmdData = [NSString stringWithFormat:@"0x0001 0xB0 0xFD 0xC3 0x0A 0xEC 0x0101040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_CYCLING_MODE params:nil completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_CYCLING_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_CYCLING_MODE");
                }
            }];
            break;
        }
        case 302://Motosport
        {
//            cmdData = [NSString stringWithFormat:@"0x0002 0xB0 0xFD 0xC3 0x0A 0xEC 0x0102040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_MOTOSPORT_MODE params:nil completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_MOTOSPORT_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_MOTOSPORT_MODE");
                }
            }];
            break;
        }
        case 303://Wintersport
        {
//            cmdData = [NSString stringWithFormat:@"0x0003 0xB0 0xFD 0xC3 0x0A 0xEC 0x0103040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_WINTERSPORT_MODE params:nil completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_WINTERSPORT_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_WINTERSPORT_MODE");
                }
            }];
            break;
        }
        case 304://Longboarding
        {
//            cmdData = [NSString stringWithFormat:@"0x0004 0xB0 0xFD 0xC3 0x0A 0xEC 0x0104040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_LONGBOARDING_MODE params:nil completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_LONGBOARDING_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_LONGBOARDING_MODE");
                }
            }];
            break;
        }
        case 305://Debug
        {
//            cmdData = [NSString stringWithFormat:@"0x0005 0xB0 0xFD 0xC3 0x0A 0xEC 0x0105040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_DEBUG_MODE params:nil completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_DEBUG_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_DEBUG_MODE");
                }
            }];
            break;
        }
        case 401://Stunt
        {
//            cmdData = [NSString stringWithFormat:@"0x0006 0xB0 0xFD 0xC3 0x0A 0xEB 0x0101040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_STUNT_MODE params:nil completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_STUNT_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_STUNT_MODE");
                }
            }];
            break;
        }
        case 402://Race
        {
//            cmdData = [NSString stringWithFormat:@"0x0007 0xB0 0xFD 0xC3 0x0A 0xEB 0x0102040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_RACE_MODE params:nil completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_RACE_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_RACE_MODE");
                }
            }];
            break;
        }
        case 403://Commute
        {
//            cmdData = [NSString stringWithFormat:@"0x0008 0xB0 0xFD 0xC3 0x0A 0xEB 0x0103040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_COMMUTE_MODE params:nil completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_COMMUTE_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_COMMUTE_MODE");
                }
            }];
            break;
        }
        default:
            break;
    }
//    NSData *data = [self dataFromHexString:cmdData];
    
    cmdData = [cmdData stringByReplacingOccurrencesOfString:@" " withString:@""];
//    cmdData = [NSString stringWithFormat:@"SEND "];

//    self.dataToSend = [cmdData dataUsingEncoding:NSUTF8StringEncoding];
//    NSMutableData *cmdDataTmp =(NSMutableData*)self.dataToSend;
//    [cmdDataTmp appendData:data];
//    self.dataToSend = [self dataFromHexString:cmdData];
    
    self.commandTextField.text = cmdData;
    self.sendDataIndex = 0;
    [self.commandTextField resignFirstResponder];
//    [self sendDataToMelody];
}
/* Converts a hex string to bytes.
 Precondition:
 . The hex string can be separated by space or not.
 . the string length without space or 0x, must be even. 2 symbols for one byte/char
 . sample input: 23 3A F1 OR 233AF1, 0x23 0X231f 2B
 */

- (NSData *) dataFromHexString:(NSString*)hexString
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

- (NSString *) cleanNonHexCharsFromHexString:(NSString *)input
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
//- (NSData *)dataFromHexString:(NSString*)string {
//    const char *chars = [string UTF8String];
//    NSInteger i = 0, len = string.length;
//    
//    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
//    char byteChars[3] = {'\0','\0','\0'};
//    unsigned long wholeByte;
//    
//    while (i < len) {
//        byteChars[0] = chars[i++];
//        byteChars[1] = chars[i++];
//        wholeByte = strtoul(byteChars, NULL, 16);
//        [data appendBytes:&wholeByte length:1];
//    }
//    
//    return data;
//}
- (IBAction)clearDebugArea:(id)sender {
    str = nil;
    self.degubInfoTextView.text =@"";
}

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
        if (str == nil) {
            str = [NSMutableString stringWithFormat:@"%@\n", @"Not sent"];
        } else {
            [str appendFormat:@"%@\n", @"Not sent"];
        }
        self.degubInfoTextView.text =str;
        return;
    }
    self.sendDataIndex += amountToSend;
    NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
    NSLog(@"Sent: %@", stringFromData);
    if (str == nil) {
        str = [NSMutableString stringWithFormat:@"%@\n", self.commandTextField.text];
    } else {
        [str appendFormat:@"%@\n", self.commandTextField.text];
    }
    self.degubInfoTextView.text =str;
    // It did send, so update our index
    
    
}
-(NSString*)getcurrentHexTimestamp{
    time_t unixTime = (time_t) [[NSDate date] timeIntervalSince1970];
    NSString *hexTimeStamp = [NSString stringWithFormat:@"0x%lX",
                              (unsigned long)unixTime];
    NSLog(@"%@", hexTimeStamp);
    return hexTimeStamp;
}

- (IBAction)ledBrightnessChanged:(id)sender {
    UISlider *slider = (UISlider*)sender;
    self.ledBrightnessValue.text =[NSString stringWithFormat:@"%ld",(long)slider.value];
    [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_LED_BRIGHTNESS params:@{@"1":self.ledBrightnessValue.text} completion:^(NSError *error) {
        if(error){
            NSLog(@"CMD_SET_LED_BRIGHTNESS Fail");
        }else{
            NSLog(@"CMD_SET_LED_BRIGHTNESS");
        }
    }];
}

@end
