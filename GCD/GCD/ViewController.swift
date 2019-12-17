// Demostrate how to handle costly task in background

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var spiinner: UIActivityIndicatorView!
    var result = 0 {
        didSet {
            resultLabel.text = String(result)
        }
    }

    var processor: TaskProcesser!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.result = 0
        self.processor = TaskProcesser(latest: result, complete: { [weak self] newValue in
            guard let self = self else {
                print("released")
                return
            }
            self.result = newValue
        })
    }

    /**
     simple async solution
     */
//    @IBAction func addButtonTapped(_ sender: Any) {
//        spiinner.startAnimating()
//        let input = self.result
//        DispatchQueue.global().async {
//            let r = heavyFunc(input)
//            DispatchQueue.main.async {
//                self.spiinner.stopAnimating()
//                self.result = r
//            }
//        }
//    }


    @IBAction func addButtonTapped(_ sender: Any) {
        processor.processTask()
    }

    @IBAction func reset(_ sender: Any) {
        result = 0

        DispatchQueue.global().async {
            while true {
                Thread.sleep(forTimeInterval: 0.1)
//                // data race
//                print(self.processor.latest)
                print(self.processor.getLatest())
            }
        }
    }

}


func heavyFunc(_ input: Int) -> Int {
    sleep(10)
    return input + 10
}

class TaskProcesser {
    private var latest: Int {
        didSet {
            DispatchQueue.main.async {
                self.updateHanlder(self.latest)
            }
        }
    }

    var updateHanlder: (Int) -> Void
    private let taskProcessQueue = DispatchQueue(label: "task.process.serial")
    private let lockQueue = DispatchQueue(label: "lock")

    init(latest: Int, complete: @escaping (Int) -> Void) {
        self.latest = latest
        self.updateHanlder = complete
    }

    func processTask() {
        taskProcessQueue.async {
//            // data race
//            let input = self.latest
            let input = self.getLatest()
            let r = heavyFunc(input)
//            self.latest = r
            self.setLatest(r)
        }
    }

    func getLatest() -> Int {
        var res: Int!
        lockQueue.sync {
            res = self.latest
        }
        return res
    }

    func setLatest(_ value: Int) {
        lockQueue.sync {
            self.latest = value
        }
    }
}
