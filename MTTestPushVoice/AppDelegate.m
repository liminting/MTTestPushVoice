//
//  AppDelegate.m
//  MTTestPushVoice
//
//  Created by kerwin on 2017/2/22.
//  Copyright © 2017年 TL. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "GeTuiSdk.h"
// 个推 速配货
#define kGtAppId           @"EkWJE5yMHc7ynGzHlKQxf5"
#define kGtAppKey          @"8igGIKbnCqAXT9wJBTuJ"
#define kGtAppSecret       @"5mfgBqe8kp7MAv8X3E3XD8"

@interface AppDelegate ()<GeTuiSdkDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [self registerUserNotification];
    NSError *error = NULL;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    if(error) {
        // Do some error handling
    }
    [session setActive:YES error:&error];
    if (error) {
        // Do some error handling
    }
    //让app支持接受远程控制事件
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    return YES;
}
#pragma mark - 用户通知(推送) _自定义方法

/** 注册用户通知 */
- (void)registerUserNotification {
    
    // 通过 appId、 appKey 、appSecret 启动SDK，注：该方法需要在主线程中调用
    [GeTuiSdk runBackgroundEnable:YES];
    [GeTuiSdk startSdkWithAppId:kGtAppId appKey:kGtAppKey appSecret:kGtAppSecret delegate:self];
    
    /*
     注册通知(推送)
     申请App需要接受来自服务商提供推送消息
     */
    
    // 判读系统版本是否是“iOS 8.0”以上
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 ||
        [UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        
        // 定义用户通知类型(Remote.远程 - Badge.标记 Alert.提示 Sound.声音)
        UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        
        // 定义用户通知设置
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        
        // 注册用户通知 - 根据用户通知设置
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else { // iOS8.0 以前远程推送设置方式
        // 定义远程通知类型(Remote.远程 - Badge.标记 Alert.提示 Sound.声音)
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        
        // 注册远程通知 -根据远程通知类型
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
    }
}

#pragma mark - 用户通知(推送)回调 _IOS 8.0以上使用

/** 已登记用户通知 */
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    // 注册远程通知（推送）
    [application registerForRemoteNotifications];
}

#pragma mark - 远程通知(推送)回调
/** 远程通知注册成功委托 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"\n>>>[DeviceToken Success]:%@\n\n", token);
    
    // [3]:向个推服务器注册deviceToken
    [GeTuiSdk registerDeviceToken:token];

}

/** 远程通知注册失败委托 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"\n>>>[DeviceToken Error]:%@\n\n", error.description);
}

#pragma mark - APP运行中接收到通知(推送)处理

/** APP已经接收到“远程”通知(推送) - (App运行在后台/App运行在前台) */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    application.applicationIconBadgeNumber = 0; // 标签
    NSLog(@"\n>>>[Receive RemoteNotification]:%@\n\n", userInfo);
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:( UILocalNotification *)notification
{
    application.applicationIconBadgeNumber = 0; // 标签
}
/** APP已经接收到“远程”通知(推送) - 透传推送消息  */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    
    NSLog(@"remote: %@", userInfo);
    
    //回调
    
    completionHandler(UIBackgroundFetchResultNewData);
    
    //语音播报
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@"Kerwin恭喜您成功实现推送语音播报"];
    
    AVSpeechSynthesizer *synth = [[AVSpeechSynthesizer alloc] init];
    
    [synth speakUtterance:utterance];

}

#pragma mark - GeTuiSdkDelegate

/** SDK启动成功返回cid */
- (void)GeTuiSdkDidRegisterClient:(NSString *)clientId {
    // [4-EXT-1]: 个推SDK已注册，返回clientId
    NSLog(@"\n>>>[GeTuiSdk RegisterClient]:%@\n\n", clientId);
}

/** SDK遇到错误回调 */
- (void)GeTuiSdkDidOccurError:(NSError *)error {
    // [EXT]:个推错误报告，集成步骤发生的任何错误都在这里通知，如果集成后，无法正常收到消息，查看这里的通知。
    NSLog(@"\n>>>[GexinSdk error]:%@\n\n", [error localizedDescription]);
}
/** SDK收到透传消息回调 */
- (void)GeTuiSdkDidReceivePayloadData:(NSData *)payloadData andTaskId:(NSString *)taskId andMsgId:(NSString *)msgId andOffLine:(BOOL)offLine fromGtAppId:(NSString *)appId {
    
    // [4]: 收到个推消息
    NSString *payloadMsg = nil;
    if (payloadData) {
        payloadMsg = [[NSString alloc] initWithBytes:payloadData.bytes length:payloadData.length encoding:NSUTF8StringEncoding];
    }
    
    NSString *msg = [NSString stringWithFormat:@"taskId=%@,messageId:%@,payloadMsg:%@%@", taskId, msgId, payloadMsg, offLine ? @"<离线消息>" : @""];
    NSLog(@"\n>>>[GexinSdk ReceivePayload]:%@\n\n", msg);
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    //localNotification.userInfo = userinfo;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    if (msg.length) {
        localNotification.alertBody = msg;
    }else{
        localNotification.alertBody = payloadMsg;
    }
    localNotification.fireDate = [NSDate date];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
}

/** SDK收到sendMessage消息回调 */
- (void)GeTuiSdkDidSendMessage:(NSString *)messageId result:(int)result {
    // [4-EXT]:发送上行消息结果反馈
    NSString *msg = [NSString stringWithFormat:@"sendmessage=%@,result=%d", messageId, result];
    NSLog(@"\n>>>[GexinSdk DidSendMessage]:%@\n\n", msg);
}

/** SDK运行状态通知 */
- (void)GeTuiSDkDidNotifySdkState:(SdkStatus)aStatus {
    // [EXT]:通知SDK运行状态
    NSLog(@"\n>>>[GexinSdk SdkState]:%u\n\n", aStatus);
}

/** SDK设置推送模式回调 */
- (void)GeTuiSdkDidSetPushMode:(BOOL)isModeOff error:(NSError *)error {
    if (error) {
        NSLog(@"\n>>>[GexinSdk SetModeOff Error]:%@\n\n", [error localizedDescription]);
        return;
    }
    
    NSLog(@"\n>>>[GexinSdk SetModeOff]:%@\n\n", isModeOff ? @"开启" : @"关闭");
}




- (void)applicationWillResignActive:(UIApplication *)application {
}
- (void)applicationDidEnterBackground:(UIApplication *)application {
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
}
- (void)applicationWillTerminate:(UIApplication *)application {
}


@end
