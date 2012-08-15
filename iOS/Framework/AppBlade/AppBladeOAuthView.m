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

static NSString* AppBladeOAuthFormat = @"%@/oauth/authorization/new?client_id=%@";

@interface AppBladeOAuthView ()

@property (nonatomic, retain) UIWebView* webView;
@property (nonatomic, assign) BOOL runJavascriptOnWebViewLoad;

- (void)close;

@end

@implementation AppBladeOAuthView

@synthesize webView = _webView;
@synthesize delegate = _delegate;
@synthesize runJavascriptOnWebViewLoad = _runJavascriptOnWebViewLoad;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // overlay view
        self.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
        CGRect webRect = CGRectInset(self.bounds, 0, 10);
        webRect = CGRectOffset(webRect, 0, 10);
        self.webView = [[[UIWebView alloc] initWithFrame:webRect] autorelease];
        self.webView.delegate = self;
        self.webView.alpha = 0.0;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [self addSubview:self.webView];
    
    NSString* oauthString = [NSString stringWithFormat:AppBladeOAuthFormat, AppBladeHost, [[AppBlade sharedManager] appBladeProjectToken]];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:oauthString]];
    [self.webView loadRequest:request];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.webView.alpha = 1.0;
    }];
}

- (void)close
{
    [UIView animateWithDuration:0.3 animations:^{
        self.webView.alpha = 0.0;
    } completion:^(BOOL finished){
        [self removeFromSuperview];
    }];
}

- (void)dealloc
{
    _delegate = nil;
    [_webView release];
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
            [self.delegate finishedOAuthWithToken:token];
            [self close];
        }
        
    }
}

@end
