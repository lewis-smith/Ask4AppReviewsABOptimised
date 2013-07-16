//
//  Ask4AppReviewsTimeRange.m
//  Body TrackIt
//
//  Created by Lewis Smith on 15/07/2013.
//
//

#import "Ask4AppReviewsTimeRange.h"

@implementation Ask4AppReviewsTimeRange

-(id) initWithDaysOfWeek:(NSArray*)daysOfWeek startHour:(NSInteger)startHour endHour:(NSInteger)endHour description:(NSString*) description {
    if (self = [super init])  {
        self.daysOfWeek = daysOfWeek;
        self.startHour = startHour;
        self.endHour = endHour;
        self.description = description;
    }
    
    return self;
}

-(BOOL) rangeIncludesDate:(NSDate*) date {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:(NSWeekdayCalendarUnit | NSHourCalendarUnit) fromDate:date];

    NSInteger weekday = [comps weekday];
    NSInteger hour = [comps hour];
    
    if (self.daysOfWeek) {
        for (NSNumber *day in self.daysOfWeek) {
            if (weekday == day.integerValue) {
                if (hour >= self.startHour && hour < self.endHour) {
                    return YES;
                }
            }
        }
    } else {
        if (hour >= self.startHour && hour < self.endHour) {
            return YES;
        }
    }
    
    return NO;
}

-(BOOL) isNow {
    return [self rangeIncludesDate: [[NSDate alloc] init]];
}

@end
