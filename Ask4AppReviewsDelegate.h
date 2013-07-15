/*
 This file is part of Ask4AppReviewsABOptimised.
 
 Copyright (c) 2012, Lewis Smith
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
 * Ask4AppReviewsDelegate.h
 * Ask4AppReviewsDelegate
 *
 * Created by Lewis Smith
 * Ask4AppReviewsABOptimised (forked from Ask4AppReviews).
 */

#import <Foundation/Foundation.h>

@class Ask4AppReviews;

@protocol Ask4AppReviewsDelegate <NSObject>

-(void)ask4ReviewsDidAskQuestion:(Ask4AppReviews *)ask4AppReviews;
-(void)ask4ReviewsDidOptToRemindLaterFromQuestion:(Ask4AppReviews *)ask4AppReviews;
-(void)ask4ReviewsDidOpenEmailCompose:(Ask4AppReviews *)ask4AppReviews;
-(void)ask4ReviewsDidSendEmail:(Ask4AppReviews *)ask4AppReviews;
-(void)ask4ReviewsDidNotSendEmail:(Ask4AppReviews *)ask4AppReviews;

-(void)ask4ReviewsDidAskForReview:(Ask4AppReviews *)ask4AppReviews;
-(void)ask4ReviewsDidOptToReview:(Ask4AppReviews *)ask4AppReviews;
-(void)ask4ReviewsDidDeclineToReview:(Ask4AppReviews *)ask4AppReviews;
-(void)ask4ReviewsDidOptToRemindLaterFromPromptToReview:(Ask4AppReviews *)ask4AppReviews;
@end
