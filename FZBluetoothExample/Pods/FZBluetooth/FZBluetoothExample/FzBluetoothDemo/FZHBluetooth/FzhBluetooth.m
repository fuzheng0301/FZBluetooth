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
		//CBCentralManagerOptionShowPowerAlertKey对应的BOOL值，当设为YES时，表示CentralManager初始化时，如果蓝牙没有打开，将弹出Alert提示框
		//CBCentralManagerOptionRestoreIdentifierKey对应的是一个唯一标识的字符串，用于蓝牙进程被杀掉恢复连接时用的。
//		dispatch_queue_t centralQueue = dispatch_queue_create("centralQueue",DISPATCH_QUEUE_SERIAL);
//		NSDictionary *dic = @{CBCentralManagerOptionShowPowerAlertKey : [NSNumber numberWithBool:YES],
//							  CBCentralManagerOptionRestoreIdentifierKey : @"unique identifier"
//							  };
//		fzhCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue options:dic];
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
            [self startScan];
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
    [self startScan];
    self.discoverPeripheralBlcok = discoverBlock;
}

- (void)startScan
{
	//不重复扫描已发现设备
	//CBCentralManagerScanOptionAllowDuplicatesKey设置为NO表示不重复扫瞄已发现设备，为YES就是允许。
	//CBCentralManagerOptionShowPowerAlertKey设置为YES就是在蓝牙未打开的时候显示弹框
//	NSDictionary *option = @{CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:NO],CBCentralManagerOptionShowPowerAlertKey:[NSNumber numberWithBool:YES]};
//	[fzhCentralManager scanForPeripheralsWithServices:nil options:option];
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
//在蓝牙于后台被杀掉时，重连之后会首先调用此方法，可以获取蓝牙恢复时的各种状态
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
        [self startScan];
    }
    if ([setOrDelNum isEqualToString:@"0"]) {
        //有自动重连的设备
        [[NSNotificationCenter defaultCenter]postNotificationName:PostAutoConnectionNotificaiton object:nil];
        if ([peripheral.name isEqualToString:perName]) {
            fzhPeripheral = peripheral;
            [fzhCentralManager connectPeripheral:peripheral options:nil];
        }
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
        if (self.connectSuccessBlock) {
            self.connectSuccessBlock(peripheral,nil,self.writeCharacteristic);
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

#pragma mark --- 断开蓝牙连接走这里
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	[self cancelPeripheralConnection];
	if (error)
		{
		NSLog(@">>> didDisconnectPeripheral for %@ with error: %@", peripheral.name, [error localizedDescription]);
		}
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
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%lu",(long)setOrDel] forKey:@"setOrDel"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if (setOrDel == DelateAutomaticConnectionEquipmen) {
        //删除自动连接设备
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"conPeripheral"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"setOrDel"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark --- 通过UUID获取peripheral
- (CBPeripheral *)retrievePeripheralWithUUIDString:(NSString *)UUIDString
{
	CBPeripheral *p = nil;
	@try {
		NSUUID *uuid = [[NSUUID alloc]initWithUUIDString:UUIDString];
		p = [fzhCentralManager retrievePeripheralsWithIdentifiers:@[uuid]][0];
	} @catch (NSException *exception) {
		NSLog(@">>> retrievePeripheralWithUUIDString error:%@",exception);
	} @finally {
	}
	return p;
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
    
#pragma mark ---此处需要筛选自己需要的特征
    [self createCharacticWithPeripheral:peripheral Service:service];
}

#pragma mark --- 重新设置特征值
-(void)createCharacticWithPeripheral:(CBPeripheral *)peripheral UUIDString:(NSString *)uuidString
{
    for (CBService *s in peripheral.services) {
        [s.peripheral discoverCharacteristics:nil forService:s];
        
        if ([s.UUID isEqual: [CBUUID UUIDWithString:uuidString]]) {
            [self createCharacticWithPeripheral:peripheral Service:s];
        }
    }
}

// 筛选特征
-(void)createCharacticWithPeripheral:(CBPeripheral *)peripheral Service:(CBService *)service
{
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

// 读数据时回调
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

//写数据后回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
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

#pragma mark --- 写入数据
- (void)writeValue:(NSString *)dataStr forCharacteristic:(CBCharacteristic *)characteristic completionBlock:(FZWriteToCharacteristicBlock)completionBlock  returnBlock:(FZEquipmentReturnBlock)equipmentBlock
{
	writeCount = 0;
	responseCount = 0;
	
	NSMutableArray *sendArr = [[NSMutableArray alloc]init];
	if (dataStr.length > 40) {
		int count = (int)dataStr.length / 40 + 1;
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

#pragma mark --- 写入数据 同步返回数据
-(NSDictionary *)writeValue:(NSString *)dataStr forCharacteristic:(CBCharacteristic *)characteristic
{
	__block NSString * str = nil;
	__block NSError *reError = nil;
	[self writeValue:dataStr forCharacteristic:characteristic completionBlock:^(CBCharacteristic *characteristic, NSError *error) {
		NSLog(@"发送成功");
		reError = error;
	} returnBlock:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSString *returnStr, NSError *error) {
		str = returnStr;
		reError = error;
	}];
	
	while (!str) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}
	
	NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
	[dict setValue:reError forKey:@"error"];
	[dict setValue:str forKey:@"returnStr"];
	return dict;
}

#pragma mark --- 获取外设的信号强度
- (void)readRSSICompletionBlock:(FZGetRSSIBlock)getRSSIBlock
{
	self.getRSSIBlock = getRSSIBlock;
	[fzhPeripheral readRSSI];
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
