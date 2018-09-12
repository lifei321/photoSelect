//
//  PHPhotoLibrary+RITLPhotoStore.m
//  RITLPhotoDemo
//
//  Created by YueWen on 2018/3/7.
//  Copyright © 2018年 YueWen. All rights reserved.
//

#import "PHPhotoLibrary+RITLPhotoStore.h"
#import "PHFetchResult+RITLPhotos.h"
#import <RITLKit/RITLKit.h>

@implementation PHPhotoLibrary (RITLPhotoStore)


- (void)fetchAlbumRegularGroupsByUserLibrary:(void (^)(NSArray<PHAssetCollection *> * _Nonnull))complete
{
    [self fetchAlbumRegularGroups:^(NSArray<PHAssetCollection *> * _Nonnull collections) {
        
        //进行排序
        NSMutableArray <PHAssetCollection *> *sortCollections = [NSMutableArray new];

        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        
        // option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:self.sortAscendingByModificationDate]];
        //        fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.sortAscendingByModificationDate]];
        
        for (PHAssetCollection *collection in collections) {
            // 有可能是PHCollectionList类的的对象，过滤掉
            if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:fetchOptions];
            if (fetchResult.count < 1) continue;
            if ([collection.localizedTitle containsString:@"Deleted"] || [collection.localizedTitle isEqualToString:@"最近删除"]) continue;
            if ([self isCameraRollAlbum:collection.localizedTitle]) {
                [sortCollections insertObject:collection atIndex:0];
            } else {
                [sortCollections addObject:collection];
            }
        }
        
        //选出对象
        PHAssetCollection *userLibrary = [sortCollections ritl_filter:^BOOL(PHAssetCollection * _Nonnull item) {
            
            return (item.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary);
            
        }].ritl_safeFirstObject;
        
        if (userLibrary) {
            
            //进行变换
            [sortCollections removeObject:userLibrary];
            [sortCollections insertObject:userLibrary atIndex:0];
        }
        
        complete([sortCollections ritl_filter:^BOOL(PHAssetCollection * _Nonnull item) {
            
            PHAssetCollectionSubtype subType = item.assetCollectionSubtype;
            
            //取出不需要的数据
            return !(subType == PHAssetCollectionSubtypeSmartAlbumAllHidden || [item.localizedTitle isEqualToString:NSLocalizedString(@"Recently Deleted", @"")]);
        }]);
    }];
}

- (BOOL)isCameraRollAlbum:(NSString *)albumName {
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length <= 1) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length <= 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    // 目前已知8.0.0 - 8.0.2系统，拍照后的图片会保存在最近添加中
    if (version >= 800 && version <= 802) {
        return [albumName isEqualToString:@"最近添加"] || [albumName isEqualToString:@"Recently Added"];
    } else {
        return [albumName isEqualToString:@"Camera Roll"] || [albumName isEqualToString:@"相机胶卷"] || [albumName isEqualToString:@"所有照片"] || [albumName isEqualToString:@"All Photos"];
    }
}

- (void)fetchAlbumRegularGroups:(void (^)(NSArray<PHAssetCollection *> * _Nonnull))complete
{
    [self.class handlerWithAuthorizationAllow:^{
        
        // 我的照片流 1.6.10重新加入..
        PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
        PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
        NSArray *allAlbums = @[myPhotoStreamAlbum,smartAlbums,topLevelUserCollections,syncedAlbums,sharedAlbums];
        NSMutableArray *albumArr = [NSMutableArray array];
        
        for (PHFetchResult *fetchResult in allAlbums) {
            
            [fetchResult transToArrayComplete:^(NSArray<id> * _Nonnull group, PHFetchResult * _Nonnull result) {
                [albumArr addObjectsFromArray:group];
            }];
        }
        
        complete(albumArr);
    }];
}

#pragma mark - 进行权限检测后的操作

///
+ (void)handlerWithAuthorizationAllow:(void(^)(void))hander
{
    [self authorizationStatusAllow:^{
        
        hander();
        
    } denied:^{}];
}

#pragma mark - 权限检测
+ (void)authorizationStatusAllow:(void(^)(void))allowHander denied:(void(^)(void))deniedHander
{
    switch (PHPhotoLibrary.authorizationStatus)
    {
            //准许
        case PHAuthorizationStatusAuthorized: allowHander(); break;
            
            //待获取
        case PHAuthorizationStatusNotDetermined:
        {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (status == PHAuthorizationStatusAuthorized) { allowHander(); }//允许，进行回调
                    else { deniedHander(); }
                });
            }];
        } break;
            
            //不允许,进行无权限回调
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted: deniedHander(); break;
    }
}


@end
