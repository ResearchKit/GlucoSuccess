// 
//  APHGlucoseLogViewController.m 
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
 
#import "APHGlucoseLogViewController.h"
#import "APHGlucoseEntryViewController.h"
#import "APHAppDelegate.h"
#import "APHSliderViewController.h"

static NSString *kGlucoseLogListCellIdentifier = @"GlucoseLogListCell";
static NSString *kGlucoseTaskId = @"APHLogGlucose-42449E07-7124-40EF-AC93-CA5BBF95FC15";

static NSDateFormatter *kDateFormatter = nil;

static CGFloat kSectionHeaderHeight = 44.0;
static CGFloat kCellHeight = 65.0;
static CGFloat kHeaderFontSize = 16.0;

typedef NS_ENUM(NSUInteger, APHGlucoseLogSections) {
    APHGlucoseLogSectionToday = 0,
    APHGlucoseLogSectionHistory,
    APHGlucoseLogSectionNumberOfSections
};

@interface APHGlucoseLogViewController () <UITableViewDataSource, UITableViewDelegate, APHSliderViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintToTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintToTopFromTableView;

@property (nonatomic, strong) NSMutableArray *glucoseEntries;
@property (nonatomic, strong) ORKStepResult *stepResult;

@property (nonatomic) BOOL bannerIsVisible;

@property (readonly) APCAppDelegate *appDelegate;

@end

@implementation APHGlucoseLogViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (kDateFormatter == nil) {
        kDateFormatter = [[NSDateFormatter alloc] init];
        [kDateFormatter setLocale:[NSLocale currentLocale]];
    }

    self.glucoseEntries = [NSMutableArray array];
    
    [self retrieveGlucoseLogSchedules];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.topItem.title = NSLocalizedString(@"Glucose Levels", @"Glucose Levels");
    
    self.bannerIsVisible = NO;
    self.constraintToTop.constant = -180;
    self.constraintToTopFromTableView.constant = 0;
    
    UIBarButtonItem *btnAdd = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                            target:self
                                                                            action:@selector(addEntryForPreviousDay:)];
    self.navigationItem.leftBarButtonItem = btnAdd;

    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (APCAppDelegate *)appDelegate
{
    return (APHAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id) __unused sender
{
    if ([segue.identifier isEqualToString:@"embedSegueToDateSlider"]) {
        APHSliderViewController *slidingDatePicker = (APHSliderViewController *)[segue destinationViewController];
        slidingDatePicker.delegate = self;
    }
}

- (void)retrieveGlucoseLogSchedules
{
    // The ScheduledTask is for each individual glucose level that is selected
    // by the user during the onboarding process. These schedules will need to be
    // grouped by the task and filtered by dueOn and sorted in a decending order by createdAt
    
    // let's clear the glucoseEntries array
    [self.glucoseEntries removeAllObjects];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startOn"
                                                                   ascending:NO];
    
    NSFetchRequest *request = [APCScheduledTask request];
    
    NSDate *todayStartOn = [[NSCalendar currentCalendar] dateBySettingHour:23
                                                                    minute:59
                                                                    second:59
                                                                    ofDate:[NSDate date]
                                                                   options:0];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(task.taskID == %@) AND (startOn <= %@)", kGlucoseTaskId, todayStartOn];
    
    request.predicate = predicate;
    request.sortDescriptors = @[sortDescriptor];
    
    NSError *error = nil;
    NSArray *entries = [self.appDelegate.dataSubstrate.mainContext executeFetchRequest:request
                                                                                 error:&error];
    
    self.glucoseEntries = [[self groupTasksByDay:entries] mutableCopy];
}

#pragma mark - Group Tasks

- (NSArray *)groupTasksByDay:(NSArray *)listOfTasks
{
    NSMutableArray *groupedTasks = [NSMutableArray new];
    NSArray *dates = [self normalizeDate:[listOfTasks valueForKey:@"startOn"]];
    
    for (NSDate *date in dates) {
        
        NSDate *startDate = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                                     minute:0
                                                                     second:0
                                                                     ofDate:date
                                                                    options:0];
        
        NSDate *endDate = [[NSCalendar currentCalendar] dateBySettingHour:23
                                                                   minute:59
                                                                   second:59
                                                                   ofDate:date
                                                                  options:0];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(startOn >= %@) AND (startOn <= %@)", startDate, endDate];
        NSArray *tasksForDay = [listOfTasks filteredArrayUsingPredicate:predicate];
        
        if (tasksForDay.count > 0) {
            
            APCScheduledTask *scheduledTask = tasksForDay.firstObject;
            APCGroupedScheduledTask *groupedTask = [[APCGroupedScheduledTask alloc] init];
            
            groupedTask.scheduledTasks = [NSMutableArray arrayWithArray:tasksForDay];
            groupedTask.taskTitle = [self relativeDateStringForDate:date];
            groupedTask.taskClassName = scheduledTask.task.taskClassName;
            groupedTask.taskCompletionTimeString = scheduledTask.task.taskCompletionTimeString;
            
            [groupedTasks addObject:groupedTask];
        }
    }
    
    return groupedTasks;
}

- (NSArray *)normalizeDate:(NSArray *)dates
{
    NSMutableArray *normalDates = [NSMutableArray new];
    
    
    for (NSDate *date in dates) {
        NSDate *normalDate = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                                      minute:0
                                                                      second:0
                                                                      ofDate:date
                                                                     options:0];
        if ([normalDates containsObject:normalDate] == NO) {
            [normalDates addObject:normalDate];
        }
    }
    
    return normalDates;
}

#pragma mark - Actions

- (void)addEntryForPreviousDay:(UIBarButtonItem *) __unused sender
{
    [self showPastEntryDatePicker];
}

- (void)showGlucoseEntryViewAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger entryIndex = indexPath.row;
    
    if (indexPath.section == APHGlucoseLogSectionHistory) {
        entryIndex++;
    }
    self.selectedTask = [self.glucoseEntries objectAtIndex:entryIndex];
    
    if ([self.delegate respondsToSelector:@selector(stepViewController:didFinishWithNavigationDirection:)] == YES) {
        [self.delegate stepViewController:self didFinishWithNavigationDirection:ORKStepViewControllerNavigationDirectionForward];
    }
}

- (void)removeGlucoseEntryAtIndexPath:(NSIndexPath *)indexPath
{
    // The self.glucoseEntries stores all grouped scheduled tasks.
    // We are only allowing deleting from the Log History, which effectively means
    // that the index needs to be +1, because 0 index is at Todays location for the
    // self.glucoseEntries, but in the Log History (a separate section) 0 index is
    // for the object that is at 1 index in self.glucoseEntries.
    
    NSInteger adjustedIndex = indexPath.row + 1;
    APCGroupedScheduledTask *selectedScheduledTaskGroup = [self.glucoseEntries objectAtIndex:adjustedIndex];
    NSArray *taskEntries = selectedScheduledTaskGroup.scheduledTasks;
    BOOL deleteSuccess = NO;
    
    for (APCScheduledTask *task in taskEntries) {
        NSError *coreDataError = nil;
        deleteSuccess = [task removeScheduledTask:&coreDataError];
        
        if (!deleteSuccess) {
            APCLogError2(coreDataError);
        }
    }
    
    if (deleteSuccess) {
        [self.glucoseEntries removeObjectAtIndex:adjustedIndex];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - Schedules

- (BOOL)isDateValidForGlucoseEntry:(NSDate *)entryDate
                           atHours:(NSArray *) __unused hours
                     scheduleError:(NSError **)incomingError
                        completion:(void (^)(BOOL dateIsValid, NSError *glucoseEntryError))completion
{
    BOOL isValidEntryDate = NO;
    
    NSError *entryDateError = nil;
    
    NSDate *startOfDay = [NSDate startOfDay:entryDate];
    NSDate *endOfDay   = [NSDate endOfDay:entryDate];
    
    NSManagedObjectContext * localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    localContext.parentContext = self.appDelegate.dataSubstrate.persistentContext;
    
    NSFetchRequest *request = [APCScheduledTask request];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(task.taskID == %@) AND (startOn >= %@) AND (endOn <= %@)",
                              kGlucoseTaskId, startOfDay, endOfDay];
    request.predicate = predicate;
    
    NSArray *entries = [localContext executeFetchRequest:request
                                                   error:&entryDateError];
    
    if (entries) {
        isValidEntryDate = (entries.count == 0);
    } else {
        APCLogError2(entryDateError);
    }
    
    *incomingError = entryDateError;
    
    if (completion) {
        completion(isValidEntryDate, entryDateError);
    }
    
    return isValidEntryDate;
}

- (BOOL)generateScheduleForGlucoseEntryDate:(NSDate *)entryDate
                                    atHours:(NSArray *)hours
                              scheduleError:(NSError **)incomingError
                                 completion:(void (^)(NSError *glucoseEntryError))completion
{
    NSError *scheduleError = nil;
    
    NSManagedObjectContext * localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    localContext.parentContext = self.appDelegate.dataSubstrate.persistentContext;
    
    NSFetchRequest *request = [APCSchedule request];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(taskID == %@)", kGlucoseTaskId];
    
    request.predicate = predicate;
    
    NSArray *entries = [localContext executeFetchRequest:request
                                                   error:&scheduleError];
    
    if (entries.count != 0) {
        APCSchedule *glucoseLogSchedule = [entries firstObject];
        
        // Get the task
        APCTask *glucoseLogTask = [APCTask taskWithTaskID:kGlucoseTaskId inContext:localContext];
        
        for (NSNumber *hour in hours) {
            NSDate *scheduleDateTime = [[NSCalendar currentCalendar] dateBySettingHour:[hour integerValue]
                                                                                minute:0
                                                                                second:0
                                                                                ofDate:entryDate
                                                                               options:0];
            
            // Let's create the scheduled task for the provided date
            APCScheduledTask *scheduledTaskForNewEntry = [APCScheduledTask newObjectForContext:localContext];
            scheduledTaskForNewEntry.startOn = scheduleDateTime;
            scheduledTaskForNewEntry.endOn = scheduleDateTime;
            scheduledTaskForNewEntry.completed = @(NO);
            scheduledTaskForNewEntry.task = glucoseLogTask;
            scheduledTaskForNewEntry.generatedSchedule = glucoseLogSchedule;
            
            NSError *newEntryError = nil;
            BOOL saveSuccess = [scheduledTaskForNewEntry saveToPersistentStore:&newEntryError];
            
            if (!saveSuccess) {
                APCLogError2(newEntryError);
                scheduleError = newEntryError;
            } else {
                //DEBUG
                APCLogDebug(@"Scheduled Task UID: %@ (Start: %@ | End: %@)",
                            scheduledTaskForNewEntry.uid, scheduledTaskForNewEntry.startOn, scheduledTaskForNewEntry.endOn);
            }
        }
    } else {
        // we could not find the schedule
        APCLogError2(scheduleError);
    }
    
    *incomingError = scheduleError;
    
    if (completion) {
        completion(scheduleError);
    }
    
    return scheduleError == nil;
}

#pragma mark - TableView
#pragma mark Datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView
{
    return APHGlucoseLogSectionNumberOfSections;
}

- (NSInteger)tableView:(UITableView *) __unused tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger rows = 1;
    
    if (section == APHGlucoseLogSectionHistory) {
        if ([self.glucoseEntries count] >= 1) {
            rows = [self.glucoseEntries count] - 1;
        } else {
            rows = 0;
        }
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kGlucoseLogListCellIdentifier];
    NSUInteger levelIndex;
    
    if (indexPath.section == APHGlucoseLogSectionToday) {
        levelIndex = indexPath.row;
    } else {
        levelIndex = indexPath.row;
        levelIndex++;
    }
    
    APCGroupedScheduledTask *task = self.glucoseEntries[levelIndex];
    
    cell.textLabel.text = task.taskTitle;
    
    if (task.complete) {
        cell.detailTextLabel.text = NSLocalizedString(@"Complete", @"Complete");
    } else {
        NSUInteger allTasks = task.scheduledTasks.count;
        NSUInteger completedTasks = task.completedTasksCount;
        
        NSNumber *remainingTasks = (completedTasks < allTasks) ? @(allTasks - completedTasks) : @(0);
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (long)[remainingTasks integerValue]];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *) __unused tableView heightForHeaderInSection:(NSInteger) __unused section
{
    return kSectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *) __unused tableView heightForRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    return kCellHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *headerView;
    
    headerView = [[UITableViewHeaderFooterView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), kSectionHeaderHeight)];
    headerView.contentView.backgroundColor = [UIColor appSecondaryColor4];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.bounds];
    
    if (section == APHGlucoseLogSectionToday) {
        CGFloat inset = 15.0;
        UIEdgeInsets  insets = UIEdgeInsetsMake(0, inset, 0, inset);
        CGRect bounds = UIEdgeInsetsInsetRect(headerView.bounds, insets);
        headerLabel.bounds = bounds;
        headerLabel.font = [UIFont appLightFontWithSize:kHeaderFontSize];
        headerLabel.textColor = [UIColor appSecondaryColor3];
        headerLabel.textAlignment = NSTextAlignmentLeft;
        headerLabel.text = NSLocalizedString(@"Tap to log a new entry.", @"Tap to log a new entry.");
    } else {
        headerLabel.font = [UIFont appLightFontWithSize:kHeaderFontSize];
        headerLabel.textColor = [UIColor appSecondaryColor3];
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.text = NSLocalizedString(@"Log History", @"Log History");
    }
    
    [headerView addSubview:headerLabel];
    
    return headerView;
}

#pragma mark Delegates

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self showGlucoseEntryViewAtIndexPath:indexPath];
}

- (NSString *)relativeDateStringForDate:(NSDate *)date
{
    NSString *relativeDate = nil;
    NSInteger numberOfDays = [self numberOfDaysFromDate:date];
    
    if (numberOfDays > 0) {
        if (numberOfDays > 7) {
            [kDateFormatter setDateFormat:@"MM/dd/YYYY"];
            relativeDate = [kDateFormatter stringFromDate:date];
        } else if ((numberOfDays > 1) && (numberOfDays <= 7)) {
            [kDateFormatter setDateFormat:@"EEEE"];
            relativeDate = [NSString stringWithFormat:@"%@", [kDateFormatter stringFromDate:date]];
        } else {
            relativeDate = NSLocalizedString(@"Yesterday", @"Yesterday");
        }
    } else {
        [kDateFormatter setDateFormat:@"MMMM dd"];
        relativeDate = [NSString stringWithFormat:NSLocalizedString(@"Today, %@",
                                                                    @"Today, {date formated as MMMM dd}"), [kDateFormatter stringFromDate:date]];
    }
    
    return relativeDate;
}

#pragma mark Editing

- (BOOL)tableView:(UITableView *) __unused tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canEdit = NO;
    
    if (indexPath.section > 0) {
        // Editing is only enabled for entries that appear
        // in the Log History section.
        canEdit = YES;
    }
    
    return canEdit;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *) __unused tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellEditingStyle editingStyle = UITableViewCellEditingStyleNone;
    
    if (indexPath.section > 0) {
        editingStyle = UITableViewCellEditingStyleDelete;
    }
    
    return editingStyle;
}

- (void)   tableView:(UITableView *) __unused tableView
  commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
   forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self removeGlucoseEntryAtIndexPath:indexPath];
    }
}

#pragma mark - Helpers

- (NSInteger)numberOfDaysFromDate:(NSDate *)date
{
    NSCalendarUnit units = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;
    
    NSString *localFromDate = [NSDateFormatter localizedStringFromDate:date
                                                         dateStyle:NSDateFormatterShortStyle
                                                         timeStyle:NSDateFormatterNoStyle];
    
    NSString *localToDate = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                           dateStyle:NSDateFormatterShortStyle
                                                           timeStyle:NSDateFormatterNoStyle];
    
    [kDateFormatter setDateStyle:NSDateFormatterShortStyle];
    NSDate *fromDate = [kDateFormatter dateFromString:localFromDate];
    NSDate *toDate = [kDateFormatter dateFromString:localToDate];
    
    
    // if 'date' is before "now" (i.e. in the past) then the components will be positive
    NSDateComponents *components = [[NSCalendar currentCalendar] components:units
                                                                   fromDate:fromDate
                                                                     toDate:toDate
                                                                    options:0];
    
    return components.day;
}

- (NSDate *)dateForSpan:(NSInteger)daySpan fromDate:(NSDate *)date
{
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:daySpan];
    
    if (!date) {
        date = [NSDate date];
    }
    
    NSDate *spanDate = [[NSCalendar currentCalendar] dateByAddingComponents:components
                                                                     toDate:date
                                                                    options:0];
    return spanDate;
}

- (ORKStepResult *)result
{
    
    if (!self.stepResult) {
        self.stepResult = [[ORKStepResult alloc] initWithIdentifier:self.step.identifier];
    }
    
    return self.stepResult;
}

#pragma mark - Past Entry Date Selection

- (void)showPastEntryDatePicker
{
    if (self.bannerIsVisible) {
        [self moveBannerOffScreen];
    } else {
        [self moveBannerOnScreen];
    }
}

- (void)moveBannerOffScreen {
    [self.view layoutIfNeeded];
    
    self.constraintToTop.constant = -240;
    self.constraintToTopFromTableView.constant = 0;
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self.view layoutIfNeeded]; // Called on parent view
                     }];
    self.bannerIsVisible = FALSE;
}

- (void)moveBannerOnScreen {
    [self.view layoutIfNeeded];
    
    self.constraintToTop.constant = 0;
    self.constraintToTopFromTableView.constant = 180;
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self.view layoutIfNeeded]; // Called on parent view
                     }];
    self.bannerIsVisible = TRUE;
}

#pragma mark - Slider Date Picker Delegate

- (void)didSelectDate:(NSDate *)selectedDate
{
    // In order to add glucose entries for previous days we will need:
    //
    //      1. Glucose Levels  == This should already be set in the currentUser.glucoseLevels
    //      2. Schedueld Task  == We will need to created this using the hours that are associated with the glucose levels.
    //
    // Only allow creating entries in the past if none exist for the day.
    
    NSString *glucoseLevels = self.appDelegate.dataSubstrate.currentUser.glucoseLevels;

    NSData *levelsData = [glucoseLevels dataUsingEncoding:NSUTF8StringEncoding];

    NSError *error = nil;
    NSArray *levels = [NSJSONSerialization JSONObjectWithData:levelsData options:NSJSONReadingAllowFragments error:&error];

    if (levels.count > 0) {

        NSOperationQueue *pastEntryQueue = [NSOperationQueue sequentialOperationQueueWithName:@"Glucose entries in the past..."];

        __weak APHGlucoseLogViewController *weakSelf = self;
        NSArray *hours = [levels valueForKey:@"scheduledHour"];

        [pastEntryQueue addOperationWithBlock:^{
            NSError *entryError = nil;

            NSDate *entryDate = selectedDate;

            [weakSelf isDateValidForGlucoseEntry:entryDate
                                         atHours:hours
                                   scheduleError:&entryError
                                      completion:^(BOOL dateIsValid, NSError *glucoseEntryError) {
                                          if (dateIsValid) {
                                              NSError *scheduleError = nil;

                                              [weakSelf generateScheduleForGlucoseEntryDate:entryDate
                                                                                    atHours:hours
                                                                              scheduleError:&scheduleError
                                                                                 completion:^(NSError *glucoseEntryError) {
                                                                                     if (glucoseEntryError) {
                                                                                         APCLogError2(glucoseEntryError);
                                                                                     } else {
                                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                                             [self moveBannerOffScreen];
                                                                                             [self retrieveGlucoseLogSchedules];
                                                                                             [self.tableView reloadData];
                                                                                             
                                                                                             NSInteger logRows = [self.tableView numberOfRowsInSection:APHGlucoseLogSectionHistory];
                                                                                             
                                                                                             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:logRows - 1 inSection:APHGlucoseLogSectionHistory];
                                                                                             
                                                                                             [self showGlucoseEntryViewAtIndexPath:indexPath];
                                                                                         });
                                                                                     }
                                                                                 }];

                                          } else {
                                              APCLogError2(glucoseEntryError);
                                          }
                                  }];
        }];

    } else {
        // Hmm... we didn't get any glucose levels. This means that while the task is
        // visible there aren't any glucose levels set, which is an error.
        // Therefore we will show the glucose level configuration screen as a modal.
        
        // TODO: Show the glucose level configuration view.
    }
}

@end
