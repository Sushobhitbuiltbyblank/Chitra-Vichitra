//
//  ShareVC.m
//  Chitra Vichitra
//
//  Created by Sushobhit_BuiltByBlank on 7/10/17.
//  Copyright © 2017 builtbyblank. All rights reserved.
//

#import "ShareVC.h"
#import <Social/Social.h>

@interface ShareVC ()<UIDocumentInteractionControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *crossBtn;
@property UIDocumentInteractionController * dicont;
@end

@implementation ShareVC


- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView.image = self.image;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)crossBtnAction:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}
- (IBAction)shareOtherBtnAction:(id)sender {
    UIActivityViewController *activityView = [[UIActivityViewController alloc]initWithActivityItems:@[self.image,@"Shared by Chitra Vichitra App"] applicationActivities:nil];
    [self presentViewController:activityView animated:true completion:nil];
}
- (IBAction)fbShareAction:(id)sender {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]){
        SLComposeViewController *fb = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [fb setInitialText:@"Facebook share"];
        [fb addImage:self.image];
        [self presentViewController:fb animated:true completion:nil];
    }
    else{
        printf("no facebook account");
    }

    
}
- (IBAction)twitterShareAction:(id)sender {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]){
        SLComposeViewController *fb = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [fb setInitialText:@"Twitter share"];
        [fb addImage:self.image];
        [self presentViewController:fb animated:true completion:nil];
    }
    else{
        printf("no twitter account");
    }
}
- (IBAction)instagramShareAction:(id)sender {
    NSURL *instagramURL = [NSURL URLWithString:@"instagram://app"];
    if ([[UIApplication sharedApplication] canOpenURL:instagramURL])
    {
        CGRect rect = CGRectZero;
        CGRect cropRect=CGRectMake(0,0,612,612);
        NSString *jpgPath=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/test.igo"];
        CGImageRef imageRef = CGImageCreateWithImageInRect([self.image CGImage], cropRect);
        UIImage *img = [[UIImage alloc] initWithCGImage:imageRef];
        CGImageRelease(imageRef);
        [UIImageJPEGRepresentation(img, 1.0) writeToFile:jpgPath atomically:YES];
        NSURL *igImageHookFile = [[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"file://%@",jpgPath]];
        self.dicont.UTI = @"com.instagram.photo";
        self.dicont = [self setupControllerWithURL:igImageHookFile usingDelegate:self];
        self.dicont.annotation = [NSDictionary dictionaryWithObject:@"Chitra Vichitra" forKey:@"InstagramCaption"];
        [self.dicont presentOpenInMenuFromRect: rect  inView: self.view animated: YES ];
    }
    else
    {
//        DisplayAlert(@"Instagram not installed in this device!\nTo share image please install instagram.");
    }
}

- (IBAction)whatsAppShareAction:(id)sender {
    NSURL *instagramURL = [NSURL URLWithString:@"whatsapp://"];
    if ([[UIApplication sharedApplication] canOpenURL:instagramURL])
    {
        CGRect rect = CGRectZero;
        CGRect cropRect=CGRectMake(0,0,612,612);
        NSString *jpgPath=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/test.wai"];
        CGImageRef imageRef = CGImageCreateWithImageInRect([self.image CGImage], cropRect);
        UIImage *img = [[UIImage alloc] initWithCGImage:imageRef];
        CGImageRelease(imageRef);
        [UIImageJPEGRepresentation(img, 1.0) writeToFile:jpgPath atomically:YES];
        NSURL *igImageHookFile = [[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"file://%@",jpgPath]];
        self.dicont.UTI = @"net.whatsapp.image";
        self.dicont = [self setupControllerWithURL:igImageHookFile usingDelegate:self];
        [self.dicont presentOpenInMenuFromRect: rect  inView: self.view animated: YES ];
    }
    else
    {
        printf("whatsapp not work");
        //        DisplayAlert(@"Instagram not installed in this device!\nTo share image please install instagram.");
    }
}

#pragma mark - Document Interaction Controller
- (UIDocumentInteractionController *) setupControllerWithURL: (NSURL*) fileURL usingDelegate: (id <UIDocumentInteractionControllerDelegate>) interactionDelegate {
    UIDocumentInteractionController *interactionController = [UIDocumentInteractionController interactionControllerWithURL: fileURL];
    interactionController.delegate = interactionDelegate;
    
    return interactionController;
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
