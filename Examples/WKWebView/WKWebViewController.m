//
//  WKWebViewController.m
//  Examples
//
//  Created by YanYi on 2018/9/9.
//  Copyright © 2018年 YanYi. All rights reserved.
//

#import "WKWebViewController.h"
#import <WebKit/WebKit.h>

@interface WKWebViewController ()
<
WKUIDelegate,
WKNavigationDelegate,
WKScriptMessageHandler
>

@property(nonatomic, strong) WKWebView *webView;

@end

@implementation WKWebViewController


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
    self.edgesForExtendedLayout = NO;
    [self UIConfig];
    NSString* path = [[NSBundle mainBundle] pathForResource:@"source" ofType:@"html"];
    NSURL* url = [NSURL fileURLWithPath:path];
    NSURLRequest* request = [NSURLRequest requestWithURL:url] ;
    [self.webView loadRequest:request];
}



#pragma mark - UITableViewDelegate

- (void)UIConfig {
    
    [self.view addSubview:self.webView];
    if (@available(iOS 11, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
}



/**
 此处接收并处理来自 JS 的调用
 可以根据message.name 来区分调用的是哪个方法 ，
 建议只设计一个通用方法来供JS调用
 然后根据参数值 message.body 来区分如何处理调用逻辑
 也可以根据  参数值来区分如何处理调用事件
 @param userContentController 控制器
 @param message ：
                message.name (方法名)
                message.body (参数)
 */
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"sendMsgToApp"]) {
        [self sendMsgToApp:message];
    }
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
}



#pragma mark WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OC 调用 JS" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"知道了小肥仔" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}




#pragma mark - Public
// 处理 JS 调用 Native 的参数
- (void)sendMsgToApp:(WKScriptMessage *)message  {
    NSDictionary *dict = [self parseJSONStringToNSDictionary:message.body];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"%@",dict);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"JS 调用 OC" message:@"你只是一只小兔几，你什么都不知道" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"嗯嗯嗯，我知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

// Native 调用 JS
- (void)sendMessageToWebView:(UIBarButtonItem *)sender {
    NSString *msg = [NSString stringWithFormat:@"我只是一只小兔几，我什么都不知道。"];
    NSString * result = [self noWhiteSpaceString:msg];
    NSString * jsStr = [NSString stringWithFormat:@"sendMessageToWebView(\"%@\")",result];
    [self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSLog(@"交互错误value :%@ error: %@",result,error);
    }];
}

- (NSDictionary *)parseJSONStringToNSDictionary:(NSString *)JSONString {
    NSData *JSONData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingMutableLeaves error:nil];
    return responseJSON;
}

// 去掉空格换行符等
- (NSString *)noWhiteSpaceString:(NSString *)str {
    NSString *newString = str;
    // 去除掉首尾的空白字符和换行字符
    newString = [newString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    newString = [newString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    newString = [newString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // 去除掉首尾的空白字符和换行字符使用
    newString = [newString stringByReplacingOccurrencesOfString:@" " withString:@""];
    return newString;
}

#pragma mark - Private

#pragma mark - Getter
- (WKWebView *)webView {
    if (_webView == nil) {
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.preferences = [[WKPreferences alloc] init];
        config.preferences.minimumFontSize = 10;
        config.preferences.javaScriptEnabled = YES;
        config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
        config.userContentController = [[WKUserContentController alloc] init];
        config.processPool = [[WKProcessPool alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:config];
        _webView.UIDelegate = self;
        _webView.navigationDelegate = self;
        _webView.frame = self.view.bounds;
        [config.userContentController addScriptMessageHandler:self name:@"sendMsgToApp"];
    }
    return _webView;
}


#pragma mark - Setter


@end
