//
//  APHActivityTrackingStepViewController.m
//  Diabetes
//
//  Copyright (c) 2014 Apple, Inc. All rights reserved.
//

#import "APHActivityTrackingStepViewController.h"
#import "APHAppDelegate.h"
#import "APHFitnessAllocation.h"

static NSInteger const kYesterdaySegmentIndex    = 0;
static NSInteger const kTodaySegmentIndex        = 1;
static NSInteger const kWeekSegmentIndex         = 2;

@interface APHActivityTrackingStepViewController () <APCPieGraphViewDatasource>
- (IBAction)resetTaskStartDate:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *daysRemaining;
@property (weak, nonatomic) IBOutlet APCPieGraphView *chartView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentDays;

@property (nonatomic) NSInteger previouslySelectedSegment;

@property (nonatomic, strong) NSArray *allocationDataset;

@property (nonatomic, strong) NSDate *allocationStartDate;

@property (nonatomic) BOOL showTodaysDataAtViewLoad;
@property (nonatomic) NSInteger numberOfDaysOfFitnessWeek;

@end

@implementation APHActivityTrackingStepViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.daysRemaining.text = [self fitnessDaysRemaining];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(handleClose:)];
    

    self.view.layer.backgroundColor = [UIColor colorWithWhite:0.973 alpha:1.000].CGColor;
    
    self.segmentDays.tintColor = [UIColor clearColor];

    [self.segmentDays setTitleTextAttributes:@{
                                               NSFontAttributeName:[UIFont appRegularFontWithSize:19.0f],
                                               NSForegroundColorAttributeName : [UIColor lightGrayColor]
                                               
                                               }
                                    forState:UIControlStateNormal];
    [self.segmentDays setTitleTextAttributes:@{
                                               NSFontAttributeName:[UIFont appMediumFontWithSize:19.0f],
                                               NSForegroundColorAttributeName : [UIColor blackColor]
                                               
                                               }
                                    forState:UIControlStateSelected];
    [self.segmentDays setTitleTextAttributes:@{
                                               NSFontAttributeName:[UIFont appMediumFontWithSize:19.0f],
                                               NSForegroundColorAttributeName : [UIColor whiteColor]
                                               }
                                    forState:UIControlStateDisabled];
    
    [[UIView appearance] setTintColor:[UIColor whiteColor]];
    
    self.previouslySelectedSegment = kTodaySegmentIndex;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(datasetDidUpdate:)
                                                 name:APHSevenDayAllocationDataIsReadyNotification
                                               object:nil];
    
    self.showTodaysDataAtViewLoad = YES;
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = nil;
    
    self.chartView.datasource = self;
    self.chartView.legendPaddingHeight = 60.0;
    self.chartView.shouldAnimate = YES;
    self.chartView.shouldAnimateLegend = NO;
    self.chartView.titleLabel.text = NSLocalizedString(@"Active Minutes", @"Active Minutes");
    
    
    APHAppDelegate *appDelegate = (APHAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.chartView.valueLabel.text = [NSString stringWithFormat:@"%d", (int) roundf(appDelegate.sevenDayFitnessAllocationData.activeSeconds/60)];
    self.chartView.valueLabel.alpha = 1;

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    APHAppDelegate *appDelegate = (APHAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate.sevenDayFitnessAllocationData todaysAllocation]) {
        if (self.showTodaysDataAtViewLoad) {
            [self handleDays:self.segmentDays];
            self.showTodaysDataAtViewLoad = NO;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:APHSevenDayAllocationDataIsReadyNotification
                                                  object:nil];
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (IBAction)handleDays:(UISegmentedControl *)sender
{
    APHAppDelegate *appDelegate = (APHAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDate *startDate = nil;
    NSDate *endDate = nil;
    
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.allocationDataset = [appDelegate.sevenDayFitnessAllocationData yesterdaysAllocation];
            
            startDate = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                                         minute:0
                                                                         second:0
                                                                         ofDate:[self dateForSpan:-1]
                                                                        options:0];
            endDate = [[NSCalendar currentCalendar] dateBySettingHour:23
                                                               minute:59
                                                               second:0
                                                               ofDate:startDate
                                                              options:0];
            
            break;
        case 1:
            self.allocationDataset = [appDelegate.sevenDayFitnessAllocationData todaysAllocation];
            startDate = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                                 minute:0
                                                                 second:0
                                                                 ofDate:[NSDate date]
                                                                options:0];

            break;
        default:
            self.allocationDataset = [appDelegate.sevenDayFitnessAllocationData weeksAllocation];
            
            startDate = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                                 minute:0
                                                                 second:0
                                                                 ofDate:self.allocationStartDate
                                                                options:0];
            

            break;
    }
    
    [self refreshAllocation:sender.selectedSegmentIndex];
}

- (void)handleClose:(UIBarButtonItem *)sender
{
    if ([self.delegate respondsToSelector:@selector(stepViewController:didFinishWithNavigationDirection:)] == YES) {
        [self.delegate stepViewController:self didFinishWithNavigationDirection:ORKStepViewControllerNavigationDirectionForward];
    }
}

- (NSDate *)dateForSpan:(NSInteger)daySpan
{
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:daySpan];
    
    NSDate *spanDate = [[NSCalendar currentCalendar] dateByAddingComponents:components
                                                                     toDate:[NSDate date]
                                                                    options:0];
    return spanDate;
}

- (NSString *)fitnessDaysRemaining
{
    NSDate *startDate = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                                 minute:0
                                                                 second:0
                                                                 ofDate:[self checkSevenDayFitnessStartDate]
                                                                options:0];
    NSDate *today = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                             minute:0
                                                             second:0
                                                             ofDate:[NSDate date]
                                                            options:0];
    
    // Disable Yesterday and Week segments when start date is today
    BOOL startDateIsToday = [startDate isEqualToDate:today];
    [self.segmentDays setEnabled:!startDateIsToday forSegmentAtIndex:0];
    [self.segmentDays setEnabled:!startDateIsToday forSegmentAtIndex:2];
    
    // Compute the remaing days of the 7 day fitness allocation.
    NSDateComponents *numberOfDaysFromStartDate = [[NSCalendar currentCalendar] components:NSCalendarUnitDay
                                                                                  fromDate:startDate
                                                                                    toDate:today
                                                                                   options:NSCalendarWrapComponents];
    self.numberOfDaysOfFitnessWeek = numberOfDaysFromStartDate.day;
    
    NSUInteger daysRemain = 0;
    
    if (self.numberOfDaysOfFitnessWeek < 7) {
        daysRemain = 7 - self.numberOfDaysOfFitnessWeek;
    }

    NSString *days = (daysRemain == 1) ? NSLocalizedString(@"Day", @"Day") : NSLocalizedString(@"Days", @"Days");
    
    NSString *remaining = [NSString stringWithFormat:NSLocalizedString(@"%lu %@ Remaining",
                                                                       @"{count} {day/s} Remaining"), daysRemain, days];
    
    return remaining;
}

- (NSDate *)checkSevenDayFitnessStartDate
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSDate *fitnessStartDate = [defaults objectForKey:kSevenDayFitnessStartDateKey];
    
    if (!fitnessStartDate) {
        
        NSDate *startDate = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                                     minute:0
                                                                     second:0
                                                                     ofDate:[NSDate date]
                                                                    options:0];
        
        fitnessStartDate = startDate;
        [self saveSevenDayFitnessStartDate:fitnessStartDate];
        
        APHAppDelegate *appDelegate = (APHAppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.sevenDayFitnessAllocationData = [[APHFitnessAllocation alloc] initWithAllocationStartDate:fitnessStartDate];
        [appDelegate.sevenDayFitnessAllocationData startDataCollection];
    }
    
    self.allocationStartDate = fitnessStartDate;
    
    return fitnessStartDate;
}

- (void)saveSevenDayFitnessStartDate:(NSDate *)startDate
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:startDate forKey:kSevenDayFitnessStartDateKey];
    
    [defaults synchronize];
}

#pragma mark - Fitness Allocation Delegate

- (void)datasetDidUpdate:(NSNotification *)notif
{
    [self handleDays:self.segmentDays];
    
    NSLog(@"Received notification: %@", notif.userInfo);
}

- (void)refreshAllocation:(NSInteger)segmentIndex
{
    if (segmentIndex == kYesterdaySegmentIndex && self.previouslySelectedSegment == kTodaySegmentIndex) {
        self.chartView.shouldDrawClockwise = NO;
    } else if (segmentIndex == kWeekSegmentIndex && self.previouslySelectedSegment == kTodaySegmentIndex) {
        self.chartView.shouldDrawClockwise = YES;
    } else if (self.previouslySelectedSegment == kYesterdaySegmentIndex) {
        self.chartView.shouldDrawClockwise = YES;
    } else if (self.previouslySelectedSegment == kWeekSegmentIndex) {
        self.chartView.shouldDrawClockwise = NO;
    }
    
    self.previouslySelectedSegment = segmentIndex;
    
    [self.chartView layoutSubviews];
}

#pragma mark - PieGraphView Delegates

-(NSInteger)numberOfSegmentsInPieGraphView
{
    return [self.allocationDataset count];
}

- (UIColor *)pieGraphView:(APCPieGraphView *)pieGraphView colorForSegmentAtIndex:(NSInteger)index
{
    return [[self.allocationDataset valueForKey:kDatasetSegmentColorKey] objectAtIndex:index];
}

- (NSString *)pieGraphView:(APCPieGraphView *)pieGraphView titleForSegmentAtIndex:(NSInteger)index
{
    return [[self.allocationDataset valueForKey:kDatasetSegmentKey] objectAtIndex:index];
}

- (CGFloat)pieGraphView:(APCPieGraphView *)pieGraphView valueForSegmentAtIndex:(NSInteger)index
{
    return [[[self.allocationDataset valueForKey:kSegmentSumKey] objectAtIndex:index] floatValue];
}

- (IBAction)resetTaskStartDate:(id)sender {
    //Updating the start date of the task.
    [self saveSevenDayFitnessStartDate: [NSDate date]];
    
    //Calling the motion history reporter to retrieve and update the data for core activity. This triggers a series of notifications that lead to the pie graph being drawn again here.
    APCMotionHistoryReporter *reporter = [APCMotionHistoryReporter sharedInstance];
    [reporter startMotionCoProcessorDataFrom:[NSDate dateWithTimeIntervalSinceNow:-24 * 60 * 60] andEndDate:[NSDate new] andNumberOfDays:1];
    
    [self.segmentDays setEnabled:YES forSegmentAtIndex:0];
    [self.segmentDays setEnabled:YES forSegmentAtIndex:2];
    
  
}
@end
