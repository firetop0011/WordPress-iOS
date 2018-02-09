import UIKit
import Lottie

class LoginPrologueViewController: UIViewController {

    @IBOutlet var loginButton: UIButton!
    @IBOutlet var signupButton: UIButton!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WordPressAuthenticator.emit(event: .loginPrologueViewed)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    // MARK: - Setup and Config

    @objc func localizeControls() {
        loginButton.setTitle(NSLocalizedString("Log In", comment: "Button title.  Tapping takes the user to the login form."),
                             for: .normal)
        loginButton.accessibilityIdentifier = "Log In"

        signupButton.setTitle(NSLocalizedString("Create a WordPress site", comment: "Button title. Tapping takes the user to a form where they can create a new WordPress site."),
                              for: .normal)

    }

    // MARK: - Actions

    @IBAction func signupTapped() {
        if Feature.enabled(.socialSignup) {

            // TODO: replace with Signup Prologue implementation

            let storyboard = UIStoryboard(name: "Signup", bundle: nil)
            let emailVC = storyboard.instantiateViewController(withIdentifier: "emailEntry")
            let navController = SignupNavigationController(rootViewController: emailVC)
            present(navController, animated: true, completion: nil)


        } else {
            performSegue(withIdentifier: "showSigninV1", sender: self)
        }
    }
}
