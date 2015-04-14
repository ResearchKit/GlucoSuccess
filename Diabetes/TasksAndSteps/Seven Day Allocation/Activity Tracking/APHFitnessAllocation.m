//
//  APHFitnessAllocation.m
//  Diabetes
//
//  Copyright (c) 2014 Apple, Inc. All rights reserved.
//

#import "APHFitnessAllocation.h"
#import <CoreMotion/CoreMotion.h>
#import "APHTheme.h"

static NSDateFormatter *dateFormatter = nil;

NSString *const kDatasetDateKey         = @"datasetDateKey";
NSString *const kDatasetValueKey        = @"datasetValueKey";
NSString *const kDatasetSegmentNameKey  = @"datasetSegmentNameKey";
NSString *const kDatasetSegmentColorKey = @"datasetSegmentColorKey";

NSString *const kDatasetSegmentKey      = @"segmentKey";
NSString *const kDatasetDateHourKey     = @"dateHourKey";
NSString *const kSegmentSumKey          = @"segmentSumKey";

NSString *const kSevenDayFitnessStartDateKey  = @"sevenDayFitnessStartDateKey";

NSString *const APHSevenDayAllocationDataIsReadyNotification = @"APHSevenDayAllocationDataIsReadyNotification";
NSString *const APHSevenDayAllocationSleepDataIsReadyNotification = @"APHSevenDayAllocationSleepDataIsReadyNotification";
NSString *const APHSevenDayAllocationHealthKitDataIsReadyNotification = @"APHSevenDayAllocationHealthKitIsReadyNotification";

NSString *const kDatasetDateKeyFormat   = @"YYYY-MM-dd-hh";

typedef NS_ENUM(NSUInteger, SevenDayFitnessDatasetKinds)
{
    SevenDayFitnessDatasetKindToday = 0,
    SevenDayFitnessDatasetKindWeek,
    SevenDayFitnessDataSetKindYesterday
};

typedef NS_ENUM(NSUInteger, SevenDayFitnessQueryType)
{
    SevenDayFitnessQueryTypeWake = 0,
    SevenDayFitnessQueryTypeSleep,
    SevenDayFitnessQueryTypeTotal
};

@interface APHFitnessAllocation()

@property (nonatomic, strong) CMMotionActivityManager *motionActivityManager;

@property (nonatomic, strong) NSMutableArray *datasetForToday;
@property (nonatomic, strong) __block NSMutableArray *datasetForTheWeek;
@property (nonatomic, strong) NSMutableArray *datasetForYesterday;

@property (nonatomic, strong) NSMutableArray *datasetNormalized;

@property (nonatomic, strong) NSMutableArray *motionDatasetForToday;
@property (nonatomic, strong) __block NSMutableArray *motionDatasetForTheWeek;

@property (nonatomic, strong) __block NSMutableArray *sleepDataset;
@property (nonatomic, strong) __block NSMutableArray *wakeDataset;

@property (nonatomic, strong) NSDate *allocationStartDate;

@property (nonatomic, strong) NSString *segmentInactive;
@property (nonatomic, strong) NSString *segmentSedentary;
@property (nonatomic, strong) NSString *segmentModerate;
@property (nonatomic, strong) NSString *segmentVigorous;
@property (nonatomic, strong) NSString *segmentSleep;

@property (nonatomic, strong) __block NSMutableArray *motionData;

@property (nonatomic,strong) NSDate *userDayStart;
@property (nonatomic,strong) NSDate *userDayEnd;

@end

@implementation APHFitnessAllocation

- (instancetype)initWithAllocationStartDate:(NSDate *)startDate
{
    self = [super init];
    
    if (self) {
        if (startDate) {
            if (startDate) {
                _allocationStartDate = startDate;
            } else {
                _allocationStartDate = [NSDate date];
            }
            
            if (!dateFormatter) {
                dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
                [dateFormatter setDateFormat:kDatasetDateKeyFormat];
            }
            
            
            _datasetForToday = [NSMutableArray array];
            _datasetForTheWeek = [NSMutableArray array];
            _datasetForYesterday = [NSMutableArray array];
            
            _motionDatasetForToday = [NSMutableArray array];
            _motionDatasetForTheWeek = [NSMutableArray array];
            
            _sleepDataset = [NSMutableArray array];
            _wakeDataset = [NSMutableArray array];
            
            _motionData = [NSMutableArray new];
            _datasetNormalized = [NSMutableArray new];
            
            _segmentSleep = NSLocalizedString(@"Sleep", @"Sleep");
            _segmentInactive = NSLocalizedString(@"Light", @"Light");
            _segmentSedentary = NSLocalizedString(@"Sedentary", @"Sedentary");
            _segmentModerate = NSLocalizedString(@"Moderate", @"Moderate");
            _segmentVigorous = NSLocalizedString(@"Vigorous", @"Vigorous");
            
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(motionDataGatheringComplete)
                                                 name:APHSevenDayAllocationSleepDataIsReadyNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reporterDone:)
                                                 name:APCMotionHistoryReporterDoneNotification
                                               object:nil];

    
    return self;
}

- (void) startDataCollection {
    
    
    NSDate *startDate = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                         minute:0
                                                         second:0
                                                         ofDate:self.allocationStartDate
                                                        options:0];
    
    NSDateComponents *numberOfDaysFromStartDate = [[NSCalendar currentCalendar] components:NSCalendarUnitDay
                                                                                  fromDate:startDate
                                                                                    toDate:[NSDate date]
                                                                                   options:NSCalendarWrapComponents];
    
    
    
    // if today number of days will be zero.
    

    // numberOfDaysFromStartDate provides the difference of days from now to start
    // of task and therefore if there is no difference we are only getting data for one day.
    numberOfDaysFromStartDate.day += 1;
    
    APCMotionHistoryReporter *reporter = [APCMotionHistoryReporter sharedInstance];
    [reporter startMotionCoProcessorDataFrom:[NSDate dateWithTimeIntervalSinceNow:-24 * 60 * 60] andEndDate:[NSDate new] andNumberOfDays:numberOfDaysFromStartDate.day];

}

- (void)reporterDone:(NSNotification *)notification {
    
    APCMotionHistoryReporter *reporter = [APCMotionHistoryReporter sharedInstance];
    

    NSArray * theMotionData = reporter.retrieveMotionReport;
    //The count will be the number of days in the array, each element represents a day
    
    if(theMotionData.count > 0)
    {
        for (NSArray *dayArray in theMotionData)
        {
            
            NSUInteger inactiveCounter    = 0;
            NSUInteger sedentaryCounter   = 0;
            NSUInteger moderateCounter    = 0;
            NSUInteger vigorousCounter    = 0;


            for(APCMotionHistoryData * theData in dayArray) {
                
                if(theData.activityType == ActivityTypeSleeping)
                {
                    [self.sleepDataset addObject:@(theData.timeInterval)];
                }
                else if(theData.activityType == ActivityTypeStationary)
                {
                    inactiveCounter += theData.timeInterval;
                }
                else if(theData.activityType == ActivityTypeWalking)
                {
                    moderateCounter += theData.timeInterval;
                }
                else if(theData.activityType == ActivityTypeRunning)
                {
                    vigorousCounter += theData.timeInterval;
                }
            
                
            }
            
            sedentaryCounter = inactiveCounter/3;
            [self.wakeDataset addObject:@{
                                          self.segmentInactive: @(inactiveCounter),
                                          self.segmentSedentary: @(sedentaryCounter),
                                          self.segmentModerate: @(moderateCounter),
                                          self.segmentVigorous: @(vigorousCounter),
                                          self.segmentSleep: self.sleepDataset[0]
                                          }];
          

        }
    }
    
    NSDictionary *dataSet = self.wakeDataset[0];
    NSNumber *moderate = [dataSet objectForKey:self.segmentModerate];
    NSNumber *vigorous = [dataSet objectForKey:self.segmentVigorous];
    
    //    Active minutes = minutes of moderate activity + 2x(minutes of vigorous activity). This should be the TOTAL ACTIVE MINUTES FOR THE WEEK,
    self.activeSeconds = (double)(2 * [moderate doubleValue]) + [vigorous doubleValue];
    
    //Not sure if this is needed
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:APHSevenDayAllocationSleepDataIsReadyNotification object:nil];
    });
}
- (HKHealthStore *) healthStore {
    APCAppDelegate *delegate = (APCAppDelegate*)[UIApplication sharedApplication].delegate;
    
    return delegate.dataSubstrate.healthStore;
}

#pragma mark - Public Interface

- (NSArray *)todaysAllocation
{
    NSArray *allocationForToday = nil;
    NSDictionary *todaysData = [self.datasetNormalized firstObject];
    
    allocationForToday = [self buildSegmentArrayForData:todaysData];
    
    return allocationForToday;
}

- (NSArray *)yesterdaysAllocation
{
    NSArray *allcationForYesterday = nil;
    if ([self.datasetNormalized count] > 1) {
        NSUInteger yesterdayIndex = [self.datasetNormalized indexOfObject:[self.datasetNormalized firstObject]] + 1;
        NSDictionary *yesterdaysData = [self.datasetNormalized objectAtIndex:yesterdayIndex];
        
        allcationForYesterday = [self buildSegmentArrayForData:yesterdaysData];
    }
    
    return allcationForYesterday;
}

- (NSArray *)weeksAllocation
{
    NSArray *allocationForTheWeek = nil;
    
    NSUInteger weekInactiveCounter = 0;
    NSUInteger weekSedentaryCounter = 0;
    NSUInteger weekModerateCounter = 0;
    NSUInteger weekVigorousCounter = 0;
    NSUInteger weekSleepCounter = 0;
    
    for (NSDictionary *day in self.datasetNormalized) {
        
        weekInactiveCounter += [day[self.segmentInactive] integerValue];
        weekSedentaryCounter += [day[self.segmentSedentary] integerValue];
        weekModerateCounter += [day[self.segmentModerate] integerValue];
        weekVigorousCounter += [day[self.segmentVigorous] integerValue];
        weekSleepCounter += [day[self.segmentSleep] integerValue];
    }
    
    NSDictionary *weekData = @{
                               self.segmentInactive: @(weekInactiveCounter),
                               self.segmentSedentary: @(weekSedentaryCounter),
                               self.segmentModerate: @(weekModerateCounter),
                               self.segmentVigorous: @(weekVigorousCounter),
                               self.segmentSleep: @(weekSleepCounter)
                              };
    
    allocationForTheWeek = [self buildSegmentArrayForData:weekData];
    
    return allocationForTheWeek;
}

#pragma mark - Helpers

- (NSArray *)buildSegmentArrayForData:(NSDictionary *)data
{
    NSMutableArray *allocationData = [NSMutableArray new];
    NSArray *segments = @[self.segmentSleep, self.segmentSedentary, self.segmentInactive, self.segmentModerate, self.segmentVigorous];
    UIColor *segmentColor = nil;
    
    for (NSString *segmentId in segments) {
        if ([segmentId isEqualToString:self.segmentSleep]) {
            segmentColor =[APHTheme colorForActivitySleep];
        } else if ([segmentId isEqualToString:self.segmentInactive]) {
            segmentColor = [APHTheme colorForActivityInactive];
        } else if ([segmentId isEqualToString:self.segmentSedentary]) {
            segmentColor = [APHTheme colorForActivitySedentary];
        } else if ([segmentId isEqualToString:self.segmentModerate]) {
            segmentColor = [APHTheme colorForActivityModerate];
        } else {
            segmentColor = [APHTheme colorForActivityVigorous];
        }
        
        [allocationData addObject:@{
                                    kSegmentSumKey: (data[segmentId]) ?: @(0),
                                    kDatasetSegmentKey: segmentId,
                                    kDatasetSegmentColorKey: segmentColor
                                    }];
    }
    
    return allocationData;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:APHSevenDayAllocationSleepDataIsReadyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:APCMotionHistoryReporterDoneNotification object:nil];
}

- (void)motionDataGatheringComplete
{
    for (NSDictionary *day in self.sleepDataset) {
        NSUInteger dayIndex = [self.sleepDataset indexOfObject:day];
        
        NSMutableDictionary *wakeData = [[self.wakeDataset objectAtIndex:dayIndex] mutableCopy];
        
        //[wakeData setObject:day[self.segmentSleep] forKey:self.segmentSleep];
        
        [self.wakeDataset replaceObjectAtIndex:dayIndex withObject:wakeData];
    }
    
    self.datasetNormalized = self.wakeDataset;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:APHSevenDayAllocationDataIsReadyNotification
                                                            object:nil];
    });
    

}

@end
