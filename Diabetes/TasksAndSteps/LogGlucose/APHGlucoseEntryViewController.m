// 
//  APHGlucoseEntryViewController.m 
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
 
#import "APHGlucoseEntryViewController.h"
#import "APHGlucoseLevelTaskViewController.h"
#import "APHGlucoseLevelsMealTimesViewController.h"
#import "APHGlucoseEntryTableViewCell.h"

static NSDateFormatter *dateFormatter = nil;

static NSString *kGlucoseLogEntryCell  = @"GlucoseLogEntryCell";
static NSString *kGlucloseLogEntryKey  = @"glucoseLogEntryKey";

static CGFloat kSectionHeaderHeight = 44.0;
static CGFloat kCellHeight = 65.0;
static CGFloat kHeaderFontSize = 16.0;

@interface APHGlucoseEntryViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, APHGlucoseEntryTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *btnSubmit;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tvBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomContraint;

@property (nonatomic, strong) ORKStepResult *cachedResult;
@property (nonatomic, strong) ORKStepResult *stepResult;

@property (nonatomic, strong) NSMutableArray *mealTimes;
@property (nonatomic, strong) NSArray *glucoseRange;
@property (nonatomic, strong) NSArray *timesForCheckingLevels;

@property (nonatomic) NSUInteger selectedIndex;


@end

@implementation APHGlucoseEntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mealTimes = [NSMutableArray array];
    
    self.btnSubmit.backgroundColor = [UIColor appPrimaryColor];
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    
    self.mealTimes = [self retireveGlucoseLevels];
    
    NSSortDescriptor *sortByScheduledHour = [NSSortDescriptor sortDescriptorWithKey:@"startOn" ascending:YES];
    [self.tasks.scheduledTasks sortUsingDescriptors:@[sortByScheduledHour]];
    
    [self setEditing:!self.tasks.complete animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.topItem.title = self.tasks.taskTitle;
    
    // Observe keyboard hide and show notifications to resize the table view appropriately.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.tableView.editing = editing;
}

#pragma mark - Actions

- (IBAction)handleSubmitButton:(UIButton *) __unused sender
{
    id <ORKStepViewControllerDelegate> mainDelegate = self.delegate;
    
    NSOperationQueue *glucoseLogQueue = [NSOperationQueue sequentialOperationQueueWithName:@"Glucose Log queue..."];
    
    [glucoseLogQueue addOperationWithBlock:^{
    
        APCAppDelegate * appDelegate = (APCAppDelegate*)[UIApplication sharedApplication].delegate;
        NSManagedObjectContext *localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        localContext.parentContext = appDelegate.dataSubstrate.persistentContext;
    
        [self.mealTimes enumerateObjectsUsingBlock:^(NSDictionary *mealTime, NSUInteger idx, BOOL * __unused stop) {
            NSNumber *mealTimeValue = mealTime[kGlucoseLevelValueKey];
            APCScheduledTask *mainContextScheduledTask = [self.tasks.scheduledTasks objectAtIndex:idx];
            
            
            
            APCScheduledTask *scheduledTask = (APCScheduledTask *)[localContext objectWithID:mainContextScheduledTask.objectID];
            
            if (mealTimeValue) {
                APHGlucoseLevelTaskViewController *taskVC = [APHGlucoseLevelTaskViewController customTaskViewController:scheduledTask];
                taskVC.glucoseLevel = mealTime;
                taskVC.localContext = localContext;
                
                self.delegate = taskVC;
                
                NSError *contentError = nil;
                APCDataResult *contentModel = [[APCDataResult alloc] initWithIdentifier:@"content"];
                
                contentModel.data = [NSJSONSerialization dataWithJSONObject:mealTime options:0 error:&contentError];
                
                self.cachedResult = [[ORKStepResult alloc] initWithStepIdentifier:self.step.identifier results:@[contentModel]];
                
                // At this point we are done collecting data for glucose.
                // All we now need is to be able to add collected data to local datastore, written
                // to the file system, encrypted, and uploaded to the server.
                
                if ([self.delegate respondsToSelector:@selector(stepViewController:didFinishWithNavigationDirection:)] == YES) {
                    [self.delegate stepViewController:self didFinishWithNavigationDirection:ORKStepViewControllerNavigationDirectionForward];
                }
                
                NSError *taskError = nil;
                [taskVC taskViewController:taskVC
                       didFinishWithReason:ORKTaskViewControllerFinishReasonCompleted
                                     error:taskError];
                
            }
        }];
    }];

    self.delegate = mainDelegate;
    
    if ([self.delegate respondsToSelector:@selector(stepViewController:didFinishWithNavigationDirection:)] == YES) {
        [self.delegate stepViewController:self didFinishWithNavigationDirection:ORKStepViewControllerNavigationDirectionForward];
    }
}

- (ORKStepResult *)result
{
    if (!self.stepResult) {
        self.stepResult = [[ORKStepResult alloc] initWithIdentifier:self.step.identifier];
    }
    
    return self.stepResult;
}

#pragma mark - TableView
#pragma mark Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *) __unused tableView numberOfRowsInSection:(NSInteger) __unused section
{
    return [self.mealTimes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    APHGlucoseEntryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kGlucoseLogEntryCell
                                                                         forIndexPath:indexPath];
    
    NSDictionary *glucoseCheckTime = [self.mealTimes objectAtIndex:indexPath.row];
    NSString *rowCaption = nil;
    
    if ([glucoseCheckTime[kGlucoseLevelTimeOfDayKey] isEqualToString:kTimeOfDayBreakfast] &&
        [glucoseCheckTime[kGlucoseLevelPeriodKey] isEqualToString:kGlucoseLevelBeforeKey]) {
        rowCaption = NSLocalizedString(@"Morning Fasting", @"Morning Fasting");
    } else if ([glucoseCheckTime[kGlucoseLevelPeriodKey] isEqualToString:kGlucoseLevelBeforeKey]) {
        rowCaption = [NSString stringWithFormat:@"Before %@", glucoseCheckTime[kGlucoseLevelTimeOfDayKey]];
    } else if (([glucoseCheckTime[kGlucoseLevelPeriodKey] isEqualToString:kGlucoseLevelAfterKey]) &&
               (![glucoseCheckTime[kGlucoseLevelTimeOfDayKey] isEqualToString:kTimeOfDayOther])) {
        rowCaption = [NSString stringWithFormat:@"After %@", glucoseCheckTime[kGlucoseLevelTimeOfDayKey]];
    } else {
        rowCaption = [NSString stringWithFormat:@"%@", glucoseCheckTime[kGlucoseLevelTimeOfDayKey]];
    }
    
    cell.captionMealTime = rowCaption;
    
    NSNumber *mealTimeValue = [self retieveLevelValueForMealTime:[glucoseCheckTime[@"indexPath"] integerValue]
                                                     atIndexPath:indexPath.row];
    
    if (!mealTimeValue) {
        cell.glucoseReading = nil;
    } else {
        if ([mealTimeValue isKindOfClass:[NSNull class]]) {
            cell.glucoseReading = @(NSNotFound);
        } else {
            cell.glucoseReading = mealTimeValue;
        }
    }
    
    cell.delegate = self;
    cell.textFieldTag = indexPath.row;
    
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger) __unused section
{
    UITableViewHeaderFooterView *headerView = nil;
    
    if (self.editing) {
        headerView = [[UITableViewHeaderFooterView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), kSectionHeaderHeight)];
        headerView.contentView.backgroundColor = [UIColor appSecondaryColor4];
        
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.bounds];
        
        CGFloat inset = 15.0;
        UIEdgeInsets  insets = UIEdgeInsetsMake(0, inset, 0, inset);
        CGRect bounds = UIEdgeInsetsInsetRect(headerView.bounds, insets);
        headerLabel.bounds = bounds;
        headerLabel.font = [UIFont appLightFontWithSize:kHeaderFontSize];
        headerLabel.textColor = [UIColor appSecondaryColor3];
        headerLabel.textAlignment = NSTextAlignmentLeft;
        headerLabel.text = NSLocalizedString(@"Tap a mealtime to log a new entry.", @"Tap a mealtime to log a new entry.");
        
        [headerView addSubview:headerLabel];
    }
    
    return headerView;
}

#pragma mark - Delegates

- (UITableViewCellEditingStyle)tableView:(UITableView *) __unused tableView editingStyleForRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *) __unused tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    return NO;
}

- (void)tableView:(UITableView *) __unused tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndex = indexPath.row;
}

#pragma mark - Custom Cell Delegate

- (void)didSubmitReading
{
    [self handleSubmitButton:nil];
}

- (void)didSelectNotMeasured
{
    [self updateValueForLevel:nil atRow:self.selectedIndex];
}

#pragma mark - TextField Delegates
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.selectedIndex = textField.tag;
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]
                                animated:YES
                          scrollPosition:UITableViewScrollPositionNone];
}

- (void)textFieldDidEndEditing:(UITextField *) textField
{
    NSNumber *reading = nil;
    NSString *inputValue = textField.text;
    
    if ((inputValue.length > 0) && ([inputValue isEqualToString:kGlucoseNotMeasured] == NO)) {
        reading = @([textField.text integerValue]);
        [self updateValueForLevel:reading atRow:self.selectedIndex];
    } else if ([inputValue isEqualToString:kGlucoseNotMeasured] == YES) {
        [self updateValueForLevel:reading atRow:self.selectedIndex];
    }
}

#pragma mark - Helpers

- (void)updateValueForLevel:(NSNumber *)value atRow:(NSInteger)row
{
    NSMutableDictionary *mealTimeEntry = [[self.mealTimes objectAtIndex:row] mutableCopy];
    
    if (!value) {
        mealTimeEntry[kGlucoseLevelValueKey] = [NSNull null];
    } else {
        mealTimeEntry[kGlucoseLevelValueKey] = value;
    }
    
    [self.mealTimes replaceObjectAtIndex:row withObject:mealTimeEntry];
}

- (void)removeValueForLevel:(NSInteger)row
{
    NSMutableDictionary *mealTimeEntry = [[self.mealTimes objectAtIndex:row] mutableCopy];
    
    [mealTimeEntry removeObjectForKey:kGlucoseLevelValueKey];
    
    [self.mealTimes replaceObjectAtIndex:row withObject:mealTimeEntry];
}

- (NSMutableArray *)retireveGlucoseLevels
{
    APCAppDelegate *apcDelegate = (APCAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // retrieve glucose levels from the datastore
    NSString *levels = [apcDelegate.dataSubstrate.currentUser glucoseLevels];
    
    NSData *levelsData = [levels dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    
    NSArray *normalizedLevels = [NSJSONSerialization JSONObjectWithData:levelsData options:NSJSONReadingAllowFragments error:&error];
    
    return [normalizedLevels mutableCopy];
}

- (NSString *)encodeForDataStore:(NSArray *)entryData
{
    NSError *error = nil;
    
    NSData *glucoseEntry = [NSJSONSerialization dataWithJSONObject:entryData options:0 error:&error];
    NSString *contentString = [[NSString alloc] initWithData:glucoseEntry encoding:NSUTF8StringEncoding];
    
    return contentString;
}

- (NSNumber *)retieveLevelValueForMealTime:(NSUInteger)mealIndexPath atIndexPath:(NSUInteger)mealTimeIndex
{
    id chosenValue = [[self.mealTimes objectAtIndex:mealTimeIndex] valueForKey:kGlucoseLevelValueKey];
    
    for (APCScheduledTask *scheduledTask in self.tasks.scheduledTasks) {
        NSArray *scheduledTaskResults = [scheduledTask.results allObjects];
        
        // sort the results in a decsending order,
        // in case there are more than one result for a meal time.
        NSSortDescriptor *sortByCreateAtDescending = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                                                 ascending:NO];
        NSArray *sortedScheduleTaskresults = [scheduledTaskResults sortedArrayUsingDescriptors:@[sortByCreateAtDescending]];
        
        // We are iterating throught the results because:
        // a.) There could be more than one result
        // b.) In case the last result is nil, we will pick the next result that has a value.
        NSString *mealTimeResult = nil;
        
        for (APCResult *result in sortedScheduleTaskresults) {
            mealTimeResult = [result resultSummary];
            if (mealTimeResult) {
                break;
            }
        }
        
        if (mealTimeResult) {
            NSData *mealTimeData = [mealTimeResult dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error = nil;
            NSDictionary *mealTime = [NSJSONSerialization JSONObjectWithData:mealTimeData
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:&error];
            
            NSUInteger resultIndexPath = [mealTime[@"indexPath"] integerValue];
            
            if (resultIndexPath == mealIndexPath) {
                id existingValue = [mealTime valueForKey:kGlucoseLevelValueKey];
                
                // Chosen and Existing values can be:
                //   - NSNumber
                //   - nil
                //   - NSNull
                //
                // We will take the Chosen value, since that is the most
                // up-to-date value. The only time the Existing value will be taken,
                // is when the chosen value is nil.
                
                if (!chosenValue) {
                    chosenValue = existingValue;
                }
                
                [self updateValueForLevel:chosenValue atRow:mealTimeIndex];
            }
        }
    }
    
    return chosenValue;
}

#pragma mark - Notifications
#pragma mark Responding to keyboard events

-(void)keyboardWillShow:(NSNotification *)notification
{
    /*
     Reduce the size of the table view so that it's not obscured by the keyboard.
     Animate the resize so that it's in sync with the appearance of the keyboard.
     */
    
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system.
    // The bottom of the table view's frame should align with the top of the keyboard's final position.
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    //CGFloat keyboardTop = keyboardRect.origin.y;
    CGFloat keyboardHeight = keyboardRect.size.height;
    CGRect newTableViewFrame = self.tableView.frame;
    newTableViewFrame.size.height = self.tableView.frame.size.height - keyboardHeight;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView animateWithDuration:animationDuration
                     animations:^{
                         [self.tableViewBottomContraint setConstant:keyboardHeight];
                     }];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    /*
     Restore the size of the table view (fill self's view).
     Animate the resize so that it's in sync with the disappearance of the keyboard.
     */
    
    NSDictionary* userInfo = [notification userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGFloat keyboardHeight = keyboardRect.size.height;
    CGRect newTableViewFrame = self.tableView.frame;
    newTableViewFrame.size.height = self.tableView.frame.size.height + keyboardHeight;
    
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView animateWithDuration:animationDuration
                     animations:^{
                         [self.tableViewBottomContraint setConstant:0.0];
                     }];
}

@end
