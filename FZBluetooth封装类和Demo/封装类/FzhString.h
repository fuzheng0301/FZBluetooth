//
//  FzhString.h
//  OkeyBluetoothDemo
//
//  Created by 付正 on 2017/9/20.
//  Copyright © 2017年 付正. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FzhString : NSObject

+(FzhString *)sharedInstance;

/**
 异或运算

 @param pan 字符串1
 @param pinv 字符串2
 @return 返回异或结果
 */
- (NSString *)pinxCreator:(NSString *)pan withPinv:(NSString *)pinv;

/**
 16进制转10进制

 @param sixteenStr 16进制字符串
 @return 10进制字符串
 */
-(NSString *)sixteenChangeTenString:(NSString *)sixteenStr;

/**
 10进制转16进制
 
 @param decimal 10进制数字
 @return 16进制字符串
 */
- (NSString *)hexStringFromString:(NSInteger)decimal;

/**
 @see 16进制字符串转2进制数据
 @param hex 16进制字符串
 @return 2进制数据
 */
-(NSData *)hex2data:(NSString *)hex;

/**
 @see 16进制字符串转2进制字符串
 @param hex 16进制字符串
 @return 2进制字符串
 */
-(NSString *)getBinaryByhex:(NSString *)hex;

/**
 @see 2进制字符串转16进制字符串
 @param binary 2进制字符串
 @return 16进制字符串
 */
-(NSString *)getHexadecimalWithBinary:(NSString *)binary;

/**
 NSData转16进制NSString
 
 @param data data数据
 @return string数据
 */
- (NSString *)fzHexStringFromData:(NSData *)data;

/**
 NSString转NSData
 
 @param str string数据
 @return data数据
 */
- (NSMutableData *)convertHexStrToData:(NSString *)str;

/**
 自定义error信息
 
 @param domain 标志字段(如：com.okey.wearkit.domain)
 @param code error编号
 @param errorStr error信息
 @return error
 */
-(NSError *)returnErrorWithDomain:(NSString *)domain Code:(int)code ErrorStr:(NSString *)errorStr;

@end
