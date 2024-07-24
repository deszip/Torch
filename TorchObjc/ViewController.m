//
//  ViewController.m
//  TorchObjc
//
//  Created by Deszip on 05.07.2024.
//

#import "ViewController.h"
#import "TRSpotlightIndex.h"

@interface ViewController ()

@property (strong, nonatomic) TRSpotlightIndex *index;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.index = [TRSpotlightIndex new];
    [self.index add:@"Sun amd moon"];
    [self.index add:@"Sol amd luna"];
}

- (IBAction)search:(id)sender {
    [self.index search:@"Sun"];
}

@end
