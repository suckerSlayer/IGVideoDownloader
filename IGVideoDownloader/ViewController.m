//
//  ViewController.m
//  IGVideoDownloader
//
//  Created by leo on 2019/11/21.
//  Copyright © 2019 yixunyun. All rights reserved.
// nothing help nothing help

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <AFNetworking/AFNetworking.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface ViewController ()<WKNavigationDelegate,WKUIDelegate>
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, copy) NSString *srcUrlString;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configUI];
    [self configWebView];
}

-(void)configUI{
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear->");
}

-(void)configWebView {
    [self.view insertSubview:self.webView atIndex:0];
    self.webView.navigationDelegate = self;
}

-(void)loadUrl:(NSString *)string {
    
    if ([string hasPrefix:@"http"] && [string containsString:@".mp4"]) {
        self.srcUrlString = string;
        [self downloadAction];
    }
        NSString *urlString = string;
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        [self.webView loadRequest:request];
        [SVProgressHUD show];
    
}

- (IBAction)downLoadAction:(UIButton *)sender {
    
    UIPasteboard *board = [UIPasteboard generalPasteboard];
    [self loadUrl:board.string];
    
//    NSString *filePath = @ "/Users/leo/Library/Developer/CoreSimulator/Devices/857206EF-3394-4EA7-B547-B918BD6FB0F2/data/Containers/Data/Application/4122AE59-AA50-424B-9AA7-F8A3C7043DCB/Documents/78028839_153273279254502_462873112034973884_n.mp4";
//    NSString *filePath = @"/var/mobile/Containers/Data/Application/98E69EA2-8005-4B2A-844E-C62400ECF4FD/Documents/78028839_153273279254502_462873112034973884_n.mp4";
//    UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
}

-(void)getVideoString:(NSString *)mainstring{
    NSString *videoString = [self getHtmlStringFrom:mainstring ByBeginString:@"<video" AndEndString:@"</video>"];

    NSString *srcString = [self getHtmlStringFrom:videoString ByBeginString:@"src=" AndEndString:@">"];
    NSString *urlString = [self getHtmlStringFrom:srcString ByBeginString:@"http" AndEndString:@"\""];
    
    self.label.text = urlString;
    self.srcUrlString = urlString;
    [UIView animateWithDuration:0.5 animations:^{
        self.downloadBtn.backgroundColor = [UIColor systemPinkColor];
    }];
    
    if([self.srcUrlString isEqualToString:@""]){//如果经过上面的步骤没有得到地址说明纸移动端,移动端的html内容和desktop不一样
        NSString *videoString = [self getHtmlStringFrom:mainstring ByBeginString:@"\"og:video\" content=\"" AndEndString:@">"];
        NSLog(@"mainString-->%@",mainstring);
        NSLog(@"videoString-->%@",videoString);
        self.srcUrlString =  [self getHtmlStringFrom:videoString ByBeginString:@"https" AndEndString:@""];
    }
    
    
    
    if(![self.srcUrlString isEqualToString:@""]) {
        UIPasteboard *board = [UIPasteboard generalPasteboard];
        board.string = self.srcUrlString;
        [self downloadAction];
    }
}

-(void)downloadAction {
    self.downloadBtn.backgroundColor = [UIColor systemPinkColor];
    self.downloadBtn.enabled = false;
    static NSURLSessionConfiguration *configuration;
    static AFHTTPSessionManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{//这里的参数只初始化一次,多次就会崩溃
        configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"instagram"];
        manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    });
    
    NSURL *downloadUrl = [NSURL URLWithString:self.srcUrlString];
    NSURLRequest *request = [NSURLRequest requestWithURL: downloadUrl];
    NSLog(@"startDownload");
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull uploadProgress) {
        // This is not called back on the main queue.
        // You are responsible for dispatching to the main queue for UI updates
        dispatch_async(dispatch_get_main_queue(), ^{
            //Update the progress view
            NSLog(@"Progress:%f",uploadProgress.fractionCompleted);
            [SVProgressHUD showProgress:uploadProgress.fractionCompleted];
        });
    }destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
        NSString *fileString = filePath.absoluteString;
        if([fileString hasPrefix:@"file://"]){
            NSRange schemeRange = [fileString rangeOfString:@"file://"];
            NSRange fileRange = NSMakeRange(schemeRange.location+schemeRange.length, fileString.length-schemeRange.length);
            fileString = [fileString substringWithRange:fileRange];
        }
         UISaveVideoAtPathToSavedPhotosAlbum(fileString, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        self.downloadBtn.backgroundColor = [UIColor greenColor];
        self.downloadBtn.enabled = true;
        [SVProgressHUD dismiss];
        [SVProgressHUD showSuccessWithStatus:@"Video Saved"];
        [SVProgressHUD dismissWithDelay:1];
                                                                    
        
    }];
    [downloadTask resume];
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    NSLog(@"videoPath->%@", videoPath);
    if (error){
        NSLog(@"%@", error);
    }
    NSLog(@"complete");
}

#pragma mark
#pragma mark --delegate--

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"webView->%@",webView.URL);
    if([webView.URL.absoluteString hasPrefix:@"http"]&&[webView.URL.absoluteString containsString:@".mp4"]){
        //是下载链接的话就不做任何事情,下载的动作在点击按钮时候就已经直接调用下载(而且是下载链接时这个网页完成载入的方法不会触发,很奇怪)
    }else {
        [webView evaluateJavaScript:@"document.getElementsByTagName('html')[0].innerHTML" completionHandler:^(NSString *_Nullable result, NSError * _Nullable error) {
            NSLog(@"getElements->%@",result);
            [SVProgressHUD dismiss];
            [self getVideoString:result];
        }];
    }
}

#pragma mark
#pragma mark  --lazyLoad/lifeCycle/tools--
- (void)viewDidLayoutSubviews {
    _webView.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
}

-(WKWebView *) webView{
    if(!_webView){
        _webView = [[WKWebView alloc] init];
//        _webView.backgroundColor = [UIColor systemPinkColor];
    }
    return _webView;
}

-(NSString *)srcUrlString {
    if(!_srcUrlString){
        _srcUrlString = [NSString string];
    }
    return _srcUrlString;
}

-(NSString *)getHtmlStringFrom:(NSString *)mainString ByBeginString:(NSString *)beginString AndEndString:(NSString *)endString{
    NSString *tempString = mainString;
    NSRange rangeBegin = [tempString rangeOfString:beginString];
    if (rangeBegin.length ==0){
        return @"";
    }
    tempString = [tempString substringFromIndex:rangeBegin.location];
    
    NSRange rangeEnd = [tempString rangeOfString:endString];
    if([endString isEqualToString:@""]){
        rangeEnd = NSMakeRange(tempString.length-1, 1);
    }
    
    if ([tempString hasPrefix:@"src="]) {
        rangeEnd = NSMakeRange(tempString.length-1, 1);
    }
    if (rangeBegin.length ==0 || rangeEnd.length == 0){
        return @"";
    }
    NSRange resultRange = NSMakeRange(0, rangeEnd.location);
    NSString *resultString = [tempString substringWithRange:resultRange];
    resultString = [self filterString:resultString];
//    NSLog(@"%@->%@",beginString,resultString);

    return resultString;
}

-(NSString *)filterString:(NSString *)string {
    string = [string stringByReplacingOccurrencesOfString:@"&amp" withString:@"&"];
    string = [string stringByReplacingOccurrencesOfString:@"&;" withString:@"&"];
    string = [string stringByRemovingPercentEncoding];
    return string;
}

@end
