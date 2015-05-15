// 
//  Glucose 
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

#import "APHGlucoseLevelsMealTimesViewController.h"
#import "APHGlucoseLevelsDaysViewController.h"
#import "APHGlucoseLevelsViewController.h"

static NSString *kGlucoseLevelCellIdentifier = @"GlucoseLevelMealTimeCell";
static NSString *kGlucoseLogTaskId           = @"APHLogGlucose-42449E07-7124-40EF-AC93-CA5BBF95FC15";
static NSDateFormatter *dateFormatter = nil;

static NSString *kGlucoseCheckTimesKey         = @"glucoseCheckTimeKey";

static NSString *kGlucoseScheduleBeforeKey     = @"scheduleBeforeKey";
static NSString *kGlucoseScheduleAfterKey      = @"scheduleAfterKey";

NSString *const kTimeOfDayBreakfast           = @"Breakfast";
NSString *const kTimeOfDayLunch               = @"Lunch";
NSString *const kTimeOfDayDinner              = @"Dinner";
NSString *const kTimeOfDayBedTime             = @"Bed Time";
NSString *const kTimeOfDayAfter               = @"After";
NSString *const kTimeOfDayBefore              = @"Before";
NSString *const kTimeOfDayMorningFasting      = @"Morning Fasting";
NSString *const kTimeOfDayOther               = @"Other";
NSString *const kTimeOfDayRecurring           = @"Recurring";

NSString *const kGlucoseLevelTimeOfDayKey     = @"timeOfDay";
NSString *const kGlucoseLevelPeriodKey        = @"period";
NSString *const kGlucoseLevelBeforeKey        = @"before";
NSString *const kGlucoseLevelAfterKey         = @"after";
NSString *const kGlucoseLevelOtherKey         = @"other";
NSString *const kGlucoseLevelScheduledHourKey = @"scheduledHour";
NSString *const kGlucoseLevelIndexPath        = @"indexPath";
NSString *const kGlucoseLevelValueKey         = @"value";

NSString *const kRecurringValueNever          = @"Never";

@interface APHGlucoseLevelsMealTimesViewController ()

@property (strong, nonatomic) NSString *sceneDataIdentifier;

@property (nonatomic, strong) NSMutableArray *glucoseLevels;

@property (nonatomic, strong) NSMutableArray *glucoseCheckTimes;
@property (nonatomic, strong) NSMutableArray *glucoseMealTimeConfiguration;

@property (nonatomic, strong) NSArray *glucoseCheckSchedules;
@property (nonatomic, strong) NSString *selectedRepeatDays;

@property (nonatomic, strong) NSArray *mealTimeDatasource;

@end

@implementation APHGlucoseLevelsMealTimesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNavAppearance];
    
    self.sceneDataIdentifier = [NSString stringWithFormat:@"%@", kGlucoseLevelCellIdentifier];
    
    self.glucoseLevels = [NSMutableArray array];
    self.glucoseCheckTimes = [NSMutableArray array];
    
    self.mealTimeDatasource = @[
                                @{
                                    kGlucoseLevelTimeOfDayKey: NSLocalizedString(kTimeOfDayBreakfast, @"Morning Fasting"),
                                    kGlucoseLevelPeriodKey: kGlucoseLevelBeforeKey
                                },
                                @{
                                    kGlucoseLevelTimeOfDayKey: NSLocalizedString(kTimeOfDayBreakfast, @"After Breakfast"),
                                    kGlucoseLevelPeriodKey: kGlucoseLevelAfterKey
                                },
                                @{
                                    kGlucoseLevelTimeOfDayKey: NSLocalizedString(kTimeOfDayLunch, @"Before Lunch"),
                                    kGlucoseLevelPeriodKey: kGlucoseLevelBeforeKey
                                },
                                @{
                                    kGlucoseLevelTimeOfDayKey: NSLocalizedString(kTimeOfDayLunch, @"After Lunch"),
                                    kGlucoseLevelPeriodKey: kGlucoseLevelAfterKey
                                },
                                @{
                                    kGlucoseLevelTimeOfDayKey: NSLocalizedString(kTimeOfDayDinner, @"Before Dinner"),
                                    kGlucoseLevelPeriodKey: kGlucoseLevelBeforeKey
                                },
                                @{
                                    kGlucoseLevelTimeOfDayKey: NSLocalizedString(kTimeOfDayDinner, @"After Dinner"),
                                    kGlucoseLevelPeriodKey: kGlucoseLevelAfterKey
                                },
                                @{
                                    kGlucoseLevelTimeOfDayKey: NSLocalizedString(kTimeOfDayBedTime, @"Before Bed Time"),
                                    kGlucoseLevelPeriodKey: kGlucoseLevelBeforeKey
                                },
                                @{
                                    kGlucoseLevelTimeOfDayKey: NSLocalizedString(kTimeOfDayOther, @"Other"),
                                    kGlucoseLevelPeriodKey: kGlucoseLevelAfterKey
                                 }
                            ];
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"Configuration Mode: %@", (self.isConfigureMode) ? @"YES" : @"NO");
    
    if (self.isConfigureMode) {
        [self prepareForConfigurationMode];
    } else {
        // check if there is data for the scene
        NSArray *sceneData = [self.onboarding.sceneData valueForKey:self.sceneDataIdentifier];
        
        if (sceneData) {
            [self.glucoseCheckTimes removeAllObjects];
            [self.glucoseCheckTimes addObjectsFromArray:sceneData];
            
            self.navigationItem.rightBarButtonItem.enabled = (self.glucoseCheckTimes.count != 0);
        }
    }
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.isConfigureMode == NO) {
        [self.onboarding.sceneData setValue:[self.glucoseCheckTimes copy]
                                     forKey:self.sceneDataIdentifier];
    } else {
        // save data, if needed to data store.
    }

    [super viewWillDisappear: animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (APCOnboarding *)onboarding
{
    return ((APCAppDelegate *)[UIApplication sharedApplication].delegate).onboarding;
}

- (void)setupNavAppearance
{
    UIBarButtonItem *backBarButton = [APCCustomBackButton customBackBarButtonItemWithTarget:self
                                                                                     action:@selector(goBackwards)
                                                                                  tintColor:[UIColor appPrimaryColor]];
    [self.navigationItem setLeftBarButtonItem:backBarButton];
    
}

- (void)prepareForConfigurationMode
{
    UIBarButtonItem *btnDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                             target:self
                                                                             action:@selector(saveGlucoseConfiguration)];
    
    self.navigationItem.rightBarButtonItem = btnDone;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.pickedDays = [defaults objectForKey:kGlucoseMealTimePickedDays];
    
    self.glucoseMealTimeConfiguration = [NSMutableArray new];
    self.glucoseMealTimeConfiguration = [self retireveGlucoseLevels];
    
    [self.glucoseCheckTimes addObjectsFromArray:self.glucoseMealTimeConfiguration];
}

- (void)saveGlucoseConfiguration
{
    if ([self.glucoseCheckTimes count] != 0) {
        [self setupSchedules];
    }
    [self goBackwards];
}

- (NSMutableArray *)retireveGlucoseLevels
{
    APCAppDelegate *apcDelegate = (APCAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *normalizedLevels = nil;
    // retrieve glucose levels from the datastore
    NSString *levels = [apcDelegate.dataSubstrate.currentUser glucoseLevels];
    
    if (levels) {
        NSData *levelsData = [levels dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        
        normalizedLevels = [NSJSONSerialization JSONObjectWithData:levelsData options:NSJSONReadingAllowFragments error:&error];
    }
    
    return [normalizedLevels mutableCopy];
}

#pragma mark - Navigation

- (IBAction)goForward {
    
    if ([self.glucoseCheckTimes count] != 0 && ![self.selectedRepeatDays isEqualToString:kRecurringValueNever]) {
        [self.onboarding.sceneData setObject:[self.glucoseCheckTimes copy] forKey:self.onboarding.currentStep.identifier];
        [self setupSchedules];
    }
    
    UIViewController *viewController = [[self onboarding] nextScene];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)goBackwards
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Glucose Levels

- (void)setupSchedules
{
    APCAppDelegate *appDelegate = (APCAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSDate *userSleepTime = appDelegate.dataSubstrate.currentUser.sleepTime;
    NSDate *userWakeTime = appDelegate.dataSubstrate.currentUser.wakeUpTime;
    NSDate *scheduleTime = nil;
    
    if (!userWakeTime) {
        userWakeTime = [[NSCalendar currentCalendar] dateBySettingHour:06
                                                                minute:00
                                                                second:00
                                                                ofDate:[NSDate date]
                                                               options:0];
    }
    
    if (!userSleepTime) {
        userSleepTime = [[NSCalendar currentCalendar] dateBySettingHour:21
                                                                 minute:00
                                                                 second:00
                                                                 ofDate:[NSDate date]
                                                                options:0];
    }
    
    NSMutableArray *scheduleTimes = [NSMutableArray array];
    
    for (NSDictionary *checkTime in self.glucoseCheckTimes) {
        NSString *timeOfDay = checkTime[kGlucoseLevelTimeOfDayKey];
        NSString *period = checkTime[kGlucoseLevelPeriodKey];
        NSNumber *scheduledHour = checkTime[kGlucoseLevelScheduledHourKey];
        
        if ([scheduledHour isEqualToNumber:@(0)]) {
            if (!scheduleTime) {
                if ([timeOfDay isEqualToString:kTimeOfDayBedTime]) {
                    scheduleTime = userSleepTime;
                } else {
                    scheduleTime = userWakeTime;
                }
            }
            
            if ([timeOfDay isEqualToString:kTimeOfDayBedTime]) {
                if ([period isEqualToString:kGlucoseLevelBeforeKey]) {
                    scheduleTime = [self offsetDate:userSleepTime byHour:-1];
                }
            } else if ([timeOfDay isEqualToString:kTimeOfDayDinner]) {
                if ([period isEqualToString:kGlucoseLevelBeforeKey]) {
                    scheduleTime = [self offsetDate:userSleepTime byHour:-4];
                } else {
                    scheduleTime = [self offsetDate:userSleepTime byHour:-2];
                }
            } else if ([timeOfDay isEqualToString:kTimeOfDayMorningFasting]){
                if ([period isEqualToString:kGlucoseLevelBeforeKey]) {
                    scheduleTime = [self offsetDate:userWakeTime byHour:1];
                } else {
                    scheduleTime = [self offsetDate:userWakeTime byHour:3];
                }
            } else if ([timeOfDay isEqualToString:kTimeOfDayOther]){
                scheduleTime = [self offsetDate:userSleepTime byHour:2];
            } else {
                if ([period isEqualToString:kGlucoseLevelBeforeKey]) {
                    scheduleTime = [self offsetDate:scheduleTime byHour:4];
                } else {
                    scheduleTime = [self offsetDate:scheduleTime byHour:6];
                }
            }
            
            NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:scheduleTime];
            
            for (NSNumber *hour in scheduleTimes) {
                if ([hour isEqual:@(components.hour)]) {
                    APCLogDebug(@"Duplicate hour: %@", hour);
                    components.hour = [hour integerValue] + 1;
                }
            }
            
            [scheduleTimes addObject:[NSNumber numberWithInteger:components.hour]];
        } else {
            [scheduleTimes addObject:scheduledHour];
        }
    }
    
    // To avoid duplicate schedules we will check to see if we already have
    // a schedule in place.
    NSFetchRequest *request = [APCSchedule request];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(taskID == %@)", kGlucoseLogTaskId];
    
    request.predicate = predicate;
    
    NSError *error = nil;
    NSArray *entries = [appDelegate.dataSubstrate.mainContext executeFetchRequest:request
                                                                            error:&error];
    
    APCSchedule *glucoseSchedule = nil;
    
    NSArray *sortedScheduleTimes = [scheduleTimes sortedArrayUsingSelector:@selector(compare:)];
    NSString *repeatDays = [self convertDayNames:self.pickedDays];
    NSString *scheduleString = [NSString stringWithFormat:@"0 %@ * * %@", [sortedScheduleTimes componentsJoinedByString:@","], repeatDays];
    
    if ([entries count] == 0) {
        glucoseSchedule = [APCSchedule newObjectForContext:appDelegate.dataSubstrate.mainContext];
        
        APCLogDebug(@"Sleep/Wake: %@/%@", userSleepTime, userWakeTime);
        APCLogDebug(@"Glucose schedule: %@", scheduleString);
        
        glucoseSchedule.scheduleString = scheduleString;
        glucoseSchedule.taskID = kGlucoseLogTaskId;
        glucoseSchedule.scheduleType = @"recurring";
        
        NSError *glucoseScheduleError = nil;
        BOOL saveSuccess = [glucoseSchedule saveToPersistentStore:&glucoseScheduleError];
        
        if (!saveSuccess) {
            APCLogError2(glucoseScheduleError);
        }
        
        // Send the schedule notification
        [[NSNotificationCenter defaultCenter] postNotificationName:APCScheduleUpdatedNotification
                                                            object:nil];
    } else {
        glucoseSchedule = [entries firstObject];
        glucoseSchedule.scheduleString = scheduleString;
        
        NSError *glucoseScheduleError = nil;
        BOOL saveSuccess = [glucoseSchedule saveToPersistentStore:&glucoseScheduleError];
        
        if (!saveSuccess) {
            APCLogError2(glucoseScheduleError);
        } else {
            [self createSchedulesForMealTimes:sortedScheduleTimes forSchedule:glucoseSchedule];
        }
    }
    
    [self saveGlucoseSetup:sortedScheduleTimes];
}

- (void)createSchedulesForMealTimes:(NSArray *)hours forSchedule:(APCSchedule *)schedule
{
    APCAppDelegate *appDelegate = (APCAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext * localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    localContext.parentContext = appDelegate.dataSubstrate.persistentContext;
    
    APCSchedule *glucoseSchedule = (APCSchedule *)[localContext objectWithID:schedule.objectID];
    
    NSArray *listOfScheduledTasks = [schedule.scheduledTasks allObjects];
    NSArray *scheduledStartTimes = [[listOfScheduledTasks valueForKey:@"startOn"] sortedArrayUsingSelector:@selector(compare:)];
    
    // Get the dates from the scheduled task's start time.
    NSMutableArray *entryStartDates = [NSMutableArray new];
    
    for (NSDate *entryDate in scheduledStartTimes) {
        NSDate *entryDateAtMidnight = [entryDate startOfDay];
        [entryStartDates addObject:entryDateAtMidnight];
    }
    
    NSSet *entryDates = [NSSet setWithArray:entryStartDates];
    
    // remove items that are in self.glucoseMealTimeConfiguration from the hours array
    NSArray *existingHours = [self.glucoseMealTimeConfiguration valueForKey:kGlucoseLevelScheduledHourKey];
    NSMutableArray *newlyAddedHours = [hours mutableCopy];
    NSMutableArray *removedHours = [NSMutableArray new];
    
    for (NSNumber *existingHour in existingHours) {
        if (![newlyAddedHours containsObject:existingHour]) {
            [removedHours addObject:existingHour];
        }
        
        [newlyAddedHours removeObjectIdenticalTo:existingHour];
    }
    
    NSArray *allMealTimeScheduledTasks = [entryDates allObjects];
    
    [self removeScheduledTasks:listOfScheduledTasks forMealTimes:removedHours];
    
    [self createScheduledTasks:allMealTimeScheduledTasks forMealTimes:newlyAddedHours forSchedule:glucoseSchedule];
}

- (void)createScheduledTasks:(NSArray *)allMealTimeScheduledTasks
                forMealTimes:(NSArray *)newlyAddedHours
                 forSchedule:(APCSchedule *)glucoseSchedule
{
    APCTask *glucoseLogTask = [APCTask taskWithTaskID:kGlucoseLogTaskId
                                            inContext:glucoseSchedule.managedObjectContext];
    
    // Loop through all newly added meal times and create a schedule
    // for the hours in newlyAddedHours array.
    for (NSDate *taskStartDate in allMealTimeScheduledTasks) {
        
        for (NSNumber *hour in newlyAddedHours) {
            NSDate *entryDateStart = [[NSCalendar currentCalendar] dateBySettingHour:[hour integerValue]
                                                                              minute:0
                                                                              second:0
                                                                              ofDate:taskStartDate
                                                                             options:0];
            
            NSDate *entryDateEnd = [taskStartDate endOfDay];
            
            // Let's create the scheduled task for the provided date
            APCScheduledTask *scheduledTaskForNewEntry = [APCScheduledTask newObjectForContext:glucoseSchedule.managedObjectContext];
            scheduledTaskForNewEntry.startOn = entryDateStart;
            scheduledTaskForNewEntry.endOn = entryDateEnd;
            scheduledTaskForNewEntry.completed = @(NO);
            scheduledTaskForNewEntry.task = glucoseLogTask;
            scheduledTaskForNewEntry.generatedSchedule = glucoseSchedule;
            
            NSError *newEntryError = nil;
            BOOL saveSuccess = [scheduledTaskForNewEntry saveToPersistentStore:&newEntryError];
            
            if (!saveSuccess) {
                APCLogError2(newEntryError);
            } else {
                //DEBUG
                APCLogDebug(@"Scheduled Task UID: %@ (Start: %@ | End: %@)",
                            scheduledTaskForNewEntry.uid, scheduledTaskForNewEntry.startOn, scheduledTaskForNewEntry.endOn);
            }
        }
    }
}

- (void)removeScheduledTasks:(NSArray *)listOfScheduledTasks forMealTimes:(NSArray *)removedHours
{
    NSSortDescriptor *sortByScheduledHour = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(startOn)) ascending:YES];
    [listOfScheduledTasks sortedArrayUsingDescriptors:@[sortByScheduledHour]];
    
    // Loop through and remove all meal times scheduled tasks
    for (APCScheduledTask *scheduledTask in listOfScheduledTasks) {
        NSString *scheduledTaskId = scheduledTask.uid;
        NSError *scheduleTaskDeleteError = nil;
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour
                                                                       fromDate:scheduledTask.startOn];
        if ([removedHours containsObject:@(components.hour)]) {
            BOOL successDeletingTask = [scheduledTask removeScheduledTask:&scheduleTaskDeleteError];
            
            if (!successDeletingTask) {
                APCLogError2(scheduleTaskDeleteError);
            } else {
                APCLogDebug(@"Removed scheduled task: %@", scheduledTaskId);
            }
        }
    }
}

- (NSString *)convertDayNames:(NSString *)selectedDays
{
    NSString *converted = nil;
    
    if (!selectedDays || [selectedDays isEqualToString:@"Everyday"]) {
        converted = @"*";
    } else {
        NSArray *days = [selectedDays componentsSeparatedByString:@" "];
        NSArray *refenceDayNames = nil;
        NSMutableArray *repeatDays = [NSMutableArray array];
        
        if ([days count] == 1) {
            refenceDayNames = [dateFormatter weekdaySymbols];
        } else {
            refenceDayNames = [dateFormatter shortWeekdaySymbols];
        }
        
        for (NSString *day in days) {
            
            if ([refenceDayNames containsObject:day]) {
                NSUInteger dayIndex = [refenceDayNames indexOfObject:day];
                [repeatDays addObject:@(dayIndex)];
            }
        }
        
        converted = [repeatDays componentsJoinedByString:@","];
    }
    
    return converted;
}

- (void)saveGlucoseSetup:(NSArray *)scheduleHours
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"indexPath" ascending:YES selector:@selector(compare:)];
    [self.glucoseCheckTimes sortUsingDescriptors:@[sortDescriptor]];
    
    for (NSUInteger idx = 0; idx < self.glucoseCheckTimes.count; idx++) {
        NSMutableDictionary *timeForChecking = [[self.glucoseCheckTimes objectAtIndex:idx] mutableCopy];
        
        timeForChecking[kGlucoseLevelScheduledHourKey] = [scheduleHours objectAtIndex:idx];
        
        [self.glucoseCheckTimes replaceObjectAtIndex:idx withObject:timeForChecking];
    }
    
    APCLogDebug(@"Glucose meal times: %@", self.glucoseCheckTimes);
    
    APCAppDelegate *apcDelegate = (APCAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSError *error = nil;
    NSData *glucoseLevelData = [NSJSONSerialization dataWithJSONObject:self.glucoseCheckTimes options:0 error:&error];
    NSString *levels = [[NSString alloc] initWithData:glucoseLevelData encoding:NSUTF8StringEncoding];
    
    // persist glucose levels to the datastore
    [apcDelegate.dataSubstrate.currentUser setGlucoseLevels:levels];
}

- (NSDate *)offsetDate:(NSDate *)date byHour:(NSUInteger)hour
{
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setHour:hour];
    
    NSDate *spanDate = [[NSCalendar currentCalendar] dateByAddingComponents:components
                                                                     toDate:date
                                                                    options:0];
    return spanDate;
}

- (void)updateGlucoseLevelsWithTimeOfDay:(NSString *)timeOfDay
                                 checkAt:(NSString *)checkAt
                              checkValue:(BOOL) __unused value
                             atIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *timeIndexPath = @(indexPath.row);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", kGlucoseLevelIndexPath, timeIndexPath];
    NSArray *filteredTimes = [self.glucoseCheckTimes filteredArrayUsingPredicate:predicate];
    
    NSNumber *scheduledHour = @(0);
    
    if ([filteredTimes count]) {
        NSUInteger existingTimeIndex = [self.glucoseCheckTimes indexOfObject:[filteredTimes firstObject]];
        [self.glucoseCheckTimes removeObjectAtIndex:existingTimeIndex];
    } else {
        
        if (self.isConfigureMode) {
            // check of the meal time was previously selected
            NSArray *previousItem = [self.glucoseMealTimeConfiguration filteredArrayUsingPredicate:predicate];
            
            if (previousItem.count > 0) {
                NSDictionary *previousTime = [previousItem firstObject];
                scheduledHour = previousTime[kGlucoseLevelScheduledHourKey];
            }
        }
        
        [self.glucoseCheckTimes addObject:@{
                                            kGlucoseLevelTimeOfDayKey: timeOfDay,
                                            kGlucoseLevelPeriodKey: checkAt,
                                            kGlucoseLevelScheduledHourKey: scheduledHour,
                                            @"indexPath": timeIndexPath
                                            }];
    }
}

#pragma mark - TableView
#pragma mark Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *) __unused tableView numberOfRowsInSection:(NSInteger) __unused section
{
    return [self.mealTimeDatasource count];
}

- (CGFloat)tableView:(UITableView *) __unused tableView heightForRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    return kGlucoseLevelCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kGlucoseLevelCellIdentifier
                                                            forIndexPath:indexPath];
    
    NSDictionary *mealTime = [self.mealTimeDatasource objectAtIndex:indexPath.row];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", kTimeOfDayMorningFasting];
    } else {
        NSString *beforeOrAfter = mealTime[kGlucoseLevelPeriodKey];
        NSString *timeOfDayPeriod = nil;
        
        if ([beforeOrAfter isEqualToString:kGlucoseLevelBeforeKey]) {
            timeOfDayPeriod = kTimeOfDayBefore;
        } else if ([beforeOrAfter isEqualToString:kGlucoseLevelAfterKey] && ![mealTime[kGlucoseLevelTimeOfDayKey] isEqualToString:kTimeOfDayOther]) {
            timeOfDayPeriod = kTimeOfDayAfter;
        } else {
            timeOfDayPeriod = @"";
        }
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", timeOfDayPeriod, mealTime[kGlucoseLevelTimeOfDayKey]];
    }
    
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %lu", kGlucoseLevelIndexPath, indexPath.row];
    NSArray *selectedMealTimes = [self.glucoseCheckTimes filteredArrayUsingPredicate:predicate];
    NSDictionary *selectedMealTime = [selectedMealTimes firstObject];
    NSNumber *selectedMealTimeIndex = selectedMealTime[kGlucoseLevelIndexPath];
    
    if (selectedMealTimeIndex && ([selectedMealTimeIndex integerValue] == indexPath.row)) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = [UIColor appPrimaryColor];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}

#pragma mark Delegates

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *mealTime = [self.mealTimeDatasource objectAtIndex:indexPath.row];
    
    NSString *mealTimeName = mealTime[kGlucoseLevelTimeOfDayKey];
    NSString *period = mealTime[kGlucoseLevelPeriodKey];

    [self updateGlucoseLevelsWithTimeOfDay:mealTimeName
                                   checkAt:period
                                checkValue:YES
                               atIndexPath:indexPath];
    
    self.navigationItem.rightBarButtonItem.enabled = (self.glucoseCheckTimes.count != 0);
    
    [tableView reloadData];
}

@end
