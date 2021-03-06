//
//  LeanChatMessageTableViewController.m
//  MessageDisplayKitLeanchatExample
//
//  Created by Jack_iMac on 15/3/21.
//  Copyright (c) 2015年 iOS软件开发工程师 曾宪华 热衷于简洁的UI QQ:543413507 http://www.pailixiu.com/blog   http://www.pailixiu.com/Jack/personal. All rights reserved.
//

#import "LeanChatMessageTableViewController.h"
#import <MessageDisplayKit/XHDisplayTextViewController.h>
#import <MessageDisplayKit/XHDisplayMediaViewController.h>
#import <MessageDisplayKit/XHDisplayLocationViewController.h>

#import <MessageDisplayKit/XHAudioPlayerHelper.h>

// IM
#import "LeanChatManager.h"

@interface LeanChatMessageTableViewController () <XHAudioPlayerHelperDelegate>

@property (nonatomic, strong) NSArray *emotionManagers;

@property (nonatomic, strong) XHMessageTableViewCell *currentSelectedCell;

@property (nonatomic, strong) AVIMConversation *conversation;

@property (nonatomic, strong) NSArray *clientIDs;

@property (nonatomic, assign) ConversationType conversationType;

@end

@implementation LeanChatMessageTableViewController

- (instancetype)initWithClientIDs:(NSArray *)clientIDs {
    self = [super init];
    if (self) {
        self.clientIDs = clientIDs;
        if (self.clientIDs.count > 1) {
            self.conversationType = ConversationTypeGrop;
        }
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[XHAudioPlayerHelper shareInstance] stopAudio];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = NSLocalizedStringFromTable(@"Chat", @"MessageDisplayKitString", @"聊天");
    
    // Custom UI
//    [self setBackgroundColor:[UIColor clearColor]];
//    [self setBackgroundImage:[UIImage imageNamed:@"TableViewBackgroundImage"]];
    
    // 设置自身用户名
    self.messageSender = kDarcyClientID;
    
    // 添加第三方接入数据
    NSMutableArray *shareMenuItems = [NSMutableArray array];
    NSArray *plugIcons = @[@"sharemore_pic", @"sharemore_video", @"sharemore_location", @"sharemore_friendcard", @"sharemore_myfav", @"sharemore_wxtalk", @"sharemore_videovoip", @"sharemore_voiceinput", @"sharemore_openapi", @"sharemore_openapi", @"avatar"];
    NSArray *plugTitle = @[@"照片", @"拍摄", @"位置", @"名片", @"我的收藏", @"实时对讲机", @"视频聊天", @"语音输入", @"大众点评", @"应用", @"曾宪华"];
    for (NSString *plugIcon in plugIcons) {
        XHShareMenuItem *shareMenuItem = [[XHShareMenuItem alloc] initWithNormalIconImage:[UIImage imageNamed:plugIcon] title:[plugTitle objectAtIndex:[plugIcons indexOfObject:plugIcon]]];
        [shareMenuItems addObject:shareMenuItem];
    }
    
    NSMutableArray *emotionManagers = [NSMutableArray array];
    for (NSInteger i = 0; i < 10; i ++) {
        XHEmotionManager *emotionManager = [[XHEmotionManager alloc] init];
        emotionManager.emotionName = [NSString stringWithFormat:@"表情%ld", (long)i];
        NSMutableArray *emotions = [NSMutableArray array];
        for (NSInteger j = 0; j < 18; j ++) {
            XHEmotion *emotion = [[XHEmotion alloc] init];
            NSString *imageName = [NSString stringWithFormat:@"section%ld_emotion%ld", (long)i , (long)j % 16];
            emotion.emotionPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"emotion%ld.gif", (long)j] ofType:@""];
            emotion.emotionConverPhoto = [UIImage imageNamed:imageName];
            [emotions addObject:emotion];
        }
        emotionManager.emotions = emotions;
        
        [emotionManagers addObject:emotionManager];
    }
    
    self.emotionManagers = emotionManagers;
    [self.emotionManagerView reloadData];
    
    self.shareMenuItems = shareMenuItems;
    [self.shareMenuView reloadData];
    
    // 创建一个对话
    [[LeanChatManager manager] createConversationsWithClientIDs:self.clientIDs conversationType:self.conversationType completion:^(BOOL succeeded, AVIMConversation *createConversation) {
        if (succeeded) {
            self.conversation = createConversation;
        }
    }];
    
    // 设置接收消息
    [[LeanChatManager manager] setupDidReceiveCommonMessageCompletion:^(AVIMMessage *message) {
        // 普通信息
        [self insertAVIMTextMessage:message];
    }];
    [[LeanChatManager manager] setupDidReceiveTypedMessageCompletion:^(AVIMTypedMessage *message) {
        // 富文本信息
        [self insertAVIMTextMessage:message];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    self.emotionManagers = nil;
    [[XHAudioPlayerHelper shareInstance] setDelegate:nil];
}


#pragma mark - LearnChat Message Handle Method

- (void)sendTextMessage:(XHMessage *)textMessage {
    AVIMTextMessage *sendTextMessage = [AVIMTextMessage messageWithText:textMessage.text attributes:nil];
    [self.conversation sendMessage:sendTextMessage options:AVIMMessageSendOptionNone callback:^(BOOL succeeded, NSError *error) {
        
    }];
}

- (void)sendPhotoMessage:(XHMessage *)photoMessage {
    UIImage *photo = photoMessage.photo;
    NSString *filePaht = [[NSBundle mainBundle] pathForResource:@"TableViewBackgroundImage" ofType:@"png"];
    AVIMImageMessage *sendPhotoMessage = [AVIMImageMessage messageWithText:nil attachedFilePath:filePaht attributes:nil];
    [self.conversation sendMessage:sendPhotoMessage callback:^(BOOL succeeded, NSError *error) {
        
    }];
}

- (void)insertAVIMTextMessage:(AVIMTypedMessage *)receiveMessage {
    AVIMMessageMediaType msgType = receiveMessage.mediaType;
    switch (msgType) {
        case kAVIMMessageMediaTypeText: {
            AVIMTextMessage *receiveTextMessage = (AVIMTextMessage *)receiveMessage;
            XHMessage *textMessage = [[XHMessage alloc] initWithText:receiveTextMessage.text sender:receiveMessage.clientId timestamp:[NSDate date]];
            textMessage.bubbleMessageType = XHBubbleMessageTypeReceiving;
            textMessage.avatar = [UIImage imageNamed:@"Avatar"];
            textMessage.avatarUrl = @"http://www.pailixiu.com/jack/meIcon@2x.png";
            [self addMessage:textMessage];
            [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeText];
            
            break;
        }
        case kAVIMMessageMediaTypeImage: {
            AVIMImageMessage *imageMessage = (AVIMImageMessage *)receiveMessage;
            XHMessage *textMessage = [[XHMessage alloc] initWithPhoto:nil thumbnailUrl:imageMessage.file.url originPhotoUrl:nil sender:imageMessage.clientId timestamp:[NSDate date]];
            textMessage.bubbleMessageType = XHBubbleMessageTypeReceiving;
            textMessage.avatar = [UIImage imageNamed:@"Avatar"];
            textMessage.avatarUrl = @"http://www.pailixiu.com/jack/meIcon@2x.png";
            [self addMessage:textMessage];
            [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeText];
            break;
        }
        default:
            break;
    }
}

/*
 [self removeMessageAtIndexPath:indexPath];
 [self insertOldMessages:self.messages];
 */

#pragma mark - XHMessageTableViewCell delegate

- (void)multiMediaMessageDidSelectedOnMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath onMessageTableViewCell:(XHMessageTableViewCell *)messageTableViewCell {
    UIViewController *disPlayViewController;
    switch (message.messageMediaType) {
        case XHBubbleMessageMediaTypeVideo:
        case XHBubbleMessageMediaTypePhoto: {
            DLog(@"message : %@", message.photo);
            DLog(@"message : %@", message.videoConverPhoto);
            XHDisplayMediaViewController *messageDisplayTextView = [[XHDisplayMediaViewController alloc] init];
            messageDisplayTextView.message = message;
            disPlayViewController = messageDisplayTextView;
            break;
        }
            break;
        case XHBubbleMessageMediaTypeVoice: {
            DLog(@"message : %@", message.voicePath);
            
            // Mark the voice as read and hide the red dot.
            message.isRead = YES;
            messageTableViewCell.messageBubbleView.voiceUnreadDotImageView.hidden = YES;
            
            [[XHAudioPlayerHelper shareInstance] setDelegate:(id<NSFileManagerDelegate>)self];
            if (_currentSelectedCell) {
                [_currentSelectedCell.messageBubbleView.animationVoiceImageView stopAnimating];
            }
            if (_currentSelectedCell == messageTableViewCell) {
                [messageTableViewCell.messageBubbleView.animationVoiceImageView stopAnimating];
                [[XHAudioPlayerHelper shareInstance] stopAudio];
                self.currentSelectedCell = nil;
            } else {
                self.currentSelectedCell = messageTableViewCell;
                [messageTableViewCell.messageBubbleView.animationVoiceImageView startAnimating];
                [[XHAudioPlayerHelper shareInstance] managerAudioWithFileName:message.voicePath toPlay:YES];
            }
            break;
        }
        case XHBubbleMessageMediaTypeEmotion:
            DLog(@"facePath : %@", message.emotionPath);
            break;
        case XHBubbleMessageMediaTypeLocalPosition: {
            DLog(@"facePath : %@", message.localPositionPhoto);
            XHDisplayLocationViewController *displayLocationViewController = [[XHDisplayLocationViewController alloc] init];
            displayLocationViewController.message = message;
            disPlayViewController = displayLocationViewController;
            break;
        }
        default:
            break;
    }
    if (disPlayViewController) {
        [self.navigationController pushViewController:disPlayViewController animated:YES];
    }
}

- (void)didDoubleSelectedOnTextMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath {
    DLog(@"text : %@", message.text);
    XHDisplayTextViewController *displayTextViewController = [[XHDisplayTextViewController alloc] init];
    displayTextViewController.message = message;
    [self.navigationController pushViewController:displayTextViewController animated:YES];
}

- (void)didSelectedAvatarOnMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath {
    DLog(@"indexPath : %@", indexPath);
}

- (void)menuDidSelectedAtBubbleMessageMenuSelecteType:(XHBubbleMessageMenuSelecteType)bubbleMessageMenuSelecteType {
    
}

#pragma mark - XHAudioPlayerHelper Delegate

- (void)didAudioPlayerStopPlay:(AVAudioPlayer *)audioPlayer {
    if (!_currentSelectedCell) {
        return;
    }
    [_currentSelectedCell.messageBubbleView.animationVoiceImageView stopAnimating];
    self.currentSelectedCell = nil;
}

#pragma mark - XHEmotionManagerView DataSource

- (NSInteger)numberOfEmotionManagers {
    return self.emotionManagers.count;
}

- (XHEmotionManager *)emotionManagerForColumn:(NSInteger)column {
    return [self.emotionManagers objectAtIndex:column];
}

- (NSArray *)emotionManagersAtManager {
    return self.emotionManagers;
}

#pragma mark - XHMessageTableViewController Delegate

- (BOOL)shouldLoadMoreMessagesScrollToTop {
    return YES;
}

- (void)loadMoreMessagesScrollTotop {
    if (!self.loadingMoreMessage) {
        self.loadingMoreMessage = YES;
        
        WEAKSELF
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 加载本地数据
            dispatch_async(dispatch_get_main_queue(), ^{
                // 更新UI
                weakSelf.loadingMoreMessage = NO;
            });
        });
    }
}

/**
 *  发送文本消息的回调方法
 *
 *  @param text   目标文本字符串
 *  @param sender 发送者的名字
 *  @param date   发送时间
 */
- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date {
    XHMessage *textMessage = [[XHMessage alloc] initWithText:text sender:sender timestamp:date];
    textMessage.avatar = [UIImage imageNamed:@"Avatar"];
    textMessage.avatarUrl = @"http://www.pailixiu.com/jack/meIcon@2x.png";
    [self addMessage:textMessage];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeText];
    [self sendTextMessage:textMessage];
}

/**
 *  发送图片消息的回调方法
 *
 *  @param photo  目标图片对象，后续有可能会换
 *  @param sender 发送者的名字
 *  @param date   发送时间
 */
- (void)didSendPhoto:(UIImage *)photo fromSender:(NSString *)sender onDate:(NSDate *)date {
    XHMessage *photoMessage = [[XHMessage alloc] initWithPhoto:photo thumbnailUrl:nil originPhotoUrl:nil sender:sender timestamp:date];
    photoMessage.avatar = [UIImage imageNamed:@"avatar"];
    photoMessage.avatarUrl = @"http://www.pailixiu.com/jack/meIcon@2x.png";
    [self addMessage:photoMessage];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypePhoto];
    [self sendPhotoMessage:photoMessage];
}

/**
 *  发送视频消息的回调方法
 *
 *  @param videoPath 目标视频本地路径
 *  @param sender    发送者的名字
 *  @param date      发送时间
 */
- (void)didSendVideoConverPhoto:(UIImage *)videoConverPhoto videoPath:(NSString *)videoPath fromSender:(NSString *)sender onDate:(NSDate *)date {
    XHMessage *videoMessage = [[XHMessage alloc] initWithVideoConverPhoto:videoConverPhoto videoPath:videoPath videoUrl:nil sender:sender timestamp:date];
    videoMessage.avatar = [UIImage imageNamed:@"avatar"];
    videoMessage.avatarUrl = @"http://www.pailixiu.com/jack/meIcon@2x.png";
    [self addMessage:videoMessage];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeVideo];
}

/**
 *  发送语音消息的回调方法
 *
 *  @param voicePath        目标语音本地路径
 *  @param voiceDuration    目标语音时长
 *  @param sender           发送者的名字
 *  @param date             发送时间
 */
- (void)didSendVoice:(NSString *)voicePath voiceDuration:(NSString *)voiceDuration fromSender:(NSString *)sender onDate:(NSDate *)date {
    XHMessage *voiceMessage = [[XHMessage alloc] initWithVoicePath:voicePath voiceUrl:nil voiceDuration:voiceDuration sender:sender timestamp:date];
    voiceMessage.avatar = [UIImage imageNamed:@"avatar"];
    voiceMessage.avatarUrl = @"http://www.pailixiu.com/jack/meIcon@2x.png";
    [self addMessage:voiceMessage];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeVoice];
}

/**
 *  发送第三方表情消息的回调方法
 *
 *  @param facePath 目标第三方表情的本地路径
 *  @param sender   发送者的名字
 *  @param date     发送时间
 */
- (void)didSendEmotion:(NSString *)emotionPath fromSender:(NSString *)sender onDate:(NSDate *)date {
    XHMessage *emotionMessage = [[XHMessage alloc] initWithEmotionPath:emotionPath sender:sender timestamp:date];
    emotionMessage.avatar = [UIImage imageNamed:@"avatar"];
    emotionMessage.avatarUrl = @"http://www.pailixiu.com/jack/meIcon@2x.png";
    [self addMessage:emotionMessage];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeEmotion];
}

/**
 *  有些网友说需要发送地理位置，这个我暂时放一放
 */
- (void)didSendGeoLocationsPhoto:(UIImage *)geoLocationsPhoto geolocations:(NSString *)geolocations location:(CLLocation *)location fromSender:(NSString *)sender onDate:(NSDate *)date {
    XHMessage *geoLocationsMessage = [[XHMessage alloc] initWithLocalPositionPhoto:geoLocationsPhoto geolocations:geolocations location:location sender:sender timestamp:date];
    geoLocationsMessage.avatar = [UIImage imageNamed:@"avatar"];
    geoLocationsMessage.avatarUrl = @"http://www.pailixiu.com/jack/meIcon@2x.png";
    [self addMessage:geoLocationsMessage];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeLocalPosition];
}

/**
 *  是否显示时间轴Label的回调方法
 *
 *  @param indexPath 目标消息的位置IndexPath
 *
 *  @return 根据indexPath获取消息的Model的对象，从而判断返回YES or NO来控制是否显示时间轴Label
 */
- (BOOL)shouldDisplayTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 2)
        return YES;
    else
        return NO;
}

/**
 *  配置Cell的样式或者字体
 *
 *  @param cell      目标Cell
 *  @param indexPath 目标Cell所在位置IndexPath
 */
- (void)configureCell:(XHMessageTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
}

/**
 *  协议回掉是否支持用户手动滚动
 *
 *  @return 返回YES or NO
 */
- (BOOL)shouldPreventScrollToBottomWhileUserScrolling {
    return YES;
}

@end
