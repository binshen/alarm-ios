//
//  MainController.m
//  alarm
//
//  Created by Bin Shen on 8/10/16.
//  Copyright © 2016 Bin Shen. All rights reserved.
//

#import "MainController.h"
#import <RMQClient/RMQClient.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface MainController ()

void AudioServicesStopSystemSound(int);
void AudioServicesPlaySystemSoundWithVibration(int, id, NSDictionary *);

@end

@implementation MainController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.alarmList = [[NSMutableArray alloc] init];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:20/255.0 green:155/255.0 blue:213/255.0 alpha:1.0]];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],NSForegroundColorAttributeName,nil]];
    
    RMQConnection *conn = [[RMQConnection alloc] initWithUri:@"amqp://guest:guest@121.40.92.176" delegate:[RMQConnectionDelegateLogger new]];
    [conn start];
    
    id<RMQChannel> ch = [conn createChannel];
    RMQExchange *x = [ch fanout:@"logs"];
    RMQQueue *q = [ch queue:@"" options:RMQQueueDeclareExclusive];
    
    [q bind:x];
    NSLog(@"Waiting for logs.");
    
    [q subscribe:^(RMQMessage * _Nonnull message) {
        NSString *msg = [[NSString alloc] initWithData:message.body encoding:NSUTF8StringEncoding];
        NSLog(@"Received %@", msg);
        
        NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
        id alarm = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        //[self.alarmList addObject:alarm];
        [self.alarmList insertObject: alarm atIndex:0];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
//        NSString *soundFilePath = [NSString stringWithFormat:@"%@/alarm.wav", [[NSBundle mainBundle] resourcePath]];
//        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
//        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
//        player.numberOfLoops = 1;
//        [player play];

        NSString *path = [[NSBundle mainBundle] pathForResource:@"alarm" ofType:@"wav"];
        SystemSoundID soundID;
        NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
        AudioServicesPlaySystemSound(soundID);
        //AudioServicesDisposeSystemSoundID(soundID);
        
        //AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        NSMutableArray* arr = [NSMutableArray array ];
        
        [arr addObject:[NSNumber numberWithBool:YES]]; //vibrate for 2000ms
        [arr addObject:[NSNumber numberWithInt:2000]];
        
        
        [dict setObject:arr forKey:@"VibePattern"];
        [dict setObject:[NSNumber numberWithFloat:0.3] forKey:@"Intensity"];
        
        AudioServicesStopSystemSound(kSystemSoundID_Vibrate);
        
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        NSArray *pattern = @[@YES, @30, @NO, @1];
        
//        if ([[UIDevice currentDevice] platformType] == UIDevice5SiPhone)
//        {
//            // iPhone 5S has a weaker vibration motor, so we vibrate for 10ms longer to compensate
//            pattern = @[@YES, @40, @NO, @1];
//        }
        
        dictionary[@"VibePattern"] = pattern;
        dictionary[@"Intensity"] = @1;
        
        AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, dictionary);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 0;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.alarmList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"AlarmCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSUInteger row = [indexPath row];
    NSDictionary *alarm = [self.alarmList objectAtIndex:row];
    cell.textLabel.text = [[alarm[@"company"] stringByAppendingString:@"-"] stringByAppendingString:alarm[@"mac"]];
    cell.detailTextLabel.text = alarm[@"created"];
    
    int level = [alarm[@"level"] intValue];
    if(level == 1) {
        cell.backgroundColor = [UIColor yellowColor];
    } else if(level == 2) {
        cell.backgroundColor = [UIColor orangeColor];
    } else {
        cell.backgroundColor = [UIColor redColor];
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
