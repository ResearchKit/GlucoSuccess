// 
//  APHSliderViewController.m 
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
 
#import "APHSliderViewController.h"
#import "APHSliderCellView.h"

static NSDateFormatter *dateFormatter = nil;

@interface APHSliderViewController () <APHSliderCellViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *sliderDays;
@property (weak, nonatomic) IBOutlet UIScrollView *sliderMonths;

@property (nonatomic) CGRect visibleRectForDaySlider;
@property (nonatomic) CGRect visibleRectForMonthSlider;

@property (nonatomic) NSUInteger selectedMonth;
@property (nonatomic) NSUInteger selectedDay;

@end

@implementation APHSliderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale currentLocale];
    }
    
    NSDate *today = [NSDate date];
    NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *todaysComponents = [[NSCalendar currentCalendar] components:units fromDate:today];
    
    NSArray *months = [dateFormatter shortMonthSymbols];
    
    for (NSString *month in months) {
        CGRect square;
        NSUInteger monthIndex = [months indexOfObject:month];
        
        square.origin.x = 50 * monthIndex;
        square.origin.y = 0;
        square.size = CGSizeMake(50, 50);
        
        APHSliderCellView *monthCell = [[APHSliderCellView alloc] initWithFrame:square];
        
        NSUInteger normalMonthIndex = monthIndex + 1;
        
        monthCell.cellKind = APHSliderCellKindMonth;
        monthCell.elementIndex = normalMonthIndex;
        monthCell.textValue = month;
        monthCell.isCurrent = (todaysComponents.month == (NSInteger) normalMonthIndex) ? YES : NO;
        monthCell.currentColor = [UIColor appPrimaryColor];
        monthCell.delegate = self;
        
        if (todaysComponents.month < (NSInteger) normalMonthIndex) {
            monthCell.isAvailable = NO;
        }
        
        if (monthCell.isCurrent) {
            self.selectedMonth = normalMonthIndex;
            self.visibleRectForMonthSlider = square;
        }
        
        [self.sliderMonths addSubview:monthCell];
    }
    
    CGSize monthSliderContentSize = CGSizeMake(months.count * 50,
                                               self.sliderMonths.frame.size.height);
    
    self.sliderMonths.contentSize = monthSliderContentSize;
    
    [self configureDaysForSelectedMonth:todaysComponents.month];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.sliderMonths scrollRectToVisible:self.visibleRectForMonthSlider animated:YES];
    [self.sliderDays scrollRectToVisible:self.visibleRectForDaySlider animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Slider

- (void)configureDaysForSelectedMonth:(NSUInteger)month
{
    
    if (self.sliderDays.subviews.count != 0) {
        NSArray *allCells = self.sliderDays.subviews;
        
        for (APHSliderCellView *cell in allCells) {
            [cell removeFromSuperview];
        }
    }
    
    NSDate *today = [NSDate date];
    NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *todaysComponents = [[NSCalendar currentCalendar] components:units fromDate:today];
    NSDateComponents *currentDateComponents = [[NSDateComponents alloc] init];
    
    currentDateComponents.day = 1;
    currentDateComponents.month = month;
    currentDateComponents.year = 2015;
    
    NSDate *currentDate = [[NSCalendar currentCalendar] dateFromComponents:currentDateComponents];
    
    NSRange daysInCurrentMonth = [[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitDay
                                                                    inUnit:NSCalendarUnitMonth
                                                                   forDate:currentDate];
    
    NSArray *weekdays = [dateFormatter shortWeekdaySymbols];
    
    for (NSUInteger day = 0; day < daysInCurrentMonth.length; day++) {
        CGRect square;
        square.origin.x = 50 * day;
        square.origin.y = 0;
        square.size = CGSizeMake(50, 50);
        
        APHSliderCellView *dayCell = [[APHSliderCellView alloc] initWithFrame:square];
        
        NSUInteger normalDayIndex = day + 1;
        
        dayCell.cellKind = APHSliderCellKindDay;
        dayCell.elementIndex = normalDayIndex;
        dayCell.textValue = [NSString stringWithFormat:@"%lu", (unsigned long)normalDayIndex];
        
        NSDateComponents *thisDayDateComponents = [[NSDateComponents alloc] init];
        thisDayDateComponents.day = normalDayIndex;
        thisDayDateComponents.month = month;
        thisDayDateComponents.year = 2015;
        
        NSDate *thisDayDate = [[NSCalendar currentCalendar] dateFromComponents:thisDayDateComponents];
        NSInteger weekdayIndex = [[NSCalendar currentCalendar] component:NSCalendarUnitWeekday
                                                                fromDate:thisDayDate];
        dayCell.detailText = [weekdays objectAtIndex:weekdayIndex - 1];

        if (todaysComponents.month == (NSInteger) month) {
            self.selectedDay = normalDayIndex;
            dayCell.isCurrent = (todaysComponents.day == (NSInteger) normalDayIndex) ? YES : NO;
        }
        
        dayCell.currentColor = [UIColor appPrimaryColor];
        dayCell.delegate = self;
        
        if ((todaysComponents.day <= (NSInteger) normalDayIndex) && (todaysComponents.month == (NSInteger) month)) {
            dayCell.isAvailable = NO;
        }
        
        if (dayCell.isCurrent) {
            self.visibleRectForDaySlider = square;
        }
        
        [self.sliderDays addSubview:dayCell];
    }
    
    CGSize daySliderContentSize = CGSizeMake(daysInCurrentMonth.length * 50,
                                             self.sliderMonths.frame.size.height);
    
    self.sliderDays.contentSize = daySliderContentSize;
}

- (void)toggleStateForCell:(NSUInteger)index kind:(APHSliderCellKind)kind
{
    NSArray *allCells = nil;
    APHSliderCellView *currentCell = nil;
    
    if (kind == APHSliderCellKindDay) {
        allCells = [self.sliderDays subviews];
    } else {
        allCells = [self.sliderMonths subviews];
    }
    
    for (APHSliderCellView *cell in allCells) {
        if ((cell.isCurrent) || (cell.elementIndex != index)) {
            cell.isCurrent = NO;
        } else {
            cell.isCurrent = YES;
            currentCell = cell;
        }
    }
    
    [self.sliderDays scrollRectToVisible:currentCell.frame animated:YES];
}

#pragma mark - Slider Cell Delegates

- (void)didSelectCell:(APHSliderCellKind)kind elementIndex:(NSUInteger)index
{
    switch (kind) {
        case APHSliderCellKindDay:
        {
            self.selectedDay = index;
        }
            break;
            
        default: // month
        {
            if (self.selectedMonth != index) {
                [self configureDaysForSelectedMonth:index];
            }
            self.selectedMonth = index;
            
        }
            break;
    }
    
    [self toggleStateForCell:index kind:kind];
}

- (IBAction)selectDateForGlucoseEntry:(UIButton *) __unused sender
{
    if ((self.selectedMonth != 0) && (self.selectedDay != 0)) {
        if ([self.delegate respondsToSelector:@selector(didSelectDate:)]) {
            
            NSDateComponents *selectedDateComponents = [[NSDateComponents alloc] init];
            
            selectedDateComponents.day = self.selectedDay;
            selectedDateComponents.month = self.selectedMonth;
            selectedDateComponents.year = 2015;
            
            NSDate *selectedDate = [[NSCalendar currentCalendar] dateFromComponents:selectedDateComponents];
            
            [self.delegate didSelectDate:selectedDate];
        }
    }
}

@end
