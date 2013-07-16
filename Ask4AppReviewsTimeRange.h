//
//  Ask4AppReviewsTimeRange.h
//  Body TrackIt
//
//  Created by Lewis Smith on 15/07/2013.
//
//

#import <Foundation/Foundation.h>

@interface Ask4AppReviewsTimeRange : NSObject

/* Array of NSNumbers which store integer values for days of the week
 1 is Sunday, 2 is Monday, etc
 */
@property (nonatomic, retain) NSArray *daysOfWeek;
@property (nonatomic, retain) NSString *description;
@property (nonatomic) NSInteger startHour;
@property (nonatomic) NSInteger endHour;

-(id) initWithDaysOfWeek:(NSArray*)daysOfWeek startHour:(NSInteger)startHour endHour:(NSInteger)endHour description:(NSString*) description;
-(BOOL) rangeIncludesDate:(NSDate*) date;
-(BOOL) isNow;

@end
