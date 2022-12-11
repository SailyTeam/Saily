#import "BSGSerialization.h"

#import "BSGJSONSerialization.h"
#import "BugsnagLogger.h"

static NSArray * BSGSanitizeArray(NSArray *input);

id BSGSanitizeObject(id obj) {
    if ([obj isKindOfClass:[NSArray class]]) {
        return BSGSanitizeArray(obj);
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        return BSGSanitizeDict(obj);
    } else if ([obj isKindOfClass:[NSString class]]) {
        return obj;
    } else if ([obj isKindOfClass:[NSNumber class]]
               && ![obj isEqualToNumber:[NSDecimalNumber notANumber]]
               && !isinf([obj doubleValue])) {
        return obj;
    }
    return nil;
}

NSMutableDictionary * BSGSanitizeDict(NSDictionary *input) {
    __block NSMutableDictionary *output =
        [NSMutableDictionary dictionaryWithCapacity:[input count]];
    [input enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj,
                                               __unused BOOL *_Nonnull stop) {
      if ([key isKindOfClass:[NSString class]]) {
          id cleanedObject = BSGSanitizeObject(obj);
          if (cleanedObject)
              output[key] = cleanedObject;
      }
    }];
    return output;
}

static NSArray * BSGSanitizeArray(NSArray *input) {
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:[input count]];
    for (id obj in input) {
        id cleanedObject = BSGSanitizeObject(obj);
        if (cleanedObject)
            [output addObject:cleanedObject];
    }
    return output;
}

NSString * BSGTruncateString(BSGTruncateContext *context, NSString *string) {
    const NSUInteger inputLength = string.length;
    if (inputLength <= context->maxLength) return string;
    // Prevent chopping in the middle of a composed character sequence
    NSRange range = [string rangeOfComposedCharacterSequenceAtIndex:context->maxLength];
    NSString *output = [string substringToIndex:range.location];
    NSUInteger count = inputLength - range.location;
    context->strings++;
    context->length += count;
    return [output stringByAppendingFormat:@"\n***%lu CHARS TRUNCATED***", (unsigned long)count];
}

id BSGTruncateStrings(BSGTruncateContext *context, id object) {
    if ([object isKindOfClass:[NSString class]]) {
        return BSGTruncateString(context, object);
    }
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *output = [NSMutableDictionary dictionaryWithCapacity:((NSDictionary *)object).count];
        for (NSString *key in (NSDictionary *)object) {
            id value = ((NSDictionary *)object)[key];
            output[key] = BSGTruncateStrings(context, value);
        }
        return output;
    }
    if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *output = [NSMutableArray arrayWithCapacity:((NSArray *)object).count];
        for (id element in (NSArray *)object) {
            [output addObject:BSGTruncateStrings(context, element)];
        }
        return output;
    }
    return object;
}
