
# OC-And-JS-Interaction
相关示例源码[在这里](https://github.com/XFNicar/OC-and-JS-interaction)

## 为什么需要交互
由于原生开发的时间周期相对表较长，难免带来一些更新不灵活的问题，有时候为了业务的需要不得不在原生APP中嵌入一些以Web实现的内容，大部分都是静态页面，一般也不会进行二次跳转，而这些页面有时候也会做一些与原生APP进行交互的功能，这些功能通常需要事先制定相应的协议，这些协议中的方法一般会当做通用的API，方便三端在新的规则出现时不需要反复制定规则，只需要在方法中更改相应的参数即可实现新规则下的交互。

## WKWebView && UIWebView 实现 OC与JS交互
这里分别介绍使用WKWebView 与 UIWebView 实现 OC与JS 交互的方式，以及一些在业务上的个人建议。在代码上这些都是很容易实现的功能，关键点是如何使用这项功能。

### 用WKWebView 实现 OC与JS交互

* **准备工作**
	
	- 1 引入 WebKit 框架
	
```
#import <WebKit/WebKit.h>
@interface WKWebViewController ()
<
WKUIDelegate,
WKNavigationDelegate,
WKScriptMessageHandler	// JS 调用原生需要实现的相关协议
>
@property(nonatomic, strong) WKWebView *webView;
@end

```

	- 2 创建 WKWebView 添加供JS调用的方法名

```
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
```


	- 3  这里需要介绍一下 **WKWebViewConfiguration**，不做深入了解的话可以跳过直接看代码 

	**WKWebView** 初始化时，有一个参数叫**configuration**，它是**WKWebViewConfiguration**类型的参数，而**WKWebViewConfiguration**有一个属性叫**userContentController**，它又是**WKUserContentController**类型的参数。**WKUserContentController**对象有一个方法**- addScriptMessageHandler:name:**，我把这个功能简称为**MessageHandler**。添加**MessageHandler**其实就是添加供**WKWebView** 中 **JS** 调用的对象（**heandle**）和方法名(**name**)。

* **交互逻辑之 JS 调用 OC**

当我们注册了**userContentController**之后，JS 调用iOS原生就会走这个代理，并且会返回**WKScriptMessage**对象**message**，其中**WKScriptMessage**对象的两个属性是我们所需要的，**message.name** 是我们给JS添加的方法名，**message.body** 则是JS给我们发送的参数值，通常我们只需要注册一个方法名，业务逻辑的区分放到body里面来处理，这样可以方便前端与Native制定新的交互规则的时候，不需要维护新的公共API。

```
#pragma mark - WKScriptMessageHandler
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
// webview跳转新页面的时候回调这个方法
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {

}

#pragma mark WKUIDelegate
// webview如果需要调用系统的控件(alert)则会调用这个方法, 如果设置了UIDelegate,没有实现这个方法，WebView的alert就不会弹出来
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OC 调用 JS" message:message preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *action = [UIAlertAction actionWithTitle:@"知道了小肥仔" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    	completionHandler();
	}];
	[alert addAction:action];
	[self presentViewController:alert animated:YES completion:nil];
}
```

* **交互逻辑之 OC 调用 JS**

	这里的代码非常简单，相关的调用只有一行代码: **- evaluateJavaScript:jsStr completionHandler:**
其中**sendMessageToWebView()**是**WebView**公开给Native调用的公共接口，相关的参数转成字符串放到括号内即可，同样的，前端只需要公开一个API，相关的业务逻辑放到参数里面处理就可以了，也是为了减少维护公共API的成本。

```
	// Native 调用 JS
	- (void)sendMessageToWebView:(UIBarButtonItem *)sender {
 		NSString *msg = [NSString stringWithFormat:@"我只是一只小兔几，我什么都不知道。"];
		NSString * result = [self noWhiteSpaceString:msg];
		// sendMessageToWebView
		NSString * jsStr = [NSString stringWithFormat:@"sendMessageToWebView(\"%@\")",result];
		[self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable result, NSError * _Nullable error) {
    		NSLog(@"交互错误value :%@ error: %@",result,error);
		}];
	}
```

### 用 UIWebView 实现 OC 与 JS 交互

* 准备工作

自然是创建**UIWebView**并设置代理了

```
self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
self.webView.delegate = self;
NSString* path = [[NSBundle mainBundle] pathForResource:@"source" ofType:@"html"];
NSURL* url = [NSURL fileURLWithPath:path];
NSURLRequest* request = [NSURLRequest requestWithURL:url] ;
[self.webView loadRequest:request];
[self.view addSubview:self.webView];
```

* 遵守协议

在该协议中，定义供JS调用的方法，建议设置为一个通用接口，方便JS调用

```
#import <JavaScriptCore/JavaScriptCore.h>
@protocol JSObjcDelegate <JSExport>
/**
前端调用Native
此API用来供前端（H5）调用，
为了方便制定调用的协议，
此API应该设计成通用API，
其中所涉及的场景应该由参数来决定，
不应设计过多的API
同理前端也应该只需设计一个API供Native调用

@param param 调用参数
*/
- (void)sendMsgToApp:(NSString *)param;
	
@end

@interface UIWebViewController : UIViewController<UIWebViewDelegate,JSObjcDelegate>

@property (nonatomic, strong) JSContext *jsContext;
@property (strong, nonatomic)  UIWebView *webView;

@end
```

* 实现协议方法，并向JSContext注册对象

所谓注册对象，就是告诉JS该调用谁的什么方法,总体来说也就是以下三行代码，只不过根据每个公司前端所写的业务不同，注入时机可能会有所区别，正常来说都是WebView通知Native在合适的时机注入即可，其中的区别我[写在这里]()了。

```
#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView {
	self.jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
	// 将JS中的iOS_NativeModel对象（JS中定义为什么名称就是什么名称）设置为当前控制器，JS才可以调用当前控制器所遵守协议中的方法
	self.jsContext[@"iOS_NativeModel"] = self;
	self.jsContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
		context.exception = exceptionValue;
    	NSLog(@"异常信息：%@", exceptionValue);
	};
}
```

* JS 调用 Native

这里就是在WebView所在的控制器实现之前的协议中的方法即可，JS调用协议中的方法就会来到方法的具体实现，PS：JS所传值为字符串，需要根据相关业务参数看是否需要转化为JSON或其他对象

```
#pragma mark - JSObjcDelegate 
// 为保证交互结果的安全可控
// 在native中执行的相关代码务必放在主线程中执行
- (void)sendMsgToApp:(NSString *)param {
	dispatch_async(dispatch_get_main_queue(), ^{
    	NSLog(@"param:%@",param);
	});
}
```

* OC 调用 JS

这里比**WKWebView**稍微复杂一些，但是基本原理是一样的，**UIWebView**这里使用**JSValue**对象来实现，设置所调用的JS函数与参数与**WKWebView**是一样的。

```
#pragma mark - Public
// 通过 JSValue 对象发送消息给 WEB 页面
- (void)sendMessageToWebView:(UIBarButtonItem *)sender {
	JSValue *jsObject = self.jsContext[@"receiveMsgFromApp"];
	NSString *param = [NSString stringWithFormat:@"%@\n%@\n%@\n详细信息：%@",@"商品获取成功",@"商品名称:哈哈",@"商品ID：123456",@"这是商品信息"];
	NSString *callBackStr = [NSString stringWithFormat:@"receiveMsgFromApp(%@)", param ];
	[jsObject callWithArguments:@[callBackStr]];
}
```

## OC与JS交互的简单介绍就到此未知了，如需深入了解，请关注我的其他文章