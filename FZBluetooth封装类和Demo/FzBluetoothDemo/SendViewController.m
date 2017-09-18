//
//  SendViewController.m
//  FzBluetoothDemo
//
//  Created by 付正 on 2017/9/18.
//  Copyright © 2017年 付正. All rights reserved.
//

#import "SendViewController.h"
#import "FzhBluetooth.h"
#import "FZBlueModel.h"
#import "FZSingletonManager.h"

@interface SendViewController ()
{
    UILabel *messageLabel;  //展示
    UITextField *textF;
}
@end

@implementation SendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"发送接收数据";
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self createUI];
}

-(void)viewDidDisappear:(BOOL)animated
{
    //断开连接
    [[FzhBluetooth shareInstance]cancelPeripheralConnection];
}

-(void)createUI
{
    textF = [[UITextField alloc]initWithFrame:CGRectMake(ScreenWidth/2-110, 80, 220, 40)];
    textF.placeholder = @"输入发送给设备的指令";
    textF.layer.borderWidth = 1.0;
    [self.view addSubview:textF];
    
    [self buttonWithTitle:@"发 送" frame:CGRectMake(ScreenWidth/2-50, 140, 100, 40) action:@selector(didClickSend) AddView:self.view];
    
    messageLabel = [[UILabel alloc]initWithFrame:CGRectMake(30, 200, ScreenWidth-60, 200)];
    messageLabel.numberOfLines = 0;
    messageLabel.layer.borderWidth = 0.5;
    [self.view addSubview:messageLabel];
}

-(void)didClickSend
{
    if (textF.text.length <= 0) {
        UIAlertView *alt = [[UIAlertView alloc]initWithTitle:@"提示" message:@"请输入内容" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alt show];
        return;
    }
    [self.view endEditing:YES];
    
    [[FzhBluetooth shareInstance]writeValue:textF.text forCharacteristic:[FZSingletonManager shareInstance].GPrint_Chatacter completionBlock:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"发送成功");
        if (!messageLabel.text) {
            messageLabel.text = @"";
        }
        messageLabel.text = [NSString stringWithFormat:@"%@\nsend：%@",messageLabel.text,textF.text];
    } returnBlock:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSString *returnStr, NSError *error) {
        NSLog(@"应答数据，%@",returnStr);
        messageLabel.text = [NSString stringWithFormat:@"%@\nrep：%@",messageLabel.text,returnStr];
    }];
}

#pragma mark --- 点击屏幕空白处收起键盘
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark --- 创建button公共方法
/**使用示例:[self buttonWithTitle:@"点 击" frame:CGRectMake((self.view.frame.size.width - 150)/2, (self.view.frame.size.height - 40)/3, 150, 40) action:@selector(didClickButton) AddView:self.view];*/
-(UIButton *)buttonWithTitle:(NSString *)title frame:(CGRect)frame action:(SEL)action AddView:(id)view
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = frame;
    button.backgroundColor = [UIColor lightGrayColor];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchDown];
    [view addSubview:button];
    return button;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
