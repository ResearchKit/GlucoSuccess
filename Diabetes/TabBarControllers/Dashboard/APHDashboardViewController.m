//
//  APHDashboardViewController.m
//  GlucoSuccess
//
// Copyright (c) 2015, Massachusetts General Hospital. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

/* Controllers */
#import "APHDashboardViewController.h"
#import "APHDashboardEditViewController.h"
#import "APHAppDelegate.h"
#import "APHGlucoseInsightsViewController.h"
#import "APHTableViewItem.h"
#import "APHFoodInsightsViewController.h"

static NSString * const kAPCBasicTableViewCellIdentifier       = @"APCBasicTableViewCell";
static NSString * const kAPCRightDetailTableViewCellIdentifier = @"APCRightDetailTableViewCell";
static NSString * const kAPCDashboardInsightsTableViewCellIdentifier = @"APCDashboardInsightsTableViewCell";
static NSString * const kAPCDashboardInsightTableViewCellIdentifier = @"APCDashboardInsightTableViewCell";
static NSString * const kAPCDashboardFoodInsightHeaderCellIdentifier = @"APCDashboardFoodInsightHeaderCell";
static NSString * const kAPCDashboardFoodInsightCellIdentifier = @"APCDashboardFoodInsightCell";
static NSInteger  const kDataCountLimit                         = 1;

static double kRefershDelayInSeconds = 60; // 3 minutes

@interface APHDashboardViewController ()<UIViewControllerTransitioningDelegate, APCFoodInsightDelegate, APCPieGraphViewDatasource>

@property (nonatomic, strong) NSMutableArray *rowItemsOrder;

@property (nonatomic, strong) __block APCScoring *stepScoring;
@property (nonatomic, strong) __block APCScoring *glucoseScoring;
@property (nonatomic, strong) __block APCScoring *weightScoring;
@property (nonatomic, strong) __block APCScoring *carbScoring;
@property (nonatomic, strong) __block APCScoring *sugarScoring;
@property (nonatomic, strong) __block APCScoring *waistScoring;
@property (nonatomic, strong) __block APCScoring *calorieScoring;

@property (nonatomic, strong) NSArray *allocationDataset;
@property (nonatomic) NSInteger dataCount;

@property (nonatomic, strong) NSOperationQueue *insightAndScoringQueue;

@property (nonatomic, strong) NSTimer *syncDataTimer;

@end

@implementation APHDashboardViewController


#pragma mark - Data

- (void)updatePieChart:(NSNotification *) __unused notification
{
    APHAppDelegate *appDelegate = (APHAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.allocationDataset = [appDelegate.sevenDayFitnessAllocationData todaysAllocation];
    [self.tableView reloadData];
}

#pragma mark - Init

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _rowItemsOrder = [NSMutableArray arrayWithArray:[defaults objectForKey:kAPCDashboardRowItemsOrder]];
        
        if (!_rowItemsOrder.count) {
            _rowItemsOrder = [[NSMutableArray alloc] initWithArray:@[
                                                                     @(kAPHDashboardItemTypeFitness),
                                                                     @(kAPHDashboardItemTypeGlucoseInsights),
                                                                     @(kAPHDashboardItemTypeDietInsights),
                                                                     @(kAPHDashboardItemTypeGlucose),
                                                                     @(kAPHDashboardItemTypeSteps),
                                                                     @(kAPHDashboardItemTypeCalories),
                                                                     @(kAPHDashboardItemTypeCarbohydrate),
                                                                     @(kAPHDashboardItemTypeSugar),
                                                                     @(kAPHDashboardItemTypeWeight)
                                                                     ]];
            
            [defaults setObject:[NSArray arrayWithArray:_rowItemsOrder] forKey:kAPCDashboardRowItemsOrder];
            [defaults synchronize];
            
        }
        
        self.title = NSLocalizedString(@"Dashboard", @"Dashboard");
        
    }
    
    return self;
}

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.insightAndScoringQueue = [NSOperationQueue sequentialOperationQueueWithName:@"Insights and Scoring"];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.stepInsight = [[APCInsights alloc] initWithFactor:APCInsightFactorSteps
                                          numberOfReadings:@(kNumberOfDaysToDisplay)
                                             insightPeriod:@(-1)
                                              baselineHigh:@(130)
                                             baselineOther:@(180)];
    
    self.carbsInsight = [[APCInsights alloc] initWithFactor:APCInsightFactorCarbohydrateConsumption
                                           numberOfReadings:@(kNumberOfDaysToDisplay)
                                              insightPeriod:@(-1)
                                               baselineHigh:@(130)
                                              baselineOther:@(180)];
    
    self.caloriesInsight = [[APCInsights alloc] initWithFactor:APCInsightFactorCalories
                                              numberOfReadings:@(kNumberOfDaysToDisplay)
                                                 insightPeriod:@(-1)
                                                  baselineHigh:@(130)
                                                 baselineOther:@(180)];
    
    self.sugarInsight = [[APCInsights alloc] initWithFactor:APCInsightFactorSugarConsumption
                                           numberOfReadings:@(kNumberOfDaysToDisplay)
                                              insightPeriod:@(-1)
                                               baselineHigh:@(130)
                                              baselineOther:@(180)];
    
    HKSampleType *carbSampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCarbohydrates];
    HKSampleType *sugarSampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietarySugar];
    
    self.carbFoodInsight = [[APCFoodInsight alloc] initFoodInsightForSampleType:carbSampleType
                                                                           unit:[HKUnit gramUnit]];
    self.carbFoodInsight.delegate = self;
    
    self.sugarFoodInsight = [[APCFoodInsight alloc] initFoodInsightForSampleType:sugarSampleType
                                                                            unit:[HKUnit gramUnit]];
    self.sugarFoodInsight.delegate = self;
    
    [self preparingScoringObjects];
    [self prepareData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:APHSevenDayAllocationDataIsReadyNotification
                                                  object:nil];
    [self removeTimer];
    
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePieChart:)
                                                 name:APHSevenDayAllocationDataIsReadyNotification
                                               object:nil];
    self.dataCount = 0;
    
    APHAppDelegate *appDelegate = (APHAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.allocationDataset = [appDelegate.sevenDayFitnessAllocationData todaysAllocation];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.rowItemsOrder = [NSMutableArray arrayWithArray:[defaults objectForKey:kAPCDashboardRowItemsOrder]];
    
    [self syncAllDatasources];
    
    if (self.syncDataTimer == nil) {
        self.syncDataTimer = [NSTimer scheduledTimerWithTimeInterval:kRefershDelayInSeconds
                                                              target:self
                                                            selector:@selector(syncAllDatasources)
                                                            userInfo:nil
                                                             repeats:YES];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeTimer];
}

- (void)removeTimer
{
    [self.syncDataTimer invalidate];
    self.syncDataTimer = nil;
}

- (void)syncAllDatasources
{
    [self prepareInsights];
    [self preparingScoringObjects];
    
    [self prepareData];
}

- (void)updateVisibleRowsInTableView:(NSNotification *) __unused notification
{
    self.dataCount++;
    
    [self prepareData];
}

#pragma mark - Data

- (void)prepareInsights
{
    __weak APCInsights *weakStepInsight = self.stepInsight;
    
    [self.insightAndScoringQueue addOperationWithBlock:^{
        [weakStepInsight factorInsight];
    }];
    
    __weak APCInsights *weakCarbsInsight = self.carbsInsight;
    
    [self.insightAndScoringQueue addOperationWithBlock:^{
        [weakCarbsInsight factorInsight];
    }];
    
    __weak APCInsights *weakCaloriesInsight = self.caloriesInsight;
    
    [self.insightAndScoringQueue addOperationWithBlock:^{
        [weakCaloriesInsight factorInsight];
    }];
    
    __weak APCInsights *weakSugarInsight = self.sugarInsight;
    
    [self.insightAndScoringQueue addOperationWithBlock:^{
        [weakSugarInsight factorInsight];
    }];
    
    __weak APCFoodInsight *weakCarbFoodInsight = self.carbFoodInsight;
    
    [self.insightAndScoringQueue addOperationWithBlock:^{
        [weakCarbFoodInsight insight];
    }];
    
    __weak APCFoodInsight *weakSugarFoodInsight = self.sugarFoodInsight;
    
    [self.insightAndScoringQueue addOperationWithBlock:^{
        [weakSugarFoodInsight insight];
    }];
}

- (void)preparingScoringObjects
{
    __weak APHDashboardViewController *weakSelf = self;
    
    [self.insightAndScoringQueue addOperationWithBlock:^{
        HKQuantityType *hkQuantity = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        weakSelf.stepScoring = [[APCScoring alloc] initWithHealthKitQuantityType:hkQuantity
                                                                            unit:[HKUnit countUnit]
                                                                    numberOfDays:-kNumberOfDaysToDisplay];
    }];
    
    [self.insightAndScoringQueue addOperationWithBlock:^{
        weakSelf.glucoseScoring = [[APCScoring alloc] initWithTask:kGlucoseLogSurveyIdentifier
                                                      numberOfDays:-kNumberOfDaysToDisplay
                                                          valueKey:@"value"
                                                           dataKey:nil
                                                           sortKey:nil
                                                           groupBy:APHTimelineGroupDay];
    }];
    
    [self.insightAndScoringQueue addOperationWithBlock:^{
        HKQuantityType *hkQuantity = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
        weakSelf.weightScoring = [[APCScoring alloc] initWithHealthKitQuantityType:hkQuantity
                                                                              unit:[HKUnit unitFromMassFormatterUnit:NSMassFormatterUnitPound]
                                                                      numberOfDays:-kNumberOfDaysToDisplay];
    }];
    
    [self.insightAndScoringQueue addOperationWithBlock:^{
        HKQuantityType *hkQuantity = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCarbohydrates];
        weakSelf.carbScoring = [[APCScoring alloc] initWithHealthKitQuantityType:hkQuantity
                                                                            unit:[HKUnit unitFromMassFormatterUnit:NSMassFormatterUnitGram]
                                                                    numberOfDays:-kNumberOfDaysToDisplay];
    }];
    
    [self.insightAndScoringQueue addOperationWithBlock:^{
        HKQuantityType *hkQuantity = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietarySugar];
        weakSelf.sugarScoring = [[APCScoring alloc] initWithHealthKitQuantityType:hkQuantity
                                                                             unit:[HKUnit unitFromMassFormatterUnit:NSMassFormatterUnitGram]
                                                                     numberOfDays:-kNumberOfDaysToDisplay];
    }];
    
    [self.insightAndScoringQueue addOperationWithBlock:^{
        HKQuantityType *hkQuantity = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
        weakSelf.calorieScoring = [[APCScoring alloc] initWithHealthKitQuantityType:hkQuantity
                                                                               unit:[HKUnit unitFromEnergyFormatterUnit:NSEnergyFormatterUnitKilocalorie]
                                                                       numberOfDays:-kNumberOfDaysToDisplay];
    }];
    
}

- (void)prepareData
{
    [self.items removeAllObjects];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setMaximumFractionDigits:0];
    
    {
        NSMutableArray *rowItems = [NSMutableArray new];
        
        NSUInteger allScheduledTasks = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.countOfAllScheduledTasksForToday;
        NSUInteger completedScheduledTasks = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.countOfCompletedScheduledTasksForToday;
        
        {
            APCTableViewDashboardProgressItem *item = [APCTableViewDashboardProgressItem new];
            item.identifier = kAPCDashboardProgressTableViewCellIdentifier;
            item.editable = NO;
            item.progress = (CGFloat)completedScheduledTasks/allScheduledTasks;
            item.caption = NSLocalizedString(@"Activity Completion", @"Activity Completion");
            item.info = NSLocalizedString(@"This is the percentage of today’s GlucoSuccess activities that you have completed. You can see what today’s items are at the Activities Menu.", @"");
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = item;
            row.itemType = kAPCTableViewDashboardItemTypeProgress;
            [rowItems addObject:row];
        }
        
        for (NSNumber *typeNumber in self.rowItemsOrder) {
            
            APHDashboardItemType rowType = typeNumber.integerValue;
            
            switch (rowType) {
                case kAPHDashboardItemTypeSteps:
                {
                    APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
                    item.caption = NSLocalizedString(@"Steps", @"");
                    item.graphData = self.stepScoring;
                    
                    NSNumber *numberOfDataPoints = [self.stepScoring numberOfDataPoints];
                    
                    if ([numberOfDataPoints integerValue] > 1) {
                        double avgSteps = [[self.stepScoring averageDataPoint] doubleValue];
                        item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : %0.0f",
                                                                                       @"Average: {avg. value}"), avgSteps];
                    }
                    
                    item.identifier = kAPCDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryPurpleColor];
                    item.info = NSLocalizedString(@"This plots your number of steps per day. It can be helpful to set a specific step goal each day. Remember to keep your iPhone on your person (e.g., in your pants pocket or clipped to your waist) to most accurately capture your physical activity.", @"");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                    
                case kAPHDashboardItemTypeGlucose:
                {
                    APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
                    item.caption = NSLocalizedString(@"Glucose", @"Glucose");
                    item.taskId = @"APHLogGlucose-42449E07-7124-40EF-AC93-CA5BBF95FC15";
                    item.graphData = self.glucoseScoring;
                    
                    NSNumber *numberOfDataPoints = [self.glucoseScoring numberOfDataPoints];
                    
                    if ([numberOfDataPoints integerValue] > 1) {
                        item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Min: %0.0f   Max: %0.0f", @"Min: {value} Max: {value}"),
                                           [[self.glucoseScoring minimumDataPoint] doubleValue], [[self.glucoseScoring maximumDataPoint] doubleValue]];
                    }
                    
                    item.identifier = kAPCDashboardGraphTableViewCellIdentifier;
                    item.graphType = kAPCDashboardGraphTypeDiscrete;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryGreenColor];
                    item.info = NSLocalizedString(@"This plots the blood glucose values you logged every day, as well as the daily minimum and maximum. Ask your physician for your specific targets. General target ranges are: before a meal (fasting or pre-prandial): 70 – 130 mg/dL; after a meal (post-prandial): less than 180 mg/dL.", @"");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeWaist:
                {
                    /*
                     APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
                     item.caption = NSLocalizedString(@"Waist", @"Waist");
                     item.graphData = self.waistScoring;
                     item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : %0.0f in", @"Average: {value} in"),
                     [[self.waistScoring averageDataPoint] doubleValue]];
                     item.identifier = kAPCDashboardGraphTableViewCellIdentifier;
                     item.editable = YES;
                     item.tintColor = [UIColor appTertiaryRedColor];
                     
                     #warning Replace Placeholder Values - APPLE-1576
                     item.info = NSLocalizedString(@"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.", @"");
                     
                     APCTableViewRow *row = [APCTableViewRow new];
                     row.item = item;
                     row.itemType = rowType;
                     [rowItems addObject:row];
                     */
                }
                    break;
                    
                case kAPHDashboardItemTypeWeight:
                {
                    APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
                    item.caption = NSLocalizedString(@"Weight", @"");
                    item.taskId = @"APHEnterWeight-76C03691-4417-4AD6-8F67-F708A8897FF6";
                    item.graphData = self.weightScoring;
                    
                    NSNumber *numberOfDataPoints = [self.weightScoring numberOfDataPoints];
                    
                    if ([numberOfDataPoints integerValue] > 1) {
                        double avgWeight = [[self.weightScoring averageDataPoint] doubleValue];
                        item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : %0.0f lbs", @""), avgWeight];
                    }
                    
                    item.identifier = kAPCDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryRedColor];
                    item.info = NSLocalizedString(@"This plots the weights you entered. Losing even a few pounds can improve your glucose control and overall health. The key is finding a weight that is achievable and sustainable. This is best achieved through small steps and gradual progress in your diet and physical activity.", @"");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                    
                case kAPHDashboardItemTypeCarbohydrate:
                {
                    APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
                    item.caption = NSLocalizedString(@"Carbohydrates", @"Carbohydrates");
                    item.graphData = self.carbScoring;
                    
                    NSNumber *numberOfDataPoints = [self.carbScoring numberOfDataPoints];
                    
                    if ([numberOfDataPoints integerValue] > 1) {
                        double avgCarbs = [[self.carbScoring averageDataPoint] doubleValue];
                        item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : %0.0f g", @"Average: {value}"), avgCarbs];
                    }
                    
                    item.identifier = kAPCDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryPurpleColor];
                    item.info = NSLocalizedString(@"This plots the total amount of carbohydrates you consumed each day (in grams). Because carbs are broken down into glucose, they can have a big impact on your glucose values. Your goals will depend on your individual situation, level of physical activity and medicines. A rule of thumb might be about 45-60 grams of carbs per meal, but check with your doctor or nutritionist for recommendations. Complex carbs (whole grains, beans, nuts, vegetables) are preferred over simple carbs (e.g., sugar), but the total amount of carbs you eat per day is important.", @"");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeSugar:
                {
                    APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
                    item.caption = NSLocalizedString(@"Sugar", @"Sugar");
                    item.graphData = self.sugarScoring;
                    
                    NSNumber *numberOfDataPoints = [self.sugarScoring numberOfDataPoints];
                    
                    if ([numberOfDataPoints integerValue] > 1) {
                        double avgSugar = [[self.sugarScoring averageDataPoint] doubleValue];
                        item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : %0.0f g", @"Average: {value}"), avgSugar];
                    }
                    
                    item.identifier = kAPCDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryBlueColor];
                    item.info = NSLocalizedString(@"This plots the amount of sugar you consumed each day (in grams). Added sugar increases glucose values and adds calories, so the goal is to try to decrease added sugar as much as possible (e.g.,  desserts or sugar-sweetened beverages such as soft drinks). A rule of thumb is to avoid foods where sugar, fructose or high-fructose corn syrup are one of the first few ingredients listed.", @"");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeCalories:
                {
                    APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
                    item.caption = NSLocalizedString(@"Calories", @"Calories");
                    item.graphData = self.calorieScoring;
                    
                    NSNumber *numberOfDataPoints = [self.calorieScoring numberOfDataPoints];
                    
                    if ([numberOfDataPoints integerValue] > 1) {
                        double avgCalories = [[self.calorieScoring averageDataPoint] doubleValue];
                        item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : %0.0f Cal", @"Average: {value} Cal"),
                                           avgCalories];
                    }
                    
                    item.identifier = kAPCDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryYellowColor];
                    item.info = NSLocalizedString(@"This plots your daily calories. Controlling the size of your portions (which will help you limit the total calories you eat) is just as important as what kinds of food you eat. Try to set specific strategies and habits to make steady, sustainable progress.", @"");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeFitness:
                {
                    if ([APCDeviceHardware isMotionActivityAvailable]) {
                        APHTableViewDashboardFitnessControlItem *item = [APHTableViewDashboardFitnessControlItem new];
                        item.caption = NSLocalizedString(@"Activity Tracker", @"");
                        
                        APHAppDelegate *appDelegate = (APHAppDelegate *)[[UIApplication sharedApplication] delegate];
                        NSString *sevenDayDistanceStr = nil;
                        
                        NSInteger activeMinutes = roundf(appDelegate.sevenDayFitnessAllocationData.activeSeconds/60);
                        
                        if (activeMinutes != 0) {
                            NSInteger lapsedDays = [appDelegate fitnessDaysShowing:APHFitnessDaysShowsLapsed];
                            
                            NSString *wordDay = [NSString stringWithFormat:@"%@", (lapsedDays == 1) ? @"day" : @"days"];
                            NSString *wordMintue = [NSString stringWithFormat:@"%@", (activeMinutes == 1) ? @"minute": @"minutes"];
                            if (lapsedDays >= 3) {
                                sevenDayDistanceStr = [NSString stringWithFormat:@"In the last %ld %@ you have been active for %ld %@ total",
                                                       (long)lapsedDays, wordDay, (long)activeMinutes, wordMintue];
                                
                                item.distanceTraveledString = sevenDayDistanceStr;
                            }
                        }
                        
                        item.identifier = @"APCDashboardPieGraphTableViewCell";
                        item.tintColor = [UIColor appTertiaryBlueColor];
                        item.editable = YES;
                        item.info = NSLocalizedString(@"The circle depicts the percentage of time you spent in various levels of activity over the past 7 days. The recommendation in type 2 diabetes is for at least 150 min of moderate activity per week.\n\n Active minutes = moderate activity minutes + 2x(vigorous activity minutes).", @"");
                        
                        APCTableViewRow *row = [APCTableViewRow new];
                        row.item = item;
                        row.itemType = rowType;
                        [rowItems addObject:row];
                    }
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeGlucoseInsights:
                {
                    NSString *glucoseLevels = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.currentUser.glucoseLevels;
                    
                    if (glucoseLevels) {
                        {
                            APCTableViewDashboardInsightsItem *item = [APCTableViewDashboardInsightsItem new];
                            item.editable = NO;
                            item.identifier = kAPCDashboardInsightsTableViewCellIdentifier;
                            item.caption = NSLocalizedString(@"Glucose Insights", @"Glucose Insights");
                            item.detailText = NSLocalizedString(@"Your behavior on good and bad glucose days", @"Your behavior on good and bad glucose days");
                            item.tintColor = [UIColor appTertiaryBlueColor];
                            item.showTopSeparator = NO;
                            item.info = NSLocalizedString(@"This looks at your recent blood glucoses, and identifies healthy diet or physical activity behaviors associated with your best glucose levels. For instance, this view will show if your best glucose levels are associated with fewer calories consumed, fewer calories from sugar, or more physical activity. Over time, this may help you gain insights into health behaviors that are most effective at controlling blood glucose in you.", @"");
                            
                            APCTableViewRow *row = [APCTableViewRow new];
                            row.item = item;
                            row.itemType = kAPHDashboardItemTypeInsights;
                            [rowItems addObject:row];
                        }
                        
                        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                        
                        // Calories
                        {
                            APCTableViewDashboardInsightItem *item = [APCTableViewDashboardInsightItem new];
                            item.editable = NO;
                            item.identifier = kAPCDashboardInsightTableViewCellIdentifier;
                            item.tintColor = [UIColor appTertiaryBlueColor];
                            
                            if (([self.caloriesInsight.valueGood doubleValue] != NSNotFound) && ([self.caloriesInsight.valueGood doubleValue] != 0)) {
                                item.goodBar = ([self.caloriesInsight.valueGood doubleValue] != NSNotFound) ? self.caloriesInsight.valueGood : @(0);
                            } else {
                                item.goodBar = @(0);
                            }
                            
                            if (([self.caloriesInsight.valueBad doubleValue] != NSNotFound) && ([self.caloriesInsight.valueBad doubleValue] != 0)) {
                                item.badBar = ([self.caloriesInsight.valueBad doubleValue] != NSNotFound) ? self.caloriesInsight.valueBad : @(0);
                            } else {
                                item.badBar = @(0);
                            }
                            
                            item.goodCaption = self.caloriesInsight.captionGood;
                            item.badCaption = self.caloriesInsight.captionBad;
                            item.insightImage = [UIImage imageNamed:@"glucose_insights_calories"];
                            
                            APCTableViewRow *row = [APCTableViewRow new];
                            row.item = item;
                            row.itemType = kAPHDashboardItemTypeInsights;
                            [rowItems addObject:row];
                        }
                        
                        // Steps
                        {
                            APCTableViewDashboardInsightItem *item = [APCTableViewDashboardInsightItem new];
                            item.editable = NO;
                            item.identifier = kAPCDashboardInsightTableViewCellIdentifier;
                            item.tintColor = [UIColor appTertiaryBlueColor];
                            
                            if (([self.stepInsight.valueGood doubleValue] != NSNotFound)) {
                                item.goodBar = ([self.stepInsight.valueGood doubleValue] != NSNotFound) ? self.stepInsight.valueGood : @(0);
                            } else {
                                item.goodBar = @(0);
                            }
                            
                            if (([self.stepInsight.valueBad doubleValue] != NSNotFound)) {
                                item.badBar = ([self.stepInsight.valueBad doubleValue] != NSNotFound) ? self.stepInsight.valueBad : @(0);
                            } else {
                                item.badBar = @(0);
                            }
                            
                            item.goodCaption = self.stepInsight.captionGood;
                            item.badCaption = self.stepInsight.captionBad;
                            item.insightImage = [UIImage imageNamed:@"glucose_insights_steps"];
                            
                            APCTableViewRow *row = [APCTableViewRow new];
                            row.item = item;
                            row.itemType = kAPHDashboardItemTypeInsights;
                            [rowItems addObject:row];
                        }
                        
                        // Sugar Calories
                        {
                            APCTableViewDashboardInsightItem *item = [APCTableViewDashboardInsightItem new];
                            
                            item.editable = NO;
                            item.identifier = kAPCDashboardInsightTableViewCellIdentifier;
                            item.tintColor = [UIColor appTertiaryBlueColor];
                            
                            NSUInteger caloriesPerGramOfSugar = 4;
                            
                            [numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
                            
                            if (([self.caloriesInsight.valueGood doubleValue] != 0) &&
                                ([self.caloriesInsight.valueGood doubleValue] != NSNotFound) &&
                                ([self.sugarInsight.valueGood doubleValue] != 0)) {
                                
                                NSNumber *gramsOfSugarConsumed = self.sugarInsight.valueGood;
                                NSNumber *totalNumberOfCaloriesConsumed = self.caloriesInsight.valueGood;
                                double sugarCaloriesConsumed = [gramsOfSugarConsumed doubleValue] * caloriesPerGramOfSugar;
                                double percentOfSugarCalories = sugarCaloriesConsumed / [totalNumberOfCaloriesConsumed doubleValue];
                                
                                double sugarCals = (percentOfSugarCalories < 1) ? percentOfSugarCalories : 1;
                                
                                item.goodCaption = [NSString stringWithFormat:@"%@ Cals as sugar",
                                                    [numberFormatter stringFromNumber:@(sugarCals)]];
                                item.goodBar = @(sugarCals);
                            } else {
                                item.goodCaption = NSLocalizedString(@"Not enough data", @"Not enough data");
                                item.goodBar = @(0);
                            }
                            
                            if ([self.caloriesInsight.valueBad doubleValue] != 0 &&
                                ([self.caloriesInsight.valueBad doubleValue] != NSNotFound) &&
                                ([self.sugarInsight.valueBad doubleValue] != 0)) {
                                NSNumber *gramsOfSugarConsumedBad = self.sugarInsight.valueBad;
                                NSNumber *totalNumberOfCaloriesConsumedBad = self.caloriesInsight.valueBad;
                                double sugarCaloriesConsumedBad = [gramsOfSugarConsumedBad doubleValue] * caloriesPerGramOfSugar;
                                double badPercentOfSugarCalories = sugarCaloriesConsumedBad / [totalNumberOfCaloriesConsumedBad doubleValue];
                                
                                double sugarCals = (badPercentOfSugarCalories < 1) ? badPercentOfSugarCalories : 1;
                                
                                item.badCaption = [NSString stringWithFormat:@"%@ Cals as sugar",
                                                   [numberFormatter stringFromNumber:@(sugarCals)]];
                                
                                item.badBar = @(sugarCals);
                            } else {
                                item.badCaption = NSLocalizedString(@"Not enough data", @"Not enough data");
                                item.badBar = @(0);
                            }
                            
                            item.insightImage = [UIImage imageNamed:@"food_insights_sugars"];
                            
                            if ((item.goodBar.doubleValue < item.badBar.doubleValue) && (item.goodBar.doubleValue != 0)) {
                                APCTableViewRow *row = [APCTableViewRow new];
                                row.item = item;
                                row.itemType = kAPHDashboardItemTypeInsights;
                                [rowItems addObject:row];
                            }
                        }
                    }
                }
                    break;
                case kAPHDashboardItemTypeDietInsights:
                {
                    // Food Insights
                    {
                        APCTableViewDashboardInsightsItem *item = [APCTableViewDashboardInsightsItem new];
                        item.editable = NO;
                        item.identifier = kAPCDashboardFoodInsightHeaderCellIdentifier;
                        item.caption = NSLocalizedString(@"Diet Insights", @"Diet Insights");
                        
                        if (self.carbFoodInsight.foodHistory.count > 0 && self.sugarFoodInsight.foodHistory.count > 0) {
                            item.detailText = NSLocalizedString(@"Your foods that are high in carbs or sugar", nil);
                        } else {
                            item.detailText = NSLocalizedString(@"Log your meals using the “Log Food” activity to learn about your diet habits",
                                                                @"Log your meals using the \"Log Food\" activity to learn about your diet habits");
                        }
                        
                        item.tintColor = [UIColor appTertiaryYellowColor];
                        item.showTopSeparator = NO;
                        item.info = NSLocalizedString(@"This lists foods high in carbohydrates or sugar, especially those that you have eaten more than once recently. These foods can drive higher blood glucoses, and might be good candidates to cut back on. Remember that fresh fruit is a good source of natural sugar; the focus is on decreasing added sugar (such as sugar-sweetened beverages). ", @"");
                        
                        APCTableViewRow *row = [APCTableViewRow new];
                        row.item = item;
                        row.itemType = kAPHDashboardItemTypeInsights;
                        [rowItems addObject:row];
                    }
                    
                    if (self.carbFoodInsight.foodHistory) {
                        NSUInteger maxFoodItems = (self.carbFoodInsight.foodHistory.count < 3) ? self.carbFoodInsight.foodHistory.count : 3;
                        for (NSUInteger idx = 0; idx < maxFoodItems; idx++) {
                            NSDictionary *insight = [self.carbFoodInsight.foodHistory objectAtIndex:idx];
                            NSNumber *carbsCals = insight[kFoodInsightCaloriesValueKey];
                            
                            APCTableViewDashboardFoodInsightItem *item = [APCTableViewDashboardFoodInsightItem new];
                            item.editable = NO;
                            item.identifier = kAPCDashboardFoodInsightCellIdentifier;
                            item.tintColor = [UIColor appTertiaryYellowColor];
                            item.titleCaption = insight[kFoodInsightFoodNameKey];
                            
                            NSString *subtitle = [NSString stringWithFormat:@"%@ Cals from carbs",
                                                  [numberFormatter stringFromNumber:carbsCals]];
                            
                            item.subtitleCaption = NSLocalizedString(subtitle, @"");
                            item.frequency = insight[kFoodInsightFrequencyKey];
                            item.foodInsightImage = [UIImage imageNamed:@"food_insights_carbs"];
                            
                            APCTableViewRow *row = [APCTableViewRow new];
                            row.item = item;
                            row.itemType = kAPHDashboardItemTypeInsights;
                            [rowItems addObject:row];
                        }
                    }
                    
                    if (self.sugarFoodInsight.foodHistory) {
                        NSUInteger maxFoodItems = (self.sugarFoodInsight.foodHistory.count < 3) ? self.sugarFoodInsight.foodHistory.count : 3;
                        for (NSUInteger idx = 0; idx < maxFoodItems; idx++) {
                            NSDictionary *insight = [self.sugarFoodInsight.foodHistory objectAtIndex:idx];
                            NSNumber *sugarCals = insight[kFoodInsightCaloriesValueKey];
                            
                            APCTableViewDashboardFoodInsightItem *item = [APCTableViewDashboardFoodInsightItem new];
                            item.editable = NO;
                            item.identifier = kAPCDashboardFoodInsightCellIdentifier;
                            item.tintColor = [UIColor appTertiaryYellowColor];
                            item.titleCaption = insight[kFoodInsightFoodNameKey];
                            
                            NSString *subtitle = [NSString stringWithFormat:@"%@ Cals from sugar",
                                                  [numberFormatter stringFromNumber:sugarCals]];
                            
                            item.subtitleCaption = NSLocalizedString(subtitle, @"");
                            item.frequency = insight[kFoodInsightFrequencyKey];
                            item.foodInsightImage = [UIImage imageNamed:@"food_insights_sugars"];
                            
                            APCTableViewRow *row = [APCTableViewRow new];
                            row.item = item;
                            row.itemType = kAPHDashboardItemTypeInsights;
                            [rowItems addObject:row];
                        }
                    }
                }
                    break;
                    
                default:
                    break;
            }
            
        }
        
        APCTableViewSection *section = [APCTableViewSection new];
        section.rows = [NSArray arrayWithArray:rowItems];
        section.sectionTitle = NSLocalizedString(@"Recent Activity", @"Recent Activity");
        [self.items addObject:section];
    }
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDatasource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    APCTableViewDashboardItem *dashboardItem = (APCTableViewDashboardItem *)[self itemForIndexPath:indexPath];
    
    if ([dashboardItem isKindOfClass:[APHTableViewDashboardFitnessControlItem class]]){
        APHTableViewDashboardFitnessControlItem *fitnessItem = (APHTableViewDashboardFitnessControlItem *)dashboardItem;
        
        APCDashboardPieGraphTableViewCell *pieGraphCell = (APCDashboardPieGraphTableViewCell *)cell;
        
        pieGraphCell.subTitleLabel.text = fitnessItem.numberOfDaysString;
        pieGraphCell.subTitleLabel2.text = fitnessItem.distanceTraveledString;
        
        pieGraphCell.pieGraphView.datasource = self;
        pieGraphCell.textLabel.text = @"";
        pieGraphCell.title = fitnessItem.caption;
        pieGraphCell.tintColor = fitnessItem.tintColor;
        pieGraphCell.pieGraphView.shouldAnimateLegend = NO;
        
        if (self.dataCount < kDataCountLimit) {
            [pieGraphCell.pieGraphView setNeedsLayout];
        }
        
        pieGraphCell.delegate = self;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    
    APCTableViewItem *dashboardItem = [self itemForIndexPath:indexPath];
    
    if ([dashboardItem isKindOfClass:[APHTableViewDashboardFitnessControlItem class]]){
        height = 288.0f;
    }
    
    return height;
}

#pragma mark - Insights Cell Delegate

- (void)dashboardInsightDidExpandForCell:(APCDashboardInsightsTableViewCell *)cell
{
    UIViewController *insightVC = nil;
    UIStoryboard *sbDashboard = [UIStoryboard storyboardWithName:@"APHDashboard" bundle:nil];
    
    if ([cell.reuseIdentifier isEqualToString:kAPCDashboardInsightsTableViewCellIdentifier]) {
        APHGlucoseInsightsViewController *glucoseInsightVC = (APHGlucoseInsightsViewController *)[sbDashboard instantiateViewControllerWithIdentifier:@"APHGlucoseInsights"];
        
        glucoseInsightVC.stepInsight = self.stepInsight;
        glucoseInsightVC.carbsInsight = self.carbsInsight;
        glucoseInsightVC.caloriesInsight = self.caloriesInsight;
        glucoseInsightVC.sugarInsight = self.sugarInsight;
        
        insightVC = glucoseInsightVC;
    } else if ([cell.reuseIdentifier isEqualToString:kAPCDashboardFoodInsightHeaderCellIdentifier]) {
        APHFoodInsightsViewController *foodInsightVC = (APHFoodInsightsViewController *)[sbDashboard instantiateViewControllerWithIdentifier:@"APHFoodInsights"];
        
        foodInsightVC.carbFoodInsights = self.carbFoodInsight.foodHistory;
        foodInsightVC.sugarFoodInsights = self.sugarFoodInsight.foodHistory;
        
        insightVC = foodInsightVC;
    }
    
    [self.navigationController presentViewController:insightVC animated:YES completion:nil];
    
}

- (void)dashboardInsightDidAskForMoreInfoForCell:(APCDashboardInsightsTableViewCell *)cell
{
    [self dashboardTableViewCellDidTapMoreInfo:(APCDashboardTableViewCell *)cell];
}

- (void)didCompleteFoodInsightForSampleType:(HKSampleType *) __unused sampleType insight:(NSArray *) __unused foodInsight
{
    if (self.carbFoodInsight.foodHistory && self.sugarFoodInsight.foodHistory) {
        [self prepareData];
    }
}

#pragma mark - Unwind segue
- (IBAction)unwindFromGlucoseInsights:(UIStoryboardSegue *) __unused segue
{
    
}

#pragma mark - Pie Graph View delegates

-(NSInteger)numberOfSegmentsInPieGraphView
{
    return [self.allocationDataset count];
}

- (UIColor *)pieGraphView:(APCPieGraphView *) __unused pieGraphView colorForSegmentAtIndex:(NSInteger)index
{
    return [[self.allocationDataset valueForKey:kDatasetSegmentColorKey] objectAtIndex:index];
}

- (NSString *)pieGraphView:(APCPieGraphView *) __unused pieGraphView titleForSegmentAtIndex:(NSInteger)index
{
    return [[self.allocationDataset valueForKey:kDatasetSegmentKey] objectAtIndex:index];
}

- (CGFloat)pieGraphView:(APCPieGraphView *) __unused pieGraphView valueForSegmentAtIndex:(NSInteger)index
{
    return [[[self.allocationDataset valueForKey:kSegmentSumKey] objectAtIndex:index] floatValue];
}

@end
