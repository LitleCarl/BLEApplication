//
//  NFCViewController.h
//  BLEApplication
//
//  Created by Apple on 16/11/2.
//  Copyright © 2016年 Tsao. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CBPeripheral;

@interface NFCViewController : UIViewController
@property (nonatomic) CBPeripheral *peripheral;
@end
