/*
 This file is part of Ask4AppReviews.
    
 Copyright (c) 2012, Arash Payan
 All rights reserved.
 
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
 * Ask4AppReviews.h
 * Ask4AppReviews
 *
 * Created by Luke Durrant on 7/12.
 * Ask4AppReviews (forked from Appirater).
 */

#import <Foundation/Foundation.h>
#import "Ask4AppReviewsDelegate.h"
#import "Ask4AppReviewsTimeRange.h"

extern NSString *const kAsk4AppReviewsFirstUseDate;
extern NSString *const kAsk4AppReviewsUseCount;
extern NSString *const kAsk4AppReviewsSignificantEventCount;
extern NSString *const kAsk4AppReviewsCurrentVersion;
extern NSString *const kAsk4AppReviewsRatedCurrentVersion;
extern NSString *const kAsk4AppReviewsDeclinedToRate;
extern NSString *const kAsk4AppReviewsReminderRequestDate;

#define Ask4AppReviews_LOCALIZED_DEVELOPER_EMAIL_ALERT NSLocalizedString(@"Your device doesn't support sending email please email %@", nil)

#define Ask4AppReviews_DEVELOPER_EMAIL_ALERT			[NSString stringWithFormat:Ask4AppReviews_LOCALIZED_DEVELOPER_EMAIL_ALERT, [Ask4AppReviews developerEmail]]

/*
 'YES' will show the Ask4AppReviews alert everytime. Useful for testing how your message
 looks and making sure the link to your app's review page works.
 */
#define Ask4AppReviews_DEBUG				NO

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>


@interface Ask4AppReviews : NSObject <UIAlertViewDelegate, MFMailComposeViewControllerDelegate> {

	UIAlertView		*questionAlert;
    UIAlertView		*ratingAlert;
    UIViewController *theViewController;
    
}
@property(nonatomic, retain) UIAlertView *questionAlert;
@property(nonatomic, retain) UIAlertView *ratingAlert;

@property(nonatomic, retain) UIViewController *theViewController;

@property(nonatomic, retain) NSObject <Ask4AppReviewsDelegate> *delegate;

/*
 Title: First question (Do you like the app?)
 */
@property(nonatomic, retain) NSString *doYouLikeAppTitle;

/*
 Body: First question (Do you like the app?)
 */
@property(nonatomic, retain) NSString *doYouLikeAppBody;

/*
 Button: I Like It
 */
@property(nonatomic, retain) NSString *likeItButton;

/*
 Button: I Don't Like It
 */
@property(nonatomic, retain) NSString *dontLikeItButton;

/*
 Button: Ask Later
 */
@property(nonatomic, retain) NSString *askLaterButton;


/*
  Title: Will you leave a review
 */
@property(nonatomic, retain) NSString *askForReviewTitle;

/*
 Body: Will you leave a review
 */
@property(nonatomic, retain) NSString *askForReviewBody;

/*
 Button: Yes, I'll leave a review
 */
@property(nonatomic, retain) NSString *reviewButton;

/*
 Button: No I won't leave a review
 */
@property(nonatomic, retain) NSString *noButton;

/*
 Email subject, if they don't like it
 */
@property(nonatomic, retain) NSString *emailSubject;

/*
 Email body, if they don't like it
 */
@property(nonatomic, retain) NSString *emailBody;

/*
 Users will need to have the same version of your app installed for this many
 days before they will be prompted to rate it.
 */
@property(nonatomic) NSInteger daysUntilPrompt;

/*
 List of days and times when a review prompt can be shown.
 */
@property(nonatomic, retain) Ask4AppReviewsTimeRange *timeRange;

/*
 An example of a 'use' would be if the user launched the app. Bringing the app
 into the foreground (on devices that support it) would also be considered
 a 'use'. You tell Ask4AppReviews about these events using the two methods:
 [Ask4AppReviews appLaunched:]
 [Ask4AppReviews appEnteredForeground:]
 
 Users need to 'use' the same version of the app this many times before
 before they will be prompted to rate it.
 */
@property(nonatomic) NSInteger usesUntilPrompt;

/*
 A significant event can be anything you want to be in your app. In a
 telephone app, a significant event might be placing or receiving a call.
 In a game, it might be beating a level or a boss. This is just another
 layer of filtering that can be used to make sure that only the most
 loyal of your users are being prompted to rate you on the app store.
 If you leave this at a value of -1, then this won't be a criteria
 used for rating. To tell Ask4AppReviews that the user has performed
 a significant event, call the method:
 [Ask4AppReviews userDidSignificantEvent:];
 */

@property(nonatomic) NSInteger eventsUntilPrompt;

/*
 Once the rating alert is presented to the user, they might select
 'Remind me later'. This value specifies how long (in days) Ask4AppReviews
 will wait before reminding them.
 */
@property(nonatomic) NSInteger daysBeforeReminding;

/*
 Set the delegate if you want to know when Appirater does something
 */
+ (void)setDelegate:(id<Ask4AppReviewsDelegate>)delegate;

/*
 DEPRECATED: While still functional, it's better to use
 appLaunched:(BOOL)canPromptForRating instead.
 
 Calls [Ask4AppReviews appLaunched:YES]. See appLaunched: for details of functionality.
 */
+ (void)appLaunched;

/*
 Tells Ask4AppReviews that the app has launched, and on devices that do NOT
 support multitasking, the 'uses' count will be incremented. You should
 call this method at the end of your application delegate's
 application:didFinishLaunchingWithOptions: method.
 
 If the app has been used enough to be rated (and enough significant events),
 you can suppress the rating alert
 by passing NO for canPromptForRating. The rating alert will simply be postponed
 until it is called again with YES for canPromptForRating. The rating alert
 can also be triggered by appEnteredForeground: and userDidSignificantEvent:
 (as long as you pass YES for canPromptForRating in those methods).
 */
+ (void)appLaunched:(BOOL)canPromptForRating;

+ (void)appLaunched:(BOOL)canPromptForRating viewController:(UIViewController*)viewController;

/*
 Tells Ask4AppReviews that the app was brought to the foreground on multitasking
 devices. You should call this method from the application delegate's
 applicationWillEnterForeground: method.
 
 If the app has been used enough to be rated (and enough significant events),
 you can suppress the rating alert
 by passing NO for canPromptForRating. The rating alert will simply be postponed
 until it is called again with YES for canPromptForRating. The rating alert
 can also be triggered by appLaunched: and userDidSignificantEvent:
 (as long as you pass YES for canPromptForRating in those methods).
 */
+ (void)appEnteredForeground:(BOOL)canPromptForRating;



/*
 Tells Ask4AppReviews that the user performed a significant event. A significant
 event is whatever you want it to be. If you're app is used to make VoIP
 calls, then you might want to call this method whenever the user places
 a call. If it's a game, you might want to call this whenever the user
 beats a level boss.
 
 If the user has performed enough significant events and used the app enough,
 you can suppress the rating alert by passing NO for canPromptForRating. The
 rating alert will simply be postponed until it is called again with YES for
 canPromptForRating. The rating alert can also be triggered by appLaunched:
 and appEnteredForeground: (as long as you pass YES for canPromptForRating
 in those methods).
 */
+ (void)userDidSignificantEvent:(BOOL)canPromptForRating;

/*
 Tells Ask4AppReviews to open the App Store page where the user can specify a
 rating for the app. Also records the fact that this has happened, so the
 user won't be prompted again to rate the app.

 The only case where you should call this directly is if your app has an
 explicit "Rate this app" command somewhere.  In all other cases, don't worry
 about calling this -- instead, just call the other functions listed above,
 and let Ask4AppReviews handle the bookkeeping of deciding when to ask the user
 whether to rate the app.
 */
+ (void)rateApp;

/* Get singleton instance to apply propery changes to 
 */
+ (Ask4AppReviews*)sharedInstance;

-(NSString*) description;
@end
