//
//  AppBladeOAuthView.m
//  AppBlade
//
//  Created by Michele Titolo on 8/13/12.
//  Copyright (c) 2012 Raizlabs Corporation. All rights reserved.
//

#import "AppBladeOAuthView.h"
#import "AppBladeWebClient.h"
#import "AppBlade.h"

static NSString* AppBladeOAuthFormat = @"https://%@/oauth/authorization/new?client_id=%@";

const int kProgressViewSizeHeight       = 80;
const int kProgressViewSizeWidth        = 200;

@interface AppBladeOAuthView ()

@property (nonatomic, retain) UIWebView* webView;

@property (nonatomic, retain) UIView* progressView;
@property (nonatomic, retain) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, retain) UILabel* activityLabel;

@property (nonatomic, assign) BOOL runJavascriptOnWebViewLoad;

- (void)closeWebView;

@end

@implementation AppBladeOAuthView

@synthesize webView = _webView;

@synthesize progressView = _progressView;
@synthesize activityIndicator = _activityIndicator;
@synthesize activityLabel = _activityLabel;

@synthesize delegate = _delegate;
@synthesize runJavascriptOnWebViewLoad = _runJavascriptOnWebViewLoad;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // overlay view
        self.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.9];
        self.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        CGRect webRect = CGRectInset(self.bounds, 0, 10);
        webRect = CGRectOffset(webRect, 0, 10);
        self.webView = [[[UIWebView alloc] initWithFrame:webRect] autorelease];
        self.webView.delegate = self;
        self.webView.alpha = 0.0;
        
        self.progressView = [[[UIView alloc] initWithFrame:CGRectMake(floor((frame.size.width - kProgressViewSizeWidth) / 2), floor((frame.size.height - kProgressViewSizeHeight) / 2), kProgressViewSizeWidth, kProgressViewSizeHeight)] autorelease];
        
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityIndicator.hidesWhenStopped = YES;
        
        self.activityIndicator.frame = CGRectMake(floor((kProgressViewSizeWidth - 40) / 2), floor((kProgressViewSizeHeight - 40) / 2), 40, 40);
        
        self.activityLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, kProgressViewSizeHeight - 30, kProgressViewSizeWidth, 30)] autorelease];
        self.activityLabel.font = [UIFont boldSystemFontOfSize:19];
        self.activityLabel.textColor = [UIColor whiteColor];
        self.activityLabel.backgroundColor = [UIColor clearColor];
        self.activityLabel.textAlignment = UITextAlignmentCenter;
        
        self.activityLabel.text = @"Checking access...";
        
        [self.progressView addSubview:self.activityIndicator];
        [self.progressView addSubview:self.activityLabel];
        self.progressView.hidden = YES;
        
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [self addSubview:self.progressView];
    [self addSubview:self.webView];
    
    NSString* oauthString = [NSString stringWithFormat:AppBladeOAuthFormat, [[AppBlade sharedManager] appBladeHost], [[AppBlade sharedManager] appBladeProjectToken]];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:oauthString]];
    [self.webView loadRequest:request];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.webView.alpha = 1.0;
    }];
}

- (void)closeWebView
{
    [UIView animateWithDuration:0.3 animations:^{
        self.webView.alpha = 0.0;
    } completion:^(BOOL finished){
        [self.webView removeFromSuperview];
        self.progressView.alpha = 0.0;
        self.progressView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.progressView.alpha = 1.0;
        } completion:^(BOOL finished){
            [self.activityIndicator startAnimating];
        }];
    }];
}

- (void)closeOAuthView
{
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished){
        [self removeFromSuperview];
    }];
}

- (void)reset
{
    [self.activityIndicator stopAnimating];
    self.progressView.hidden = YES;
    
    [self addSubview:self.webView];
    
    NSString* oauthString = [NSString stringWithFormat:AppBladeOAuthFormat, [[AppBlade sharedManager] appBladeHost], [[AppBlade sharedManager] appBladeProjectToken]];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:oauthString]];
    [self.webView loadRequest:request];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.webView.alpha = 1.0;
    }];
    
}

- (void)dealloc
{
    _delegate = nil;
    [_webView release];
    [_activityIndicator release];
    [_progressView release];
    [_activityLabel release];
    [super dealloc];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeFormSubmitted || navigationType == UIWebViewNavigationTypeFormResubmitted) {
        self.runJavascriptOnWebViewLoad = YES;
    }
    else {
        self.runJavascriptOnWebViewLoad = NO;
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.runJavascriptOnWebViewLoad) {
        
        NSString* token = [webView stringByEvaluatingJavaScriptFromString:@"getToken()"];
        if (token) {
            [self.delegate finishedOAuthWithCode:token];
            [self closeWebView];
        }
        
    }
}

@end
