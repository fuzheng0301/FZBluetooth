//
//  FzhCallBlock.h
//  FzBluetoothDemo
//
//  Created by 付正 on 2017/9/21.
//  Copyright © 2017年 付正. All rights reserved.
//

#ifndef FzhCallBlock_h
#define FzhCallBlock_h

/** 蓝牙状态改变的block */
typedef void(^FZStateUpdateBlock)(CBManagerState *state);
/** 发现一个蓝牙外设的block */
typedef void(^FZDiscoverPeripheralBlock)(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI);
/** 连接完成的block*/
typedef void(^FZConnectSuccessBlock)(CBPeripheral *peripheral,CBService *service, CBCharacteristic *character);
/** 连接失败的block*/
typedef void(^FZConnectFailBlock)(CBPeripheral *peripheral, NSError *error);
/** 获取蓝牙外设信号的回调 */
typedef void(^FZGetRSSIBlock)(double number, NSError *error);
/** 往特性中写入数据的回调 */
typedef void(^FZWriteToCharacteristicBlock)(CBCharacteristic *characteristic, NSError *error);
/** 设备返回数据的回调 */
typedef void(^FZEquipmentReturnBlock)(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSString *returnStr, NSError *error);

#endif /* FzhCallBlock_h */
