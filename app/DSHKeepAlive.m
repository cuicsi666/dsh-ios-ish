//
//  DSHKeepAlive.m
//  DSH
//

#import "DSHKeepAlive.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NSNotificationName const DSHKeepAliveDidChangeNotification = @"DSHKeepAliveDidChangeNotification";

static NSString *const kKeepAliveEnabled = @"DSHKeepAliveEnabled";

@interface DSHKeepAlive () <AVAudioPlayerDelegate>
@property (nonatomic, strong, nullable) AVAudioPlayer *player;
@property (nonatomic, assign) BOOL appInBackground;
@end

@implementation DSHKeepAlive

+ (instancetype)shared {
    static DSHKeepAlive *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [DSHKeepAlive new]; });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _appInBackground = NO;
        if ([NSUserDefaults.standardUserDefaults objectForKey:kKeepAliveEnabled] == nil) {
            [NSUserDefaults.standardUserDefaults setBool:YES forKey:kKeepAliveEnabled];
        }
        NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
        [nc addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [nc addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (BOOL)isKeepAliveEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:kKeepAliveEnabled];
}

- (void)setEnabled:(BOOL)enabled {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kKeepAliveEnabled];
    [self apply];
    [NSNotificationCenter.defaultCenter postNotificationName:DSHKeepAliveDidChangeNotification object:nil];
}

- (void)appDidEnterBackground {
    self.appInBackground = YES;
    [self apply];
}

- (void)appWillEnterForeground {
    self.appInBackground = NO;
    [self apply];
}

- (void)apply {
    if (!self.keepAliveEnabled || !self.appInBackground) {
        // 前台无需保活；关闭时停播并释放会话
        [self stopPlaying];
        return;
    }
    [self startPlaying];
}

- (void)startPlaying {
    if (self.player && self.player.isPlaying) return;

    NSError *sessionErr = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault options:0 error:&sessionErr];
    [session setActive:YES error:nil];

    NSURL *url = [NSBundle.mainBundle URLForResource:@"silence" withExtension:@"wav"];
    if (!url) {
        NSLog(@"[KeepAlive] silence.wav 缺失");
        return;
    }
    NSError *err = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    if (!player) {
        NSLog(@"[KeepAlive] player init failed: %@", err);
        return;
    }
    player.numberOfLoops = -1;   // 无限循环
    player.volume = 0.0001f;     // 静音（非 0，保证音频管线活跃）
    player.delegate = self;
    self.player = player;
    [player play];
    NSLog(@"[KeepAlive] started (background silent playback)");
}

- (void)stopPlaying {
    if (!self.player) return;
    [self.player stop];
    self.player = nil;
    [AVAudioSession.sharedInstance setActive:NO
                                  withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                        error:nil];
    NSLog(@"[KeepAlive] stopped");
}

// 音频中断（来电等）后，若仍在后台且开关开启则恢复
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(AVAudioSessionInterruptionOptions)options {
    if ((options & AVAudioSessionInterruptionOptionShouldResume) && self.appInBackground && self.keepAliveEnabled) {
        [player play];
    }
}

@end
