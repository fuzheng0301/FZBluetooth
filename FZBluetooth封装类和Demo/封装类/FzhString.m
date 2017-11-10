//
//  FzhString.m
//  OkeyBluetoothDemo
//
//  Created by 付正 on 2017/9/20.
//  Copyright © 2017年 付正. All rights reserved.
//

#import "FzhString.h"

@implementation FzhString

//创建一个单例
static FzhString *dbManger=nil;
+(FzhString *)sharedInstance
{
    @synchronized(self){
        if (nil==dbManger) {
            dbManger=[[FzhString alloc]init];
        }
        return dbManger;
    }
}

#pragma mark --- 异或运算
- (NSString *)pinxCreator:(NSString *)pan withPinv:(NSString *)pinv
{
    if (pan.length != pinv.length)
    {
        return nil;
    }
    const char *panchar = [pan UTF8String];
    const char *pinvchar = [pinv UTF8String];
    NSString *temp = [[NSString alloc] init];
    for (int i = 0; i < pan.length; i++)
    {
        int panValue = [self charToint:panchar[i]];
        int pinvValue = [self charToint:pinvchar[i]];
        
        temp = [temp stringByAppendingString:[NSString stringWithFormat:@"%X",panValue^pinvValue]];
    }
    return temp;
}
- (int)charToint:(char)tempChar
{
    if (tempChar >= '0' && tempChar <='9') {
        return tempChar - '0';
    } else if (tempChar >= 'A' && tempChar <= 'F') {
        return tempChar - 'A' + 10;
    }
    return 0;
}

#pragma mark --- 2进制字符串转16进制字符串
-(NSString *)getHexadecimalWithBinary:(NSString *)binary
{
    NSMutableDictionary  *hexDic = [[NSMutableDictionary alloc] init];
    [hexDic setObject:@"0" forKey:@"0000"];
    [hexDic setObject:@"1" forKey:@"0001"];
    [hexDic setObject:@"2" forKey:@"0010"];
    [hexDic setObject:@"3" forKey:@"0011"];
    [hexDic setObject:@"4" forKey:@"0100"];
    [hexDic setObject:@"5" forKey:@"0101"];
    [hexDic setObject:@"6" forKey:@"0110"];
    [hexDic setObject:@"7" forKey:@"0111"];
    [hexDic setObject:@"8" forKey:@"1000"];
    [hexDic setObject:@"9" forKey:@"1001"];
    [hexDic setObject:@"a" forKey:@"1010"];
    [hexDic setObject:@"b" forKey:@"1011"];
    [hexDic setObject:@"c" forKey:@"1100"];
    [hexDic setObject:@"d" forKey:@"1101"];
    [hexDic setObject:@"e" forKey:@"1110"];
    [hexDic setObject:@"f" forKey:@"1111"];
    NSString *binaryString=@"";
    for (int i = 0; i < binary.length; i ++) {
        NSString *key = [binary substringWithRange:NSMakeRange(i, 4)];
        binaryString = [binaryString stringByAppendingString:[hexDic objectForKey:key]];
        i += 3;
    }
    
    return binaryString;
}

#pragma mark --- 16进制字符串转2进制字符串
-(NSString *)getBinaryByhex:(NSString *)hex
{
    NSMutableDictionary  *hexDic = [[NSMutableDictionary alloc] init];
    [hexDic setObject:@"0000" forKey:@"0"];
    [hexDic setObject:@"0001" forKey:@"1"];
    [hexDic setObject:@"0010" forKey:@"2"];
    [hexDic setObject:@"0011" forKey:@"3"];
    [hexDic setObject:@"0100" forKey:@"4"];
    [hexDic setObject:@"0101" forKey:@"5"];
    [hexDic setObject:@"0110" forKey:@"6"];
    [hexDic setObject:@"0111" forKey:@"7"];
    [hexDic setObject:@"1000" forKey:@"8"];
    [hexDic setObject:@"1001" forKey:@"9"];
    [hexDic setObject:@"1010" forKey:@"A"];
    [hexDic setObject:@"1011" forKey:@"B"];
    [hexDic setObject:@"1100" forKey:@"C"];
    [hexDic setObject:@"1101" forKey:@"D"];
    [hexDic setObject:@"1110" forKey:@"E"];
    [hexDic setObject:@"1111" forKey:@"F"];
    [hexDic setObject:@"1010" forKey:@"a"];
    [hexDic setObject:@"1011" forKey:@"b"];
    [hexDic setObject:@"1100" forKey:@"c"];
    [hexDic setObject:@"1101" forKey:@"d"];
    [hexDic setObject:@"1110" forKey:@"e"];
    [hexDic setObject:@"1111" forKey:@"f"];
    NSMutableString *binaryString=[[NSMutableString alloc] init];
    for (int i=0; i<[hex length]; i++) {
        NSRange rage;
        rage.length = 1;
        rage.location = i;
        NSString *key = [hex substringWithRange:rage];
        binaryString = [NSMutableString stringWithFormat:@"%@%@",binaryString,[NSString stringWithFormat:@"%@",[hexDic objectForKey:key]]];
    }
    return binaryString;
}

#pragma mark --- 十进制准换为十六进制字符串
- (NSString *)hexStringFromString:(NSInteger)decimal
{
    NSString *hex =@"";
    NSString *letter;
    NSInteger number;
    for (int i = 0; i<9; i++) {
        number = decimal % 16;
        decimal = decimal / 16;
        switch (number) {
            case 10:
                letter =@"a"; break;
            case 11:
                letter =@"b"; break;
            case 12:
                letter =@"c"; break;
            case 13:
                letter =@"d"; break;
            case 14:
                letter =@"e"; break;
            case 15:
                letter =@"f"; break;
            default:
                letter = [NSString stringWithFormat:@"%ld", (long)number];
        }
        hex = [letter stringByAppendingString:hex];
        if (decimal == 0) {
            
            break;
        }
    }
    if (hex.length == 1) {
        hex = [NSString stringWithFormat:@"0%@",hex];
    }
    return hex;
}

#pragma mark --- 16进制转10进制
-(NSString *)sixteenChangeTenString:(NSString *)sixteenStr
{
    NSString * temp10 = [NSString stringWithFormat:@"%lu",strtoul([sixteenStr UTF8String],0,16)];
    return temp10;
}

#pragma mark --- 16进制转2进制数据
-(NSData *)hex2data:(NSString *)hex
{
    NSMutableData *data = [NSMutableData dataWithCapacity:hex.length / 2];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < hex.length / 2; i++) {
        byte_chars[0] = [hex characterAtIndex:i*2];
        byte_chars[1] = [hex characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

#pragma mark - NSData转16进制NSString
- (NSString *)fzHexStringFromData:(NSData *)data
{
    Byte *bytes = (Byte *)[data bytes];
    //下面是Byte 转换为16进制
    NSString *hexStr=@"";
    for(int i=0;i<[data length];i++){
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length]==1){
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        }else{
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
        }
    }
    return hexStr;
}

#pragma mark - NSString转NSData
- (NSMutableData *)convertHexStrToData:(NSString *)str
{
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] %2 == 0) {
        range = NSMakeRange(0,2);
    } else {
        range = NSMakeRange(0,1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    
    return hexData;
}

#pragma mark --- 自定义error
-(NSError *)returnErrorWithDomain:(NSString *)domain Code:(int)code ErrorStr:(NSString *)errorStr
{
    NSString *desc = NSLocalizedString(errorStr, @"");
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
    NSError *error = [NSError errorWithDomain:domain
                                         code:code
                                     userInfo:userInfo];
    return error;
}

@end
