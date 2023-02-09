import Foundation
import WordPressKit

final class BlazeService {

    private let remote: BlazeServiceRemote

    // MARK: - Init

    required init?(contextManager: CoreDataStack = ContextManager.shared,
                   remote: BlazeServiceRemote? = nil) {
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext) else {
            return nil
        }

        self.remote = remote ?? .init(wordPressComRestApi: account.wordPressComRestV2Api)
    }

    // MARK: - Methods

    func getStatus(for blog: Blog, callback: @escaping BlazeStatusResponseCallback) {
        guard let siteId = blog.dotComID?.intValue else {
            callback(.failure(BlazeServiceError.invalidSiteId))
            return
        }

        remote.getStatus(forSiteId: siteId, callback: callback)
    }
}

extension BlazeService {

    typealias BlazeStatusResponseCallback = BlazeServiceRemote.BlazeStatusResponseCallback

    enum BlazeServiceError: Error {
        case invalidSiteId
    }
}
