//
//  PathListTableViewController.h
//  CommonViewControllers
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/20.
//  Copyright © 2022 Zheng Wu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PathListTableViewController : UITableViewController

- (instancetype)initWithPath:(NSString *)path;
@property (nonatomic, copy, readonly) NSString *entryPath;

- (instancetype)initWithContents:(NSArray <NSString *> *)contents;
@property (nonatomic, strong, readonly) NSArray <NSString *> *contents;

@property (nonatomic, assign) CGFloat indentationWidth;
@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, assign, getter=isStriped) BOOL striped;
@property (nonatomic, assign) BOOL pullToReload;
@property (nonatomic, assign) BOOL tapToCopy;
@property (nonatomic, assign) BOOL pressToCopy;
@property (nonatomic, assign) BOOL showFullPath;
@property (nonatomic, assign) BOOL allowSearch;

@end

NS_ASSUME_NONNULL_END
