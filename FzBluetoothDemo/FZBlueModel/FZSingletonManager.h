//
//  FZSingletonManager.h
//  FZeyBluetoothDemo
//
//  Created by 付正 on 2017/5/22.
//  Copyright © 2017年 付正. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface FZSingletonManager : NSObject

@property (strong, nonatomic)   CBPeripheral * GPrint_Peripheral;//当前连接的Peripheral
@property (strong, nonatomic)   CBCharacteristic * GPrint_Chatacter;//当前连接的Chatacter

+(FZSingletonManager *)shareInstance;

@end
