import PeekKit
import UIKit

class ViewController: UIViewController {
    private let peeker = Peeker()

    @IBAction func onPeekClick(_ sender: Any) {
        peeker.peek(from: self) { status in
            print("peek:", status)
        }
    }
}
