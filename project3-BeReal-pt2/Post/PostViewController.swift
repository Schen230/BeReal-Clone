//
//  PostViewController.swift
//  project2-BeReal
//
//  Created by Sunny Chen on 9/14/24.
//

import UIKit
import ParseSwift
import PhotosUI
import CoreLocation
import ImageIO

class PostViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var previewImageView: UIImageView!
    
    
    private var pickedImage: UIImage?
    private var imageLocation: CLLocationCoordinate2D?
    private var imageDate: Date?
    private let geocoder = CLGeocoder()
    private var city: String?
    private var state: String? 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shareButton.isEnabled = false
        updateUI()
    }
    
    private func updateUI() {
        previewImageView.image = pickedImage
    }
    
    @IBAction func onPickedImageTapped(_ sender: Any) {
        // TODO: Pt 1 - Present Image picker
        // Create a configuration object
        var config = PHPickerConfiguration()
        // Set the filter to only show images (No videos)
        config.filter = .images
        // Request the original file format. Fastest method that avoids transcoding.
        config.preferredAssetRepresentationMode = .current
        // Only allow one image to be selected.
        config.selectionLimit = 1
        // Instantiate a picker, passing in the configuration
        let picker = PHPickerViewController(configuration: config)
        // Set the picker delegate so we can receive whatever image the user picks.
        picker.delegate = self
        // Present the picker
        present(picker, animated: true)
        
    }
    
    @IBAction func onShareTapped(_ sender: Any) {
        
        // Dismiss Keyboard
        view.endEditing(true)
        
        // Create and save Post
        // Unwrap optional pickedImage
        guard let image = pickedImage,
              // Create and compress image data (jpeg) from UIImage
              let imageData = image.jpegData(compressionQuality: 0.1) else {
            return
        }
        // Create a Parse File by providing a name and passing in the image data
        let imageFile = ParseFile(name: "image.jpg", data: imageData)
        
        // Create Post object
        var post = Post()
        
        // Set properties
        post.imageFile = imageFile
        post.caption = captionTextField.text
        post.city = self.city
        post.state = self.state
        
        // Set the user as the current user
        post.user = User.current
        
        // Save object in background (async)
        post.save { [weak self] result in
            // Switch to the main thread for any UI updates
            DispatchQueue.main.async {
                switch result {
                case.success(let post):
                    print("😳 Post saved! \(post)")
                    
                    // Get current user
                    if var currentUser = User.current{
                        
                        // Update the 'lastPostedDate' property on the user with the current date
                        currentUser.lastPostedDate = Date()
                        
                        // Save updates to the user (async)
                        currentUser.save { [weak self] result in
                            switch result{
                            case.success(let user):
                                print("😳 User Saved! \(user)")
                                
                                // Switch to the main thread for any UI updates
                                DispatchQueue.main.async {
                                    self?.navigationController?.popViewController(animated: true)
                                }
                            case.failure(let error):
                                self?.showAlert(description: error.localizedDescription)
                            }
                        }
                    }
                    // Return to previous view controller
                    self?.navigationController?.popViewController(animated: true)
                case.failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func onTakePhotoTapped(_ sender: Any) {
        // Make sure user has a camera available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("😵 📷 Camera not available")
            return
        }
        // Instantiate the image picker
        let imagePicker = UIImagePickerController()
        
        // Shows the camera
        imagePicker.sourceType = .camera
        
        // Allows user to edit image within image picker flow
        imagePicker.allowsEditing = true
        
        // The image picker will return captured photos via its delegate method to its assigned delegate
        // Delegate assignee must conform and implement both `UIImagePickerControllerDelegate` and `UINavigationControllerDelegate`
        imagePicker.delegate = self
        
        // Preset the image picker (camera)
        present(imagePicker, animated: true)
    }
    
    
    
    @IBAction func onViewTapped(_ sender: Any) {
        // Dismiss keyboard
        view.endEditing(true)
    }
    
    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Location:", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
    
    private func extractLocationMetadata(from url: URL) {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let gpsData = imageProperties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              let latitude = gpsData[kCGImagePropertyGPSLatitude] as? Double,
              let longitude = gpsData[kCGImagePropertyGPSLongitude] as? Double else {
            DispatchQueue.main.async {
                self.showAlert(description: "No location data found in the image.")
            }
            return
        }
        print("Extracted GPS Data: \(latitude), \(longitude)")
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        self.imageLocation = location.coordinate
        reverseGeocodeLocation(location)
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in if let error = error {
            print("Reverse geocoding error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self?.showAlert(description: "Location Unknown.")
            }
            return
        }
            guard let placemark = placemarks?.first else {
                DispatchQueue.main.async {
                    self?.showAlert(description: "Location Unknown")
                }
                return
            }
            print("\(placemark)")
            
            self?.city = placemark.locality ?? "Unknown City"
            self?.state = placemark.administrativeArea ?? "Unknown State"
            
            DispatchQueue.main.async {
                if let city = self?.city, let state = self?.state {
                    self?.showAlert(description: "Location: \(city), \(state)")
                    print("\(city), \(state)")
                }
            }
        }
    }
}

extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        // Get the edited image from the info dictionary (if 'allowsEditing = true' for image picker)
        // Alternatively, to get the original image, use the '.originalImage' infokey instead.
        guard let image = info[.editedImage] as? UIImage else {
            print("😵 Unable to get image")
            return
        }
        // Set image on preview image view
        previewImageView.image = image
        
        // Set image to use when saving post
        pickedImage = image
        
        //Enable the post button
        shareButton.isEnabled = true
    }
}

// TODO: Pt 1 - Add PHPickerViewController delegate and handle picked image.
extension PostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        
        // Make sure we have a non nil item provider
        guard let provider = results.first?.itemProvider,
              // Make sure the provider can load a UIImage
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        // Load a UIImage from the provider
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
        
            // Make sure we can case the returned object to a UIImage
            guard let image = object as? UIImage else {
                self?.showAlert()
                return
            }
            
            if let error = error {
                self?.showAlert(description: error.localizedDescription)
                return
            } else {
                // UI updates like setting image on image view should be done on main thread
                DispatchQueue.main.async {
                    // Set image on preview image view
                    self?.previewImageView.image = image
                    // Set image to use when saving post
                    self?.pickedImage = image
                    // Show share button
                    self?.shareButton .isEnabled = true
                    // Update UI to unhide image view
                    self?.updateUI()
                }
            }
            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { (url, error) in guard let url = url else {return}
                
                self?.extractLocationMetadata(from: url)
            }
        }
        
        // Fetch asset metadata (location and date)
        if let assetIdentifier = result.assetIdentifier {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
            guard let asset = fetchResult.firstObject else {
                print("No asset found for the selected image.")
                return
            }

            // Store date metadata
            self.imageDate = asset.creationDate

            // Store location metadata
            if let location = asset.location {
                self.imageLocation = location.coordinate
                print("Location: \(self.imageLocation?.latitude ?? 0), \(self.imageLocation?.longitude ?? 0)")
                self.reverseGeocodeLocation(location)  // Reverse geocode if needed
            } else {
                print("No location metadata available.")
            }
        }

    }
    
    
}
