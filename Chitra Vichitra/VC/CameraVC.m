//
//  CameraVC.m
//  Chitra Vichitra
//
//  Created by Sushobhit_BuiltByBlank on 5/12/17.
//  Copyright © 2017 builtbyblank. All rights reserved.
//

#import "CameraVC.h"
#import "GPUImage.h"
#import <CoreImage/CoreImage.h>
#import "FrameCVCell.h"
#import "CaptureImageVC.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ShareVC.h"
@import GoogleMobileAds;

@interface CameraVC ()<UICollectionViewDelegate,UICollectionViewDataSource,UINavigationControllerDelegate, UIImagePickerControllerDelegate>{
    GPUImageStillCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageShowcaseFilterType filterType;
    GPUImageUIElement *uiElementInput;
    GPUImageFilterPipeline *pipeline;
    GPUImagePicture *stillImageSource;
    UIImage *captureImage;
    NSString *identifer;
    UIView *touchView;
    UIImage *origonalImage;
    UIAlertController *actionSheet;
}
@property (weak, nonatomic) IBOutlet UIButton *undoBtn;
@property (weak, nonatomic) IBOutlet UISlider *filterSettingsSlider;
@property (weak, nonatomic) IBOutlet GPUImageView *filterView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bVBottomC;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ACBVBottomC;
@property (nonatomic, strong) UIImagePickerController* imagePicker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *galleryBtn;
@property (weak, nonatomic) IBOutlet GPUImageView *otherView;
@property (weak, nonatomic) IBOutlet UIView *afterClickbottomView;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UIButton *settingBtn;
@property(nonatomic, strong) GADBannerView *bannerView;
@property (weak, nonatomic) IBOutlet UIView *adView;

@end

@implementation CameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupFilter];
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraViewTapAction:)];
    [self.filterView addGestureRecognizer:tgr];
    
    //setup banner ad
    self.bannerView = [[GADBannerView alloc]
                       initWithAdSize:kGADAdSizeSmartBannerPortrait];
    [self.adView addSubview:self.bannerView];
    self.bannerView.adUnitID = @"ca-app-pub-3940256099942544/2934735716";
    self.bannerView.rootViewController = self;
    [self.bannerView loadRequest:[GADRequest request]];
    GADRequest *request = [GADRequest request];
    request.testDevices = @[ kGADSimulatorID,                       // All simulators
                             @"efac8914d02a3f4ac9dc877b78ad7749" ]; // Sample device ID
    [self showhideAdview];
    [self setUpActionSheet];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Note: I needed to stop camera capture before the view went off the screen in order to prevent a crash from the camera still sending frames
    [videoCamera stopCameraCapture];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Note: I needed to start camera capture after the view went on the screen, when a partially transition of navigation view controller stopped capturing via viewWilDisappear.
    [videoCamera startCameraCapture];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
}


//- (id)initWithFilterType:(GPUImageShowcaseFilterType)newFilterType
//{
//    if (self)
//    {
//        filterType = newFilterType;
//    }
//    return self;
//}

- (void)setupFilter
{
    videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    filter = [[GPUImageFilter alloc] init];
    GPUImageView *filterView = (GPUImageView *)self.filterView;
    [filter addTarget:filterView];
    [videoCamera addTarget:filter];
    [videoCamera startCameraCapture];
    //Identifier for collectionview cell
    identifer = @"filterCell";
    // Still image source processer.
}

-(void)changeFilter: (GPUImageOutput<GPUImageInput> *)selectedfilter
{
   
    if (self.filterView.isHidden){
        GPUImageView *filterView = (GPUImageView *)self.otherView;
        [selectedfilter addTarget:filterView];
        stillImageSource = [[GPUImagePicture alloc] initWithImage:captureImage];
        [stillImageSource addTarget:selectedfilter];
//        [selectedfilter useNextFrameForImageCapture];
        [stillImageSource processImage];
//        captureImage = [selectedfilter imageFromCurrentFramebuffer];
        captureImage = [selectedfilter imageByFilteringImage:captureImage];
    }
    else{
        [videoCamera removeAllTargets];
        [videoCamera addTarget:selectedfilter];
        GPUImageView *filterView = (GPUImageView *)self.filterView;
        if (videoCamera.cameraPosition == AVCaptureDevicePositionFront)
        {
            [self.filterView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
        }
        else{
            [self.filterView setInputRotation:kGPUImageNoRotation atIndex:0];
        }
        [selectedfilter addTarget:filterView];
    }
}
#pragma mark  - button Action
- (IBAction)SwitchCamera:(id)sender {
    [videoCamera rotateCamera];
    if (videoCamera.cameraPosition == AVCaptureDevicePositionFront)
    {
        [self.filterView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
    }
    else{
        [self.filterView setInputRotation:kGPUImageNoRotation atIndex:0];
    }
}
- (IBAction)captureBtn:(id)sender {
    [videoCamera capturePhotoAsImageProcessedUpToFilter:filter withCompletionHandler:^(UIImage *processedImage, NSError *error)
     {
         captureImage = processedImage;
         origonalImage = captureImage;
         self.filterView.hidden = YES;
         filter = [[GPUImageFilter alloc]init];
         [self changeFilter:filter];
         self.filterSettingsSlider.hidden = YES;
         [self showHideAfterClickView];
         [self showhideAdview];
//         [self performSegueWithIdentifier:@"gotoCaptureImageVC" sender:sender];
//         UIImageWriteToSavedPhotosAlbum(processedImage, self, nil, nil);
     }];
}
- (IBAction)settingAction:(id)sender {
    [self showHideview];
}
- (IBAction)resetAction:(id)sender {
    filter = [[GPUImageFilter alloc]init];
    captureImage = origonalImage;
    [self changeFilter:filter];
    self.filterSettingsSlider.hidden = true;
}
- (IBAction)openGallery:(id)sender {
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    // Displays saved pictures and movies, if both are available, from the
    // Camera Roll album.
    self.imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
    //    [UIImagePickerController availableMediaTypesForSourceType:
    //     UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    self.imagePicker.allowsEditing = NO;
    
    self.imagePicker.delegate = self;
    self.filterSettingsSlider.hidden = true;
    [self presentViewController:self.imagePicker animated:YES completion:nil];
    

}
- (IBAction)backAction:(id)sender {
    [self goBack];
   }
- (IBAction)saveAction:(id)sender {
    [self presentViewController:actionSheet animated:YES completion:nil];
//        [self performSegueWithIdentifier:@"gotoCaptureImageVC" sender:sender];
}
- (IBAction)settingtwoAction:(id)sender {
    [self showHideAfterClickView];
    [self showHideview];
}
- (IBAction)undoBtnAction:(id)sender {
    filter = [[GPUImageFilter alloc] init];
    captureImage = origonalImage;
    self.filterSettingsSlider.hidden = YES;
    [self changeFilter:filter];
}

-(void)goBack{
    [self showHideAfterClickView];
    self.filterView.hidden = NO;
    filter = [[GPUImageFilter alloc]init];
    captureImage = origonalImage;
    [self changeFilter:filter];
    self.filterSettingsSlider.hidden = true;
    [self showhideAdview];

}
-(void)showHideview{
    [self.view layoutIfNeeded];
    if (self.bVBottomC.constant == 0){
        self.bVBottomC.constant = -100;
        [UIView animateWithDuration:.5 animations:^{
            [self.view layoutIfNeeded]; // Called on parent view
        }];
    }
    else{
        self.bVBottomC.constant = 0;
        [UIView animateWithDuration:.5 animations:^{
            [self.view layoutIfNeeded]; // Called on parent view
        }];
    }
}
-(void)showHideAfterClickView{
    [self.view layoutIfNeeded];
    if (self.ACBVBottomC.constant == 0){
        self.ACBVBottomC.constant = -100;
        self.undoBtn.hidden = true;
        [UIView animateWithDuration:.5 animations:^{
            [self.view layoutIfNeeded]; // Called on parent view
        }];
    }
    else{
        self.undoBtn.hidden = false;
        self.ACBVBottomC.constant = 0;
        [UIView animateWithDuration:.5 animations:^{
            [self.view layoutIfNeeded]; // Called on parent view
        }];
    }
}
-(void)showhideAdview {
    [self.view layoutIfNeeded];
    if (self.adView.isHidden == false){
        self.adView.hidden = true;
        [UIView animateWithDuration:.5 animations:^{
            [self.view layoutIfNeeded]; // Called on parent view
        }];
    }
    else{
        self.adView.hidden = false;
        [UIView animateWithDuration:.5 animations:^{
            [self.view layoutIfNeeded]; // Called on parent view
        }];
    }
}
#pragma mark - CollectionView method
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return GPUIMAGE_NUMFILTERS;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    FrameCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifer forIndexPath:indexPath];
    switch (indexPath.row)
    {
        case GPUIMAGE_NONE:cell.filterName.text = @"Original"; break;
        case GPUIMAGE_SATURATION: cell.filterName.text = @"Saturation"; break;
        case GPUIMAGE_CONTRAST: cell.filterName.text = @"Contrast"; break;
        case GPUIMAGE_BRIGHTNESS: cell.filterName.text = @"Brightness"; break;
        case GPUIMAGE_LEVELS: cell.filterName.text = @"Levels"; break;
        case GPUIMAGE_EXPOSURE: cell.filterName.text = @"Exposure"; break;
        case GPUIMAGE_RGB: cell.filterName.text = @"RGB"; break;
        case GPUIMAGE_HUE: cell.filterName.text = @"Hue"; break;
        case GPUIMAGE_WHITEBALANCE: cell.filterName.text = @"White balance"; break;
        case GPUIMAGE_MONOCHROME: cell.filterName.text = @"Monochrome"; break;
        case GPUIMAGE_FALSECOLOR: cell.filterName.text = @"False color"; break;
        case GPUIMAGE_SHARPEN: cell.filterName.text = @"Sharpen"; break;
        case GPUIMAGE_UNSHARPMASK: cell.filterName.text = @"Unsharp mask"; break;
        case GPUIMAGE_GAMMA: cell.filterName.text = @"Gamma"; break;
        case GPUIMAGE_TONECURVE: cell.filterName.text = @"Tone curve"; break;
        case GPUIMAGE_HIGHLIGHTSHADOW: cell.filterName.text = @"Highlights and shadows"; break;
        case GPUIMAGE_HAZE: cell.filterName.text = @"Haze"; break;
        case GPUIMAGE_THRESHOLD: cell.filterName.text = @"Threshold"; break;
        case GPUIMAGE_ADAPTIVETHRESHOLD: cell.filterName.text = @"Adaptive threshold"; break;
        case GPUIMAGE_AVERAGELUMINANCETHRESHOLD: cell.filterName.text = @"Average luminance threshold"; break;
        case GPUIMAGE_COLORINVERT: cell.filterName.text = @"Color invert"; break;
        case GPUIMAGE_GRAYSCALE: cell.filterName.text = @"Grayscale"; break;
        case GPUIMAGE_SEPIA: cell.filterName.text = @"Sepia tone"; break;
        case GPUIMAGE_PIXELLATE: cell.filterName.text = @"Pixellate"; break;
        case GPUIMAGE_POLARPIXELLATE: cell.filterName.text = @"Polar pixellate"; break;
        case GPUIMAGE_POLKADOT: cell.filterName.text = @"Polka dot"; break;
        case GPUIMAGE_HALFTONE: cell.filterName.text = @"Halftone"; break;
        case GPUIMAGE_CROSSHATCH: cell.filterName.text = @"Crosshatch"; break;
        case GPUIMAGE_SOBELEDGEDETECTION: cell.filterName.text = @"Sobel edge detection"; break;
        case GPUIMAGE_PREWITTEDGEDETECTION: cell.filterName.text = @"Prewitt edge detection"; break;
        case GPUIMAGE_CANNYEDGEDETECTION: cell.filterName.text = @"Canny edge detection"; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION: cell.filterName.text = @"Threshold edge detection"; break;
        case GPUIMAGE_XYGRADIENT: cell.filterName.text = @"XY derivative"; break;
        case GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR: cell.filterName.text = @"Hough transform line detection"; break;
        case GPUIMAGE_MOTIONDETECTOR: cell.filterName.text = @"Motion detector"; break;
        case GPUIMAGE_LOWPASS: cell.filterName.text = @"Low pass"; break;
        case GPUIMAGE_HIGHPASS: cell.filterName.text = @"High pass"; break;
        case GPUIMAGE_SKETCH: cell.filterName.text = @"Sketch"; break;
        case GPUIMAGE_THRESHOLDSKETCH: cell.filterName.text = @"Threshold Sketch"; break;
        case GPUIMAGE_TOON: cell.filterName.text = @"Toon"; break;
        case GPUIMAGE_SMOOTHTOON: cell.filterName.text = @"Smooth toon"; break;
        case GPUIMAGE_TILTSHIFT: cell.filterName.text = @"Tilt shift"; break;
        case GPUIMAGE_CGA: cell.filterName.text = @"CGA colorspace"; break;
        case GPUIMAGE_CONVOLUTION: cell.filterName.text = @"3x3 convolution"; break;
        case GPUIMAGE_EMBOSS: cell.filterName.text = @"Emboss"; break;
        case GPUIMAGE_LAPLACIAN: cell.filterName.text = @"Laplacian"; break;
        case GPUIMAGE_POSTERIZE: cell.filterName.text = @"Posterize"; break;
        case GPUIMAGE_SWIRL: cell.filterName.text = @"Swirl"; break;
        case GPUIMAGE_BULGE: cell.filterName.text = @"Bulge"; break;
        case GPUIMAGE_PINCH: cell.filterName.text = @"Pinch"; break;
        case GPUIMAGE_STRETCH: cell.filterName.text = @"Stretch"; break;
        case GPUIMAGE_DILATION: cell.filterName.text = @"Dilation"; break;
        case GPUIMAGE_EROSION: cell.filterName.text = @"Erosion"; break;
        case GPUIMAGE_OPENING: cell.filterName.text = @"Opening"; break;
        case GPUIMAGE_CLOSING: cell.filterName.text = @"Closing"; break;
//        case GPUIMAGE_MOSAIC: cell.filterName.text = @"Mosaic"; break;
        case GPUIMAGE_LOCALBINARYPATTERN: cell.filterName.text = @"Local binary pattern"; break;
        case GPUIMAGE_KUWAHARA: cell.filterName.text = @"Kuwahara"; break;
        case GPUIMAGE_KUWAHARARADIUS3: cell.filterName.text = @"Kuwahara (fixed radius)"; break;
        case GPUIMAGE_VIGNETTE: cell.filterName.text = @"Vignette"; break;
        case GPUIMAGE_GAUSSIAN: cell.filterName.text = @"Gaussian blur"; break;
        case GPUIMAGE_BILATERAL: cell.filterName.text = @"Bilateral blur"; break;
        case GPUIMAGE_MOTIONBLUR: cell.filterName.text = @"Motion blur"; break;
        case GPUIMAGE_ZOOMBLUR: cell.filterName.text = @"Zoom blur"; break;
        case GPUIMAGE_BOXBLUR: cell.filterName.text = @"Box blur"; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE: cell.filterName.text = @"Gaussian selective blur"; break;
        case GPUIMAGE_GAUSSIAN_POSITION: cell.filterName.text = @"Gaussian (centered)"; break;
        case GPUIMAGE_CUSTOM: cell.filterName.text = @"Custom"; break;
        case GPUIMAGE_FILECONFIG: cell.filterName.text = @"Filter Chain"; break;
        case GPUIMAGE_FILTERGROUP: cell.filterName.text = @"Filter Group"; break;
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self showHideview];
    if (self.filterView.isHidden)
    {
        [self showHideAfterClickView];
    }
    filterType = (GPUImageShowcaseFilterType) indexPath.row;
    switch (indexPath.row)
    {
        case GPUIMAGE_NONE:
        {
            filter = [[GPUImageFilter alloc] init];
            captureImage = origonalImage;
            self.filterSettingsSlider.hidden = YES;
            [self changeFilter:filter];

        }; break;
        case GPUIMAGE_SEPIA:
        {
            self.title = @"Sepia Tone";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];

            filter = [[GPUImageSepiaFilter alloc] init];
        }; break;
        case GPUIMAGE_PIXELLATE:
        {
            self.title = @"Pixellate";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.3];
            
            filter = [[GPUImagePixellateFilter alloc] init];
        }; break;
        case GPUIMAGE_POLARPIXELLATE:
        {
            self.title = @"Polar Pixellate";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:-0.1];
            [self.filterSettingsSlider setMaximumValue:0.1];
            
            filter = [[GPUImagePolarPixellateFilter alloc] init];
        }; break;
        case GPUIMAGE_POLKADOT:
        {
            self.title = @"Polka Dot";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.3];
            
            filter = [[GPUImagePolkaDotFilter alloc] init];
        }; break;
        case GPUIMAGE_HALFTONE:
        {
            self.title = @"Halftone";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.01];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.05];
            
            filter = [[GPUImageHalftoneFilter alloc] init];

        }; break;
        case GPUIMAGE_CROSSHATCH:
        {
            self.title = @"Crosshatch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.03];
            [self.filterSettingsSlider setMinimumValue:0.01];
            [self.filterSettingsSlider setMaximumValue:0.06];
            
            filter = [[GPUImageCrosshatchFilter alloc] init];

        }; break;
        case GPUIMAGE_COLORINVERT:
        {
            self.title = @"Color Invert";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageColorInvertFilter alloc] init];
        }; break;
        case GPUIMAGE_GRAYSCALE:
        {
            self.title = @"Grayscale";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageGrayscaleFilter alloc] init];

        }; break;
        case GPUIMAGE_MONOCHROME:
        {
            self.title = @"Monochrome";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
            filter = [[GPUImageMonochromeFilter alloc] init];
            [(GPUImageMonochromeFilter *)filter setColor:(GPUVector4){0.0f, 0.0f, 1.0f, 1.f}];
            
        }; break;
        case GPUIMAGE_FALSECOLOR:
        {
            self.title = @"False Color";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageFalseColorFilter alloc] init];
        }; break;
        case GPUIMAGE_SATURATION:
        {
            self.title = @"Saturation";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            
            filter = [[GPUImageSaturationFilter alloc] init];
        }; break;
        case GPUIMAGE_CONTRAST:
        {
            self.title = @"Contrast";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageContrastFilter alloc] init];
        }; break;
        case GPUIMAGE_BRIGHTNESS:
        {
            self.title = @"Brightness";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageBrightnessFilter alloc] init];
        }; break;
        case GPUIMAGE_LEVELS:
        {
            self.title = @"Levels";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageLevelsFilter alloc] init];
        }; break;
        case GPUIMAGE_RGB:
        {
            self.title = @"RGB";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageRGBFilter alloc] init];
        }; break;
        case GPUIMAGE_HUE:
        {
            self.title = @"Hue";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:360.0];
            [self.filterSettingsSlider setValue:90.0];
            
            filter = [[GPUImageHueFilter alloc] init];
        }; break;
        case GPUIMAGE_WHITEBALANCE:
        {
            self.title = @"White Balance";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:2500.0];
            [self.filterSettingsSlider setMaximumValue:7500.0];
            [self.filterSettingsSlider setValue:5000.0];
            
            filter = [[GPUImageWhiteBalanceFilter alloc] init];
        }; break;
        case GPUIMAGE_EXPOSURE:
        {
            self.title = @"Exposure";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-4.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageExposureFilter alloc] init];
        }; break;
        case GPUIMAGE_SHARPEN:
        {
            self.title = @"Sharpen";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageSharpenFilter alloc] init];
        }; break;
        case GPUIMAGE_UNSHARPMASK:
        {
            self.title = @"Unsharp Mask";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageUnsharpMaskFilter alloc] init];
            
            //            [(GPUImageUnsharpMaskFilter *)filter setIntensity:3.0];
        }; break;
        case GPUIMAGE_GAMMA:
        {
            self.title = @"Gamma";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:3.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageGammaFilter alloc] init];
        }; break;
        case GPUIMAGE_TONECURVE:
        {
            self.title = @"Tone curve";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageToneCurveFilter alloc] init];
            [(GPUImageToneCurveFilter *)filter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
        }; break;
        case GPUIMAGE_HIGHLIGHTSHADOW:
        {
            self.title = @"Highlights and Shadows";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
            filter = [[GPUImageHighlightShadowFilter alloc] init];
        }; break;
        case GPUIMAGE_HAZE:
        {
            self.title = @"Haze / UV";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-0.2];
            [self.filterSettingsSlider setMaximumValue:0.2];
            [self.filterSettingsSlider setValue:0.2];
            
            filter = [[GPUImageHazeFilter alloc] init];
        }; break;
        case GPUIMAGE_THRESHOLD:
        {
            self.title = @"Luminance Threshold";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageLuminanceThresholdFilter alloc] init];
        }; break;
        case GPUIMAGE_ADAPTIVETHRESHOLD:
        {
            self.title = @"Adaptive Threshold";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:20.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        }; break;
        case GPUIMAGE_AVERAGELUMINANCETHRESHOLD:
        {
            self.title = @"Avg. Lum. Threshold";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageAverageLuminanceThresholdFilter alloc] init];
        }; break;
        case GPUIMAGE_SOBELEDGEDETECTION:
        {
            self.title = @"Sobel Edge Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.25];
            
            filter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_XYGRADIENT:
        {
            self.title = @"XY Derivative";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageXYDerivativeFilter alloc] init];
        }; break;
        case GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR:
        {
            self.title = @"Line Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.2];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.6];
            
            filter = [[GPUImageHoughTransformLineDetector alloc] init];
            [(GPUImageHoughTransformLineDetector *)filter setLineDetectionThreshold:0.60];
        }; break;
            
        case GPUIMAGE_PREWITTEDGEDETECTION:
        {
            self.title = @"Prewitt Edge Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImagePrewittEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_CANNYEDGEDETECTION:
        {
            self.title = @"Canny Edge Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION:
        {
            self.title = @"Threshold Edge Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.25];
            
            filter = [[GPUImageThresholdEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_LOCALBINARYPATTERN:
        {
            self.title = @"Local Binary Pattern";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageLocalBinaryPatternFilter alloc] init];
        }; break;
        case GPUIMAGE_LOWPASS:
        {
            self.title = @"Low Pass";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageLowPassFilter alloc] init];
        }; break;
        case GPUIMAGE_HIGHPASS:
        {
            self.title = @"High Pass";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageHighPassFilter alloc] init];
        }; break;
        case GPUIMAGE_MOTIONDETECTOR:
        {
            self.title = @"Motion Detector";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageMotionDetector alloc] init];
        }; break;
        case GPUIMAGE_SKETCH:
        {
            self.title = @"Sketch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.25];
            
            filter = [[GPUImageSketchFilter alloc] init];
        }; break;
        case GPUIMAGE_THRESHOLDSKETCH:
        {
            self.title = @"Threshold Sketch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.25];
            
            filter = [[GPUImageThresholdSketchFilter alloc] init];
        }; break;
        case GPUIMAGE_TOON:
        {
            self.title = @"Toon";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageToonFilter alloc] init];
        }; break;
        case GPUIMAGE_SMOOTHTOON:
        {
            self.title = @"Smooth Toon";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:6.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageSmoothToonFilter alloc] init];
        }; break;
        case GPUIMAGE_TILTSHIFT:
        {
            self.title = @"Tilt Shift";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.2];
            [self.filterSettingsSlider setMaximumValue:0.8];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageTiltShiftFilter alloc] init];
            [(GPUImageTiltShiftFilter *)filter setTopFocusLevel:0.4];
            [(GPUImageTiltShiftFilter *)filter setBottomFocusLevel:0.6];
            [(GPUImageTiltShiftFilter *)filter setFocusFallOffRate:0.2];
        }; break;
        case GPUIMAGE_CGA:
        {
            self.title = @"CGA Colorspace";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageCGAColorspaceFilter alloc] init];
        }; break;
        case GPUIMAGE_CONVOLUTION:
        {
            self.title = @"3x3 Convolution";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImage3x3ConvolutionFilter alloc] init];
            //            [(GPUImage3x3ConvolutionFilter *)filter setConvolutionKernel:(GPUMatrix3x3){
            //                {-2.0f, -1.0f, 0.0f},
            //                {-1.0f,  1.0f, 1.0f},
            //                { 0.0f,  1.0f, 2.0f}
            //            }];
            [(GPUImage3x3ConvolutionFilter *)filter setConvolutionKernel:(GPUMatrix3x3){
                {-1.0f,  0.0f, 1.0f},
                {-2.0f, 0.0f, 2.0f},
                {-1.0f,  0.0f, 1.0f}
            }];
            
            //            [(GPUImage3x3ConvolutionFilter *)filter setConvolutionKernel:(GPUMatrix3x3){
            //                {1.0f,  1.0f, 1.0f},
            //                {1.0f, -8.0f, 1.0f},
            //                {1.0f,  1.0f, 1.0f}
            //            }];
            //            [(GPUImage3x3ConvolutionFilter *)filter setConvolutionKernel:(GPUMatrix3x3){
            //                { 0.11f,  0.11f, 0.11f},
            //                { 0.11f,  0.11f, 0.11f},
            //                { 0.11f,  0.11f, 0.11f}
            //            }];
        }; break;
        case GPUIMAGE_EMBOSS:
        {
            self.title = @"Emboss";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageEmbossFilter alloc] init];
        }; break;
        case GPUIMAGE_LAPLACIAN:
        {
            self.title = @"Laplacian";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageLaplacianFilter alloc] init];
        }; break;
        case GPUIMAGE_POSTERIZE:
        {
            self.title = @"Posterize";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:20.0];
            [self.filterSettingsSlider setValue:10.0];
            
            filter = [[GPUImagePosterizeFilter alloc] init];
        }; break;
        case GPUIMAGE_SWIRL:
        {
            self.title = @"Swirl";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageSwirlFilter alloc] init];
        }; break;
        case GPUIMAGE_BULGE:
        {
            self.title = @"Bulge";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageBulgeDistortionFilter alloc] init];
        }; break;
        case GPUIMAGE_PINCH:
        {
            self.title = @"Pinch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-2.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImagePinchDistortionFilter alloc] init];
        }; break;
        case GPUIMAGE_STRETCH:
        {
            self.title = @"Stretch";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageStretchDistortionFilter alloc] init];
        }; break;
        case GPUIMAGE_DILATION:
        {
            self.title = @"Dilation";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageRGBDilationFilter alloc] initWithRadius:4];
        }; break;
        case GPUIMAGE_EROSION:
        {
            self.title = @"Erosion";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageRGBErosionFilter alloc] initWithRadius:4];
        }; break;
        case GPUIMAGE_OPENING:
        {
            self.title = @"Opening";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageRGBOpeningFilter alloc] initWithRadius:4];
        }; break;
        case GPUIMAGE_CLOSING:
        {
            self.title = @"Closing";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageRGBClosingFilter alloc] initWithRadius:4];
        }; break;
            
//        case GPUIMAGE_MOSAIC:
//        {
//            self.title = @"Mosaic";
//            self.filterSettingsSlider.hidden = NO;
//            
//            [self.filterSettingsSlider setMinimumValue:0.002];
//            [self.filterSettingsSlider setMaximumValue:0.05];
//            [self.filterSettingsSlider setValue:0.025];
//            
//            filter = [[GPUImageMosaicFilter alloc] init];
//            [(GPUImageMosaicFilter *)filter setTileSet:@"squares.png"];
//            [(GPUImageMosaicFilter *)filter setColorOn:NO];
//            //[(GPUImageMosaicFilter *)filter setTileSet:@"dotletterstiles.png"];
//            //[(GPUImageMosaicFilter *)filter setTileSet:@"curvies.png"];
//            
//        }; break;
        case GPUIMAGE_CUSTOM:
        {
            self.title = @"Custom";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"CustomFilter"];
        }; break;
        case GPUIMAGE_KUWAHARA:
        {
            self.title = @"Kuwahara";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:3.0];
            [self.filterSettingsSlider setMaximumValue:8.0];
            [self.filterSettingsSlider setValue:3.0];
            
            filter = [[GPUImageKuwaharaFilter alloc] init];
        }; break;
        case GPUIMAGE_KUWAHARARADIUS3:
        {
            self.title = @"Kuwahara (Radius 3)";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageKuwaharaRadius3Filter alloc] init];
        }; break;
        case GPUIMAGE_VIGNETTE:
        {
            self.title = @"Vignette";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.5];
            [self.filterSettingsSlider setMaximumValue:0.9];
            [self.filterSettingsSlider setValue:0.75];
            
            filter = [[GPUImageVignetteFilter alloc] init];
        }; break;
        case GPUIMAGE_GAUSSIAN:
        {
            self.title = @"Gaussian Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:24.0];
            [self.filterSettingsSlider setValue:2.0];
            
            filter = [[GPUImageGaussianBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_BOXBLUR:
        {
            self.title = @"Box Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:24.0];
            [self.filterSettingsSlider setValue:2.0];
            
            filter = [[GPUImageBoxBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_MOTIONBLUR:
        {
            self.title = @"Motion Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:180.0f];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageMotionBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_ZOOMBLUR:
        {
            self.title = @"Zoom Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.5f];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageZoomBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE:
        {
            self.title = @"Selective Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:.75f];
            [self.filterSettingsSlider setValue:40.0/320.0];
            
            filter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            [(GPUImageGaussianSelectiveBlurFilter*)filter setExcludeCircleRadius:40.0/320.0];
        }; break;
        case GPUIMAGE_GAUSSIAN_POSITION:
        {
            self.title = @"Selective Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:.75f];
            [self.filterSettingsSlider setValue:40.0/320.0];
            
            filter = [[GPUImageGaussianBlurPositionFilter alloc] init];
            [(GPUImageGaussianBlurPositionFilter*)filter setBlurRadius:40.0/320.0];
        }; break;
        case GPUIMAGE_BILATERAL:
        {
            self.title = @"Bilateral Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:10.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageBilateralFilter alloc] init];
        }; break;
        case GPUIMAGE_FILTERGROUP:
        {
            self.title = @"Filter Group";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.3];
            
            filter = [[GPUImageFilterGroup alloc] init];
            
            GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
            [(GPUImageFilterGroup *)filter addFilter:sepiaFilter];
            
            GPUImagePixellateFilter *pixellateFilter = [[GPUImagePixellateFilter alloc] init];
            [(GPUImageFilterGroup *)filter addFilter:pixellateFilter];
            
            [sepiaFilter addTarget:pixellateFilter];
            [(GPUImageFilterGroup *)filter setInitialFilters:[NSArray arrayWithObject:sepiaFilter]];
            [(GPUImageFilterGroup *)filter setTerminalFilter:pixellateFilter];
        }; break;
            
        default: filter = [[GPUImageSepiaFilter alloc] init]; break;
    }
    [self changeFilter:filter];
}

#pragma mark -
#pragma mark Filter adjustments

- (IBAction)updateFilterFromSlider:(id)sender;
{
//    [videoCamera resetBenchmarkAverage];
    switch(filterType)
    {
        case GPUIMAGE_SEPIA: [(GPUImageSepiaFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PIXELLATE: [(GPUImagePixellateFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_POLARPIXELLATE: [(GPUImagePolarPixellateFilter *)filter setPixelSize:CGSizeMake([(UISlider *)sender value], [(UISlider *)sender value])]; break;
        case GPUIMAGE_POLKADOT: [(GPUImagePolkaDotFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HALFTONE: [(GPUImageHalftoneFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SATURATION: [(GPUImageSaturationFilter *)filter setSaturation:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CONTRAST: [(GPUImageContrastFilter *)filter setContrast:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BRIGHTNESS: [(GPUImageBrightnessFilter *)filter setBrightness:[(UISlider *)sender value]]; break;
        case GPUIMAGE_LEVELS: {
            float value = [(UISlider *)sender value];
            [(GPUImageLevelsFilter *)filter setRedMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            [(GPUImageLevelsFilter *)filter setGreenMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            [(GPUImageLevelsFilter *)filter setBlueMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
        }; break;
        case GPUIMAGE_EXPOSURE: [(GPUImageExposureFilter *)filter setExposure:[(UISlider *)sender value]]; break;
        case GPUIMAGE_MONOCHROME: [(GPUImageMonochromeFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_RGB: [(GPUImageRGBFilter *)filter setGreen:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HUE: [(GPUImageHueFilter *)filter setHue:[(UISlider *)sender value]]; break;
        case GPUIMAGE_WHITEBALANCE: [(GPUImageWhiteBalanceFilter *)filter setTemperature:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SHARPEN: [(GPUImageSharpenFilter *)filter setSharpness:[(UISlider *)sender value]]; break;
        case GPUIMAGE_UNSHARPMASK: [(GPUImageUnsharpMaskFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
            //        case GPUIMAGE_UNSHARPMASK: [(GPUImageUnsharpMaskFilter *)filter setBlurSize:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GAMMA: [(GPUImageGammaFilter *)filter setGamma:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CROSSHATCH: [(GPUImageCrosshatchFilter *)filter setCrossHatchSpacing:[(UISlider *)sender value]]; break;
        case GPUIMAGE_POSTERIZE: [(GPUImagePosterizeFilter *)filter setColorLevels:round([(UISlider*)sender value])]; break;
        case GPUIMAGE_HAZE: [(GPUImageHazeFilter *)filter setDistance:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SOBELEDGEDETECTION: [(GPUImageSobelEdgeDetectionFilter *)filter setEdgeStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PREWITTEDGEDETECTION: [(GPUImagePrewittEdgeDetectionFilter *)filter setEdgeStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SKETCH: [(GPUImageSketchFilter *)filter setEdgeStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_THRESHOLD: [(GPUImageLuminanceThresholdFilter *)filter setThreshold:[(UISlider *)sender value]]; break;
        case GPUIMAGE_ADAPTIVETHRESHOLD: [(GPUImageAdaptiveThresholdFilter *)filter setBlurRadiusInPixels:[(UISlider*)sender value]]; break;
        case GPUIMAGE_AVERAGELUMINANCETHRESHOLD: [(GPUImageAverageLuminanceThresholdFilter *)filter setThresholdMultiplier:[(UISlider *)sender value]]; break;
        case GPUIMAGE_LOWPASS: [(GPUImageLowPassFilter *)filter setFilterStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HIGHPASS: [(GPUImageHighPassFilter *)filter setFilterStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_MOTIONDETECTOR: [(GPUImageMotionDetector *)filter setLowPassFilterStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_KUWAHARA: [(GPUImageKuwaharaFilter *)filter setRadius:round([(UISlider *)sender value])]; break;
        case GPUIMAGE_SWIRL: [(GPUImageSwirlFilter *)filter setAngle:[(UISlider *)sender value]]; break;
        case GPUIMAGE_EMBOSS: [(GPUImageEmbossFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CANNYEDGEDETECTION: [(GPUImageCannyEdgeDetectionFilter *)filter setBlurTexelSpacingMultiplier:[(UISlider*)sender value]]; break;
            //        case GPUIMAGE_CANNYEDGEDETECTION: [(GPUImageCannyEdgeDetectionFilter *)filter setLowerThreshold:[(UISlider*)sender value]]; break;
        case GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR: [(GPUImageHoughTransformLineDetector *)filter setLineDetectionThreshold:[(UISlider*)sender value]]; break;
            //        case GPUIMAGE_HARRISCORNERDETECTION: [(GPUImageHarrisCornerDetectionFilter *)filter setSensitivity:[(UISlider*)sender value]]; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION: [(GPUImageThresholdEdgeDetectionFilter *)filter setThreshold:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SMOOTHTOON: [(GPUImageSmoothToonFilter *)filter setBlurRadiusInPixels:[(UISlider*)sender value]]; break;
        case GPUIMAGE_THRESHOLDSKETCH: [(GPUImageThresholdSketchFilter *)filter setThreshold:[(UISlider *)sender value]]; break;
            //        case GPUIMAGE_BULGE: [(GPUImageBulgeDistortionFilter *)filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BULGE: [(GPUImageBulgeDistortionFilter *)filter setScale:[(UISlider *)sender value]]; break;
        case GPUIMAGE_TONECURVE: [(GPUImageToneCurveFilter *)filter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, [(UISlider *)sender value])], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]]; break;
        case GPUIMAGE_HIGHLIGHTSHADOW: [(GPUImageHighlightShadowFilter *)filter setHighlights:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PINCH: [(GPUImagePinchDistortionFilter *)filter setScale:[(UISlider *)sender value]]; break;
//        case GPUIMAGE_MOSAIC:  [(GPUImageMosaicFilter *)filter setDisplayTileSize:CGSizeMake([(UISlider *)sender value], [(UISlider *)sender value])]; break;
        case GPUIMAGE_VIGNETTE: [(GPUImageVignetteFilter *)filter setVignetteEnd:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BOXBLUR: [(GPUImageBoxBlurFilter *)filter setBlurRadiusInPixels:[(UISlider*)sender value]]; break;
        case GPUIMAGE_GAUSSIAN: [(GPUImageGaussianBlurFilter *)filter setBlurRadiusInPixels:[(UISlider*)sender value]]; break;
            //        case GPUIMAGE_GAUSSIAN: [(GPUImageGaussianBlurFilter *)filter setBlurPasses:round([(UISlider*)sender value])]; break;
            //        case GPUIMAGE_BILATERAL: [(GPUImageBilateralFilter *)filter setBlurSize:[(UISlider*)sender value]]; break;
        case GPUIMAGE_BILATERAL: [(GPUImageBilateralFilter *)filter setDistanceNormalizationFactor:[(UISlider*)sender value]]; break;
        case GPUIMAGE_MOTIONBLUR: [(GPUImageMotionBlurFilter *)filter setBlurAngle:[(UISlider*)sender value]]; break;
        case GPUIMAGE_ZOOMBLUR: [(GPUImageZoomBlurFilter *)filter setBlurSize:[(UISlider*)sender value]]; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE: [(GPUImageGaussianSelectiveBlurFilter *)filter setExcludeCircleRadius:[(UISlider*)sender value]]; break;
        case GPUIMAGE_GAUSSIAN_POSITION: [(GPUImageGaussianBlurPositionFilter *)filter setBlurRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_FILTERGROUP: [(GPUImagePixellateFilter *)[(GPUImageFilterGroup *)filter filterAtIndex:1] setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_TILTSHIFT:
        {
            CGFloat midpoint = [(UISlider *)sender value];
            [(GPUImageTiltShiftFilter *)filter setTopFocusLevel:midpoint - 0.1];
            [(GPUImageTiltShiftFilter *)filter setBottomFocusLevel:midpoint + 0.1];
        }; break;
        case GPUIMAGE_LOCALBINARYPATTERN:
        {
            CGFloat multiplier = [(UISlider *)sender value];
            [(GPUImageLocalBinaryPatternFilter *)filter setTexelWidth:(multiplier / self.view.bounds.size.width)];
            [(GPUImageLocalBinaryPatternFilter *)filter setTexelHeight:(multiplier / self.view.bounds.size.height)];
        }; break;
        default: break;
    }
     [stillImageSource processImage];
}


- (void)cameraViewTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        CGPoint location = [tgr locationInView:self.filterView];
        CGPoint pointOfInterest = CGPointMake(.5f, .5f);
        //        NSLog(@"taplocation x = %f y = %f", location.x, location.y);
        CGSize frameSize = [[self filterView] frame].size;
        
        if ([videoCamera cameraPosition] == AVCaptureDevicePositionFront) {
            location.x = frameSize.width - location.x;
        }
        
        pointOfInterest = CGPointMake(location.y / frameSize.height, 1.f - (location.x / frameSize.width));
        touchView.hidden = YES;
        touchView = [[UIView alloc] init];
        [touchView setBackgroundColor:[UIColor clearColor]];
        touchView.frame = CGRectMake(location.x-75, location.y-75, 150, 150);
        touchView.layer.borderColor = [UIColor yellowColor].CGColor;
        touchView.layer.borderWidth = 1.0f;
        [self.view addSubview:touchView];
        [UIView animateWithDuration:0.1 delay:0.2 options:0 animations:^{
            touchView.frame = CGRectMake(location.x-50, location.y-50, 100, 100);
        }completion:^(BOOL finished) {
            touchView.frame = CGRectMake(location.x-50, location.y-50, 100, 100);
        }];
        [UIView animateWithDuration:0.3 delay:1 options:0 animations:^{
            touchView.alpha = 0;
        } completion:^(BOOL finished) {
            touchView.hidden = YES;
        }];

        if ([videoCamera.inputCamera isFocusPointOfInterestSupported] && [videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            NSError *error;
            if ([videoCamera.inputCamera lockForConfiguration:&error]) {
                [videoCamera.inputCamera setFocusPointOfInterest:pointOfInterest];
                [videoCamera.inputCamera setFocusMode:AVCaptureFocusModeAutoFocus];
                [videoCamera.inputCamera setExposurePointOfInterest:pointOfInterest];
                [videoCamera.inputCamera setExposureMode:AVCaptureExposureModeAutoExpose];
                [videoCamera.inputCamera unlockForConfiguration];
            }
        }
        if ([videoCamera.inputCamera isFocusPointOfInterestSupported] && [videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        {
            NSError *error;
            if ([videoCamera.inputCamera lockForConfiguration:&error]) {
                [videoCamera.inputCamera setFocusPointOfInterest:pointOfInterest];
                [videoCamera.inputCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                [videoCamera.inputCamera setExposurePointOfInterest:pointOfInterest];
                [videoCamera.inputCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                [videoCamera.inputCamera unlockForConfiguration];
            }
        }
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"gotoShareVC"])
    {
        // Get reference to the destination view controller
        ShareVC *vc = [segue destinationViewController];
        vc.image = [filter imageByFilteringImage:origonalImage];
        // Pass any objects to the view controller here, like...
        
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@synthesize filterSettingsSlider = _filterSettingsSlider;
# pragma mark - imagePicker Delegate method
// For responding to the user tapping Cancel.
- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    self.imagePicker =nil;
}

// For responding to the user accepting a newly-captured picture or movie
- (void) imagePickerController: (UIImagePickerController *) picker
 didFinishPickingMediaWithInfo: (NSDictionary *) info {
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *resultImage;
    
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0)
        == kCFCompareEqualTo) {
        
        editedImage = (UIImage *) [info objectForKey:
                                   UIImagePickerControllerEditedImage];
        originalImage = (UIImage *) [info objectForKey:
                                     UIImagePickerControllerOriginalImage];
        
        if (editedImage) {
            resultImage = editedImage;
        } else {
            resultImage = originalImage;
        }
    }
    captureImage = resultImage;
    origonalImage = captureImage;
    self.filterView.hidden = YES;
    filter = [[GPUImageFilter alloc]init];
    [self changeFilter:filter];
    self.filterSettingsSlider.hidden = YES;
    [self showHideAfterClickView];
    [self showhideAdview];
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    self.imagePicker = nil;
}

#pragma mark - Action Sheet 

-(void)setUpActionSheet {
    actionSheet = [UIAlertController
                                alertControllerWithTitle:nil      //  Must be "nil", otherwise a blank title area will appear above our two buttons
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* button0 = [UIAlertAction
                              actionWithTitle:@"Cancel"
                              style:UIAlertActionStyleCancel
                              handler:^(UIAlertAction * action)
                              {
                                  //  UIAlertController will automatically dismiss the view
                              }];
    
    UIAlertAction* button1 = [UIAlertAction
                              actionWithTitle:@"Save on Gallery"
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  UIImageWriteToSavedPhotosAlbum([filter imageByFilteringImage:origonalImage],
                                                                 self, // send the message to 'self' when calling the callback
                                                                 @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                                                 NULL); // you generally won't need a contextInfo here
                                  [self goBack];
                              }];
    
    UIAlertAction* button2 = [UIAlertAction
                              actionWithTitle:@"Share"
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  [self performSegueWithIdentifier:@"gotoShareVC" sender:action];
                              }];
    
    [actionSheet addAction:button0];
    [actionSheet addAction:button1];
    [actionSheet addAction:button2];
}

-(void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo {
    if (error) {
        // Do anything needed to handle the error or display it to the user
    } else {
        printf("image saved");
        // .... do anything you want here to handle
        // .... when the image has been saved in the photo album
    }
}
@end
