#import "Comment.h"
#import "ContextManager.h"
#import "Blog.h"
#import "BasePost.h"
#import "WordPress-Swift.h"


@implementation Comment

@dynamic blog;
@dynamic post;
@dynamic author;
@dynamic author_email;
@dynamic author_ip;
@dynamic author_url;
@dynamic authorAvatarURL;
@dynamic commentID;
@dynamic content;
@dynamic dateCreated;
@dynamic depth;
@dynamic hierarchy;
@dynamic link;
@dynamic parentID;
@dynamic postID;
@dynamic postTitle;
@dynamic status;
@dynamic type;
@dynamic isLiked;
@dynamic likeCount;
@dynamic canModerate;
@synthesize isNew;
@synthesize attributedContent;

#pragma mark - Helper methods

+ (NSString *)titleForStatus:(NSString *)status
{
    if ([status isEqualToString:[Comment descriptionFor:CommentStatusTypePending]]) {
        return NSLocalizedString(@"Pending moderation", @"Comment status");
    } else if ([status isEqualToString:[Comment descriptionFor:CommentStatusTypeApproved]]) {
        return NSLocalizedString(@"Comments", @"Comment status");
    }

    return status;
}

- (NSString *)postTitle
{
    NSString *title = nil;
    if (self.post) {
        title = self.post.postTitle;
    } else {
        [self willAccessValueForKey:@"postTitle"];
        title = [self primitiveValueForKey:@"postTitle"];
        [self didAccessValueForKey:@"postTitle"];
    }

    if (title == nil || [@"" isEqualToString:title]) {
        title = NSLocalizedString(@"(no title)", @"the post has no title.");
    }
    return title;

}

- (NSDate *)dateCreated
{
    NSDate *date = nil;

    [self willAccessValueForKey:@"dateCreated"];
    date = [self primitiveValueForKey:@"dateCreated"];
    [self didAccessValueForKey:@"dateCreated"];

    return date;
}

- (NSString *)sectionIdentifier
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterLongStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;
    return [formatter stringFromDate:self.dateCreated];
}

- (BOOL)isPrivateContent
{
    if ([self.post respondsToSelector:@selector(isPrivateAtWPCom)]) {
        return (BOOL)[self.post performSelector:@selector(isPrivateAtWPCom)];
    }
    return NO;
}

- (NSString *)authorUrlForDisplay
{
    return self.author_url.hostname;
}

- (BOOL)hasAuthorUrl
{
    return self.author_url && ![self.author_url isEqualToString:@""];
}

- (BOOL)isApproved
{
    return [self.status isEqualToString:[Comment descriptionFor:CommentStatusTypeApproved]];
}

- (BOOL)isReadOnly
{
    // If the current user cannot moderate the comment, they can only Like and Reply if the comment is Approved.
    if ((self.blog.isHostedAtWPcom || self.blog.isAtomic)
        && !self.canModerate && !self.isApproved) {
        return YES;
    }

    return NO;
}

- (BOOL)authorIsPostAuthor
{
    return [[self authorURL] isEqual:[self.post authorURL]];
}

- (NSNumber *)numberOfLikes
{
    return self.likeCount ?: @(0);
}

@end
