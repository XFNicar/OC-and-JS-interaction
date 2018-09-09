//
//  UIWebViewController.h
//  Examples
//
//  Created by YanYi on 2018/9/9.
//  Copyright © 2018年 YanYi. All rights reserved.
//

#import <UIKit/UIKit.h>
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
