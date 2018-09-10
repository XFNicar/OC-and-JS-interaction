

# OC-and-JS-interaction

相关示例源码[在这里](https://github.com/XFNicar/OC-and-JS-interaction)

## 为什么需要交互


由于原生开发的时间周期相对表较长，难免带来一些更新不灵活的问题，有时候为了业务的需要不得不在原生APP中嵌入一些以Web实现的内容，大部分都是静态页面，一般也不会进行二次跳转，而这些页面有时候也会做一些与原生APP进行交互的功能，这些功能通常需要事先制定相应的协议，这些协议中的方法一般会当做通用的API，方便三端在新的规则出现时不需要反复制定规则，只需要在方法中更改相应的参数即可实现新规则下的交互。



## WKWebView && UIWebView 实现 OC与JS交互 

这里分别介绍使用WKWebView 与 UIWebView 实现 OC与JS 交互的方式，以及一些在业务上的个人建议。在代码上这些都是很容易实现的功能，关键点是如何使用这项功能。

### 用WKWebView 实现 OC与JS交互 

* 准备工作 
	* 1 **引入 WebKit 框架**
		
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
	
	* 2 **创建 WKWebView 添加供JS调用的方法名**

			
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

- 这里需要介绍一下 **WKWebViewConfiguration**， 不做深入了解的话可以跳过直接看代码 
		
	**WKWebView** 初始化时，有一个参数叫**configuration**，它是**WKWebViewConfiguration**类型的参数，而**WKWebViewConfiguration**有一个属性叫**userContentController**，它又是**WKUserContentController**类型的参数。**WKUserContentController**对象有一个方法**- addScriptMessageHandler:name:**，我把这个功能简称为**MessageHandler**。
添加**MessageHandler**其实就是添加供**WKWebView** 中 **JS** 调用的对象（**heandle**）和方法名(**name**)。

* 交互逻辑之 JS 调用 OC
		
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


*  交互逻辑之 OC 调用 JS

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