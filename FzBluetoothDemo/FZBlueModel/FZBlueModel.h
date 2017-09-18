//
//  FZBlueModel.h
//  FZBluetoothDemo
//
//  Created by 付正 on 2017/6/19.
//  Copyright © 2017年 付正. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface FZBlueModel : NSObject

@property (nonatomic, strong) NSString *blueName;   //设备名称
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic * GPrint_Chatacter;
@property (nonatomic, strong) NSString * UUIDString; //UUID
@property (nonatomic, strong) NSString * distance;  //中心到外设的距离

@end
