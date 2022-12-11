#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Removes any values which would be rejected by NSJSONSerialization for
 documented reasons or is NSNull

 @param input a dictionary
 @return a new dictionary
 */
NSMutableDictionary * BSGSanitizeDict(NSDictionary *input);

/**
 Cleans the object, including nested dictionary and array values

 @param obj any object or nil
 @return a new object for serialization or nil if the obj was incompatible or NSNull
 */
id _Nullable BSGSanitizeObject(id _Nullable obj);

typedef struct _BSGTruncateContext {
    NSUInteger maxLength;
    NSUInteger strings;
    NSUInteger length;
} BSGTruncateContext;

NSString * BSGTruncateString(BSGTruncateContext *context, NSString *_Nullable string);

id BSGTruncateStrings(BSGTruncateContext *context, id object);

NS_ASSUME_NONNULL_END
