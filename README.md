# FZBluetooth
iOS蓝牙原生封装，助力智能硬件开发

![](https://github.com/fuzheng0301/FZBluetooth/blob/master/FZBluetooth%E5%B0%81%E8%A3%85%E7%B1%BB%E5%92%8CDemo/A62BABB1B55584D69200FCDA02F4B02F.png)

最近公司在做硬件设备，作为一名iOS开发人员，主要负责手机软件、硬件的连接方面，开发连接硬件使用的SDK，其中主要模块是蓝牙连接，通过蓝牙与硬件设备连接，发送指令使硬件工作。 
功能说起来很简单，但是寻找了好几天的蓝牙方面的Demo，看到了很多前人大神们封装的Bluetooth方法，感觉对于我等小白实在是有点深奥，方法繁多，不知从何处下手。所以最后考虑再三，还是从底层基础入手，自己重新整理、封装了一份蓝牙的查找、连接、写入、断开的类，本着程序员的开源精神，分享出来，欢迎大家指正。

# 使用 Cocoapods 导入
FZBluetooth is available on [CocoaPods](http://cocoapods.org).  Add the following to your Podfile:

```ruby
pod "FZBluetooth","~>1.0.0"
```

# 目录
1. [系统蓝牙状态监听](https://github.com/fuzheng0301/FZBluetooth/blob/master/README.md#1.系统蓝牙状态监听)
2. [蓝牙搜索](https://github.com/fuzheng0301/FZBluetooth/blob/master/README.md#2.蓝牙搜索)
3. [蓝牙设备的连接](https://github.com/fuzheng0301/FZBluetooth/blob/master/README.md#3.蓝牙设备的连接)
4. [设备的自动连接设置](https://github.com/fuzheng0301/FZBluetooth/blob/master/README.md#4.设备的自动连接设置)
	[根据设备peripheral自动连接](https://github.com/fuzheng0301/FZBluetooth/blob/master/README.md#4.1.根据设备peripheral自动连接)
	[通过设备UUID自动连接](https://github.com/fuzheng0301/FZBluetooth/blob/master/README.md#4.2.通过设备UUID自动连接)
5. [写入数据](https://github.com/fuzheng0301/FZBluetooth/blob/master/README.md#5.写入数据)
	[异步Block方式返回结果](https://github.com/fuzheng0301/FZBluetooth/blob/master/README.md#5.1.异步Block方式返回结果)
	[同步返回结果](https://github.com/fuzheng0301/FZBluetooth/blob/master/README.md#5.2.同步返回结果)
6. [蓝牙的断开](https://github.com/fuzheng0301/FZBluetooth/blob/master/README.md#6.蓝牙的断开)
7. [其他](https://github.com/fuzheng0301/FZBluetooth/blob/master/README.md#7.其他)

# 方法说明简介

## 1.系统蓝牙状态监听
这个很方便，在系统蓝牙方法centralManagerDidUpdateState中就可以实时获取到蓝牙状态的改变，所以用一个Block回调就可以得到状态，根据状态变化做对应操作即可。

方法代码如下：
```
/**

系统当前蓝牙的状态

@paramstateBlock 实时返回当前蓝牙状态

*/

- (void)returnBluetoothStateWithBlock:(FZStateUpdateBlock)stateBlock;
```

## 2.蓝牙搜索
蓝牙搜索的功能方法中，用系统原生的方法scanForPeripheralsWithServices:options:，在蓝牙搜索的代理方法centralManager:didDiscoverPeripheral:advertisementData:RSSI:里获取搜索结果，用Block返回搜索结果。另外添加了方法通过设置参数nameStr来筛选返回的设备名称，nameStr为设备模糊搜索参数，设备中包含nameStr字段即可返回搜索结果。

封装后的代码调用方法如下：
```
/*

* 开始搜索蓝牙外设，每次在block中返回一个蓝牙外设信息

*@paramnameStr  模糊搜索设备名称，目标设备名称包含字段

*  返回的block参数可参考CBCentralManager 的centralManager:didDiscoverPeripheral:advertisementData:RSSI:

*@paramdiscoverBlock 搜索到蓝牙外设后的回调

*/

- (void)scanForPeripheralsWithPrefixName:(NSString *)nameStr discoverPeripheral:(FZDiscoverPeripheralBlock)discoverBlock;
```

## 3.蓝牙设备的连接
蓝牙的连接为系统方法connectPeripheral:options:，连接设备的结果分别通过代理方法centralManager:didConnectPeripheral:返回成功、centralManager:didFailToConnectPeripheral:error:返回失败，通过两个Block分别返回成功和失败。其中成功后要停止搜索stopScan，失败要返回失败原因。

代码方法如下：
```
/*

*  连接某个蓝牙外设，并查询服务，特性，特性描述

*@paramperipheral          要连接的蓝牙外设

*@paramcompletionBlock    操作执行完的回调

*/

- (void)connectPeripheral:(CBPeripheral *)peripheral completeBlock:(FZConnectSuccessBlock)completionBlock failBlock:(FZConnectFailBlock)failBlock;
```

## 4.设备的自动连接设置
设备的自动连接，这里我写了两种方法，大家可以根据自己喜好自由选择。
### 4.1.根据设备peripheral自动连接
方法代码如下：
```
/**

设置或删除自动连接设备

设置后，在代理方法connectionWithPerpheral:里会返回设备的peripheral

@param setOrDel 自动连接和删除自动连接

@param peripheral 设备peripheral

*/

-(void)createAutomaticConnectionEquipmenWithSetOrDelate:(AutomaticConnectionEquipmenEnum)setOrDel Peripheral:(CBPeripheral *)peripheral;
```
这个方法中setOrDel有两个枚举值，分别为：SetAutomaticConnectionEquipmen（设置自动重连）和DelateAutomaticConnectionEquipmen（删除自动重连）。

**使用方法：** 

设置自动重连设备后，这里传入的peripheral会自动保存，服从代理：FZAutomaticConnectionDelegate，在代理方法
```
/**

自动连接的设备代理方法

*/

- (void)connectionWithPerpheral:(CBPeripheral *)peripheral;
```
中可以获取到重连的设备peripheral，随后进行连接操作即可。

### 4.2.通过设备UUID自动连接
代码方法如下：
```
/**

通过UUID获取peripheral

用户自主记录想要自动连接的UUID，获取peripheral后调用连接方法

@param UUIDString UUID

@return peripheral

*/

- (CBPeripheral *)retrievePeripheralWithUUIDString:(NSString *)UUIDString;
```
**使用方法：**
获取到设备的UUID后，通过此方法得到设备的peripheral，然后调用连接设备的方法即可自动重新连接。

## 5.写入数据
写入数据，在大多数的第三方方法里会有UUID、characteristic、peripheral等很多参数，混乱不易理解。这里我封装后只留了一个characteristic特性参数，而且已经帮大家筛选出来了，可以在封装方法头文件里，连接设备成功后直接获取到。另一方面，写入内容直接用NSString类型就可以，内部会自动转成NSData格式写入设备。

写入数据原生方法为writeValue:forCharacteristic:type:，写入数据后会在代理方法peripheral:didWriteValueForCharacteristic:error:方法里得到是否写入成功，成功与否用Block返回了结果。另外，如果蓝牙设备有应答的时候，会在peripheral:didUpdateValueForCharacteristic:error:方法里返回，处理起来比较麻烦，我下面封装了两种方法，一种通过Block异步返回结果，一种为同步返回应答结果，大家可以根据需要自由选择。

### 5.1.异步Block方式返回结果
代码封装后的接口为：
```
/*

*  往某个特性中写入数据

*@paramcharacteristic 特性对象

*@paramcompletionBlock 写入完成后的回调,只有type为CBCharacteristicWriteWithResponse时，才会回调

*/

- (void)writeValue:(NSString *)dataStr forCharacteristic:(CBCharacteristic *)characteristic completionBlock:(FZWriteToCharacteristicBlock)completionBlock returnBlock:(FZEquipmentReturnBlock)equipmentBlock;
```
### 5.2.同步返回结果
接口方法为：
```
/**

* 往某个特性中写入数据，同步返回结果 

* @param dataStr 写入的数据

* @param characteristic 特性对象

* @return 设备应答结果 returnStr 应答内容 error 错误信息

*/

-(NSDictionary *)writeValue:(NSString *)dataStr forCharacteristic:(CBCharacteristic *)characteristic;
```
同步返回的字典中有两个参数：returnStr和error，returnStr为设备应答数据，error为错误信息，判断error为nil时为成功，取returnStr进行下一步操作即可。

**这里需要注意的是：实际开发中，可以用一个叫lightBlue的蓝牙开发辅助APP，看一下设备有多少特征值，我们实际用的时候需要用哪个，这个可以直接询问硬件厂商或硬件开发人员，然后在调用写入方法前，设置封装类中的属性UUIDString的对应值，可以保证连接过程中稳定不出问题**

## 6.蓝牙的断开
蓝牙的断开，只留了一个方法，断开当前连接的设备，使用系统原生方法cancelPeripheralConnection:，设备的信息在连接时已自动记录，所以不需要传入参数

代码封装后的方法如下：
```
/*

*  断开蓝牙连接

*/

- (void)readRSSICompletionBlock:(FZGetRSSIBlock)getRSSIBlock;
```

## 7.其他
其他的方法，头文件里开放了”RSSI转距离Double类型数据”、”NSData转16进制字符串”、”NSString类型转NSData类型数据”三个方法。





