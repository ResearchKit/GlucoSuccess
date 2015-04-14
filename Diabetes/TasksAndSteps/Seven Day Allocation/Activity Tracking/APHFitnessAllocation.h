//
//  APHFitnessAllocation.h
//  Diabetes
//
//  Copyright (c) 2014 Apple, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@import APCAppCore;

extern NSString *const kDatasetDateKey;
extern NSString *const kDatasetValueKey;
extern NSString *const kDatasetSegmentNameKey;
extern NSString *const kDatasetSegmentColorKey;
extern NSString *const kDatasetSegmentKey;
extern NSString *const kDatasetDateHourKey;
extern NSString *const kSegmentSumKey;
extern NSString *const kSevenDayFitnessStartDateKey;
extern NSString *const APHSevenDayAllocationDataIsReadyNotification;
extern NSString *const APHSevenDayAllocationHealthKitDataIsReadyNotification;

@interface APHFitnessAllocation : NSObject

@property (nonatomic) NSTimeInterval activeSeconds;

- (instancetype)initWithAllocationStartDate:(NSDate *)startDate;
- (NSArray *)todaysAllocation;
- (NSArray *)yesterdaysAllocation;
- (NSArray *)weeksAllocation;
- (void) startDataCollection;

@end
