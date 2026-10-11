//
//  DSHSidebarViewController.h
//  DSH
//
//  原生侧栏面板（半屏抽屉）：状态、保活开关、工具入口、维护操作。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DSHSidebarViewController : UITableViewController

/// actions key: reload / terminal / capabilities / activity / log / restart / repair
- (instancetype)initWithActions:(NSDictionary<NSString *, void (^)(void)> *)actions;

@end

NS_ASSUME_NONNULL_END
