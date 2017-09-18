//
//  FZSingletonManager.m
//  FZeyBluetoothDemo
//
//  Created by 付正 on 2017/5/22.
//  Copyright © 2017年 付正. All rights reserved.
//

#import "FZSingletonManager.h"

@implementation FZSingletonManager

+(FZSingletonManager *)shareInstance
{
    static FZSingletonManager * singletonManager = nil;
    @synchronized(self){
        if (!singletonManager) {
            singletonManager = [[FZSingletonManager alloc]init];
        }
    }
    return singletonManager;
}

@end
