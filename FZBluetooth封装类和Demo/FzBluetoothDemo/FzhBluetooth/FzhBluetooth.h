//
//  FzhBluetooth.h
//  BlueTooth
//
//  Created by 付正 on 2017/9/14.
//  Copyright © 2017年 BFMobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "FzhCallBlock.h"

typedef enum : NSUInteger {
    SetAutomaticConnectionEquipmen = 0,
    DelateAutomaticConnectionEquipmen,
} AutomaticConnectionEquipmenEnum;

@protocol FZAutomaticConnectionDelegate

/**
 自动连接的设备代理方法
 */
@optional - (void)connectionWithPerpheral:(CBPeripheral *)peripheral;

@end

@interface FzhBluetooth : NSObject<CBPeripheralDelegate,CBCentralManagerDelegate,CBPeripheralManagerDelegate>

@property (assign,nonatomic) AutomaticConnectionEquipmenEnum connectionEquipment;
@property (strong, nonatomic) id delegate;
@property (copy, nonatomic) FZStateUpdateBlock stateUpdateBlock;
/** 发现一个蓝牙外设的回调 */
@property (copy, nonatomic) FZDiscoverPeripheralBlock               discoverPeripheralBlcok;
/** 连接外设完成的回调 */
@property (copy, nonatomic) FZConnectSuccessBlock                connectSuccessBlock;
/** 连接外设失败的回调 */
@property (copy, nonatomic) FZConnectFailBlock                connectFailBlock;
/** 获取蓝牙外设信号强度的回调  */
@property (copy, nonatomic) FZGetRSSIBlock                          getRSSIBlock;
/** 将数据写入特性中的回调 */
@property (copy, nonatomic) FZWriteToCharacteristicBlock            writeToCharacteristicBlock;
@property (copy, nonatomic) FZEquipmentReturnBlock equipmentReturnBlock;

@property (nonatomic, strong) CBCharacteristic * writeCharacteristic;//可写入参数,蓝牙连接成功,2秒后获得参数值
@property (nonatomic, strong) CBCharacteristic * notifyCharacteristic;//可通知参数,蓝牙连接成功,2秒后获得参数值

+(instancetype)shareInstance;

/**
 设置设备特性UUID，如果不设置默认为空
 */
@property (nonatomic, strong) NSString *UUIDString;

/**
 * 连接设备后获取到的所有Service
 */
@property (nonatomic, strong) NSMutableArray *serviceArr;

/**
 系统当前蓝牙的状态

 @param stateBlock 实时返回当前蓝牙状态
 */
- (void)returnBluetoothStateWithBlock:(FZStateUpdateBlock)stateBlock;

/**
 *  开始搜索蓝牙外设，每次在block中返回一个蓝牙外设信息
 *
 *  @param nameStr  模糊搜索设备名称，目标设备名称包含字段
 *  返回的block参数可参考CBCentralManager 的 centralManager:didDiscoverPeripheral:advertisementData:RSSI:
 *
 *  @param discoverBlock 搜索到蓝牙外设后的回调
 */
- (void)scanForPeripheralsWithPrefixName:(NSString *)nameStr discoverPeripheral:(FZDiscoverPeripheralBlock)discoverBlock;

/**
 *  连接某个蓝牙外设，并查询服务，特性，特性描述
 *
 *  @param peripheral          要连接的蓝牙外设
 *  @param completionBlock     操作执行完的回调
 */
- (void)connectPeripheral:(CBPeripheral *)peripheral
            completeBlock:(FZConnectSuccessBlock)completionBlock
                failBlock:(FZConnectFailBlock)failBlock;

/**
 *  获取某外设的距离
 *
 *  @param getRSSIBlock 获取信号完成后的回调
 */
- (void)readRSSICompletionBlock:(FZGetRSSIBlock)getRSSIBlock;

/**
 RSSI转距离number

 @param RSSI RSSI
 @return 距离
 */
- (double)fzRssiToNumber:(NSNumber *)RSSI;

/**
 *  往某个特性中写入数据，自动识别数据长度超过限制分段传输
 *
 *  @param dataStr       写入的数据
 *  @param characteristic 特性对象
 *  @param completionBlock 写入完成后的回调,只有type为CBCharacteristicWriteWithResponse时，才会回调
 */
- (void)writeValue:(NSString *)dataStr forCharacteristic:(CBCharacteristic *)characteristic completionBlock:(FZWriteToCharacteristicBlock)completionBlock returnBlock:(FZEquipmentReturnBlock)equipmentBlock;

/**
 *  停止扫描
 */
- (void)stopScan;

/**
 *  断开蓝牙连接
 */
- (void)cancelPeripheralConnection;

/**
 设置或删除自动连接设备

 @param setOrDel 自动连接和删除自动连接
 @param peripheral 设备peripheral
 */
-(void)createAutomaticConnectionEquipmenWithSetOrDelate:(AutomaticConnectionEquipmenEnum)setOrDel Peripheral:(CBPeripheral *)peripheral;

@end
