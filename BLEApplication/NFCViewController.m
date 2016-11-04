//
//  NFCViewController.m
//  BLEApplication
//
//  Created by Apple on 16/11/2.
//  Copyright © 2016年 Tsao. All rights reserved.
//

#import "NFCViewController.h"
#import "BabyBluetooth.h"
#import <ReactiveCocoa.h>
#import <MBProgressHUD.h>
#import "NSString+componentsByLength.h"
@interface NFCViewController (){
    BabyBluetooth *baby;
}
@property (nonatomic, assign) BOOL loaded;

@property (weak, nonatomic) IBOutlet UITextField *writeTextfield;
@property (weak, nonatomic) IBOutlet UITextView *writeTextView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UITextField *notifyTextfield;
@property (weak, nonatomic) IBOutlet UITextView *notifyTextView;

// Write char
@property (nonatomic, strong) CBCharacteristic *writeChar;

// Notify char
@property (nonatomic, strong) CBCharacteristic *notifyChar;
@end

@implementation NFCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpTrigger];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(clearNotify)];
    self.navigationItem.rightBarButtonItem = item;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard{
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

- (void)clearNotify{
    self.notifyTextView.text = @"";
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // 取消监听，断开连接
    if (self.peripheral && self.notifyChar) {
        [baby cancelNotify:self.peripheral characteristic:self.notifyChar];
    }
    if (self.peripheral) {
        [baby cancelPeripheralConnection:self.peripheral];
    }
}

- (void)setUpTrigger {
    baby = [BabyBluetooth shareBabyBluetooth];
    
    __weak typeof(self) weakSelf = self;

    //设置发现设service的Characteristics的委托
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        
        if (weakSelf.loaded == false && peripheral == weakSelf.peripheral && [service.UUID.UUIDString isEqualToString:@"549A2E16-3F21-42D7-93F4-BEF86B297E30"]) {
            weakSelf.loaded = true;
            [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.UUID.UUIDString hasPrefix:@"AFA54F4C"]) {
                    weakSelf.notifyChar = obj;
                    [baby notify:weakSelf.peripheral characteristic:self.notifyChar block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
                        // 接收到新的Notify
                        weakSelf.notifyTextView.text = [NSString stringWithFormat:@"%@\n%@", self.notifyTextView.text, [[NSString alloc] initWithData:characteristics.value encoding:NSUTF8StringEncoding]];
                        [weakSelf.notifyTextView setNeedsLayout];
                        [weakSelf.notifyTextView layoutIfNeeded];
                          if(weakSelf.notifyTextView.text.length > 0 ) {
                            NSRange bottom = NSMakeRange(weakSelf.notifyTextView.text.length -1, 1);
                            [weakSelf.notifyTextView scrollRangeToVisible:bottom];
                        }
                    }];
                }
                else if ([obj.UUID.UUIDString hasPrefix:@"85BD1FAB"]) {
                    weakSelf.writeChar = obj;
                }
            }];
        }
    }];
    
    [[[self.sendButton rac_signalForControlEvents:UIControlEventTouchUpInside] filter:^BOOL(id value) {

        return self.writeTextView.text.length > 0 && self.writeChar;
    }] subscribeNext:^(id x) {
        [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];

        NSArray *subStrs = [self.writeTextView.text componentSaparetedByLength:15];
        [subStrs enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *data = [NSString stringWithFormat:@"%@%@", obj, (idx + 1) == subStrs.count ? @"" : @"_"];
            [self.peripheral writeValue:[data dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.writeChar type:CBCharacteristicWriteWithResponse];
        }];
        
    }];
    
    [baby setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
       // 发送成功
    }];
    
    [baby setBlockOnDidUpdateNotificationStateForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        
    }];
}

@end
