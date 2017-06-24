//
//  CaptureImageVC.m
//  Chitra Vichitra
//
//  Created by Sushobhit_BuiltByBlank on 5/18/17.
//  Copyright © 2017 builtbyblank. All rights reserved.
//

#import "CaptureImageVC.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <Social/Social.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface CaptureImageVC ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *shareBtn;
@end

@implementation CaptureImageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.imageView setImage:self.image];
    [self setUpActionSheet];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setUpActionSheet {
    
}

- (IBAction)shareBtnAction:(id)sender {
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
