//
//  ExamplesListViewController.m
//  Examples
//
//  Created by YanYi on 2018/9/9.
//  Copyright © 2018年 YanYi. All rights reserved.
//

#import "ExamplesListViewController.h"
#import "WKWebViewController.h"
#import "UIWebViewController.h"

@interface ExamplesListViewController ()

@property (nonatomic, strong) NSMutableArray        *dataSource;

@end

@implementation ExamplesListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"代码示例";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"examplesId"];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"examplesId" forIndexPath:indexPath];
    cell.textLabel.text = self.dataSource[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        UIWebViewController *webVC = [UIWebViewController new];
        [self.navigationController pushViewController:webVC animated:YES];
    }
    if (indexPath.row == 1) {
        WKWebViewController *webVC = [WKWebViewController new];
        [self.navigationController pushViewController:webVC animated:YES];
    }
    
}

- (NSMutableArray *)dataSource {
    if (_dataSource == nil) {
        NSArray *array = @[@"UIWebView实现OC与JS交互",@"WKWebView实现OC与JS交互"];
        _dataSource = [[NSMutableArray alloc]initWithArray:array];
    }
    return _dataSource;
}

@end
