//
//  ViewController.m
//  IMYWebViewDemo
//
//  Created by njim3 on 2018/10/29.
//  Copyright © 2018 njim3. All rights reserved.
//

#import "ViewController.h"
#import <IMYWebView.h>
#import <XLPhotoBrowser.h>

@interface ViewController () <IMYWebViewDelegate> {
    NSString* _htmlData;
    CGFloat _webViewHeight;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainSVHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *mainView;

@property (nonatomic, strong) IMYWebView* webView;

@property (nonatomic, strong) NSMutableArray* imageMutArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self layoutViews];
    [self setViewAction];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    self.mainSVHeightConstraint.constant = CUSTOM_VIEW_HEIGHT + 1;
}

- (void)layoutViews {
    [self.mainView addSubview: self.webView];
    
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_offset(UIEdgeInsetsMake(8.0f, 8.0f, 8.0f, 8.0f));
    }];
}

- (void)setViewAction {
    [self loadHtmlData];
    
    [self.webView loadHTMLString: _htmlData baseURL: nil];
}

- (IBAction)refreshBBIAction:(UIBarButtonItem *)sender {
    [self.webView stopLoading];
    
    [self.webView loadHTMLString: _htmlData baseURL: nil];
}


- (void)loadHtmlData {
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:
                          [FILE_HTML_DATA stringByDeletingPathExtension]
                                                         ofType:
                          [FILE_HTML_DATA pathExtension]];
    
    NSString* htmlStr = [NSString stringWithContentsOfFile: htmlPath
                                                  encoding: NSUTF8StringEncoding
                                                     error: nil];
    
    NSString* htmlStructureStr = @"<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0,user-scalable=no\"><style>*{margin: 0;padding: 0;}body{font-size: 12pt;} img{width: 100%% !important}</style></head><body>%@</body></html>";
    
    _htmlData = [NSString stringWithFormat: htmlStructureStr,
                                [htmlStr stringByReplacingOccurrencesOfString:
                                 @"<p><br/></p>" withString: @""]];
}

- (void)getImages {
    [self.imageMutArr removeAllObjects];
    
    [self nodeCountOfTag: @"img" withNodeCountCallback:^(NSInteger count) {
        for (int i = 0; i < count; ++i) {
            NSString* jsStr = [NSString stringWithFormat:
                        @"document.getElementsByTagName('img')[%d].src", i];
            
            [self.webView evaluateJavaScript: jsStr
                           completionHandler:^(id object, NSError *error) {
                               if (!error) {
                                   [self.imageMutArr addObject: (NSString*)object];
                               }
                           }];
        }
        
        
    }];
}

// 获取某个标签的结点数量
- (void)nodeCountOfTag: (NSString*)tag
 withNodeCountCallback: (void(^) (NSInteger))callback {
    NSString* jsStr = [NSString stringWithFormat:
                       @"document.getElementsByTagName('%@').length", tag];
    
    [self.webView evaluateJavaScript: jsStr
                   completionHandler:^(id object, NSError *error) {
                       NSInteger count = error ? 0 : [object integerValue];
                       
                       callback(count);
                   }];
}

#pragma mark - IMYWebView delegate methods
- (void)webViewDidFinishLoad:(IMYWebView *)webView {
    [webView evaluateJavaScript: @"document.documentElement.scrollHeight"
              completionHandler:^(id object, NSError *error) {
                  CGFloat height = (CGFloat)[object integerValue];

                  if (!error) {
                      self.mainSVHeightConstraint.constant = height + 16.0f;
                  }
              }];

    [webView evaluateJavaScript: @"function assignImageClickAction(){var imgs=document.getElementsByTagName('img');var length=imgs.length;for(var i=0; i < length;i++){img=imgs[i];if(\"ad\" ==img.getAttribute(\"flag\")){var parent = this.parentNode;if(parent.nodeName.toLowerCase() != \"a\")return;}img.onclick=function(){window.location.href='image-preview:'+this.src}}}"
              completionHandler: ^(id object, NSError *error) {

    }];

    [webView evaluateJavaScript: @"assignImageClickAction();"
              completionHandler: ^(id object, NSError *error) {

    }];

    [self getImages];
}

- (BOOL)webView:(IMYWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    
    if ([request.URL.scheme isEqualToString: @"about:blank"])
        return YES;
    else if ([request.URL.scheme isEqualToString: @"image-preview"]) {
        NSString* imageUrlStr = [request.URL.absoluteString
                                 substringFromIndex: 14];

        if (self.imageMutArr.count != 0) {
            // 启动图片浏览器
            NSUInteger index = [self.imageMutArr indexOfObject: imageUrlStr];
            
            [XLPhotoBrowser showPhotoBrowserWithImages: self.imageMutArr
                                     currentImageIndex: index];
            
        }
    }
    
    return YES;
}

#pragma mark - Variables getter
- (IMYWebView*)webView {
    if (!_webView) {
        _webView = [[IMYWebView alloc] init];
        
        _webView.delegate = self;
        _webView.scrollView.scrollEnabled = NO;
        _webView.scrollView.bounces = NO;
    }
    
    return _webView;
}

- (NSMutableArray*)imageMutArr {
    if (!_imageMutArr) {
        _imageMutArr = [NSMutableArray array];
    }
    
    return _imageMutArr;
}

@end
