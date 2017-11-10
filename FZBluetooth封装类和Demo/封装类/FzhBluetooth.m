//
//  FzhBluetooth.m
//  BlueTooth
//
//  Created by 付正 on 2017/9/14.
//  Copyright © 2017年 BFMobile. All rights reserved.
//

#import "FzhBluetooth.h"
#import "FzhString.h"

@implementation FzhBluetooth
{
    CBCentralManager *fzhCentralManager;
    CBPeripheral *fzhPeripheral;
    CBCharacteristic *fzgCharacteristic;
    
    NSString *prefixString; //记录设备名称包含字符串
    NSString *resultStr;    //记录应答数据
    
    NSInteger   writeCount;   /**< 写入次数 */
    NSInteger   responseCount; /**< 返回次数 */
}

+(instancetype)shareInstance
{
    static FzhBluetooth *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[FzhBluetooth alloc]init];
    });
    return share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        fzhCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        resultStr = @"";
        self.serviceArr = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)dealloc
{
    [self stopScan];
    fzhCentralManager.delegate = nil;
    fzhPeripheral.delegate = nil;
}

#pragma mark --- 系统当前蓝牙的状态
- (void)returnBluetoothStateWithBlock:(FZStateUpdateBlock)stateBlock
{
    self.stateUpdateBlock = stateBlock;
}

//检查App的设备BLE是否可用 （ensure that Bluetooth low energy is supported and available to use on the central device）
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (_stateUpdateBlock) {
        _stateUpdateBlock(central.state);
    }
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
            //discover what peripheral devices are available for your app to connect to
            //第一个参数为CBUUID的数组，需要搜索特点服务的蓝牙设备，只要每搜索到一个符合条件的蓝牙设备都会调用didDiscoverPeripheral代理方法
            [fzhCentralManager scanForPeripheralsWithServices:nil options:nil];
            break;
        default:
            NSLog(@"Central Manager did change state");
            break;
    }
}

#pragma mark --- 搜索蓝牙设备
- (void)scanForPeripheralsWithPrefixName:(NSString *)nameStr discoverPeripheral:(FZDiscoverPeripheralBlock)discoverBlock;
{
    prefixString = nameStr;
    [self start];
    self.discoverPeripheralBlcok = discoverBlock;
}

- (void)start
{
    [fzhCentralManager scanForPeripheralsWithServices:nil options:nil];
}

#pragma mark --- 连接蓝牙
- (void)connectPeripheral:(CBPeripheral *)peripheral
            completeBlock:(FZConnectSuccessBlock)completionBlock
                failBlock:(FZConnectFailBlock)failBlock
{
    fzhPeripheral = peripheral;
    
    //连接设备
    [fzhCentralManager connectPeripheral:peripheral options:nil];
    //4.设置代理
//    fzhPeripheralManager.delegate = self;
    
    self.connectSuccessBlock = completionBlock;
    self.connectFailBlock = failBlock;
    
}

//搜索蓝牙代理方法
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    //
    NSString *perName = [[NSUserDefaults standardUserDefaults] objectForKey:@"conPeripheral"];
    NSString *setOrDelNum = [[NSUserDefaults standardUserDefaults] objectForKey:@"setOrDel"];
    
    if (_discoverPeripheralBlcok) {
        if (prefixString.length > 0) {
            if ([peripheral.name hasPrefix:prefixString]) {
                _discoverPeripheralBlcok(central,peripheral,advertisementData,RSSI);
            }
        } else {
            _discoverPeripheralBlcok(central,peripheral,advertisementData,RSSI);
        }
        [self start];
    }
    if ([setOrDelNum isEqualToString:@"0"]) {
        //有自动重连的设备
        if ([peripheral.name isEqualToString:perName]) {
            [fzhCentralManager connectPeripheral:peripheral options:nil];
        }
        return;
    }
}

// 蓝牙设备连接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [fzhCentralManager stopScan];
    //Before you begin interacting with the peripheral, you should set the peripheral’s delegate to ensure that it receives the appropriate callbacks（设置代理）
    [fzhPeripheral setDelegate:self];
    //discover all of the services that a peripheral offers,搜索服务,回调didDiscoverServices
    [fzhPeripheral discoverServices:nil];
    
    //延时操作
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_connectSuccessBlock) {
            _connectSuccessBlock(peripheral,nil,self.writeCharacteristic);
        } else {
            //返回连接成功
            if ([self.delegate respondsToSelector:@selector(connectionWithPerpheral:)]) {
                [self.delegate connectionWithPerpheral:peripheral];
            }
        }
    });
}

// 连接失败，就会得到回调：
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (_connectFailBlock) {
        _connectFailBlock(peripheral,error);
    }
}

#pragma mark --- 获取外设的信号强度
- (void)readRSSICompletionBlock:(FZGetRSSIBlock)getRSSIBlock
{
    self.getRSSIBlock = getRSSIBlock;
    [fzhPeripheral readRSSI];
}

#pragma mark --- 写入数据
- (void)writeValue:(NSString *)dataStr forCharacteristic:(CBCharacteristic *)characteristic completionBlock:(FZWriteToCharacteristicBlock)completionBlock  returnBlock:(FZEquipmentReturnBlock)equipmentBlock
{
    writeCount = 0;
    responseCount = 0;
    
    NSMutableArray *sendArr = [[NSMutableArray alloc]init];
    if (dataStr.length > 40) {
        int count = dataStr.length / 40 + 1;
        for (int i = 0; i < count; i ++) {
            if (i < count-1) {
                [sendArr addObject:[dataStr substringWithRange:NSMakeRange(0+i*40, 40)]];
            } else {
                [sendArr addObject:[dataStr substringFromIndex:i*40]];
            }
        }
        for (NSString *sendStr in sendArr) {
            NSData *data = [[FzhString sharedInstance] convertHexStrToData:sendStr];
            _writeToCharacteristicBlock = completionBlock;
            _equipmentReturnBlock = equipmentBlock;
            if (fzhPeripheral == nil) {
                NSString *desc = NSLocalizedString(@"Not connected devices", @"");
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
                NSError *error = [NSError errorWithDomain:@"com.okey.wearkit.ErrorDomain"
                                                     code:-101
                                                 userInfo:userInfo];
                _writeToCharacteristicBlock(nil,error);
                return;
            }
            [fzhPeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            writeCount ++;
        }
        return;
    }
    NSData *data = [[FzhString sharedInstance] convertHexStrToData:dataStr];
    _writeToCharacteristicBlock = completionBlock;
    _equipmentReturnBlock = equipmentBlock;
    if (fzhPeripheral == nil) {
        NSString *desc = NSLocalizedString(@"Not connected devices", @"");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
        NSError *error = [NSError errorWithDomain:@"com.okey.wearkit.ErrorDomain"
                                             code:-101
                                         userInfo:userInfo];
        _writeToCharacteristicBlock(nil,error);
        return;
    }
    [fzhPeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    writeCount ++;
}

//写数据后回调
- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    resultStr = @"";
    if (!_writeToCharacteristicBlock) {
        return;
    }
    responseCount ++;
    if (writeCount != responseCount) {
        return;
    }
    _writeToCharacteristicBlock(characteristic,error);
}

#pragma mark --- 停止扫描
- (void)stopScan
{
    [fzhCentralManager stopScan];
}

#pragma mark --- 断开蓝牙连接
- (void)cancelPeripheralConnection
{
    if (fzhPeripheral) {
        [fzhCentralManager cancelPeripheralConnection:fzhPeripheral];
    }
}

#pragma mark --- 设置或删除自动连接设备
-(void)createAutomaticConnectionEquipmenWithSetOrDelate:(AutomaticConnectionEquipmenEnum)setOrDel Peripheral:(CBPeripheral *)peripheral
{
    self.connectionEquipment = setOrDel;
    if (setOrDel == SetAutomaticConnectionEquipmen) {
        //设置自动连接设备
        [[NSUserDefaults standardUserDefaults] setObject:peripheral.name forKey:@"conPeripheral"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%lu",(unsigned long)setOrDel] forKey:@"setOrDel"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if (setOrDel == DelateAutomaticConnectionEquipmen) {
        //删除自动连接设备
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"conPeripheral"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"setOrDel"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark --- 断开蓝牙连接走这里
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self cancelPeripheralConnection];
    if (error)
    {
        NSLog(@">>> didDisconnectPeripheral for %@ with error: %@", peripheral.name, [error localizedDescription]);
    }
}

//获取服务后的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"didDiscoverServices : %@", [error localizedDescription]);
        return;
    }
    
    //提取出所有特征
    self.serviceArr = [NSMutableArray arrayWithArray:peripheral.services];
    
    for (CBService *s in peripheral.services) {
        [s.peripheral discoverCharacteristics:nil forService:s];
    }
}

//获取特征后的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"didDiscoverCharacteristicsForService error : %@", [error localizedDescription]);
        return;
    }
    
#warning ---此处需要筛选自己需要的特征
    if (self.UUIDString) {
        if (![service.UUID  isEqual:[CBUUID UUIDWithString:self.UUIDString]]) {
            return;
        }
    }
    
    for (CBCharacteristic *c in service.characteristics)
    {
        CBCharacteristicProperties properties = c.properties;
        if (properties & CBCharacteristicPropertyWrite) {
            fzgCharacteristic = c;
            self.writeCharacteristic = c;
        }else if (properties & CBCharacteristicPropertyNotify) {
            self.notifyCharacteristic = c;
            [peripheral setNotifyValue:YES forCharacteristic:c];
        }else if (properties & CBCharacteristicPropertyWriteWithoutResponse) {
            fzgCharacteristic = c;
            self.writeCharacteristic = c;
        }else if (properties & CBCharacteristicPropertyIndicate) {
            self.notifyCharacteristic = c;
        }
    }
}

//订阅的特征值有新的数据时回调
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@",
              [error localizedDescription]);
    }
    [peripheral readValueForCharacteristic:characteristic];
}

// 获取到特征的值时回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        //报错了
        NSLog(@"didUpdateValueForCharacteristic error : %@", error.localizedDescription);
        return;
    }
    if (!characteristic.value) {
        return;
    }
    if (resultStr.length <= 0 || ![resultStr isEqualToString:[[FzhString sharedInstance] fzHexStringFromData:characteristic.value]]) {
        resultStr = [[FzhString sharedInstance]fzHexStringFromData:characteristic.value];
        if (_equipmentReturnBlock) {
            _equipmentReturnBlock(peripheral,characteristic,resultStr,error);
        }
    }
}

#pragma mark ---------------- 获取信号之后的回调 ------------------
# if  __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    if (_getRSSIBlock) {
        double number = [self fzRssiToNumber:peripheral.RSSI];
        _getRSSIBlock(number,error);
    }
}
#else
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    if (_getRSSIBlock) {
        double number = [self fzRssiToNumber:RSSI];
        _getRSSIBlock(number,error);
    }
}
#endif

#pragma mark - RSSI转距离number
- (double)fzRssiToNumber:(NSNumber *)RSSI
{
    int tempRssi = [RSSI intValue];
    int absRssi = abs(tempRssi);
    float power = (absRssi-75)/(10*2.0);
    double number = pow(10, power);//除0外，任何数的0次方等于1
    return number;
}

@end
