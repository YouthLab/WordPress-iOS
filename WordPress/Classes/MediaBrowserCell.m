/*
 * MediaBrowserCell.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "MediaBrowserCell.h"
#import "Media.h"
#import "WPImageSource.h"
#import "UIImage+Resize.h"

@interface WPImageSource (Media)

- (void)downloadThumbnailForMedia:(Media*)media success:(void (^)(NSNumber *mediaId))success failure:(void (^)(NSError *error))failure;

@end

@interface MediaBrowserCell ()

@property (nonatomic, weak) UIImageView *thumbnail;
@property (nonatomic, weak) UILabel *title;
@property (nonatomic, weak) UIButton *checkbox;

@end

@implementation MediaBrowserCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        BOOL isRetina = [[UIApplication sharedApplication] respondsToSelector:@selector(scale)];
        self.contentView.layer.borderWidth = isRetina ? 0.5f : 1.0f;
        self.contentView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        self.contentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        
        UIImageView *thumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, IS_IPAD ? 200 : 145)];
        _thumbnail = thumbnail;
        [_thumbnail setContentMode:UIViewContentModeCenter];
        [self.contentView addSubview:_thumbnail];
        
        // With enlarged touch area
        UIButton *checkbox = [[UIButton alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 37.0f, 0, 37.0f, 37.0f)];
        _checkbox = checkbox;
        [_checkbox addTarget:self action:@selector(checkboxPressed) forControlEvents:UIControlEventTouchUpInside];
        [_checkbox setImage:[UIImage imageNamed:@"media_checkbox_empty"] forState:UIControlStateNormal];
        [_checkbox setImage:[UIImage imageNamed:@"media_checkbox_filled"] forState:UIControlStateHighlighted];
        [self.contentView addSubview:_checkbox];
        
        UIView *titleContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.thumbnail.frame), self.contentView.bounds.size.width, 20.0f)];
        titleContainer.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        [self.contentView addSubview:titleContainer];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(3, 0, titleContainer.frame.size.width-6, titleContainer.frame.size.height)];
        _title = title;
        _title.backgroundColor = [UIColor clearColor]; 
        _title.textColor = [UIColor whiteColor];
        _title.lineBreakMode = NSLineBreakByTruncatingTail;
        _title.font = [WPStyleGuide subtitleFont];
        [titleContainer addSubview:_title];
    }
    return self;
}

- (void)setIsSelected:(BOOL *)isSelected {
    _isSelected = isSelected;
    
    if (_isSelected) {
        [_checkbox setImage:[UIImage imageNamed:@"media_checkbox_filled"] forState:UIControlStateNormal];
    } else {
        [_checkbox setImage:[UIImage imageNamed:@"media_checkbox_empty"] forState:UIControlStateNormal];
    }
}

- (void)checkboxPressed {
    self.isSelected = !_isSelected;
    if (_isSelected) {
        [_delegate mediaCellSelected:self.media];
    } else {
        [_delegate mediaCellDeselected:self.media];
    }
}

- (void)prepareForReuse {
    self.thumbnail.image = nil;
    self.isSelected = false;
    if (!_thumbnail.image) {
        _thumbnail.contentMode = UIViewContentModeCenter;
    }
}

- (void)setMedia:(Media *)media {
    _media = media;
    self.title.text = _media.title;
    
    if (_media.thumbnail.length > 0) {
        _thumbnail.image = [UIImage imageWithData:_media.thumbnail];
        _thumbnail.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        if (_media.remoteURL && [_media.mediaType isEqualToString:@"image"]) {
            [_thumbnail setImage:[UIImage imageNamed:@"media_image_placeholder"]];
            [[WPImageSource sharedSource] downloadThumbnailForMedia:_media success:^(NSNumber *mediaId){
                if ([mediaId isEqualToNumber:_media.mediaID]) {
                    _thumbnail.contentMode = UIViewContentModeScaleAspectFit;
                    _thumbnail.image = [UIImage imageWithData:_media.thumbnail];
                }
            } failure:^(NSError *error) {
                WPFLog(@"Failed to download thumbnail for media %@: %@", _media.remoteURL, error);
            }];
        } else {
            _thumbnail.contentMode = UIViewContentModeCenter;
            if ([_media.mediaType isEqualToString:@"movie"]) {
                [_thumbnail setImage:[UIImage imageNamed:@"media_movieclip"]];
            } else {
                [_thumbnail setImage:[UIImage imageNamed:@"media_image_placeholder"]];
            }
        }
    }
}

@end

@implementation WPImageSource (Media)

- (void)downloadThumbnailForMedia:(Media*)media success:(void (^)(NSNumber *mediaId))success failure:(void (^)(NSError *))failure {
    NSURL *thumbnailUrl = [NSURL URLWithString:[media.remoteURL stringByAppendingString:@"?w=145"]];
    [self downloadImageForURL:thumbnailUrl withSuccess:^(UIImage *image) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *thumbnail = image;
            if (thumbnail.size.width > 145 || thumbnail.size.height > 145) {
                thumbnail = [image thumbnailImage:145 transparentBorder:0 cornerRadius:0 interpolationQuality:0.9];
            }
            __block NSData *thumbnailData = UIImageJPEGRepresentation(thumbnail, 0.90);
            dispatch_async(dispatch_get_main_queue(), ^{
                media.thumbnail = thumbnailData;
                success(media.mediaID);
            });
        });
        
    } failure:failure];
}

@end