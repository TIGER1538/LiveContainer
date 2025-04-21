#import <Foundation/Foundation.h>

typedef void (^LCParseMachOCallback)(const char *path, struct mach_header_64 *header, int fd, void* filePtr);

typedef NS_ENUM(NSInteger, Store){
    SideStore = 0,
    AltStore = 1,
    Unknown = -1
};

NSString *LCParseMachO(const char *path, bool readOnly, LCParseMachOCallback callback);
void LCPatchAddRPath(const char *path, struct mach_header_64 *header);
void LCPatchExecSlice(const char *path, struct mach_header_64 *header, bool doInject);
void LCPatchLibrary(const char *path, struct mach_header_64 *header);
void LCChangeExecUUID(struct mach_header_64 *header);
void LCPatchAltStore(const char *path, struct mach_header_64 *header);
NSString* getEntitlementXML(struct mach_header_64* header, void** entitlementXMLPtrOut);
NSString* getLCEntitlementXML(void);
bool checkCodeSignature(const char* path);
void refreshFile(NSString* execPath);

@interface PKZipArchiver : NSObject

- (NSData *)zippedDataForURL:(NSURL *)url;

@end

@interface LCUtils : NSObject

+ (void)validateJITLessSetupWithCompletionHandler:(void (^)(BOOL success, NSError *error))completionHandler;
+ (NSURL *)archiveIPAWithBundleName:(NSString*)newBundleName error:(NSError **)error;
+ (NSURL *)archiveTweakedAltStoreWithError:(NSError **)error;
+ (NSData *)certificateData;
+ (NSString *)certificatePassword;

+ (BOOL)launchToGuestApp;
+ (BOOL)launchToGuestAppWithURL:(NSURL *)url;

+ (NSProgress *)signAppBundleWithZSign:(NSURL *)path completionHandler:(void (^)(BOOL success, NSError *error))completionHandler;
+ (NSString*)getCertTeamIdWithKeyData:(NSData*)keyData password:(NSString*)password;
+ (int)validateCertificateWithCompletionHandler:(void(^)(int status, NSDate *expirationDate, NSString *error))completionHandler;

+ (BOOL)isAppGroupAltStoreLike;
+ (Store)store;
+ (NSString *)teamIdentifier;
+ (NSString *)appGroupID;
+ (NSString *)appUrlScheme;
+ (NSURL *)appGroupPath;
+ (NSString *)storeInstallURLScheme;
+ (NSString *)getVersionInfo;
@end

