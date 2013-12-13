//
//  AbstractComment.m
//  WordPress
//
//  Created by Eric J on 3/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "AbstractComment.h"
#import "NSString+XMLExtensions.h"


@implementation AbstractComment

@dynamic author;
@dynamic author_email;
@dynamic author_ip;
@dynamic author_url;
@dynamic commentID;
@dynamic content;
@dynamic dateCreated;
@dynamic link;
@dynamic parentID;
@dynamic postID;
@dynamic postTitle;
@dynamic status;
@dynamic type;


#pragma mark - WPContentViewProvider protocol

- (NSString *)titleForDisplay {
    return self.postTitle;
}

- (NSString *)authorForDisplay {
    return [self.author length] > 0 ? [[self.author stringByDecodingXMLCharacters] trim] : [self.author_email trim];
}

- (NSString *)blogNameForDisplay {
    return nil;
}

- (NSString *)statusForDisplay {
    return nil;
}

- (NSString *)contentForDisplay {
    return [self.content stringByDecodingXMLCharacters];
}

- (NSString *)contentPreviewForDisplay {
    return [self.content stringByDecodingXMLCharacters];
}
- (NSURL *)blavatarURLForDisplay {
    return nil;
}

- (NSString *)gravatarEmailForDisplay {
    return [self.author_email trim];
}

- (NSDate *)dateForDisplay {
    return self.dateCreated;
}


@end
