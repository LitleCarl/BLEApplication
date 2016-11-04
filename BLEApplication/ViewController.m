//
//  ViewController.m
//  BLEApplication
//
//  Created by Apple on 16/11/2.
//  Copyright © 2016年 Tsao. All rights reserved.
//

#import "ViewController.h"
#import "NFCViewController.h"
#import "BabyBluetooth.h"
#import <ReactiveCocoa.h>
#import <MBProgressHUD.h>

@interface ViewController () <UITableViewDataSource, UITableViewDelegate> {
    BabyBluetooth *baby;
}

@property (nonatomic, strong) NSMutableArray *pheripherals;
@property (weak, nonatomic) IBOutlet UITableView *mainTableView;

@end

@implementation ViewController

//定义变量


-(void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"扫描外设";
    
    self.pheripherals = [NSMutableArray new];
    
    //初始化BabyBluetooth 蓝牙库
    baby = [BabyBluetooth shareBabyBluetooth];
    //设置蓝牙委托
    [self babyDelegate];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"重新扫描" style:UIBarButtonItemStylePlain target:self action:@selector(rescan)];
    self.navigationItem.rightBarButtonItem = item;
}

// 重新扫描
- (void)rescan {
    if (baby.centralManager.state == CBCentralManagerStatePoweredOn) {
        self.pheripherals = [NSMutableArray new];
        [self.mainTableView reloadData];
        [baby cancelAllPeripheralsConnection];
        baby.scanForPeripherals().begin().stop(10);
    }
}

//设置蓝牙委托
-(void)babyDelegate{
    __weak typeof (self) weakSelf = self;
    //设置扫描到设备的委托
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        
        NSMutableArray *currentIDs = [NSMutableArray new];
        [weakSelf.pheripherals enumerateObjectsUsingBlock:^(CBPeripheral * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [currentIDs addObject:obj.identifier];
        }];
        
        if (![currentIDs containsObject:peripheral.identifier]) {
            [weakSelf.pheripherals addObject:peripheral];
        }
        
        [weakSelf.mainTableView reloadData];
        
        NSLog(@"搜索到了设备:%@",peripheral.name);
    }];
    
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBCentralManagerStatePoweredOn) {
            //设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态
            baby.scanForPeripherals().begin().stop(10);
        }
    }];
    
    //过滤器
    //设置查找设备的过滤器
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        if (peripheralName.length >1) {
            return YES;
        }
        return NO;
    }];
    
    [baby setFilterOnConnectToPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        return YES;
    }];
    
    //设置设备连接成功的委托,同一个baby对象，使用不同的channel切换委托回调
    [baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        NSLog(@"设备：%@--连接成功", peripheral.name);
        
        [baby cancelScan];
        
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
        
        NFCViewController *controller = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NFCController"];
        
        controller.peripheral = peripheral;
        controller.title = peripheral.name;
        [weakSelf.navigationController pushViewController:controller animated:YES];
    }];
    
    //设置设备连接失败的委托
    [baby setBlockOnFailToConnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--连接失败", peripheral.name);
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];

    }];
    
    //设置设备断开连接的委托
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--断开连接", peripheral.name);
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];

    }];
}

#pragma mark - UITableViewDataSource/UITableViewDelegate -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    baby.having([self.pheripherals objectAtIndex:indexPath.row]).then.connectToPeripherals().discoverServices().discoverCharacteristics().begin();
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.pheripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"device_name_cell" forIndexPath:indexPath];
    CBPeripheral *peripheral = [self.pheripherals objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", peripheral.name];
    
    return cell;
}

@end
