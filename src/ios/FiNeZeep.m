#import <Cordova/CDV.h>
#import "CDVFile.h"
#import "FiNeZeep.h"

@interface FiNeZeep : CDVPlugin
@end

@implementation FiNeZeep

- (NSString *)pathForURL:(NSString *)urlString {
    NSString *path = nil;
    id filePlugin = [self.commandDelegate getCommandInstance:@"File"];
    if (filePlugin != nil) {
        CDVFilesystemURL *url = [CDVFilesystemURL fileSystemURLWithString:urlString];
        path = [filePlugin filesystemPathForURL:url];
    }
    if (!path && [urlString hasPrefix:@"file:"]) {
        path = [[NSURL URLWithString:urlString] path];
    }
    return path;
}

- (void)zip:(CDVInvokedUrlCommand *)command {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *fromPath = [self pathForURL:[command.arguments objectAtIndex:0]];
        NSString *toPath   = [self pathForURL:[command.arguments objectAtIndex:1]];

        BOOL success = [SSZipArchive createZipFileAtPath:toPath
                                 withContentsOfDirectory:fromPath
                                     keepParentDirectory:NO
                                           withPassword:nil];

        CDVPluginResult *pluginResult = success
            ? [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"✅ zip completed"]
            : [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"❌ zip failed"];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    });
}

- (void)unzip:(CDVInvokedUrlCommand *)command {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *fromPath = [self pathForURL:[command.arguments objectAtIndex:0]];
        NSString *toPath   = [self pathForURL:[command.arguments objectAtIndex:1]];

        NSError *error = nil;
        BOOL success = [SSZipArchive unzipFileAtPath:fromPath
                                        toDestination:toPath
                                            overwrite:YES
                                             password:nil
                                                error:&error
                                             delegate:nil];

        CDVPluginResult *pluginResult = success
            ? [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"✅ unzip completed"]
            : [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"❌ unzip failed: %@", error.localizedDescription ?: @"Unknown error"]];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    });
}

@end
