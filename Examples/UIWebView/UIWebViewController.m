//
//  UIWebViewController.m
//  Examples
//
//  Created by YanYi on 2018/9/9.
//  Copyright © 2018年 YanYi. All rights reserved.
//

#import "UIWebViewController.h"

@interface UIWebViewController ()

@end

@implementation UIWebViewController


#pragma mark - LifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"调用JS" style:UIBarButtonItemStylePlain target:self action:@selector(sendMessageToWebView:)];
    self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.webView.delegate = self;
    NSString* path = [[NSBundle mainBundle] pathForResource:@"source" ofType:@"html"];
    NSURL* url = [NSURL fileURLWithPath:path];
    NSURLRequest* request = [NSURLRequest requestWithURL:url] ;
    [self.webView loadRequest:request];
    [self.view addSubview:self.webView];
}



#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.jsContext[@"iOS_NativeModel"] = self;
    self.jsContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
        context.exception = exceptionValue;
        NSLog(@"异常信息：%@", exceptionValue);
    };
}
#pragma mark - JSObjcDelegate 
// 为保证交互结果的安全可控
// 在native中执行的相关代码务必放在主线程中执行
- (void)sendMsgToApp:(NSString *)param {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"param:%@",param);
    });
}

#pragma mark - Public
// 通过 JSValue 对象发送消息给 WEB 页面
- (void)sendMessageToWebView:(UIBarButtonItem *)sender {
    JSValue *jsObject = self.jsContext[@"receiveMsgFromApp"];
    NSString *param = [NSString stringWithFormat:@"%@\n%@\n%@\n详细信息：%@",@"商品获取成功",@"商品名称:哈哈",@"商品ID：123456",@"这是商品信息"];
    NSString *callBackStr = [NSString stringWithFormat:@"receiveMsgFromApp(%@)", param ];
    [jsObject callWithArguments:@[callBackStr]];
}

#pragma mark - Private


// 处理 APP 接收 WEB 页面发送来的消息
- (NSString *)stringToDictionary:(NSString *)param {
    NSMutableDictionary *callBack = [NSMutableDictionary new];
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:callBack options:NSJSONWritingPrettyPrinted error:&parseError];
    NSString *result = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"receiveMsgFromApp(%@)", result ];
}

#pragma mark - Getter

#pragma mark - Setter


@end
