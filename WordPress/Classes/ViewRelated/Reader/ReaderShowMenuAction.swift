import UIKit
/// Encapsulates a command to create and handle the extended menu for each post in Reader
final class ReaderShowMenuAction {
    private let isLoggedIn: Bool

    init(loggedIn: Bool) {
        isLoggedIn = loggedIn
    }

    func execute(with post: ReaderPost,
                 context: NSManagedObjectContext,
                 siteTopic: ReaderSiteTopic? = nil,
                 readerTopic: ReaderAbstractTopic? = nil,
                 anchor: UIView,
                 vc: UIViewController,
                 source: ReaderPostMenuSource,
                 followCommentsService: FollowCommentsService
    ) {

        // Create the action sheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addCancelActionWithTitle(ReaderPostMenuButtonTitles.cancel, handler: nil)


        // Block site button
        if shouldShowBlockSiteMenuItem(readerTopic: readerTopic, post: post) {
            let handler: (UIAlertAction) -> Void = { action in
                guard let post: ReaderPost = ReaderActionHelpers.existingObject(for: post.objectID, in: context) else {
                    return
                }
                self.postSiteBlockingWillBeginNotification(post)
                ReaderBlockSiteAction(asBlocked: true).execute(with: post, context: context, completion: {
                    ReaderHelpers.dispatchSiteBlockedMessage(post: post, success: true)
                    self.postSiteBlockingDidFinish(post)
                },
                failure: { error in
                    ReaderHelpers.dispatchSiteBlockedMessage(post: post, success: false)
                    self.postSiteBlockingDidFail(post, error: error)
                })
            }
            alertController.addActionWithTitle(ReaderPostMenuButtonTitles.blockSite,
                                               style: .destructive,
                                               handler: handler)
        }

        if shouldShowBlockUserMenuItem(post: post) {
            // Block user button
            alertController.addActionWithTitle(
                ReaderPostMenuButtonTitles.blockUser,
                style: .destructive,
                handler: { (action: UIAlertAction) in
                    if let post: ReaderPost = ReaderActionHelpers.existingObject(for: post.objectID, in: context) {
                        ReaderBlockUserAction(asBlocked: true).execute(with: post, context: context, completion: {
                            ReaderHelpers.dispatchUserBlockedMessage(post: post, success: true)

                            // Notify Reader Cards Stream so the post card is updated.
                            NotificationCenter.default.post(
                                name: .ReaderUserBlocked,
                                object: nil,
                                userInfo: [ReaderNotificationKeys.post: post]
                            )
                        }, failure: { _ in
                            ReaderHelpers.dispatchUserBlockedMessage(post: post, success: false)
                        })
                    }
                }
            )
        }

        // Report button
        if shouldShowReportPostMenuItem(readerTopic: readerTopic, post: post) {
            alertController.addActionWithTitle(ReaderPostMenuButtonTitles.reportPost,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in
                                                if let post: ReaderPost = ReaderActionHelpers.existingObject(for: post.objectID, in: context) {
                                                    ReaderReportPostAction().execute(with: post, context: context, origin: vc)
                                                }
            })
        }

        // Notification
        if let siteTopic = siteTopic, isLoggedIn, post.isFollowing {
            let isSubscribedForPostNotifications = siteTopic.isSubscribedForPostNotifications
            let buttonTitle = isSubscribedForPostNotifications ? ReaderPostMenuButtonTitles.unsubscribe : ReaderPostMenuButtonTitles.subscribe
            alertController.addActionWithTitle(buttonTitle,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in
                                                if let topic: ReaderSiteTopic = ReaderActionHelpers.existingObject(for: siteTopic.objectID, in: context) {
                                                    let subscribe = !topic.isSubscribedForPostNotifications

                                                    ReaderSubscribingNotificationAction().execute(for: topic.siteID, context: context, subscribe: subscribe, completion: {
                                                        ReaderHelpers.dispatchToggleNotificationMessage(topic: topic, success: true)
                                                    }, failure: { _ in
                                                        ReaderHelpers.dispatchToggleNotificationMessage(topic: topic, success: false)
                                                    })
                                                }
                                               })
        }

        // Following
        if isLoggedIn {
            let buttonTitle = post.isFollowing ? ReaderPostMenuButtonTitles.unfollow : ReaderPostMenuButtonTitles.follow

            alertController.addActionWithTitle(buttonTitle,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in
                                                if let post: ReaderPost = ReaderActionHelpers.existingObject(for: post.objectID, in: context) {
                                                    ReaderFollowAction().execute(with: post,
                                                                                 context: context,
                                                                                 completion: { follow in
                                                                                    ReaderHelpers.dispatchToggleFollowSiteMessage(post: post, follow: follow, success: true)
                                                                                    (vc as? ReaderStreamViewController)?.updateStreamHeaderIfNeeded()
                                                                                 }, failure: { follow, _ in
                                                                                    ReaderHelpers.dispatchToggleFollowSiteMessage(post: post, follow: follow, success: false)
                                                                                 })
                                                }
                                               })
        }

        // Seen
        if post.isSeenSupported {
            alertController.addActionWithTitle(post.isSeen ? ReaderPostMenuButtonTitles.markUnseen : ReaderPostMenuButtonTitles.markSeen,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in

                                                let event: WPAnalyticsEvent = post.isSeen ? .readerPostMarkUnseen : .readerPostMarkSeen
                                                WPAnalytics.track(event, properties: ["source": source.description])

                                                if let post: ReaderPost = ReaderActionHelpers.existingObject(for: post.objectID, in: context) {
                                                    ReaderSeenAction().execute(with: post, context: context, completion: {
                                                        ReaderHelpers.dispatchToggleSeenMessage(post: post, success: true)

                                                        // Notify Reader Stream so the post card is updated.
                                                        NotificationCenter.default.post(name: .ReaderPostSeenToggled,
                                                                                        object: nil,
                                                                                        userInfo: [ReaderNotificationKeys.post: post])
                                                    },
                                                    failure: { _ in
                                                        ReaderHelpers.dispatchToggleSeenMessage(post: post, success: false)
                                                    })
                                                }
                                               })
        }

        // Visit
        alertController.addActionWithTitle(ReaderPostMenuButtonTitles.visit,
                                           style: .default,
                                           handler: { (action: UIAlertAction) in
                                            ReaderVisitSiteAction().execute(with: post, context: context, origin: vc)
        })

        // Share
        alertController.addActionWithTitle(ReaderPostMenuButtonTitles.share,
                                           style: .default,
                                           handler: { (action: UIAlertAction) in
                                            ReaderShareAction().execute(with: post, context: context, anchor: anchor, vc: vc)
        })

        // Comment Subscription (Follow Comments by Email & Notifications)
        if post.canSubscribeComments {
            let buttonTitle = post.isSubscribedComments ? ReaderPostMenuButtonTitles.unFollowConversation : ReaderPostMenuButtonTitles.followConversation
            alertController.addActionWithTitle(
                buttonTitle,
                style: .default,
                handler: { (action: UIAlertAction) in
                    if let post: ReaderPost = ReaderActionHelpers.existingObject(for: post.objectID, in: context) {
                        Self.trackToggleCommentSubscription(isSubscribed: post.isSubscribedComments, post: post, sourceViewController: vc)

                        ReaderSubscribeCommentsAction().execute(
                            with: post,
                            context: context,
                            followCommentsService: followCommentsService,
                            sourceViewController: vc) {
                            (vc as? ReaderDetailViewController)?.updateFollowButtonState()
                        }
                    }
                })
        }

        if WPDeviceIdentification.isiPad() {
            alertController.modalPresentationStyle = .popover
            vc.present(alertController, animated: true)
            if let presentationController = alertController.popoverPresentationController {
                presentationController.permittedArrowDirections = .any
                presentationController.sourceView = anchor
                presentationController.sourceRect = anchor.bounds
            }
        } else {
            vc.present(alertController, animated: true)
        }
    }

    private func shouldShowBlockSiteMenuItem(readerTopic: ReaderAbstractTopic?, post: ReaderPost) -> Bool {
        guard let topic = readerTopic,
              isLoggedIn else {
            return false
        }

        return ReaderHelpers.isTopicTag(topic) ||
            ReaderHelpers.topicIsDiscover(topic) ||
            ReaderHelpers.topicIsFreshlyPressed(topic) ||
            ReaderHelpers.topicIsFollowing(topic)
    }

    private func shouldShowBlockUserMenuItem(post: ReaderPost) -> Bool {
        guard isLoggedIn else {
            return false
        }

        // we don't currently handle blocking users on non-WP.com sites due to
        // author IDs not being unique
        return post.isWPCom
    }

    private func shouldShowReportPostMenuItem(readerTopic: ReaderAbstractTopic?, post: ReaderPost) -> Bool {
        return shouldShowBlockSiteMenuItem(readerTopic: readerTopic, post: post)
    }

    private static func trackToggleCommentSubscription(isSubscribed: Bool, post: ReaderPost, sourceViewController: UIViewController) {
        var properties = [String: Any]()
        properties[WPAppAnalyticsKeyFollowAction] = isSubscribed ? "followed" : "unfollowed"
        properties["notifications_enabled"] = isSubscribed
        properties[WPAppAnalyticsKeyBlogID] = post.siteID
        properties[WPAppAnalyticsKeySource] = Self.sourceForTrackingEvents(sourceViewController: sourceViewController)
        WPAnalytics.trackReader(.readerMoreToggleFollowConversation, properties: properties)
    }

    private static func sourceForTrackingEvents(sourceViewController: UIViewController) -> String {
        if sourceViewController is ReaderDetailViewController {
            return "reader_post_details_comments"
        } else if sourceViewController is ReaderStreamViewController {
            return "reader"
        }

        return "unknown"
    }

    // MARK: - Sending Notifications

    private func postSiteBlockingWillBeginNotification(_ post: ReaderPost) {
        NotificationCenter.default.post(name: .ReaderSiteBlockingWillBegin,
                                        object: nil,
                                        userInfo: [ReaderNotificationKeys.post: post])
    }

    /// Notify Reader Cards Stream so the post card is updated.
    private func postSiteBlockingDidFinish(_ post: ReaderPost) {
        NotificationCenter.default.post(name: .ReaderSiteBlocked,
                                        object: nil,
                                        userInfo: [ReaderNotificationKeys.post: post])
    }

    private func postSiteBlockingDidFail(_ post: ReaderPost, error: Error?) {
        NotificationCenter.default.post(name: .ReaderSiteBlockingFailed,
                                        object: nil,
                                        userInfo: [ReaderNotificationKeys.post: post, ReaderNotificationKeys.error: error])
    }
}
