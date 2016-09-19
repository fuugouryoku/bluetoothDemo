//
//  ViewController.m
//  bluetoothDemo
//
//  Created by on 16/9/19.
//  Copyright © 2016年 fuugouryoku. All rights reserved.
//

#import "ViewController.h"
#import "TableViewCell.h"
#import <CoreBluetooth/CoreBluetooth.h>



@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
//将iphone设备作为中心角色连接其他外设
@property (nonatomic,strong)CBCentralManager *centralManager;
@property (nonatomic,strong)NSMutableArray *periphralDeviceArray;
@property (nonatomic,strong)CBPeripheral *conn;
@end

@implementation ViewController


-(NSMutableArray *)periphralDeviceArray{
    if (!_periphralDeviceArray) {
        _periphralDeviceArray = [NSMutableArray array];
    }
    return _periphralDeviceArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //1.创建中心角色
   
    self.centralManager  = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue() options:@{CBCentralManagerOptionShowPowerAlertKey:@YES}];
    
   
}

#pragma -CBCentralManagerDelegate
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    /*CBCentralManagerStateUnknown,未知
    CBCentralManagerStateResetting,正在重置
    CBCentralManagerStateUnsupported,不支持
    CBCentralManagerStateUnauthorized,未授权
    CBCentralManagerStatePoweredOff,蓝牙关闭
    CBCentralManagerStatePoweredOn,蓝牙开启*/
    switch (central.state) {
        case CBCentralManagerStateUnknown: {
            NSLog(@"未知");
            break;
        }
        case CBCentralManagerStateResetting: {
            NSLog(@"正在重置");
            break;
        }
        case CBCentralManagerStateUnsupported: {
            NSLog(@"不支持");
            break;
        }
        case CBCentralManagerStateUnauthorized: {
            NSLog(@"未授权");
            break;
        }
        case CBCentralManagerStatePoweredOff: {
            NSLog(@"蓝牙关闭");
            break;
        }
        case CBCentralManagerStatePoweredOn: {
            NSLog(@"蓝牙开启");
            [self scanPerphal];
            break;
        }
    }
    
    
}

#pragma -扫描外设
-(void)scanPerphal
{
    //可以指定扫描的服务
    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
}


-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
        NSLog(@"名称：%@,广告包：%@,信号强度：%@",peripheral.name,advertisementData,RSSI);
   __block BOOL isFound = NO;
    [self.periphralDeviceArray enumerateObjectsUsingBlock:^(CBPeripheral *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
            [self.periphralDeviceArray removeObject:obj];
            [self.periphralDeviceArray addObject:peripheral];
            isFound = YES;
            *stop = YES;
        }
        
    }];
    
    if (!isFound) {
        [self.periphralDeviceArray addObject:peripheral];
    }
    [self.tableView reloadData];
}
#pragma -连接成功外设回调
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    self.conn = peripheral;
    self.conn.delegate = self;
    //开始扫描外设
    [self.conn discoverServices:nil];
}

#pragma -CBPeripheralDelegate
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{  if(error){
    NSLog(@"%s error:%@",__func__,error.localizedDescription);
      return;
    }
    //循环遍历外设的服务，发现外设的服务特征
    for (CBService *service in peripheral.services) {
        //扫描服务中的特征
        [peripheral discoverCharacteristics:nil forService:service];
    }
    
}
//外设已经发现服务中的特征的回调
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if(error){
        NSLog(@"%s error:%@",__func__,error.localizedDescription);
        return;
    }
    //遍历服务中的特征
    for (CBCharacteristic *characteristic in service.characteristics) {
        //发现特征中的描述
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
        
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error){
        NSLog(@"%s error:%@",__func__,error.localizedDescription);
        return;
    }
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        NSLog(@"%@",descriptor.value);
    }
    
    
    
}

#pragma -tableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.periphralDeviceArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CELL" forIndexPath:indexPath];
    CBPeripheral *peripheral = self.periphralDeviceArray[indexPath.item];
    cell.textLabel.text = peripheral.identifier.UUIDString;
    cell.detailTextLabel.text = peripheral.RSSI.stringValue;
    
    return cell;
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.centralManager stopScan];
    self.conn = self.periphralDeviceArray[indexPath.item];
    [self.centralManager connectPeripheral:self.conn options:nil];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
