//
//  ViewController.m
//  FzBluetoothDemo
//
//  Created by 付正 on 2017/9/18.
//  Copyright © 2017年 付正. All rights reserved.
//

#import "ViewController.h"
#import "FzhBluetooth.h"
#import "FZBlueModel.h"
#import "FZHProgressHUD.h"
#import "FZSingletonManager.h"
#import "SendViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,FZHProgressHUDDelegate,FZAutomaticConnectionDelegate>
{
    UITableView *mytableView;
    UILabel * nameLabel; //蓝牙名字
    UILabel * uuidStrLabel;  //UUID
    UILabel * distanceLabel; //距离
    
    FZHProgressHUD * HUD;
    FzhBluetooth *bluetooth;
}
@property (nonatomic,strong) NSMutableArray *blueListArr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"搜索设备";
    self.blueListArr = [[NSMutableArray alloc]init];
    
    //加载圈
    HUD = [[FZHProgressHUD alloc]initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:HUD];
    HUD.delegate = self;
    HUD.animationType = FZHProgressHUDAnimationZoom;
    HUD.labelText = @"连接中...";
    
    //创建展示列表
    [self createTableView];
    
    bluetooth = [[FzhBluetooth alloc]init];
    bluetooth.delegate = self;
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    label.text = @"请打开系统蓝牙";
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor blackColor];
    label.alpha = 0.3;
    label.userInteractionEnabled = NO;
    //监听蓝牙状态
    [bluetooth returnBluetoothStateWithBlock:^(CBManagerState *state) {
        if (state != CBCentralManagerStatePoweredOn) {
            [self.view addSubview:label];
        } else {
            [label removeFromSuperview];
            //搜索蓝牙设备
            [self scanBluetooths];
        }
    }];
    
}

#pragma mark --- 创建蓝牙设备列表
-(void)createTableView
{
    mytableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight-64) style:UITableViewStylePlain];
    mytableView.delegate = self;
    mytableView.dataSource = self;
    [self.view addSubview:mytableView];
}

#pragma mark --- 搜索蓝牙设备
-(void)scanBluetooths
{
    [bluetooth scanForPeripheralsWithPrefixName:@"okey" discoverPeripheral:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备:%@",peripheral.name);
        
        NSInteger perpheralIndex = -1 ;
        for (int i = 0;  i < self.blueListArr.count; i++) {
            FZBlueModel *model = [[FZBlueModel alloc]init];
            model = self.blueListArr[i];
            if ([model.peripheral.identifier isEqual:peripheral.identifier]) {
                perpheralIndex = i ;
                break ;
            }
        }
        FZBlueModel *model = [[FZBlueModel alloc]init];
        model.blueName = peripheral.name;
        model.peripheral = peripheral;
        model.UUIDString = peripheral.identifier.UUIDString;
        double min = [bluetooth  fzRssiToNumber:RSSI];
        model.distance = [NSString stringWithFormat:@"%.2f",min];
        if (perpheralIndex != -1) {
            [self.blueListArr replaceObjectAtIndex:perpheralIndex withObject:model];
        }
        else{
            [self.blueListArr addObject:model];
        }
        [mytableView reloadData];
    }];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.blueListArr.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 5, ScreenWidth-20, 20)];
        [cell addSubview:nameLabel];
        
        uuidStrLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 25, ScreenWidth*3/4, 20)];
        uuidStrLabel.font = [UIFont systemFontOfSize:11];
        [cell addSubview:uuidStrLabel];
        
        distanceLabel = [[UILabel alloc]initWithFrame:CGRectMake(ScreenWidth*3/4+10, 25, ScreenWidth/4-20, 20)];
        distanceLabel.font = [UIFont systemFontOfSize:11];
        distanceLabel.textAlignment = NSTextAlignmentRight;
        [cell addSubview:distanceLabel];
    }
    while ([cell.contentView.subviews lastObject])
    {
        [(UIView *)[cell.contentView.subviews lastObject] removeFromSuperview];
    }
    
    FZBlueModel *blueModel = self.blueListArr[indexPath.row];
    nameLabel.text = blueModel.blueName;
    uuidStrLabel.text = blueModel.UUIDString;
    distanceLabel.text = [NSString stringWithFormat:@"距离：%@米",blueModel.distance];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [HUD show:YES];
    
    //停止扫描
    [bluetooth stopScan];
    
    FZBlueModel *blueModel = self.blueListArr[indexPath.row];
    //设置目标设备特征UUID
    bluetooth .UUIDString = @"0000FEE9-0000-1000-8000-00805F9B34FB";
    //连接设备
    [bluetooth connectPeripheral:blueModel.peripheral completeBlock:^(CBPeripheral *peripheral, CBService *service, CBCharacteristic *character) {
        NSLog(@"链接成功");
        [HUD hide:YES];
        
        [FZSingletonManager shareInstance].GPrint_Chatacter = bluetooth .writeCharacteristic;
        [FZSingletonManager shareInstance].GPrint_Peripheral = peripheral;
        
        //设置自动重连
        [bluetooth createAutomaticConnectionEquipmenWithSetOrDelate:SetAutomaticConnectionEquipmen Peripheral:peripheral];
        
        SendViewController *sendVC = [[SendViewController alloc]init];
        [self.navigationController pushViewController:sendVC animated:YES];
        
    } failBlock:^(CBPeripheral *peripheral, NSError *error) {
        NSLog(@"链接失败");
    }];
}

#pragma mark --- 自动连接设备走到这里
-(void)connectionWithPerpheral:(CBPeripheral *)peripheral
{
    [FZSingletonManager shareInstance].GPrint_Chatacter = bluetooth .writeCharacteristic;
    [FZSingletonManager shareInstance].GPrint_Peripheral = peripheral;
    
    SendViewController *sendVC = [[SendViewController alloc]init];
    [self.navigationController pushViewController:sendVC animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
