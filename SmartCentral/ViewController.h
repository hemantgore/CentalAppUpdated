//
//  ViewController.h
//  SmartCentral
//
//  Created on 24/06/15.
//  Copyright (c) 2015 H. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface ViewController : UIViewController<BLEDelegate>
{
    BLE *bleShield;
    NSMutableString *str;
}

@end

