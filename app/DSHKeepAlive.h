//
//  DSHKeepAlive.h
//  DSH
//
//  静音保活：后台循环播放一段无声音频，让 iOS 不挂起 App，
//  从而 guest 模拟器与 dsh web 服务持续存活——回到前台即热恢复（秒开）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const DSHKeepAliveDidChangeNotification;

@interface DSHKeepAlive : NSObject

+ (instancetype)shared;

/// 当前是否启用（NSUserDefaults 持久化，默认 YES）
@property (nonatomic, readonly, getter=isKeepAliveEnabled) BOOL keepAliveEnabled;

/// 启动/停止静音保活（尊重用户开关；后台时才真正持有音频会话）
- (void)apply;

/// 设置开关并立即生效
- (void)setEnabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
