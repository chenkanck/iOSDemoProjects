import UIKit
import CoreImage

let dataSourceURL = URL(string:"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist")!

class ListViewController: UITableViewController {
    var photos: [PhotoRecord] = []
    let pendingOperations = PendingOperations()

  override func viewDidLoad() {
    super.viewDidLoad()
    print("view did load \(Date())")
    self.title = "Classic Photos"
    fetchPhotoDetails()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    print("view did appear \(Date())")
  }
  
  // MARK: - Table view data source
  override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)

    //1
    if cell.accessoryView == nil {
      let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
      cell.accessoryView = indicator
    }
    let indicator = cell.accessoryView as! UIActivityIndicatorView

    //2
    let photoDetails = photos[indexPath.row]

    //3
    cell.textLabel?.text = photoDetails.name
    cell.imageView?.image = photoDetails.image

    //4
    switch (photoDetails.state) {
    case .filtered:
      indicator.stopAnimating()
    case .failed:
      indicator.stopAnimating()
      cell.textLabel?.text = "Failed to load"
    case .new, .downloaded:
      indicator.startAnimating()
      startOperations(for: photoDetails, at: indexPath)
    }

    return cell
  }
}

// MARK: - operation Queue
extension ListViewController {
    func startOperations(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
      switch (photoRecord.state) {
      case .new:
        startDownload(for: photoRecord, at: indexPath)
      case .downloaded:
        startFiltration(for: photoRecord, at: indexPath)
      default:
        NSLog("do nothing")
      }
    }

    func startDownload(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
      //1
      guard pendingOperations.downloadsInProgress[indexPath] == nil else {
        return
      }

      //2
      let downloader = ImageDownloader(photoRecord)

      //3
      downloader.completionBlock = {
        if downloader.isCancelled {
          return
        }

        DispatchQueue.main.async {
          self.pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
          self.tableView.reloadRows(at: [indexPath], with: .fade)
        }
      }

      //4
      pendingOperations.downloadsInProgress[indexPath] = downloader

      //5
      pendingOperations.downloadQueue.addOperation(downloader)
    }

    func startFiltration(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
      guard pendingOperations.filtrationsInProgress[indexPath] == nil else {
          return
      }

      let filterer = ImageFiltration(photoRecord)
      filterer.completionBlock = {
        if filterer.isCancelled {
          return
        }

        DispatchQueue.main.async {
          self.pendingOperations.filtrationsInProgress.removeValue(forKey: indexPath)
          self.tableView.reloadRows(at: [indexPath], with: .fade)
        }
      }

      pendingOperations.filtrationsInProgress[indexPath] = filterer
      pendingOperations.filtrationQueue.addOperation(filterer)
    }
}

// MARK: - Loading list
extension ListViewController {
    func fetchPhotoDetails() {
      let request = URLRequest(url: dataSourceURL)
      UIApplication.shared.isNetworkActivityIndicatorVisible = true

      // 1
      let task = URLSession(configuration: .default).dataTask(with: request) { data, response, error in

        // 2
        let alertController = UIAlertController(title: "Oops!",
                                                message: "There was an error fetching photo details.",
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)

        if let data = data {
          do {
            // 3
            let datasourceDictionary =
              try PropertyListSerialization.propertyList(from: data,
                                                         options: [],
                                                         format: nil) as! [String: String]

            // 4
            for (name, value) in datasourceDictionary {
              let url = URL(string: value)
              if let url = url {
                let photoRecord = PhotoRecord(name: name, url: url)
                self.photos.append(photoRecord)
              }
            }

            // 5
            DispatchQueue.main.async {
              UIApplication.shared.isNetworkActivityIndicatorVisible = false
              self.tableView.reloadData()
            }
            // 6
          } catch {
            DispatchQueue.main.async {
              self.present(alertController, animated: true, completion: nil)
            }
          }
        }

        // 6
        if error != nil {
          DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.present(alertController, animated: true, completion: nil)
          }
        }
      }
      // 7
      task.resume()
    }
}
