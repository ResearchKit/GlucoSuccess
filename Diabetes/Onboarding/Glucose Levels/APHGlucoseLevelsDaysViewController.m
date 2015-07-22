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
 
#import "APHGlucoseLevelsDaysViewController.h"
#import "APHGlucoseLevelsMealTimesViewController.h"
#import "APHGlucoseLevelsViewController.h"

static NSString *kGlucoseLevelCellIdentifier = @"GlucoseLevelDayCell";
NSString * const kGlucoseMealTimePickedDays  = @"glucoseMealTimePickedDays";

static NSDateFormatter *dateFormatter = nil;

@interface APHGlucoseLevelsDaysViewController ()

@property (strong, nonatomic) NSString *sceneDataIdentifier;

@property (nonatomic, strong) NSString *pickedDays;

@property (nonatomic, strong) NSArray *daysOfWeek;

@property (nonatomic, strong) NSMutableArray *selectedDays;
@property (nonatomic, strong) NSMutableArray *selectedIndices;

@end

@implementation APHGlucoseLevelsDaysViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNavAppearance];
    
    self.sceneDataIdentifier = [NSString stringWithFormat:@"%@", kGlucoseLevelCellIdentifier];
    
    self.selectedDays = [NSMutableArray array];
    self.selectedIndices = [NSMutableArray array];
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    
    self.daysOfWeek = [dateFormatter weekdaySymbols];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // check if there is data for the scene
    NSString *sceneData = [self.onboarding.sceneData valueForKey:self.sceneDataIdentifier];
    
    if (sceneData) {
        self.pickedDays = sceneData;
        
        if (self.pickedDays) {
            if ([self.pickedDays isEqualToString:@"Everyday"]) {
                [[dateFormatter weekdaySymbols] enumerateObjectsUsingBlock:^(id __unused obj, NSUInteger idx, BOOL * __unused stop) {
                    [self.selectedIndices addObject:@(idx)];
                }];
            } else if ([self.pickedDays isEqualToString:@"Weekdays"]) {
                self.selectedDays = [[dateFormatter weekdaySymbols] mutableCopy];
                [self.selectedDays removeObjectAtIndex:0];
                [self.selectedDays removeLastObject];
                
                [self.selectedDays enumerateObjectsUsingBlock:^(id __unused obj, NSUInteger idx, BOOL * __unused stop) {
                    [self.selectedIndices addObject:@(idx)];
                }];
            } else if ([self.pickedDays isEqualToString:@"Never"]) {
                // do nothing.
            } else {
                self.selectedDays = [[self.pickedDays componentsSeparatedByString:@" "] mutableCopy];
                
                if ([self.selectedDays count] == 1) {
                    NSNumber *dayIndex = @([self.daysOfWeek indexOfObject:self.pickedDays]);
                    [self.selectedIndices addObject:dayIndex];
                } else {
                    [self.selectedDays enumerateObjectsUsingBlock:^(NSString *day, NSUInteger __unused idx, BOOL * __unused stop) {
                        NSArray *dayReference = [dateFormatter shortWeekdaySymbols];
                        NSNumber *dayIndex = @([dayReference indexOfObject:day]);
                        [self.selectedIndices addObject:dayIndex];
                    }];
                }
            }
        }
    } else {
        // Select all day by default
        [[dateFormatter weekdaySymbols] enumerateObjectsUsingBlock:^(id __unused obj, NSUInteger idx, BOOL * __unused stop) {
            [self.selectedIndices addObject:@(idx)];
        }];
    }
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL) __unused animated
{
    [self.onboarding.sceneData setValue:self.pickedDays
                                 forKey:self.sceneDataIdentifier];
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (APCOnboarding *)onboarding
{
    return ((id<APCOnboardingManagerProvider>)
            [UIApplication sharedApplication].delegate).onboardingManager.onboarding;
}

- (void)setupNavAppearance
{
    UIBarButtonItem *backBarButton = [APCCustomBackButton customBackBarButtonItemWithTarget:self
                                                                                     action:@selector(goBackwards)
                                                                                  tintColor:[UIColor appPrimaryColor]];
    [self.navigationItem setLeftBarButtonItem:backBarButton];
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id) __unused sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"SegueToMealTimes"]) {
        
        if (self.pickedDays) {
            NSOrderedSet *pickedDays = [NSOrderedSet orderedSetWithArray:[self.pickedDays componentsSeparatedByString:@" "]];
            self.pickedDays = [[pickedDays array] componentsJoinedByString:@" "];
        }
        
        // save the pickedDays to User Defaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self.pickedDays forKey:kGlucoseMealTimePickedDays];
        [defaults synchronize];
        
        [[segue destinationViewController] setPickedDays:self.pickedDays];
    }
}

- (void)goBackwards
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - TableView
#pragma mark Datastore

- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *) __unused tableView numberOfRowsInSection:(NSInteger) __unused section
{
    return [self.daysOfWeek count];
}

- (CGFloat)tableView:(UITableView *) __unused tableView heightForRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    return kGlucoseLevelCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kGlucoseLevelCellIdentifier
                                                            forIndexPath:indexPath];
    
    NSString *day = [self.daysOfWeek objectAtIndex:indexPath.row];
    
    cell.textLabel.text = day;
    
    NSNumber *dayIndex = @(indexPath.row);
    
    if ([self.selectedIndices containsObject:dayIndex]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = [UIColor appPrimaryColor];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}

#pragma mark Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSNumber *dayIndex = @(indexPath.row);
    
    if ([self.selectedIndices containsObject:dayIndex]) {
        [self.selectedIndices removeObject:dayIndex];
    } else {
        [self.selectedIndices addObject:dayIndex];
    }
    
    [self prepareDetailLabel];
    
    [tableView reloadData];
}

- (void)prepareDetailLabel
{
    NSArray *dayReference = nil;
    
    if ([self.selectedIndices count] == 1) {
        dayReference = [dateFormatter weekdaySymbols];
    } else {
        dayReference = [dateFormatter shortWeekdaySymbols];
    }
    
    NSMutableArray *days = [NSMutableArray array];
    
    // sort the indices to keep the days in proper order
    NSArray *sortedIndices = [self.selectedIndices sortedArrayUsingSelector:@selector(compare:)];
    
    for (NSNumber *dayIndex in sortedIndices) {
        [days addObject:[dayReference objectAtIndex:[dayIndex integerValue]]];
    }
    
    if ([days count] == 0) {
        self.pickedDays = nil;
    } else if ([days count] == 7) {
        self.pickedDays = NSLocalizedString(@"Everyday", @"Everyday");
    } else {
        self.pickedDays = [days componentsJoinedByString:@" "];
    }
    
}

@end
