/*
 This file is part of Ask4AppReviews (forked from Appirater).
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */
/*
 * Ask4AppReviews.m
 * Ask4AppReviews
 *
 * Created by Luke Durrant on 7/12.
 * Ask4AppReviews (forked from Appirater).
 */

#import "Ask4AppReviews.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>
#import "Ask4AppReviewsTimeRange.h"


NSString *const kAsk4AppReviewsFirstUseDate				= @"kAsk4AppReviewsFirstUseDate";
NSString *const kAsk4AppReviewsUseCount					= @"kAsk4AppReviewsUseCount";
NSString *const kAsk4AppReviewsSignificantEventCount		= @"kAsk4AppReviewsSignificantEventCount";
NSString *const kAsk4AppReviewsCurrentVersion			= @"kAsk4AppReviewsCurrentVersion";
NSString *const kAsk4AppReviewsRatedCurrentVersion		= @"kAsk4AppReviewsRatedCurrentVersion";
NSString *const kAsk4AppReviewsDeclinedToRate			= @"kAsk4AppReviewsDeclinedToRate";
NSString *const kAsk4AppReviewsReminderRequestDate		= @"kAsk4AppReviewsReminderRequestDate";
NSString *const kAsk4AppReviewsAppIdBundleKey            = @"AppStoreId";
NSString *const kAsk4AppReviewsEmailBundleKey            = @"DeveloperEmail";

//                                itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=357627360
//                                itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=579976234
NSString *templateReviewURL = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=APP_ID";

static id<Ask4AppReviewsDelegate> _delegate;

@interface Ask4AppReviews ()
- (BOOL)connectedToNetwork;
+ (NSString*)appStoreAppID;
+ (NSString*)developerEmail;
- (void)showRatingAlert;
- (void)showQuestionAlert;
- (BOOL)ratingConditionsHaveBeenMet;
- (void)incrementUseCount;
- (void)hideRatingAlert;
@end

@implementation Ask4AppReviews 

@synthesize questionAlert;
@synthesize ratingAlert;
@synthesize theViewController;

+ (void)setDelegate:(id<Ask4AppReviewsDelegate>)delegate{
    _delegate = delegate;
}

-(id) init {
    if (self = [super init])  {
        
        NSString *appName = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
        
        if (appName == nil) {
            appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
        }
        self.doYouLikeAppTitle = [NSString stringWithFormat: @"%@ Feedback", appName];
        self.doYouLikeAppBody = [NSString stringWithFormat: @"How do you feel about %@", appName];
        self.likeItButton = @"It's really useful";
        self.dontLikeItButton = @"Room for improvement";
        self.askLaterButton = @"Ask another time";
        
        self.askForReviewTitle = @"Could you leave a review?";
        self.askForReviewBody = @"Every positive review helps us keep the updates coming.";
        self.reviewButton = [NSString stringWithFormat:@"Review %@", appName];
        self.noButton = @"No, thank you";
        
        self.emailSubject = [NSString stringWithFormat:@"%@ Feedback", appName];
        self.emailBody = @"Your feedback will help us deliver the features you need the most.";
        
        self.daysUntilPrompt = 30;
        self.usesUntilPrompt = 20;
        self.eventsUntilPrompt = -1;
        self.daysBeforeReminding = 1;
    }
    return self;
}

- (BOOL)connectedToNetwork {
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
	
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
	
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);

    if (!didRetrieveFlags)
    {
        NSLog(@"Error. Could not recover network reachability flags");
        return NO;
    }
	
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
	BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;
	
	NSURL *testURL = [NSURL URLWithString:@"http://www.apple.com/"];
	NSURLRequest *testRequest = [NSURLRequest requestWithURL:testURL  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
	NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:self];
	
    return ((isReachable && !needsConnection) || nonWiFi) ? (testConnection ? YES : NO) : NO;
}

+(NSString*)appStoreAppID {
	
   NSString* value = [[[NSBundle mainBundle] infoDictionary] objectForKey:kAsk4AppReviewsAppIdBundleKey];
	
   NSAssert1(value, @"Error - you have not specified %@ property in your info.plist", kAsk4AppReviewsAppIdBundleKey);
	
   return value;
}

+(NSString*)developerEmail {
	
    NSString* value = [[[NSBundle mainBundle] infoDictionary] objectForKey:kAsk4AppReviewsEmailBundleKey];
	
    NSAssert1(value, @"Error - you have not specified %@ property in your info.plist", kAsk4AppReviewsEmailBundleKey);
	
    return value;
}

+ (Ask4AppReviews*)sharedInstance {
	static Ask4AppReviews *ask = nil;
	if (ask == nil)
	{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            ask = [[Ask4AppReviews alloc] init];
            ask.delegate = _delegate;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:
                UIApplicationWillResignActiveNotification object:nil];
        });
	}
	
	return ask;
}

- (void)showRatingAlert {

	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:self.askForReviewTitle
														 message:self.askForReviewBody
														delegate:self
											   cancelButtonTitle:self.noButton
											   otherButtonTitles:self.reviewButton, self.askLaterButton, nil];
    alertView.tag = 2;
	self.ratingAlert = alertView;
	[alertView show];
    
}

- (void)showQuestionAlert
{      
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:self.doYouLikeAppTitle
														 message:self.doYouLikeAppBody
														delegate:self
											   cancelButtonTitle:self.askLaterButton
											   otherButtonTitles:self.likeItButton, self.dontLikeItButton, nil];
    alertView.tag = 1;
	self.questionAlert = alertView;
	[alertView show];
    
}

- (BOOL)ratingConditionsHaveBeenMet {
	if (Ask4AppReviews_DEBUG)
		return YES;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSDate *dateOfFirstLaunch = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kAsk4AppReviewsFirstUseDate]];
	NSTimeInterval timeSinceFirstLaunch = [[NSDate date] timeIntervalSinceDate:dateOfFirstLaunch];
	NSTimeInterval timeUntilRate = 60 * 60 * 24 * self.daysUntilPrompt;
	if (timeSinceFirstLaunch < timeUntilRate)
		return NO;
	
	// check if the app has been used enough
	int useCount = [userDefaults integerForKey:kAsk4AppReviewsUseCount];
	if (useCount <= self.usesUntilPrompt)
		return NO;
	
	// check if the user has done enough significant events
	int sigEventCount = [userDefaults integerForKey:kAsk4AppReviewsSignificantEventCount];
	if (sigEventCount <= self.eventsUntilPrompt)
		return NO;
	
	// has the user previously declined to rate this version of the app?
	if ([userDefaults boolForKey:kAsk4AppReviewsDeclinedToRate])
		return NO;
	
	// has the user already rated the app?
	if ([userDefaults boolForKey:kAsk4AppReviewsRatedCurrentVersion])
		return NO;
	
	// if the user wanted to be reminded later, has enough time passed?
	NSDate *reminderRequestDate = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kAsk4AppReviewsReminderRequestDate]];
	NSTimeInterval timeSinceReminderRequest = [[NSDate date] timeIntervalSinceDate:reminderRequestDate];
	NSTimeInterval timeUntilReminder = 60 * 60 * 24 * self.daysBeforeReminding;
	if (timeSinceReminderRequest < timeUntilReminder)
		return NO;
    
    //if we are limited to prompting to a specific time, is that time now?
    if (self.timeRange) {
        if (![self.timeRange isNow]) {
            return NO;
        }
    }
	
	return YES;
}

- (void)incrementUseCount {
	// get the app's version
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	
	// get the version number that we've been tracking
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *trackingVersion = [userDefaults stringForKey:kAsk4AppReviewsCurrentVersion];
	if (trackingVersion == nil)
	{
		trackingVersion = version;
		[userDefaults setObject:version forKey:kAsk4AppReviewsCurrentVersion];
	}
	
	if (Ask4AppReviews_DEBUG)
		NSLog(@"Ask4AppReviews Tracking version: %@", trackingVersion);
	
	if ([trackingVersion isEqualToString:version])
	{
		// check if the first use date has been set. if not, set it.
		NSTimeInterval timeInterval = [userDefaults doubleForKey:kAsk4AppReviewsFirstUseDate];
		if (timeInterval == 0)
		{
			timeInterval = [[NSDate date] timeIntervalSince1970];
			[userDefaults setDouble:timeInterval forKey:kAsk4AppReviewsFirstUseDate];
		}
		
		// increment the use count
		int useCount = [userDefaults integerForKey:kAsk4AppReviewsUseCount];
		useCount++;
		[userDefaults setInteger:useCount forKey:kAsk4AppReviewsUseCount];
		if (Ask4AppReviews_DEBUG)
			NSLog(@"Ask4AppReviews Use count: %d", useCount);
	}
	else
	{
		// it's a new version of the app, so restart tracking
		[userDefaults setObject:version forKey:kAsk4AppReviewsCurrentVersion];
		[userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kAsk4AppReviewsFirstUseDate];
		[userDefaults setInteger:1 forKey:kAsk4AppReviewsUseCount];
		[userDefaults setInteger:0 forKey:kAsk4AppReviewsSignificantEventCount];
		[userDefaults setBool:NO forKey:kAsk4AppReviewsRatedCurrentVersion];
		[userDefaults setBool:NO forKey:kAsk4AppReviewsDeclinedToRate];
		[userDefaults setDouble:0 forKey:kAsk4AppReviewsReminderRequestDate];
        
	}
	
	[userDefaults synchronize];
}

- (void)incrementSignificantEventCount {
	// get the app's version
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	
	// get the version number that we've been tracking
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *trackingVersion = [userDefaults stringForKey:kAsk4AppReviewsCurrentVersion];
	if (trackingVersion == nil)
	{
		trackingVersion = version;
		[userDefaults setObject:version forKey:kAsk4AppReviewsCurrentVersion];
	}
	
	if (Ask4AppReviews_DEBUG)
		NSLog(@"Ask4AppReviews Tracking version: %@", trackingVersion);
	
	if ([trackingVersion isEqualToString:version])
	{
		// check if the first use date has been set. if not, set it.
		NSTimeInterval timeInterval = [userDefaults doubleForKey:kAsk4AppReviewsFirstUseDate];
		if (timeInterval == 0)
		{
			timeInterval = [[NSDate date] timeIntervalSince1970];
			[userDefaults setDouble:timeInterval forKey:kAsk4AppReviewsFirstUseDate];
		}
		
		// increment the significant event count
		int sigEventCount = [userDefaults integerForKey:kAsk4AppReviewsSignificantEventCount];
		sigEventCount++;
		[userDefaults setInteger:sigEventCount forKey:kAsk4AppReviewsSignificantEventCount];
		if (Ask4AppReviews_DEBUG)
			NSLog(@"Ask4AppReviews Significant event count: %d", sigEventCount);
	}
	else
	{
		// it's a new version of the app, so restart tracking
		[userDefaults setObject:version forKey:kAsk4AppReviewsCurrentVersion];
		[userDefaults setDouble:0 forKey:kAsk4AppReviewsFirstUseDate];
		[userDefaults setInteger:0 forKey:kAsk4AppReviewsUseCount];
		[userDefaults setInteger:1 forKey:kAsk4AppReviewsSignificantEventCount];
		[userDefaults setBool:NO forKey:kAsk4AppReviewsRatedCurrentVersion];
		[userDefaults setBool:NO forKey:kAsk4AppReviewsDeclinedToRate];
		[userDefaults setDouble:0 forKey:kAsk4AppReviewsReminderRequestDate];
	}
	
	[userDefaults synchronize];
}

- (void)incrementAndRate:(BOOL)canPromptForRating {
	[self incrementUseCount];
	
	if (canPromptForRating &&
		[self ratingConditionsHaveBeenMet] &&
		[self connectedToNetwork])
	{
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           //If they have been asked before and said remind me take them straight to the rating alert

                           NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                           double kAsk4AppReviewsReminder = [userDefaults doubleForKey:kAsk4AppReviewsReminderRequestDate];
                           
                           if(kAsk4AppReviewsReminder == 0 || Ask4AppReviews_DEBUG)
                           {
                               [self showQuestionAlert];
                           }else{
                               [self showRatingAlert];
                           }
                       });
	}
}

- (void)incrementSignificantEventAndRate:(BOOL)canPromptForRating {
	[self incrementSignificantEventCount];
	
	if (canPromptForRating &&
		[self ratingConditionsHaveBeenMet] &&
		[self connectedToNetwork])
	{
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                           double kAsk4AppReviewsReminder = [userDefaults doubleForKey:kAsk4AppReviewsReminderRequestDate];
                           
                           if(kAsk4AppReviewsReminder == 0 || Ask4AppReviews_DEBUG)
                           {
                               [self showQuestionAlert];
                           }else{
                               [self showRatingAlert];
                           }
                       });
	}
}

+ (void)appLaunched {
	[Ask4AppReviews appLaunched:YES];
}

+ (void)appLaunched:(BOOL)canPromptForRating  {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [[Ask4AppReviews sharedInstance] incrementAndRate:canPromptForRating];
                   });
}


+ (void)appLaunched:(BOOL)canPromptForRating viewController:(UIViewController*)viewController {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [[Ask4AppReviews sharedInstance] setTheViewController:viewController];
                       
                       [[Ask4AppReviews sharedInstance] incrementAndRate:canPromptForRating];
                       
                   });
}

- (void)hideRatingAlert {
	if (self.ratingAlert.visible) {
		if (Ask4AppReviews_DEBUG)
			NSLog(@"Ask4AppReviews Hiding Alert");
        
		[self.ratingAlert dismissWithClickedButtonIndex:-1 animated:NO];
        
	}	
    if (self.questionAlert.visible) {
		if (Ask4AppReviews_DEBUG)
			NSLog(@"Ask4AppReviews questionAlert Alert");
        
		[self.questionAlert dismissWithClickedButtonIndex:-1 animated:NO];
        
	}	
}

+ (void)appWillResignActive {
	if (Ask4AppReviews_DEBUG)
		NSLog(@"Ask4AppReviews appWillResignActive");
	[[Ask4AppReviews sharedInstance] hideRatingAlert];
}

+ (void)appEnteredForeground:(BOOL)canPromptForRating {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [[Ask4AppReviews sharedInstance] incrementAndRate:canPromptForRating];
                   });
}

+ (void)userDidSignificantEvent:(BOOL)canPromptForRating {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [[Ask4AppReviews sharedInstance] incrementSignificantEventAndRate:canPromptForRating];
                   });
}

+ (void)rateApp {
#if TARGET_IPHONE_SIMULATOR
	NSLog(@"Ask4AppReviews NOTE: iTunes App Store is not supported on the iOS simulator. Unable to open App Store page.");
#else
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *reviewURL = [templateReviewURL stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%@", [self appStoreAppID]]];

	[userDefaults setBool:YES forKey:kAsk4AppReviewsRatedCurrentVersion];
	[userDefaults synchronize];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
#endif
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (result == MFMailComposeResultSent) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(ask4ReviewsDidSendEmail:)]){
            [self.delegate ask4ReviewsDidSendEmail:self];
        }
    } else {
        if(self.delegate && [self.delegate respondsToSelector:@selector(ask4ReviewsDidNotSendEmail:)]){
            [self.delegate ask4ReviewsDidNotSendEmail:self];
        }
    }
    [theViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //NSLog(@"tag %i buttonIndex %i  ", alertView.tag, buttonIndex);
    if(alertView.tag == 1)
    {
        
        //we are asking if they like the app: like, dislike, remind
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        switch (buttonIndex) {
            case 0:
            {
                // remind them later
                
                if(self.delegate && [self.delegate respondsToSelector:@selector(ask4ReviewsDidOptToRemindLaterFromQuestion:)]){
                    [self.delegate ask4ReviewsDidOptToRemindLaterFromQuestion:self];
                }
                
                [userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kAsk4AppReviewsReminderRequestDate];
                [userDefaults synchronize];
                
                break;
            }
            case 1:
            {
                //like it
                
                if(self.delegate && [self.delegate respondsToSelector:@selector(ask4ReviewsDidAskForReview:)]){
                    [self.delegate ask4ReviewsDidAskForReview:self];
                }
                [self showRatingAlert];
                break;
            }
            case 2:
                
                //They have issues ask them to fill in a email question
                //You need to include UIMessage Framework
                
                if(self.delegate && [self.delegate respondsToSelector:@selector(ask4ReviewsDidOpenEmailCompose:)]) {
                    [self.delegate ask4ReviewsDidOpenEmailCompose:self];
                }
                
                if ([MFMailComposeViewController canSendMail]) {
                    MFMailComposeViewController *mPicker = [[MFMailComposeViewController alloc] init];
                    mPicker.mailComposeDelegate = self;
                    
                    [mPicker setSubject:self.emailSubject];
                    
                    NSArray *toRecipients = [NSArray arrayWithObject:[Ask4AppReviews developerEmail]]; 
                    
                    [mPicker setToRecipients:toRecipients];
                    [mPicker setMessageBody:self.emailBody isHTML:NO];
                    
                    [theViewController presentViewController:mPicker animated:YES completion:nil];

                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure" 
                                                                    message:Ask4AppReviews_DEVELOPER_EMAIL_ALERT
                                                                   delegate:nil 
                                                          cancelButtonTitle:@"OK" 
                                                          otherButtonTitles: nil];
                    [alert show];
                }
                //We dont want them to rate it
                [userDefaults setBool:YES forKey:kAsk4AppReviewsDeclinedToRate];
                [userDefaults synchronize];
                           
                break;
            default:
                break;
        }
        
        
    }else if(alertView.tag == 2)
    {
        
        //we are asking if the have any issues using app no, yes or remind me later
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        switch (buttonIndex) {
            case 0:
            {
                // they don't want to rate it
                
                if(self.delegate && [self.delegate respondsToSelector:@selector(ask4ReviewsDidDeclineToReview:)]){
                    [self.delegate ask4ReviewsDidDeclineToReview:self];
                }
                
                [userDefaults setBool:YES forKey:kAsk4AppReviewsDeclinedToRate];
                [userDefaults synchronize];
                
                break;
            }
            case 1:
            {
                // they want to rate it
                
                if(self.delegate && [self.delegate respondsToSelector:@selector(ask4ReviewsDidOptToReview:)]){
                    [self.delegate ask4ReviewsDidOptToReview:self];
                }
                
                [Ask4AppReviews rateApp];
                break;
            }
            case 2:
                // remind them later
                
                if(self.delegate && [self.delegate respondsToSelector:@selector(ask4ReviewsDidOptToRemindLaterFromPromptToReview:)]){
                    [self.delegate ask4ReviewsDidOptToRemindLaterFromPromptToReview:self];
                }
                
                [userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kAsk4AppReviewsReminderRequestDate];
                [userDefaults synchronize];
                break;
            default:
                break;
        }
        

    }
    
}

-(NSString*) description {
    NSMutableString *description = [NSMutableString stringWithString:@"Debug: "];
    if (Ask4AppReviews_DEBUG)
		[description appendString:@"Yes"];
    else
        [description appendString:@"No"];
    
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSDate *dateOfFirstLaunch = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kAsk4AppReviewsFirstUseDate]];
	NSTimeInterval timeSinceFirstLaunch = [[NSDate date] timeIntervalSinceDate:dateOfFirstLaunch];
	NSTimeInterval timeUntilRate = 60 * 60 * 24 * self.daysUntilPrompt;
	
    [description appendFormat:@"\nDate of first Launch: %@ Time Since First Launch: %f Time Until Rate: %f Days Until Prompt: %d", dateOfFirstLaunch, timeSinceFirstLaunch, timeUntilRate, self.daysUntilPrompt];
    
    if (timeSinceFirstLaunch < timeUntilRate)
		[description appendString:@"\ntimeSinceFirstLaunch < timeUntilRate = NO - WOULD NOT PROMPT"];
    else
        [description appendString:@"\ntimeSinceFirstLaunch < timeUntilRate = YES"];
	
    [description appendFormat:@"\nUse count: %d Uses until prompt: %d", [userDefaults integerForKey:kAsk4AppReviewsUseCount], self.usesUntilPrompt];
    
	[description appendFormat:@"\nSig events: %d Events until prompt: %d", [userDefaults integerForKey:kAsk4AppReviewsSignificantEventCount], self.eventsUntilPrompt];
    
    [description appendFormat:@"\nUser already declined: %d", [userDefaults boolForKey:kAsk4AppReviewsDeclinedToRate]];
	
    [description appendFormat:@"\nUser already rated: %d", [userDefaults boolForKey:kAsk4AppReviewsRatedCurrentVersion]];
	
	// if the user wanted to be reminded later, has enough time passed?
	NSDate *reminderRequestDate = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kAsk4AppReviewsReminderRequestDate]];
	NSTimeInterval timeSinceReminderRequest = [[NSDate date] timeIntervalSinceDate:reminderRequestDate];
	NSTimeInterval timeUntilReminder = 60 * 60 * 24 * self.daysBeforeReminding;
    
    [description appendFormat:@"\nReminder Request date: %@ Time Since Reminder Request: %f Time Until Remind: %f Days Until Prompt: %d", reminderRequestDate, timeSinceReminderRequest, timeUntilReminder, self.daysBeforeReminding];
    
	if (timeSinceReminderRequest < timeUntilReminder)
		[description appendString:@"\ntimeSinceReminderRequest < timeUntilReminder: NO - WOULD NOT PROMPT"];
    else
		[description appendString:@"\ntimeSinceReminderRequest < timeUntilReminder: NO"];
    
    [description appendFormat:@"\nTime range: %@", self.timeRange];
    if (![self.timeRange isNow])
        [description appendFormat:@"[timeRange isNow]: NO - WOULD NOT PROMPT"];
    else
        [description appendFormat:@"[timeRange isNow]: YES"];
    
    return description;
}

@end
