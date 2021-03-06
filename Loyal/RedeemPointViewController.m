//
//  RedeemPointViewController.m
//  Loyal
//
//  Created by Dias Nurul Arifin on 4/26/14.
//  Copyright (c) 2014 Dias Nurul Arifin. All rights reserved.
//

#import "RedeemPointViewController.h"
#import "ASIFormDataRequest.h"
#import "RedeemPointModel.h"
#import "RedeemPointCell.h"
#import "AppDelegate.h"
#import "JASidePanelController.h"
#import "Util.h"

@interface RedeemPointViewController ()

@end

@implementation RedeemPointViewController
{
    NSMutableArray *redeems;
    UIAlertView *alert;
    int currPage;
    NSUserDefaults *defaults;
}
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    JASidePanelController *rootViewController = (JASidePanelController *)delegate.window.rootViewController;
    
    UIViewController *buttonController = self;
    if ([buttonController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)buttonController;
        if ([nav.viewControllers count] > 0) {
            buttonController = [nav.viewControllers objectAtIndex:0];
        }
    }
    buttonController.navigationItem.leftBarButtonItem = [rootViewController leftButtonForCenterPanel];
    
    currPage = 0;
    redeems = [[NSMutableArray alloc] init];
    
    [self loadMore];
}

- (void)loadMore
{
    alert = [[UIAlertView alloc]
             initWithTitle:@"Loading..."
             message:@"Please wait we're getting your data"
             delegate:nil
             cancelButtonTitle:nil
             otherButtonTitles: nil];
    [alert show];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://apimobile.pendhapa.com/api/LuckyDraw"] ];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary *postBody = @{
                               @"Customer_Sequent_No":[defaults stringForKey:@"custSeqNo"],
                               @"PNum":[defaults stringForKey:@"pNum"],
                               @"PType":[defaults stringForKey:@"pType"],
                               @"PageNo":[NSNumber numberWithInt:currPage+1],
                               @"PageLength":[NSNumber numberWithInt:10]
                               };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postBody
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [request appendPostData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setRequestMethod:@"POST"];
    [request setDelegate:self];
    [request startAsynchronous];
    NSLog(@"Yolo Getting Data...");
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSMutableDictionary *allEvents = [NSJSONSerialization
                                      JSONObjectWithData:[request responseData]
                                      options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves
                                      error:nil];
    NSArray *results = [allEvents valueForKey:@"LuckyDrawList"];
    [alert dismissWithClickedButtonIndex:0 animated:YES];
    if (results.count < 1) {
        UIAlertView *alertWarning = [[UIAlertView alloc]
                                     initWithTitle:nil
                                     message:@"No more data!"
                                     delegate:nil
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles: nil];
        [alertWarning show];
    } else {
        for (NSDictionary *data in results)
        {
            RedeemPointModel *point = [RedeemPointModel new];
            point.date = data[@"pos_date"];
            point.amount = data[@"total_amount"];
            point.point = data[@"total_point"];
            [redeems addObject:point];
        }
        [self.tableView reloadData];
        currPage++;
        [alert dismissWithClickedButtonIndex:0 animated:YES];
    }
    
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    NSLog(@"Yolo Error: %@", error);
    [alert dismissWithClickedButtonIndex:0 animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [redeems count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == redeems.count && tableView != self.searchDisplayController.searchResultsTableView) {
        return (RedeemPointCell *)[self.tableView dequeueReusableCellWithIdentifier:@"LoadMoreCell"];
    }
    
    static NSString *CellIdentifier = @"Cell";
    RedeemPointCell *cell = (RedeemPointCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[RedeemPointCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    RedeemPointModel *data = [redeems objectAtIndex:indexPath.row];
    if (data.outlet != (id)[NSNull null])
        cell.outletLabel.text = data.outlet;
    if (data.date != (id)[NSNull null])
        cell.dateLabel.text = [Util formatXmlDate:data.date];
    if (data.point != (id)[NSNull null])
        cell.pointLabel.text = [NSString stringWithFormat:@"%@", data.point];
    if (data.amount != (id)[NSNull null]){
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
        NSString *numberAsString = [numberFormatter stringFromNumber:data.amount];
        cell.amountLabel.text = [NSString stringWithFormat:@"Rp. %@", numberAsString];
    }
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==redeems.count) {
        return 42;
    }else{
        return 92;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==redeems.count) {
        [self loadMore];
    }
}

@end
