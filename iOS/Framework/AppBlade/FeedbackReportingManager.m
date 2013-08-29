//
//  FeedbackReporting
//  AppBlade
//
//  Created by AndrewTremblay on 7/15/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "FeedbackReportingManager.h"
#import "AppBlade.h"
#import <QuartzCore/QuartzCore.h>


@interface FeedbackReportingManager ()
@end

@implementation FeedbackReportingManager
@synthesize delegate;

@synthesize feedbackDictionary;
@synthesize showingFeedbackDialogue;
@synthesize tapRecognizer;
@synthesize feedbackWindow;


- (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)webOpDelegate
{
    if((self = [super init])) {
        self.delegate = webOpDelegate;
    }
    
    return self;
}

- (void)allowFeedbackReportingForWindow:(UIWindow *)window withOptions:(AppBladeFeedbackSetupOptions)options
{
    AppBlade *delegateRef = (AppBlade *)self.delegate;
    self.feedbackWindow = window;
    
    if (options == AppBladeFeedbackSetupTripleFingerDoubleTap || options == AppBladeFeedbackSetupDefault) {
        //Set up our custom triple finger double-tap
        self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:delegateRef action:@selector(showFeedbackDialogue)] ;
        self.tapRecognizer.numberOfTapsRequired = 2;
        self.tapRecognizer.numberOfTouchesRequired = 3;
        self.tapRecognizer.delegate = delegateRef;
        [self.feedbackWindow addGestureRecognizer:self.tapRecognizer];
    }
    [delegateRef checkAndCreateAppBladeCacheDirectory];
    
    if ([self hasPendingFeedbackReports]) {
        [delegateRef handleBackloggedFeedback];
    }
}

- (void)showFeedbackDialogueWithOptions:(AppBladeFeedbackDisplayOptions)options
{
    AppBlade *delegateRef = (AppBlade *)self.delegate;
    if(!self.showingFeedbackDialogue){
        self.showingFeedbackDialogue = YES;
        if(self.feedbackDictionary == nil){
            self.feedbackDictionary = [NSMutableDictionary  dictionary];
        }
        
        //More like SETUP feedback dialogue, am I right? I'm hilarious. Anyway, this gets all our ducks in a row before showing the feedback dialogue
        if(options == AppBladeFeedbackDisplayWithScreenshot || options == AppBladeFeedbackDisplayDefault){
            NSString* screenshotPath = [delegateRef captureScreen];
            [self.feedbackDictionary setObject:[screenshotPath lastPathComponent] forKey:kAppBladeFeedbackKeyScreenshot];
        }
        else
        {
            
        }
        //other setup methods (like the reintroduction of the console log) will go here
        [delegateRef promptFeedbackDialogue];
    }
    else
    {
        ABDebugLog_internal(@"Feedback window already presenting, or a screenshot is trying to be captured");
        return;
    }    
}

- (void)handleWebClientSentFeedback:(AppBladeWebOperation *)client withSuccess:(BOOL)success
{
    if (success) {
        ABDebugLog_internal(@"Feedback succeeded!")
    }else{
        ABDebugLog_internal(@"Feedback failed!")
    }
}




#pragma mark - Web Request Generators

- (AppBladeWebOperation*) generateFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString*)console params:(NSDictionary*)paramsDict
{
    
    AppBladeWebOperation *client = [[AppBladeWebOperation alloc] initWithDelegate:self.delegate];
    [client setApi: AppBladeWebClientAPI_Feedback];

    NSString* screenshotPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:screenshot];
    // Build report URL.
    NSString* reportString = [NSString stringWithFormat:reportFeedbackURLFormat, [client.delegate appBladeHost]];
    NSURL* reportURL = [NSURL URLWithString:reportString];
    
    NSString *multipartBoundary = [NSString stringWithFormat:@"---------------------------%@", [client genRandNumberLength:64]];
    
    // Create the API request.
    NSMutableURLRequest* apiRequest = [client requestForURL:reportURL];
    [apiRequest setValue:[@"multipart/form-data; boundary=" stringByAppendingString:multipartBoundary] forHTTPHeaderField:@"Content-Type"];
    [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [apiRequest setHTTPMethod:@"POST"];
    
    NSMutableData* body = [NSMutableData dataWithData:[[NSString stringWithFormat:@"--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"feedback[notes]\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[note dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"feedback[screenshot]\"; filename=\"base64:%@\"\r\n", screenshot] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData* screenshotData = [[client encodeBase64WithData:[NSData dataWithContentsOfFile:screenshotPath]] dataUsingEncoding:NSUTF8StringEncoding];
    [body appendData:screenshotData];
    
    if([NSPropertyListSerialization propertyList:paramsDict isValidForFormat:NSPropertyListXMLFormat_v1_0]){
        NSError* error = nil;
        NSData *paramsData = [NSPropertyListSerialization dataWithPropertyList:paramsDict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
        if(error == nil){
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"Content-Disposition: form-data; name=\"custom_params\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"Content-Type: text/xml\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:paramsData];
            ABDebugLog_internal(@"Parsed params! They were included.");
        }
        else
        {
            ABErrorLog(@"Error parsing params. They weren't included. %@ ",error.debugDescription);
        }
    }
    
    [body appendData:[[[@"\r\n--" stringByAppendingString:multipartBoundary] stringByAppendingString:@"--"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [apiRequest setHTTPBody:body];
    [apiRequest setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
    
    //set our weak/block references
    __weak AppBladeWebOperation *weakClient = client;
    //set our blocks
    [client setPrepareBlock:^(NSMutableURLRequest * apiRequest){
        NSLog(@"WOO WE'RE IN A BLOCK %@", apiRequest);
        [weakClient addSecurityToRequest:apiRequest];
    }];
 
    
    NSDictionary *blockFeedbackDictionary = [[[NSDictionary alloc] initWithObjectsAndKeys:note, kAppBladeFeedbackKeyNotes, screenshot, kAppBladeFeedbackKeyScreenshot, nil] copy];
    [client setSuccessBlock:^(id data, NSError* error){
        ABDebugLog_internal(@"feedback Successful");
        
        NSDictionary* feedback = [weakClient.userInfo objectForKey:kAppBladeFeedbackKeyFeedback];
        // Clean up
        NSString* screenshotPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:[feedback objectForKey:kAppBladeFeedbackKeyScreenshot]];
        [[NSFileManager defaultManager] removeItemAtPath:screenshotPath error:nil];
        
        NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
        NSMutableArray* backups = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
        
        NSString* fileName = [weakClient.userInfo objectForKey:kAppBladeFeedbackKeyBackup];
        
        NSString* filePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName];
        ABDebugLog_internal(@"Removing supporting feedback files and the feedback file herself");
        [self removeIntermediateFeedbackFiles:filePath];
        
        ABDebugLog_internal(@"Removing Successful feedback object from main feedback list");
        [backups removeObject:fileName];
        if (backups.count > 0) {
            ABDebugLog_internal(@"writing pending feedback objects back to file");
            [backups writeToFile:backupFilePath atomically:YES];
        }
        
        ABDebugLog_internal(@"checking for more pending feedback");
        if ([self hasPendingFeedbackReports]) {
            ABDebugLog_internal(@"more pending feedback");
            [[AppBlade sharedManager] handleBackloggedFeedback];
        }
        else
        {
            ABDebugLog_internal(@"no more pending feedback");
        }

    }];
    [client setFailBlock:^(id data, NSError* error){
        @synchronized (self){
            ABErrorLog(@"ERROR sending feedback");
            NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
            NSMutableArray* backupFiles = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
            NSString *fileName = [weakClient.userInfo objectForKey:kAppBladeFeedbackKeyBackup];
            BOOL isBacklog = ([[backupFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@",fileName]] count] > 0);
            if (!isBacklog) {
                NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
                NSString* newFeedbackName = [[NSString stringWithFormat:@"%0.0f", now] stringByAppendingPathExtension:@"plist"];
                NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:newFeedbackName];
                [blockFeedbackDictionary writeToFile:feedbackPath atomically:YES];
                
                if (!backupFiles) {
                    backupFiles = [NSMutableArray array];
                }
                
                [backupFiles addObject:newFeedbackName];
                
                BOOL success = [backupFiles writeToFile:backupFilePath atomically:YES];
                if(!success){
                    ABErrorLog(@"Error writing backup file to %@", backupFilePath);
                }
            }
            else {
                
            }
        }

    }];
    
    [client setRequestCompletionBlock:^(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *error){
        int status = [[responseHeaders valueForKey:@"statusCode"] intValue];
        BOOL succeeded = (status == 201 || status == 200);
        
        BOOL isBacklog = [[weakClient delegate] containsOperationInPendingRequests:weakClient];
        if (succeeded){
            NSLog(@"Success!");
            if(weakClient.successBlock != nil) {
                NSLog(@"successBlock!");
                weakClient.successBlock(receivedData, nil);
            }
        }
        else if (!isBacklog) {
            ABDebugLog_internal(@"Unsuccesful feedback not found in backLog");
            
            // If we fail sending, add to backlog
            // We do not remove backlogged files unless the request is sucessful
            
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            NSString* newFeedbackName = [[NSString stringWithFormat:@"%0.0f", now] stringByAppendingPathExtension:@"plist"];
            NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:newFeedbackName];
            
            [blockFeedbackDictionary writeToFile:feedbackPath atomically:YES];
            
            NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
            NSMutableArray* backupFiles = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
            if (!backupFiles) {
                backupFiles = [NSMutableArray array];
            }
            
            [backupFiles addObject:newFeedbackName];
            
            BOOL success = [backupFiles writeToFile:backupFilePath atomically:YES];
            if(!success){
                ABErrorLog(@"Error writing backup file to %@", backupFilePath);
            }
        } //else it's failed and already in the backlog. Keep it there.
    }];
    

    
    return client;
}


#pragma mark Stored Web Request Behavior

- (BOOL)hasPendingFeedbackReports
{
    BOOL toRet = NO;
    @synchronized (self){
        NSString *feedbackBacklogFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
        if([[NSFileManager defaultManager] fileExistsAtPath:feedbackBacklogFilePath]){
            ABDebugLog_internal(@"found file at %@", feedbackBacklogFilePath);
            NSMutableArray* backupFiles = [NSMutableArray arrayWithContentsOfFile:feedbackBacklogFilePath];
            if (backupFiles.count > 0) {
                ABDebugLog_internal(@"found %d files at feedbackBacklogFilePath", backupFiles.count);
                toRet = YES;
            }
            else
            {
                ABDebugLog_internal(@"found NO files at feedbackBacklogFilePath");
                toRet = NO;
            }
        }
        else
        {
            ABDebugLog_internal(@"found nothing at %@", feedbackBacklogFilePath);
            toRet = NO;
        }
    }
    return toRet;
}


- (void)removeIntermediateFeedbackFiles:(NSString *)feedbackPath
{
    NSDictionary* feedback = [NSDictionary dictionaryWithContentsOfFile:feedbackPath];
    if (feedback) {
        ABDebugLog_internal(@"Cleaning Feedback %@", feedback);
        NSString *screenshotFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:[feedback objectForKey:kAppBladeFeedbackKeyScreenshot]];
        
        NSError *screenShotError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:screenshotFilePath error:&screenShotError];
    }
    NSError *feedbackPathError = nil;
    [[NSFileManager defaultManager] removeItemAtPath:feedbackPath error:&feedbackPathError];
    
}

- (void)handleBackloggedFeedback
{
    ABDebugLog_internal(@"handleBackloggedFeedback");
    NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
    NSMutableArray* backupFiles = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
    if (backupFiles.count > 0) {
        NSString* fileName = [backupFiles objectAtIndex:0]; //get earliest unsent feedback
        NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName];
        
        NSDictionary* feedback = [NSDictionary dictionaryWithContentsOfFile:feedbackPath];
        if (feedback) {
            ABDebugLog_internal(@"Feedback found at %@", feedbackPath);
            ABDebugLog_internal(@"backlog Feedback dictionary %@", feedback);
            NSString *screenshotFileName = [feedback objectForKey:kAppBladeFeedbackKeyScreenshot];
            //validate that additional files exist
            NSString *screenshotFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:screenshotFileName];
            bool screenShotFileExists = [[NSFileManager defaultManager] fileExistsAtPath:screenshotFilePath];
            if(screenShotFileExists){
                AppBladeWebOperation * client = [self generateFeedbackWithScreenshot:screenshotFileName note:[feedback objectForKey:kAppBladeFeedbackKeyNotes] console:nil params:[[AppBlade sharedManager] getCustomParams]];
                client.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:feedback, kAppBladeFeedbackKeyFeedback, fileName, kAppBladeFeedbackKeyBackup, nil];
                [[[AppBlade sharedManager] pendingRequests] addOperation:client];
            }
            else
            {
                //clean up files if one doesn't exist
                [self removeIntermediateFeedbackFiles:feedbackPath];
                ABDebugLog_internal(@"invalid feedback at %@, removing File and intermediate files", feedbackPath);
                [backupFiles removeObject:fileName];
                ABDebugLog_internal(@"writing valid pending feedback objects back to file");
                [backupFiles writeToFile:backupFilePath atomically:YES];
                
            }
        }
        else
        {
            ABDebugLog_internal(@"No Feedback found at %@, invalid feedback, removing File", feedbackPath);
            [backupFiles removeObject:fileName];
            ABDebugLog_internal(@"writing valid pending feedback objects back to file");
            [backupFiles writeToFile:backupFilePath atomically:YES];
        }
    }
}

@end

#ifndef SKIP_FEEDBACK
#pragma clang diagnostic ignored "-Wprotocol"
@implementation AppBlade (FeedbackReporting)
@dynamic feedbackManager;
@dynamic pendingRequests;


- (void)promptFeedbackDialogue
{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect screenFrame = self.feedbackManager.feedbackWindow.frame;
    
    CGRect vFrame = CGRectZero;
    if([[self.feedbackManager.feedbackWindow subviews] count] > 0){
        UIView *v = [[self.feedbackManager.feedbackWindow subviews] objectAtIndex:0];
        vFrame = v.frame; //adjust for any possible offset in the subview we'll add our feedback to.
    }
    
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        //make an adjustment for the case where the view we're adding to is stretched beyond the window.
        screenFrame.origin.x = screenFrame.origin.x -vFrame.origin.x + statusBarFrame.size.width;
        
        // We need to react properly to interface orientations
        CGSize size = screenFrame.size;
        screenFrame.size.width = size.height;
        screenFrame.size.height = size.width;
        CGPoint origin = screenFrame.origin;
        screenFrame.origin.x = origin.y;
        screenFrame.origin.y = origin.x;
    }
    else
    {
        //make an adjustment for the case where the view we're adding to is stretched beyond the window.
        screenFrame.origin.y = screenFrame.origin.y -vFrame.origin.y + statusBarFrame.size.height;
    }
    
    ABDebugLog_internal(@"Displaying feedback dialog in frame X:%.f Y:%.f W:%.f H:%.f",
                        screenFrame.origin.x, screenFrame.origin.y,
                        screenFrame.size.width, screenFrame.size.height);
    
    
    FeedbackDialogue *feedback = [[FeedbackDialogue alloc] initWithFrame:CGRectMake(screenFrame.origin.x, screenFrame.origin.y, screenFrame.size.width, screenFrame.size.height)];
    feedback.delegate = self;
    
    // get the first window in the application if one was not supplied.
    if (!self.feedbackManager.feedbackWindow){
        self.feedbackManager.feedbackWindow = [[UIApplication sharedApplication] keyWindow];
        self.feedbackManager.showingFeedbackDialogue = YES;
        ABDebugLog_internal(@"Feedback window not defined, using default (Images might not come through.)");
    }
    if([[self.feedbackManager.feedbackWindow subviews] count] > 0){
        [[[self.feedbackManager.feedbackWindow subviews] objectAtIndex:0] addSubview:feedback];
        self.feedbackManager.showingFeedbackDialogue = YES;
        [feedback.textView becomeFirstResponder];
    }
    else
    {
        ABErrorLog(@"No subviews in feedback window, cannot prompt feedback dialog at this time.");
        feedback.delegate = nil;
        self.feedbackManager.showingFeedbackDialogue = NO;
    }
}




- (void)reportFeedback:(NSString *)feedback
{
#ifndef SKIP_FEEDBACK
    [self.feedbackManager.feedbackDictionary setObject:feedback forKey:kAppBladeFeedbackKeyNotes];
    
    ABDebugLog_internal(@"caching and attempting send of feedback %@", self.feedbackDictionary);
    
    //store the feedback in the cache director in the event of a termination
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSString* newFeedbackName = [[NSString stringWithFormat:@"%0.0f", now] stringByAppendingPathExtension:@"plist"];
    NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:newFeedbackName];
    
    [self.feedbackManager.feedbackDictionary writeToFile:feedbackPath atomically:YES];
    NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
    NSMutableArray* backupFiles = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
    if (!backupFiles) {
        backupFiles = [NSMutableArray array];
    }
    [backupFiles addObject:newFeedbackName];
    
    BOOL success = [backupFiles writeToFile:backupFilePath atomically:YES];
    if(!success){
        ABErrorLog(@"Error writing backup file to %@", backupFilePath);
    }
    
    AppBladeWebOperation * client = [self.feedbackManager generateFeedbackWithScreenshot:[self.feedbackManager.feedbackDictionary objectForKey:kAppBladeFeedbackKeyScreenshot] note:feedback console:nil params:[self getCustomParams]];
    ABDebugLog_internal(@"Sending screenshot");
    [self.pendingRequests addOperation:client];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
    
}



-(NSString *)captureScreen
{
    [self checkAndCreateAppBladeCacheDirectory];
    UIImage *currentImage = [self getContentBelowView];
    if(currentImage == nil){
        ABErrorLog(@"ERROR, could not capture screenshot, possible invalid keywindow");
    }
    NSString* fileName = [[self randomString:36] stringByAppendingPathExtension:@"png"];
	NSString *pngFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName] ;
	NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(currentImage)];
	[data1 writeToFile:pngFilePath atomically:YES];
    ABDebugLog_internal(@"Screen captured in fileName %@", fileName);
    return pngFilePath ;
    
}

- (UIImage*)getContentBelowView
{
    UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIGraphicsBeginImageContext(keyWindow.bounds.size);
    [keyWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImage* returnImage = nil;
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            returnImage = [self rotateImage:image angle:270];
        }
        else {
            returnImage = [self rotateImage:image angle:90];
        }
    }
    else {
        returnImage = image;
    }
    
    return returnImage;
    
}

// From: http://megasnippets.com/source-codes/objective_c/rotate_image
- (UIImage *) rotateImage:(UIImage *)img angle:(int)angle
{
    CGImageRef imgRef = [img CGImage];
    CGContextRef context;
    
    switch (angle) {
        case 90:
            UIGraphicsBeginImageContext(CGSizeMake(img.size.height, img.size.width));
            context = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(context, img.size.height, img.size.width);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextRotateCTM(context, M_PI/2.0);
            break;
        case 180:
            UIGraphicsBeginImageContext(CGSizeMake(img.size.width, img.size.height));
            context = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(context, img.size.width, 0);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextRotateCTM(context, -M_PI);
            break;
        case 270:
            UIGraphicsBeginImageContext(CGSizeMake(img.size.height, img.size.width));
            context = UIGraphicsGetCurrentContext();
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextRotateCTM(context, -M_PI/2.0);
            break;
        default:
            return nil;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, img.size.width, img.size.height), imgRef);
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return ret;
}

@end

#endif

