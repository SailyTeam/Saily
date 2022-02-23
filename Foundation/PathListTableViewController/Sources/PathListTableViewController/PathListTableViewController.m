//
//  PathListTableViewController.m
//  CommonViewControllers
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/20.
//  Copyright © 2022 Zheng Wu. All rights reserved.
//

#import "PathListTableViewController.h"

@interface PathListTableViewController () <UISearchResultsUpdating>

@property (nonatomic, strong) NSArray <NSString *> *filteredContents;
@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation PathListTableViewController
@synthesize entryPath = _entryPath;
@synthesize contents = _contents;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Path List Viewer", @"");
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _indentationWidth = 14.0;
        _rowHeight = 26.0;
        _entryPath = path;
        [self setupWithPath];
    }
    return self;
}

- (instancetype)initWithContents:(NSArray<NSString *> *)contents {
    if (self = [super init]) {
        _indentationWidth = 14.0;
        _rowHeight = 26.0;
        _contents = contents;
        [self setupWithContents:NO];
    }
    return self;
}

- (void)setupWithPath {
    NSData *contentsData = [NSData dataWithContentsOfFile:_entryPath];
    if (!contentsData) return;
    NSString *contentsString = [[NSString alloc] initWithData:contentsData encoding:NSUTF8StringEncoding];
    if (!contentsString) return;
    NSMutableArray <NSString *> *contents = [[contentsString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
    [contents removeObject:@""];
    _contents = [contents copy];
    [self setupWithContents:NO];
}

- (void)setupWithContents:(BOOL)isFiltered {
    NSMutableArray <NSString *> *mContents = [(isFiltered ? _filteredContents : _contents) mutableCopy];
    for (NSString *contentPath in (isFiltered ? _filteredContents : _contents)) {
        NSMutableArray <NSString *> *contentComponents = [[contentPath pathComponents] mutableCopy];
        if ([contentComponents count] == 0) {
            continue;
        }
        do {
            [contentComponents removeLastObject];
            if ([contentComponents count] == 0) {
                break;
            }
            NSString *testPath = [NSString pathWithComponents:contentComponents];
            if (![mContents containsObject:testPath]) {
                [mContents addObject:testPath];
            }
        } while ([contentComponents count] > 0);
    }
    [mContents removeObjectsInArray:@[@"", @"/"]];
    [mContents sortUsingSelector:@selector(localizedCompare:)];
    if (isFiltered) {
        _filteredContents = [mContents copy];
    } else {
        _contents = [mContents copy];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.title.length == 0) {
        if (self.entryPath) {
            NSString *entryName = [self.entryPath lastPathComponent];
            self.title = entryName;
        } else {
            self.title = [[self class] viewerName];
        }
    }

    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.searchController = ({
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.searchResultsUpdater = self;
        searchController.obscuresBackgroundDuringPresentation = NO;
        searchController.hidesNavigationBarDuringPresentation = YES;
        searchController;
    });

    if (self.pullToReload && self.entryPath) {
        self.refreshControl = ({
            UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
            [refreshControl addTarget:self action:@selector(reloadDataFromEntry:) forControlEvents:UIControlEventValueChanged];
            refreshControl;
        });
    }

    if (self.allowSearch) {
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
        self.navigationItem.searchController = self.searchController;
    }

    [self.tableView setSeparatorInset:UIEdgeInsetsZero];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ContentCell"];
}

- (void)reloadDataFromEntry:(UIRefreshControl *)sender {
    if ([self.searchController isActive]) {
        return;
    }
    [self loadDataFromEntry];
    if ([sender isRefreshing]) {
        [sender endRefreshing];
    }
}

- (void)loadDataFromEntry {
    [self setupWithPath];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchController.isActive ? self.filteredContents.count : self.contents.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *rowText = self.searchController.isActive ? self.filteredContents[indexPath.row] : self.contents[indexPath.row];
    return MAX([[rowText pathComponents] count] - 1, 0);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return self.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ContentCell" forIndexPath:indexPath];
    cell.indentationWidth = self.indentationWidth;

    NSString *rowText = [(self.searchController.isActive ? self.filteredContents[indexPath.row] : self.contents[indexPath.row]) lastPathComponent];

    NSString *searchContent = self.searchController.isActive ? self.searchController.searchBar.text : nil;

    NSDictionary *rowAttrs = @{ NSFontAttributeName: [UIFont fontWithName:@"Courier" size:14.0], NSForegroundColorAttributeName: [UIColor labelColor] };

    NSMutableAttributedString *mRowText = [[NSMutableAttributedString alloc] initWithString:rowText attributes:rowAttrs];
    if (searchContent) {
        NSRange searchRange = [rowText rangeOfString:searchContent options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch range:NSMakeRange(0, rowText.length)];
        if (searchRange.location != NSNotFound) {
            [mRowText addAttributes:@{
                 NSForegroundColorAttributeName: [UIColor colorWithDynamicProvider:^UIColor *_Nonnull (UITraitCollection *_Nonnull traitCollection) {
                                                      if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                                                          return [UIColor systemBackgroundColor];
                                                      } else {
                                                          return [UIColor labelColor];
                                                      }
                                                  }],
                 NSBackgroundColorAttributeName: [UIColor colorWithRed:253.0/255.0 green:247.0/255.0 blue:148.0/255.0 alpha:1.0],
             } range:searchRange];
        }
    }

    [cell.textLabel setAttributedText:mRowText];
    [cell.textLabel setNumberOfLines:1];

    if (self.isStriped) {
        if (indexPath.row % 2 == 0) {
            [cell setBackgroundColor:[UIColor systemBackgroundColor]];
        } else {
            [cell setBackgroundColor:[UIColor secondarySystemBackgroundColor]];
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.tapToCopy) {
        NSString *content = (self.searchController.isActive ? self.filteredContents[indexPath.row] : self.contents[indexPath.row]);
        [[UIPasteboard generalPasteboard] setString:content];
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
    if (self.pressToCopy) {
        NSString *content = (self.searchController.isActive ? self.filteredContents[indexPath.row] : self.contents[indexPath.row]);
        NSArray <UIAction *> *cellActions = @[
            [UIAction actionWithTitle:@"Copy Name" image:[UIImage systemImageNamed:@"doc.on.doc"] identifier:nil handler:^(__kindof UIAction *_Nonnull action) {
                 [[UIPasteboard generalPasteboard] setString:[content lastPathComponent]];
             }],
            [UIAction actionWithTitle:@"Copy Path" image:[UIImage systemImageNamed:@"doc.on.clipboard"] identifier:nil handler:^(__kindof UIAction *_Nonnull action) {
                 [[UIPasteboard generalPasteboard] setString:content];
             }],
        ];
        return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu *_Nullable (NSArray<UIMenuElement *> *_Nonnull suggestedActions) {
                    UIMenu *menu = [UIMenu menuWithTitle:(self.showFullPath ? content : @"") children:cellActions];
                    return menu;
                }];
    }
    return nil;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *text = self.searchController.searchBar.text;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastPathComponent CONTAINS[cd] %@", text];
    if (predicate) {
        self.filteredContents = [self.contents filteredArrayUsingPredicate:predicate];
        [self setupWithContents:YES];
    }
    [self.tableView reloadData];
}

#pragma mark -

- (void)dealloc {
#if DEBUG
    NSLog(@"-[%@ dealloc]", [self class]);
#endif
}

@end
