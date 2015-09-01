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

@interface ViewController () <MelodyManagerDelegate,MelodySmartDelegate,UITextFieldDelegate,SmartHelmetDataDelegate>{
    MelodyManager *melodyManager;
    NSMutableArray *_objects;
    SmartBLEManager *smartManager;
    BOOL _rowData;
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
- (void)dataReceivedFromPeripheral:(NSData *)data{
    NSString* temp = nil;
    if(!_rowData)
        temp = data?[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]:@"";
else
        temp = [[NSString alloc] initWithFormat:@"%@", data];

    if (str == nil) {
        str = [NSMutableString stringWithFormat:@"ACK: %@\n",temp];
    } else {
        [str appendFormat:@"ACK: %@\n",temp];
    }
    self.degubInfoTextView.text =str;
}
- (void)scan {
    //    [self clearObjects];
    //    [melodyManager scanForMelody];
    //    [self performSelector:@selector(stop) withObject:nil afterDelay:3.0];
    //    [NSTimer scheduledTimerWithTimeInterval:(float)3.2 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
    smartManager = [SmartBLEManager sharedManager];
    smartManager.delegate = self;
    
    [smartManager scanSmartHelmet:^(NSError *error) {
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
- (void)updateDebugInfo:(NSError*)error{
    if(error){
        
        if (str == nil) {
            str = [NSMutableString stringWithFormat:@"%@\n", [error localizedDescription]];
        }else{
            [str appendFormat:@"%@\n", [error localizedDescription]];
        }
        
    }else{
        
        if (str == nil) {
            str = [NSMutableString stringWithFormat:@"Sent: %@\n", [[SmartBLEManager sharedManager] lastSentCommand]];
        }else{
            [str appendFormat:@"Sent: %@\n", [[SmartBLEManager sharedManager] lastSentCommand]];
        }
    }
    self.degubInfoTextView.text =str;
}
//System msgs
- (IBAction)setSysMode:(id)sender {
    UIButton *btn = (UIButton*)sender;
    NSString *cmdData;// = [NSString stringWithFormat:@"SEND 0x0001 0xB0 0xFD 0xC0 0x0A 0x0101040404 0x01%@",[self getcurrentHexTimestamp]];
    switch (btn.tag) {
        case 301://Cycling
        {
//            cmdData = [NSString stringWithFormat:@"0x0001 0xB0 0xFD 0xC3 0x0A 0xEC 0x0101040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_SYS_MAIN_MODE params:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d",CYCLING] forKey:@"1"] completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_CYCLING_MODE Fail");
                    
                }else{
                    NSLog(@"CMD_SET_CYCLING_MODE");
                }
                [self updateDebugInfo:error];
            }];
            break;
        }
        case 302://Motosport
        {
//            cmdData = [NSString stringWithFormat:@"0x0002 0xB0 0xFD 0xC3 0x0A 0xEC 0x0102040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_SYS_MAIN_MODE params:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d",MOTOSPORT]forKey:@"1"] completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_MOTOSPORT_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_MOTOSPORT_MODE");
                }
                [self updateDebugInfo:error];
            }];
            break;
        }
        case 303://Wintersport
        {
//            cmdData = [NSString stringWithFormat:@"0x0003 0xB0 0xFD 0xC3 0x0A 0xEC 0x0103040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_SYS_MAIN_MODE params:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d",WINTERSPORT] forKey:@"1"] completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_WINTERSPORT_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_WINTERSPORT_MODE");
                }
                [self updateDebugInfo:error];
            }];
            break;
        }
        case 304://Longboarding
        {
//            cmdData = [NSString stringWithFormat:@"0x0004 0xB0 0xFD 0xC3 0x0A 0xEC 0x0104040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_SYS_MAIN_MODE params:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d",LONGBOARDING] forKey:@"1"] completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_LONGBOARDING_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_LONGBOARDING_MODE");
                }
                [self updateDebugInfo:error];
            }];
            break;
        }
        case 305://Debug
        {
//            cmdData = [NSString stringWithFormat:@"0x0005 0xB0 0xFD 0xC3 0x0A 0xEC 0x0105040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_SYS_MAIN_MODE params:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d",DEBUG_MODE] forKey:@"1"] completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_DEBUG_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_DEBUG_MODE");
                }
                [self updateDebugInfo:error];
            }];
            break;
        }
        case 401://Stunt
        {
//            cmdData = [NSString stringWithFormat:@"0x0006 0xB0 0xFD 0xC3 0x0A 0xEB 0x0101040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_SYS_SUB_MODE params:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d",STUNT] forKey:@"1"] completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_STUNT_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_STUNT_MODE");
                }
                [self updateDebugInfo:error];
            }];
            break;
        }
        case 402://Race
        {
//            cmdData = [NSString stringWithFormat:@"0x0007 0xB0 0xFD 0xC3 0x0A 0xEB 0x0102040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_SYS_SUB_MODE params:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d",RACE] forKey:@"1"] completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_RACE_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_RACE_MODE");
                }
                [self updateDebugInfo:error];
            }];
            break;
        }
        case 403://Commute
        {
//            cmdData = [NSString stringWithFormat:@"0x0008 0xB0 0xFD 0xC3 0x0A 0xEB 0x0103040404 0x01 %@",[self getcurrentHexTimestamp]];
            [[SmartBLEManager sharedManager] sendCommandToHelmet:CMD_SET_SYS_SUB_MODE params:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d",COMMUTE] forKey:@"1"] completion:^(NSError *error) {
                if(error){
                    NSLog(@"CMD_SET_COMMUTE_MODE Fail");
                }else{
                    NSLog(@"CMD_SET_COMMUTE_MODE");
                }
                [self updateDebugInfo:error];
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
        [self updateDebugInfo:error];
    }];
}
- (IBAction)rawDataMode:(id)sender {
    UISwitch *rawD = (UISwitch*)sender;
    _rowData = rawD.isOn;
}

@end
