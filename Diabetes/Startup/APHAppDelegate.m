// 
//  APHAppDelegate.m 
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
 
#import "APHAppDelegate.h"
#import "APHProfileExtender.h"
#import "APHAppDelegate+APHMigration.h"

/*********************************************************************************/
#pragma mark - Survey Identifiers
/*********************************************************************************/
static NSString* const kDailyCheckSurveyIdentifier      = @"DailyCheck-1E174061-5B02-11E4-8ED6-0800200C9A66";
static NSString* const kWeeklyCheckSurveyIdentifier     = @"WeeklyCheck-1E174061-5B02-11E4-8ED6-0800200C9A66";
static NSString* const kWaistCheckSurveyIdentifier      = @"APHMeasureWaist-8BCC1BB7-4991-4018-B9CA-4DE820B1CC73";
static NSString* const kWeightCheckSurveyIdentifier     = @"APHEnterWeight-76C03691-4417-4AD6-8F67-F708A8897FF6";
NSString* const kGlucoseLogSurveyIdentifier             = @"APHLogGlucose-42449E07-7124-40EF-AC93-CA5BBF95FC15";
static NSString* const kFoodLogSurveyIdentifier         = @"FoodLog-92F2B523-C7A1-40DF-B89E-BC60EB801AF0";
static NSString* const kSevenDayAllocationIdentifier    = @"APHSevenDayAllocation-00000000-1111-1111-1111-F810BE28D995";
static NSString* const kBaselineSurveyIdentifier        = @"BaselineSurvey-1E77771-5B02-11E4-8ED6-0800200C9A66";
static NSString* const kSleepSurveyIdentifier           = @"SleepSurvey-1E77771-5B02-11E4-8ED6-0811200C9A66";
static NSString* const kQualityOfLifeSurveyIdentifier   = @"QualityOfLife-1E77771-5B02-11E4-8ED6-0811200C9A66";

static NSString *kFeetCheckStepIdentifier               = @"foot_check";

/*********************************************************************************/
#pragma mark - Initializations Options
/*********************************************************************************/
static NSString* const kStudyIdentifier                 = @"studyname";
static NSString* const kAppPrefix                       = @"studyname";
static NSString* const kConsentPropertiesFileName       = @"APHConsentSection";

static NSString *const kJSONScheduleStringKey           = @"scheduleString";
static NSString *const kJSONTasksKey                    = @"tasks";
static NSString *const kJSONScheduleTaskIDKey           = @"taskID";
static NSString *const kJSONSchedulesKey                = @"schedules";

static NSString *const kMigrationTaskIdKey              = @"taskId";
static NSString *const kMigrationOffsetByDaysKey        = @"offsetByDays";
static NSString *const kMigrationGracePeriodInDaysKey   = @"gracePeriodInDays";
static NSString *const kMigrationRecurringKindKey       = @"recurringKind";

static NSString *const kVideoShownKey = @"VideoShown";

static NSString *const kHealthKitMetadataKeyFoodType = @"HKFoodType";
static NSString *const kHealthKitMetadataKeyFoodMeal = @"HKFoodMeal";

typedef NS_ENUM(NSUInteger, APHMigrationRecurringKinds)
{
    APHMigrationRecurringKindWeekly = 0,
    APHMigrationRecurringKindMonthly,
    APHMigrationRecurringKindQuarterly,
    APHMigrationRecurringKindSemiAnnual,
    APHMigrationRecurringKindAnnual
};

@interface APHAppDelegate ()

@property (nonatomic, strong) APHProfileExtender* profileExtender;
@property  (nonatomic, assign)  NSInteger environment;

@end

@implementation APHAppDelegate

- (BOOL)application:(UIApplication*) __unused application willFinishLaunchingWithOptions:(NSDictionary*) __unused launchOptions
{
    [super application:application willFinishLaunchingWithOptions:launchOptions];
    
    [self enableBackgroundDeliveryForHealthKitTypes];
    
    return YES;
}

- (void)enableBackgroundDeliveryForHealthKitTypes
{
    NSArray* dataTypesWithReadPermission = self.initializationOptions[kHKReadPermissionsKey];
    
    if (dataTypesWithReadPermission)
    {
        for (id dataType in dataTypesWithReadPermission)
        {
            HKObjectType*   sampleType  = nil;
            
            if ([dataType isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* categoryType = (NSDictionary*) dataType;
                
                //Distinguish
                if (categoryType[kHKWorkoutTypeKey])
                {
                    sampleType = [HKObjectType workoutType];
                }
                else if (categoryType[kHKCategoryTypeKey])
                {
                    sampleType = [HKObjectType categoryTypeForIdentifier:categoryType[kHKCategoryTypeKey]];
                }
            }
            else
            {
                sampleType = [HKObjectType quantityTypeForIdentifier:dataType];
            }
            
            if (sampleType)
            {
                [self.dataSubstrate.healthStore enableBackgroundDeliveryForType:sampleType
                                                                      frequency:HKUpdateFrequencyImmediate
                                                                 withCompletion:^(BOOL success, NSError *error)
                 {
                     if (!success)
                     {
                         if (error)
                         {
                             APCLogError2(error);
                         }
                     }
                     else
                     {
                         APCLogDebug(@"Enabling background delivery for healthkit");
                     }
                 }];
            }
        }
    }
}

- (void) setUpInitializationOptions
{
    NSDictionary *permissionsDescriptions = @{
                                              @(kAPCSignUpPermissionsTypeLocation) : NSLocalizedString(@"Using your GPS enables the app to accurately determine distances travelled. Your actual location will never be shared.", @""),
                                              @(kAPCSignUpPermissionsTypeCoremotion) : NSLocalizedString(@"Using the motion co-processor allows the app to determine your activity, helping the study better understand how activity level may influence disease.", @""),
                                              @(kAPCSignUpPermissionsTypeMicrophone) : NSLocalizedString(@"Access to microphone is required for your Voice Recording Activity.", @""),
                                              @(kAPCSignUpPermissionsTypeLocalNotifications) : NSLocalizedString(@"Allowing notifications enables the app to show you reminders.", @""),
                                              @(kAPCSignUpPermissionsTypeHealthKit) : NSLocalizedString(@"On the next screen, you will be prompted to grant GlucoSuccess access to read and write some of your general and health information, such as height, weight and steps taken so you don't have to enter it again.", @""),
                                              };
    
    NSMutableDictionary * dictionary = [super defaultInitializationOptions];
    
#ifdef DEBUG
    self.environment = SBBEnvironmentStaging;
#else
    self.environment = SBBEnvironmentProd;
#endif
    
    [dictionary addEntriesFromDictionary:@{
                                           kStudyIdentifierKey                  : kStudyIdentifier,
                                           kAppPrefixKey                        : kAppPrefix,
                                           kBridgeEnvironmentKey                : @(self.environment),
                                           kHKReadPermissionsKey                : @[
                                                   HKQuantityTypeIdentifierBodyMass,
                                                   HKQuantityTypeIdentifierHeight,
                                                   HKQuantityTypeIdentifierStepCount,
                                                   HKQuantityTypeIdentifierDietaryCarbohydrates,
                                                   HKQuantityTypeIdentifierDietarySugar,
                                                   HKQuantityTypeIdentifierDietaryEnergyConsumed,
                                                   HKQuantityTypeIdentifierBloodGlucose
                                                   ],
                                           kHKWritePermissionsKey                : @[
                                                   HKQuantityTypeIdentifierBodyMass,
                                                   HKQuantityTypeIdentifierHeight
                                                   ],
                                           kAppServicesListRequiredKey           : @[
                                                   @(kAPCSignUpPermissionsTypeLocalNotifications),
                                                   @(kAPCSignUpPermissionsTypeCoremotion)
                                                   ],
                                           kAppServicesDescriptionsKey : permissionsDescriptions,
                                           kAppProfileElementsListKey            : @[
                                                   @(kAPCUserInfoItemTypeEmail),
                                                   @(kAPCUserInfoItemTypeBiologicalSex),
                                                   @(kAPCUserInfoItemTypeHeight),
                                                   @(kAPCUserInfoItemTypeWeight),
                                                   @(kAPCUserInfoItemTypeWakeUpTime),
                                                   @(kAPCUserInfoItemTypeSleepTime),
                                                   ]
                                           }];

    self.initializationOptions = dictionary;
    
    self.profileExtender = [[APHProfileExtender alloc] init];
}

- (NSDictionary*)researcherSpecifiedUnits
{
    NSDictionary* hkUnits =
    @{
      HKQuantityTypeIdentifierStepCount                 : [HKUnit countUnit],
      HKQuantityTypeIdentifierBodyMass                  : [HKUnit gramUnitWithMetricPrefix:HKMetricPrefixKilo],
      HKQuantityTypeIdentifierHeight                    : [HKUnit meterUnit],

      
      HKQuantityTypeIdentifierDietaryCarbohydrates      : [HKUnit gramUnit],
      HKQuantityTypeIdentifierDietarySugar              : [HKUnit gramUnit],
      HKQuantityTypeIdentifierDietaryEnergyConsumed     : [HKUnit calorieUnit],
      HKQuantityTypeIdentifierBloodGlucose              : [[HKUnit gramUnitWithMetricPrefix:HKMetricPrefixMilli] unitDividedByUnit:[HKUnit literUnitWithMetricPrefix:HKMetricPrefixDeci]]
      };
    
    return hkUnits;
}

-(void)setUpTasksReminder{
    APCTaskReminder *dailySurveyReminder = [[APCTaskReminder alloc]initWithTaskID:kDailyCheckSurveyIdentifier reminderBody:NSLocalizedString(@"Complete Daily Check", nil)];
    APCTaskReminder *weeklySurveyReminder = [[APCTaskReminder alloc]initWithTaskID:kWeeklyCheckSurveyIdentifier reminderBody:NSLocalizedString(@"Complete Weekly Survey", nil)];
    APCTaskReminder *waistSurveyReminder = [[APCTaskReminder alloc]initWithTaskID:kWaistCheckSurveyIdentifier reminderBody:NSLocalizedString(@"Complete Waist Measurement", nil)];
    APCTaskReminder *weightSurveyReminder = [[APCTaskReminder alloc]initWithTaskID:kWeightCheckSurveyIdentifier reminderBody:NSLocalizedString(@"Complete Weight Measurement", nil)];
    APCTaskReminder *glucoseSurveyReminder = [[APCTaskReminder alloc]initWithTaskID:kGlucoseLogSurveyIdentifier reminderBody:NSLocalizedString(@"Complete Glucose Log", nil)];
    APCTaskReminder *foodSurveyReminder = [[APCTaskReminder alloc]initWithTaskID:kFoodLogSurveyIdentifier reminderBody:NSLocalizedString(@"Complete Food Log", nil)];
    
    NSPredicate *footCheckPredicate = [NSPredicate predicateWithFormat:@"SELF.integerValue == 1"];
    APCTaskReminder *footCheckReminder = [[APCTaskReminder alloc]initWithTaskID:kDailyCheckSurveyIdentifier resultsSummaryKey:kFeetCheckStepIdentifier completedTaskPredicate:footCheckPredicate reminderBody:NSLocalizedString(@"Check Your Feet", nil)];
    
    [self.tasksReminder.reminders removeAllObjects];
    [self.tasksReminder manageTaskReminder:dailySurveyReminder];
    [self.tasksReminder manageTaskReminder:weeklySurveyReminder];
    [self.tasksReminder manageTaskReminder:waistSurveyReminder];
    [self.tasksReminder manageTaskReminder:weightSurveyReminder];
    [self.tasksReminder manageTaskReminder:glucoseSurveyReminder];
    [self.tasksReminder manageTaskReminder:foodSurveyReminder];
    [self.tasksReminder manageTaskReminder:footCheckReminder];
    
    if ([self doesPersisteStoreExist] == NO)
    {
        APCLogEvent(@"This app is being launched for the first time. Turn all reminders on");
        for (APCTaskReminder *reminder in self.tasksReminder.reminders) {
            [[NSUserDefaults standardUserDefaults]setObject:reminder.reminderBody forKey:reminder.reminderIdentifier];
        }
        
        if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone){
            [self.tasksReminder setReminderOn:@YES];
        }
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
}

- (void) setUpAppAppearance
{
    [APCAppearanceInfo setAppearanceDictionary:@{
                                                 kPrimaryAppColorKey : [UIColor colorWithRed:0.020 green:0.549 blue:0.737 alpha:1.000],  //#058cbc Diabetes
                                                 kWeightCheckSurveyIdentifier: [UIColor appTertiaryRedColor],
                                                 kGlucoseLogSurveyIdentifier : [UIColor appTertiaryGreenColor],
                                                 kSevenDayAllocationIdentifier: [UIColor appTertiaryBlueColor],
                                                 kDailyCheckSurveyIdentifier: [UIColor lightGrayColor],
                                                 kWeeklyCheckSurveyIdentifier: [UIColor lightGrayColor],
                                                 kWaistCheckSurveyIdentifier: [UIColor appTertiaryRedColor],
                                                 kFoodLogSurveyIdentifier: [UIColor appTertiaryYellowColor],
                                                 kBaselineSurveyIdentifier: [UIColor appTertiaryGrayColor],
                                                 }];
    [[UINavigationBar appearance] setTintColor:[UIColor appPrimaryColor]];
    [[UINavigationBar appearance] setBackgroundColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                            NSForegroundColorAttributeName : [UIColor appSecondaryColor1],
                                                            NSFontAttributeName : [UIFont appNavBarTitleFont]
                                                            }];
    [[UIView appearance] setTintColor: [UIColor appPrimaryColor]];
}

- (id <APCProfileViewControllerDelegate>) profileExtenderDelegate {
    
    return self.profileExtender;
}

- (void) showOnBoarding
{
    [super showOnBoarding];
    
    [self showStudyOverview];
}

- (void) showStudyOverview
{
    APCStudyOverviewViewController *studyController = [[UIStoryboard storyboardWithName:@"APCOnboarding" bundle:[NSBundle appleCoreBundle]] instantiateViewControllerWithIdentifier:@"StudyOverviewVC"];
    [self setUpRootViewController:studyController];
}

- (BOOL) isVideoShown
{
    return NO;
}

- (NSArray *)reviewConsentActions
{
    return @[kReviewConsentActionPDF, kReviewConsentActionSlides];
}

- (NSArray *)metadataKeysForCorrelation
{
    return @[kHealthKitMetadataKeyFoodMeal, kHealthKitMetadataKeyFoodType];
}

- (NSDictionary *)migrateTasksAndSchedules:(NSDictionary *)currentTaskAndSchedules
{
    NSMutableDictionary *migratedTaskAndSchedules = nil;
    
    if (currentTaskAndSchedules == nil) {
        APCLogError(@"Nothing was loaded from the JSON file. Therefore nothing to migrate.");
    } else {
        migratedTaskAndSchedules = [currentTaskAndSchedules mutableCopy];
        
        NSArray *schedulesToMigrate = @[
                                        @{
                                            kMigrationTaskIdKey: kWeeklyCheckSurveyIdentifier,
                                            kMigrationOffsetByDaysKey: @(5),
                                            kMigrationGracePeriodInDaysKey: @(5),
                                            kMigrationRecurringKindKey: @(APHMigrationRecurringKindWeekly)
                                            },
                                        @{
                                            kMigrationTaskIdKey: kSleepSurveyIdentifier,
                                            kMigrationOffsetByDaysKey: @(29),
                                            kMigrationGracePeriodInDaysKey: @(5),
                                            kMigrationRecurringKindKey: @(APHMigrationRecurringKindMonthly)
                                            },
                                        @{
                                            kMigrationTaskIdKey: kQualityOfLifeSurveyIdentifier,
                                            kMigrationOffsetByDaysKey: @(34),
                                            kMigrationGracePeriodInDaysKey: @(5),
                                            kMigrationRecurringKindKey: @(APHMigrationRecurringKindMonthly)
                                            }
                                        ];
        
        NSArray *schedules = migratedTaskAndSchedules[kJSONSchedulesKey];
        NSMutableArray *migratedSchedules = [NSMutableArray new];
        NSDate *launchDate = [NSDate date];
        
        for (NSDictionary *schedule in schedules) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", kMigrationTaskIdKey, schedule[kJSONScheduleTaskIDKey]];
            NSArray *matchedSchedule = [schedulesToMigrate filteredArrayUsingPredicate:predicate];
            
            if (matchedSchedule.count > 0) {
                NSDictionary *taskInfo = [matchedSchedule firstObject];
                
                NSMutableDictionary *updatedSchedule = [schedule mutableCopy];
                
                NSDate *offsetDate = [launchDate dateByAddingDays:[taskInfo[kMigrationOffsetByDaysKey] integerValue]];
                
                NSCalendarUnit units = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitWeekday;
                
                NSDateComponents *componentForGracePeriodStartOn = [[NSCalendar currentCalendar] components:units
                                                                                                   fromDate:offsetDate];
                
                NSString *dayOfMonth = [NSString stringWithFormat:@"%ld", (long)componentForGracePeriodStartOn.day];
                NSString *dayOfWeek = nil;
                
                if ([taskInfo[kMigrationRecurringKindKey] integerValue] == APHMigrationRecurringKindWeekly) {
                    dayOfWeek = [NSString stringWithFormat:@"%ld", (long)componentForGracePeriodStartOn.weekday];
                    dayOfMonth = @"*";
                } else {
                    dayOfWeek = @"*";
                }
                
                NSString *months = nil;
                
                switch ([taskInfo[kMigrationRecurringKindKey] integerValue]) {
                    case APHMigrationRecurringKindMonthly:
                    months = @"1/1";
                    break;
                    case APHMigrationRecurringKindQuarterly:
                    months = @"1/3";
                    break;
                    default:
                    months = @"*";
                    break;
                }
                
                updatedSchedule[kJSONScheduleStringKey] = [NSString stringWithFormat:@"0 5 %@ %@ %@", dayOfMonth, months, dayOfWeek];
                
                [migratedSchedules addObject:updatedSchedule];
            } else {
                [migratedSchedules addObject:schedule];
            }
        }
        
        migratedTaskAndSchedules[kJSONSchedulesKey] = migratedSchedules;
    }
    
    return migratedTaskAndSchedules;
}

- (NSDictionary *) tasksAndSchedulesWillBeLoaded
{
    NSError *jsonError = nil;
    NSString *resource = [[NSBundle mainBundle] pathForResource:@"APHTasksAndSchedules" ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:resource];
    NSDictionary *tasksAndScheduledFromJSON = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];
    
    NSDictionary *migratedSchedules = [self migrateTasksAndSchedules:tasksAndScheduledFromJSON];
    
    return migratedSchedules;
}

- (void)performMigrationAfterDataSubstrateFrom:(NSInteger) __unused previousVersion currentVersion:(NSInteger) __unused currentVersion
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSError *migrationError = nil;
    
    if (self.doesPersisteStoreExist == NO)
    {
        APCLogEvent(@"This application is being launched for the first time. We know this because there is no persistent store.");
    }
    else if ( [defaults objectForKey:@"previousVersion"] == nil)
    {
        APCLogEvent(@"The entire data model version %d", kTheEntireDataModelOfTheApp);
        
        // Add the newly added surveys
        [self addNewSurveys];
        
        NSError *jsonError = nil;
        NSString *resource = [[NSBundle mainBundle] pathForResource:@"APHTasksAndSchedules" ofType:@"json"];
        NSData *jsonData = [NSData dataWithContentsOfFile:resource];
        NSDictionary *tasksAndScheduledFromJSON = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];
        
        NSDictionary *migratedSchedules = [self migrateTasksAndSchedules:tasksAndScheduledFromJSON];
        
        [APCSchedule updateSchedulesFromJSON:migratedSchedules[kJSONSchedulesKey]
                                   inContext:self.dataSubstrate.persistentContext];
    }
    else if ([[defaults objectForKey:@"previousVersion"] isEqual: @3])
    {
        APCLogEvent(@"The entire data model version %d", kTheEntireDataModelOfTheApp);
        if (![self performMigrationFromThreeToFourWithError:&migrationError])
        {
            APCLogEvent(@"Migration from version %@ to %@ has failed.", [defaults objectForKey:@"previousVersion"], @(kTheEntireDataModelOfTheApp));
        }
    }
    
    
    [defaults setObject:majorVersion forKey:@"shortVersionString"];
    [defaults setObject:minorVersion forKey:@"version"];
    
    if (!migrationError)
    {
        [defaults setObject:@(currentVersion) forKey:@"previousVersion"];
    }
    
}

- (void)addNewSurveys
{
    NSDictionary * staticScheduleAndTask = @{ @"tasks":
                                                  @[
                                                      @{
                                                          @"taskTitle" : @"Sleep Survey",
                                                          @"taskID": kSleepSurveyIdentifier,
                                                          @"taskFileName" : @"DiabetesSleepSurvey",
                                                          @"taskClassName" : @"APCGenericSurveyTaskViewController",
                                                          @"taskCompletionTimeString" : @"25 Questions"
                                                        },
                                                      @{
                                                          @"taskTitle" : @"Quality of Life Survery",
                                                          @"taskID": kQualityOfLifeSurveyIdentifier,
                                                          @"taskFileName" : @"DiabetesQoLSurvey",
                                                          @"taskClassName" : @"APCGenericSurveyTaskViewController",
                                                          @"taskCompletionTimeString" : @"15 Questions"
                                                        }
                                                    ],
                                              
                                              @"schedules":
                                                  @[
                                                      
                                                      @{
                                                          @"scheduleType": @"recurring",
                                                          @"scheduleString": @"0 5 30 * *",
                                                          @"taskID": kSleepSurveyIdentifier
                                                      },
                                                      @{
                                                          @"scheduleType": @"recurring",
                                                          @"scheduleString": @"0 5 30 * *",
                                                          @"taskID": kQualityOfLifeSurveyIdentifier
                                                      }
                                                    ]
                                              };
    
    // Update schedules based on launch date
    NSDictionary *updatedSchedulesAndTask = [self migrateTasksAndSchedules:staticScheduleAndTask];
    
    [APCTask updateTasksFromJSON:updatedSchedulesAndTask[@"tasks"]
                       inContext:self.dataSubstrate.persistentContext];
    
    [APCSchedule createSchedulesFromJSON:updatedSchedulesAndTask[@"schedules"]
                               inContext:self.dataSubstrate.persistentContext];
    
    APCScheduler *scheduler = [[APCScheduler alloc] initWithDataSubstrate:self.dataSubstrate];
    [scheduler updateScheduledTasksIfNotUpdating:YES];
}

- (NSDictionary *)configureTasksForActivities
{
    // Tasks to only show in the Keep Going section.
    // This needs to be re-factored in order to be more flexible.
    return @{
             kActivitiesSectionKeepGoing: @[
                     @"APHSevenDayAllocation-00000000-1111-1111-1111-F810BE28D995",
                     @"APHLogGlucose-42449E07-7124-40EF-AC93-CA5BBF95FC15"
                    ],
             kActivitiesRequiresMotionSensor: @[@"APHSevenDayAllocation-00000000-1111-1111-1111-F810BE28D995"]
            };
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [super applicationDidBecomeActive:application];
    
    [self startActivityTrackerTask];
}

- (void)afterOnBoardProcessIsFinished
{
    [self startActivityTrackerTask];
}

- (void)startActivityTrackerTask
{
    BOOL isUserSignedIn = self.dataSubstrate.currentUser.signedIn;
    
    
    if (isUserSignedIn && [APCDeviceHardware isiPhone5SOrNewer]) {
        NSDate *fitnessStartDate = [self checkSevenDayFitnessStartDate];
        if (fitnessStartDate) {
            self.sevenDayFitnessAllocationData = [[APCFitnessAllocation alloc] initWithAllocationStartDate:fitnessStartDate];
            
            [self.sevenDayFitnessAllocationData startDataCollection];
        }
    }
}

- (NSDate *)checkSevenDayFitnessStartDate
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSDate *fitnessStartDate = [defaults objectForKey:kSevenDayFitnessStartDateKey];
    
    if (!fitnessStartDate) {
        fitnessStartDate = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                                    minute:0
                                                                    second:0
                                                                    ofDate:[NSDate date]
                                                                   options:0];
        
        [defaults setObject:fitnessStartDate forKey:kSevenDayFitnessStartDateKey];
        [defaults synchronize];

    }
    
    return fitnessStartDate;
}

- (NSInteger)fitnessDaysShowing:(APHFitnessDaysShows)showKind
{
    NSInteger numberOfDays = 7;
    
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
    
    NSDateComponents *numberOfDaysFromStartDate = [[NSCalendar currentCalendar] components:NSCalendarUnitDay
                                                                                  fromDate:startDate
                                                                                    toDate:today
                                                                                   options:NSCalendarWrapComponents];
    
    NSInteger lapsedDays = numberOfDaysFromStartDate.day;
    
    if (showKind == APHFitnessDaysShowsRemaining) {
        // Compute the remaing days
        if (lapsedDays < 7) {
            numberOfDays = 7 - lapsedDays;
        }
    } else {
        // Compute days lapsed
        if (lapsedDays < 7) {
            numberOfDays = (lapsedDays == 0) ? 1 : lapsedDays;
        }
    }
    
    return numberOfDays;
}

/*********************************************************************************/
#pragma mark - Datasubstrate Delegate Methods
/*********************************************************************************/
- (void) setUpCollectors
{
    if (self.dataSubstrate.currentUser.consented)
    {
        if (!self.passiveDataCollector)
        {
            self.passiveDataCollector = [[APCPassiveDataCollector alloc] init];
        }
        
        [self configureObserverQueries];
        [self configureMotionActivityObserver];
    }
}

- (NSDate *)proxyConsentDate
{
    NSDate *consentDate = [[NSDate date] startOfDay];
    NSFileManager*  fileManager = [NSFileManager defaultManager];
    NSString*       filePath    = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"db.sqlite"];
    
    if ([fileManager fileExistsAtPath:filePath])
    {
        NSError*        error       = nil;
        NSDictionary*   attributes  = [fileManager attributesOfItemAtPath:filePath error:&error];
        
        if (!attributes)
        {
            if (error)
            {
                APCLogError2(error);
            }
        }
        else
        {
            consentDate = [attributes fileCreationDate];
        }
    }
    
    return consentDate;
}

- (void)configureMotionActivityObserver
{
    NSString*(^CoreMotionDataSerializer)(id) = ^NSString *(id dataSample)
    {
        CMMotionActivity* motionActivitySample  = (CMMotionActivity*)dataSample;
        NSString* motionActivity                = [CMMotionActivity activityTypeName:motionActivitySample];
        NSNumber* motionConfidence              = @(motionActivitySample.confidence);
        NSString* stringToWrite                 = [NSString stringWithFormat:@"%@,%@,%@\n",
                                                   motionActivitySample.startDate.toStringInISO8601Format,
                                                   motionActivity,
                                                   motionConfidence];
        
        return stringToWrite;
    };
    
    NSDate* (^LaunchDate)() = ^
    {
        APCUser*    user        = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.currentUser;
        NSDate*     consentDate = nil;
        
        if (user.consentSignatureDate)
        {
            consentDate = user.consentSignatureDate;
        }
        else
        {
            consentDate = [self proxyConsentDate];
        }
        
        return consentDate;
    };
    
    APCCoreMotionBackgroundDataCollector *motionCollector = [[APCCoreMotionBackgroundDataCollector alloc] initWithIdentifier:@"motionActivityCollector"
                                                                                                              dateAnchorName:@"APCCoreMotionCollectorAnchorName"
                                                                                                            launchDateAnchor:LaunchDate];
    
    NSArray*            motionColumnNames   = @[@"startTime",@"activityType",@"confidence"];
    APCPassiveDataSink* receiver            = [[APCPassiveDataSink alloc] initWithIdentifier:@"motionActivityCollector"
                                                                                 columnNames:motionColumnNames
                                                                          operationQueueName:@"APCCoreMotion Activity Collector"
                                                                               dataProcessor:CoreMotionDataSerializer
                                                                           fileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication];
    
    [motionCollector setReceiver:receiver];
    [motionCollector setDelegate:receiver];
    [motionCollector start];
    [self.passiveDataCollector addDataSink:motionCollector];
}


- (void)configureObserverQueries
{
    NSDate* (^LaunchDate)() = ^
    {
        APCUser*    user        = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.currentUser;
        NSDate*     consentDate = nil;
        
        if (user.consentSignatureDate)
        {
            consentDate = user.consentSignatureDate;
        }
        else
        {
            consentDate = [self proxyConsentDate];
        }
        
        return consentDate;
    };

NSString*(^QuantityDataSerializer)(id, HKUnit*) = ^NSString*(id dataSample, HKUnit* unit)
    {
        HKQuantitySample*   qtySample           = (HKQuantitySample *)dataSample;
        NSString*           startDateTimeStamp  = [qtySample.startDate toStringInISO8601Format];
        NSString*           endDateTimeStamp    = [qtySample.endDate toStringInISO8601Format];
        NSString*           healthKitType       = qtySample.quantityType.identifier;
        NSNumber*           quantityValue       = @([qtySample.quantity doubleValueForUnit:unit]);
        NSString*           quantityUnit        = unit.unitString;
        
        NSString*           correlation         = @"No Data";
        NSDictionary*       metaData            = qtySample.metadata;
        
        if (metaData)
        {
            NSString*           meal                = [metaData objectForKey:@"HKFoodMeal"];
            NSString*           foodItem            = [metaData objectForKey:@"HKFoodType"];
            
            if (meal && foodItem)
            {
                correlation = [NSString stringWithFormat:@"\"%@ - %@\"", meal, foodItem];
            }
        }
        
        NSString*           sourceIdentifier    = qtySample.source.bundleIdentifier;
        NSString*           quantitySource      = qtySample.source.name;
        
        if (quantitySource == nil)
        {
            quantitySource = @"not available";
        }
        else if ([[[UIDevice currentDevice] name] isEqualToString:quantitySource])
        {
            if ([APCDeviceHardware platformString])
            {
                quantitySource = [APCDeviceHardware platformString];
            }
            else
            {
                //  This shouldn't get called.
                quantitySource = @"iPhone";
            }
            
        }
        
        NSString *stringToWrite = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@\n",
                                   startDateTimeStamp,
                                   endDateTimeStamp,
                                   healthKitType,
                                   quantityValue,
                                   quantityUnit,
                                   correlation,
                                   sourceIdentifier,
                                   quantitySource];
        
        return stringToWrite;
    };
    
    NSString*(^WorkoutDataSerializer)(id) = ^(id dataSample)
    {
        HKWorkout*  sample                      = (HKWorkout*)dataSample;
        NSString*   startDateTimeStamp          = [sample.startDate toStringInISO8601Format];
        NSString*   endDateTimeStamp            = [sample.endDate toStringInISO8601Format];
        NSString*   healthKitType               = sample.sampleType.identifier;
        NSString*   activityType                = [HKWorkout apc_workoutActivityTypeStringRepresentation:(int)sample.workoutActivityType];
        double      energyConsumedValue         = [sample.totalEnergyBurned doubleValueForUnit:[HKUnit kilocalorieUnit]];
        NSString*   energyConsumed              = [NSString stringWithFormat:@"%f", energyConsumedValue];
        NSString*   energyUnit                  = [HKUnit kilocalorieUnit].description;
        double      totalDistanceConsumedValue  = [sample.totalDistance doubleValueForUnit:[HKUnit meterUnit]];
        NSString*   totalDistance               = [NSString stringWithFormat:@"%f", totalDistanceConsumedValue];
        NSString*   distanceUnit                = [HKUnit meterUnit].description;
        NSString*   sourceIdentifier            = sample.source.bundleIdentifier;
        NSString*   quantitySource              = sample.source.name;
        
        if (quantitySource == nil)
        {
            quantitySource = @"not available";
        }
        else if ([[[UIDevice currentDevice] name] isEqualToString:quantitySource])
        {
            if ([APCDeviceHardware platformString])
            {
                quantitySource = [APCDeviceHardware platformString];
            }
            else
            {
                //  This shouldn't get called.
                quantitySource = @"iPhone";
            }
        }
        
        NSError*    error                       = nil;
        NSString*   metaData                    = [NSDictionary apc_stringFromDictionary:sample.metadata error:&error];
        
        if (!metaData)
        {
            if (error)
            {
                APCLogError2(error);
            }
            
            metaData = @"";
        }
        
        NSString*   metaDataStringified         = [NSString stringWithFormat:@"\"%@\"", metaData];
        NSString*   stringToWrite               = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
                                                   startDateTimeStamp,
                                                   endDateTimeStamp,
                                                   healthKitType,
                                                   activityType,
                                                   totalDistance,
                                                   distanceUnit,
                                                   energyConsumed,
                                                   energyUnit,
                                                   quantitySource,
                                                   sourceIdentifier,
                                                   metaDataStringified];
        
        return stringToWrite;
    };
    
    NSString*(^CategoryDataSerializer)(id) = ^NSString*(id dataSample)
    {
        HKCategorySample*   catSample       = (HKCategorySample *)dataSample;
        NSString*           stringToWrite   = nil;
        
        if ([catSample.categoryType.identifier isEqualToString:@"HKCategoryTypeIdentifierSleepAnalysis"])
        {
            NSString*           startDateTime   = [catSample.startDate toStringInISO8601Format];
            NSString*           healthKitType   = catSample.sampleType.identifier;
            NSString*           categoryValue   = nil;
            
            if (catSample.value == HKCategoryValueSleepAnalysisAsleep)
            {
                categoryValue = @"HKCategoryValueSleepAnalysisAsleep";
            }
            else
            {
                categoryValue = @"HKCategoryValueSleepAnalysisInBed";
            }
            
            NSString*           quantityUnit        = [[HKUnit secondUnit] unitString];
            NSString*           sourceIdentifier    = catSample.source.bundleIdentifier;
            NSString*           quantitySource      = catSample.source.name;
            
            if (quantitySource == nil)
            {
                quantitySource = @"not available";
            }
            else if ([[[UIDevice currentDevice] name] isEqualToString:quantitySource])
            {
                if ([APCDeviceHardware platformString])
                {
                    quantitySource = [APCDeviceHardware platformString];
                }
                else
                {
                    //  This shouldn't get called.
                    quantitySource = @"iPhone";
                }
                
            }

            // Get the difference in seconds between the start and end date for the sample
            NSTimeInterval secondsSpentInBedOrAsleep = [catSample.endDate timeIntervalSinceDate:catSample.startDate];
            NSString*                quantityValue   = [NSString stringWithFormat:@"%f", secondsSpentInBedOrAsleep];
            
            stringToWrite   = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@\n",
                                                           startDateTime,
                                                           healthKitType,
                                                           categoryValue,
                                                           quantityValue,
                                                           quantityUnit,
                                                           quantitySource,
                                                           sourceIdentifier];
        }
        
        return stringToWrite;
    };

    NSArray* dataTypesWithReadPermission = self.initializationOptions[kHKReadPermissionsKey];
    
    if (!self.passiveDataCollector)
    {
        self.passiveDataCollector = [[APCPassiveDataCollector alloc] init];
    }
    
    // Just a note here that we are using n collectors to 1 data sink for quantity sample type data.
    NSArray*                    quantityColumnNames = @[@"startTime,endTime,type,value,unit,source,sourceIdentifier"];
    APCPassiveDataSink*         quantityreceiver    =[[APCPassiveDataSink alloc] initWithQuantityIdentifier:@"HealthKitDataCollector"
                                                                                                columnNames:quantityColumnNames
                                                                                         operationQueueName:@"APCHealthKitQuantity Activity Collector"
                                                                                              dataProcessor:QuantityDataSerializer
                                                                                          fileProtectionKey:NSFileProtectionCompleteUnlessOpen];
    NSArray*                    workoutColumnNames  = @[@"startTime,endTime,type,workoutType,total distance,unit,energy consumed,unit,source,sourceIdentifier,metadata"];
    APCPassiveDataSink*         workoutReceiver     = [[APCPassiveDataSink alloc] initWithIdentifier:@"HealthKitWorkoutCollector"
                                                                                         columnNames:workoutColumnNames
                                                                                  operationQueueName:@"APCHealthKitWorkout Activity Collector"
                                                                                       dataProcessor:WorkoutDataSerializer
                                                                                   fileProtectionKey:NSFileProtectionCompleteUnlessOpen];
    NSArray*                    categoryColumnNames = @[@"startTime,type,category value,value,unit,source,sourceIdentifier"];
    APCPassiveDataSink*         sleepReceiver       = [[APCPassiveDataSink alloc] initWithIdentifier:@"HealthKitSleepCollector"
                                                                                         columnNames:categoryColumnNames
                                                                                  operationQueueName:@"APCHealthKitSleep Activity Collector"
                                                                                       dataProcessor:CategoryDataSerializer
                                                                                   fileProtectionKey:NSFileProtectionCompleteUnlessOpen];
    
    if (dataTypesWithReadPermission)
    {
        for (id dataType in dataTypesWithReadPermission)
        {
            HKSampleType* sampleType = nil;
            
            if ([dataType isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* categoryType = (NSDictionary *) dataType;
                
                //Distinguish
                if (categoryType[kHKWorkoutTypeKey])
                {
                    sampleType = [HKObjectType workoutType];
                }
                else if (categoryType[kHKCategoryTypeKey])
                {
                    sampleType = [HKObjectType categoryTypeForIdentifier:categoryType[kHKCategoryTypeKey]];
                }
            }
            else
            {
                sampleType = [HKObjectType quantityTypeForIdentifier:dataType];
            }
            
            if (sampleType)
            {
                // This is really important to remember that we are creating as many user defaults as there are healthkit permissions here.
                NSString*                               uniqueAnchorDateName    = [NSString stringWithFormat:@"APCHealthKit%@AnchorDate", dataType];
                APCHealthKitBackgroundDataCollector*    collector               = nil;
                
                //If the HKObjectType is a HKWorkoutType then set a different receiver/data sink.
                if ([sampleType isKindOfClass:[HKWorkoutType class]])
                {
                    collector = [[APCHealthKitBackgroundDataCollector alloc] initWithIdentifier:sampleType.identifier
                                                                                     sampleType:sampleType anchorName:uniqueAnchorDateName
                                                                               launchDateAnchor:LaunchDate
                                                                                    healthStore:self.dataSubstrate.healthStore];
                    [collector setReceiver:workoutReceiver];
                    [collector setDelegate:workoutReceiver];
                }
                else if ([sampleType isKindOfClass:[HKCategoryType class]])
                {
                    collector = [[APCHealthKitBackgroundDataCollector alloc] initWithIdentifier:sampleType.identifier
                                                                                     sampleType:sampleType anchorName:uniqueAnchorDateName
                                                                               launchDateAnchor:LaunchDate
                                                                                    healthStore:self.dataSubstrate.healthStore];
                    [collector setReceiver:sleepReceiver];
                    [collector setDelegate:sleepReceiver];
                }
                else
                {
                    NSDictionary* hkUnitKeysAndValues = [self researcherSpecifiedUnits];
                    
                    collector = [[APCHealthKitBackgroundDataCollector alloc] initWithQuantityTypeIdentifier:sampleType.identifier
                                                                                                 sampleType:sampleType anchorName:uniqueAnchorDateName
                                                                                           launchDateAnchor:LaunchDate
                                                                                                healthStore:self.dataSubstrate.healthStore
                                                                                                       unit:[hkUnitKeysAndValues objectForKey:sampleType.identifier]];
                    [collector setReceiver:quantityreceiver];
                    [collector setDelegate:quantityreceiver];
                }
                
                [collector start];
                [self.passiveDataCollector addDataSink:collector];
            }
        }
    }
}

/*********************************************************************************/
#pragma mark - APCOnboardingDelegate Methods
/*********************************************************************************/

- (APCScene *)inclusionCriteriaSceneForOnboarding:(APCOnboarding *) __unused onboarding
{
    APCScene *scene = [APCScene new];
    scene.name = @"APHInclusionCriteriaViewController";
    scene.storyboardName = @"APHOnboarding";
    scene.bundle = [NSBundle mainBundle];
    
    return scene;
}

- (APCScene *)customInfoSceneForOnboarding:(APCOnboarding *) __unused onboarding
{
    APCScene *scene = [APCScene new];
    scene.name = @"APHGlucoseLevels";
    scene.storyboardName = @"APHOnboarding";
    scene.bundle = [NSBundle mainBundle];
    
    return scene;
}

/*********************************************************************************/
#pragma mark - Consent
/*********************************************************************************/

- (ORKTaskViewController *)consentViewController
{
    APCConsentTask*         task = [[APCConsentTask alloc] initWithIdentifier:@"Consent"
                                                           propertiesFileName:kConsentPropertiesFileName];
    ORKTaskViewController*  consentVC = [[ORKTaskViewController alloc] initWithTask:task
                                                                        taskRunUUID:[NSUUID UUID]];
    
    return consentVC;
}

@end
