//
//  ViewController.swift
//  LoveInASnap
//
//  Created by Lyndsey Scott on 1/11/15
//  for http://www.raywenderlich.com/
//  Copyright (c) 2015 Lyndsey Scott. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController, UITextViewDelegate, UINavigationControllerDelegate {
  
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var findTextField: UITextField!
  @IBOutlet weak var replaceTextField: UITextField!
  @IBOutlet weak var topMarginConstraint: NSLayoutConstraint!
  
  var activityIndicator:UIActivityIndicatorView!
  var originalTopMargin:CGFloat!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    originalTopMargin = topMarginConstraint.constant
  }
  
  @IBAction func takePhoto(sender: AnyObject) {
    
    // 1. If you’re currently editing either the text view or a text field, close the keyboard and move the view back to its original position.
    view.endEditing(true)
    moveViewDown()
    
    // 2. Create a UIAlertController with the action sheet style to present a set of capture options to the user.
    let imagePickerActionSheet = UIAlertController(title: "Snap/Upload Photo",
      message: nil, preferredStyle: .ActionSheet)
    
    // 3. If the device has a camera, add the Take Photo button to imagePickerActionSheet. Selecting this button creates and presents an instance of UIImagePickerController with sourceType .Camera.
    if UIImagePickerController.isSourceTypeAvailable(.Camera) {
      let cameraButton = UIAlertAction(title: "Take Photo",
        style: .Default) { (alert) -> Void in
          let imagePicker = UIImagePickerController()
          imagePicker.delegate = self
          imagePicker.sourceType = .Camera
          self.presentViewController(imagePicker,
            animated: true,
            completion: nil)
      }
      imagePickerActionSheet.addAction(cameraButton)
    }
    
    // 4. Add a Choose Existing button to imagePickerActionSheet. Selecting this button creates and presents an instance of UIImagePickerController with sourceType .PhotoLibrary.
    let libraryButton = UIAlertAction(title: "Choose Existing",
      style: .Default) { (alert) -> Void in
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .PhotoLibrary
        self.presentViewController(imagePicker,
          animated: true,
          completion: nil)
    }
    imagePickerActionSheet.addAction(libraryButton)
    
    // 5. Add a Cancel button to imagePickerActionSheet. Selecting this button cancels your UIImagePickerController, even though you don’t specify an action beyond setting the style as .Cancel.
    let cancelButton = UIAlertAction(title: "Cancel",
      style: .Cancel) { (alert) -> Void in
    }
    imagePickerActionSheet.addAction(cancelButton)
    
    // 6. Finally, present your instance of UIAlertController.
    presentViewController(imagePickerActionSheet, animated: true,
      completion: nil)
  }
  
  func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
    
    // Helper method to scale image before OCR is performed
    // Given maxDimension, this method takes the height or width of the image — whichever is greater — and sets that dimension equal to the maxDimension argument. It then scales the other side of the image appropriately based on the aspect ratio, redraws the original image to fit into the newly calculated frame, then finally returns the newly scaled image back to the calling method.
    
    var scaledSize = CGSize(width: maxDimension, height: maxDimension)
    var scaleFactor: CGFloat
    
    if image.size.width > image.size.height {
      scaleFactor = image.size.height / image.size.width
      scaledSize.width = maxDimension
      scaledSize.height = scaledSize.width * scaleFactor
    } else {
      scaleFactor = image.size.width / image.size.height
      scaledSize.height = maxDimension
      scaledSize.width = scaledSize.height * scaleFactor
    }
    
    UIGraphicsBeginImageContext(scaledSize)
    image.drawInRect(CGRectMake(0, 0, scaledSize.width, scaledSize.height))
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return scaledImage
  }
  
  func performImageRecognition(image: UIImage) {
    
    // 1. Initialize tesseract to a contain a new G8Tesseract object.
    let tesseract = G8Tesseract()
    
    // 2. Tesseract will search for the .traineddata files of the languages you specify in this parameter; specifying eng and fra will search for “eng.traineddata” and “fra.traineddata”containing the data to detect English and French text respectively. The French trained data has been included in this project since the sample poem you’ll be using for this tutorial contains a bit of French (Très romantique!). The poem’s French accented characters aren’t in the English character set, so you need to link to French .traineddata in order for those accents to appear; it’s also good to include the French data since there’s a component of .traineddata which takes language vocabulary into account.
    tesseract.language = "eng+fra"
    
    // 3. You can specify three different OCR engine modes: .TesseractOnly, which is the fastest, but least accurate method; .CubeOnly, which is slower but more accurate since it employs more artificial intelligence; and .TesseractCubeCombined, which runs both .TesseractOnly and .CubeOnly to produce the most accurate results — but as a result is the slowest mode of the three.
    tesseract.engineMode = .TesseractCubeCombined
    
    // 4. Tesseract assumes by default that it’s processing a uniform block of text, but your sample image has multiple paragraphs. Tesseract’s pageSegmentationMode lets the Tesseract engine know how the text is divided, so in this case, set pageSegmentationMode to .Auto to allow for fully automatic page segmentation and thus the ability to recognize paragraph breaks.
    tesseract.pageSegmentationMode = .Auto
    
    // 5. Here you set maximumRecognitionTime to limit the amount of time your Tesseract engine devotes to image recognition. However, only the Tesseract engine is limited by this setting; if you’re using the .CubeOnly or .TesseractCubeCombined engine mode, the Cube engine will continue processing even once your Tesseract engine has hit its maximumRecognitionTime.
    tesseract.maximumRecognitionTime = 60.0
    
    // 6. You’ll get the best results from Tesseract when the text contrasts highly with the background. Tesseract has a built in filter, g8_blackAndWhite(), that desaturates the image, increases the contrast, and reduces the exposure. Here, you’re assigning the filtered image to the image property of your Tesseract object, before kicking off the Tesseract image recognition process.
    tesseract.image = image.g8_blackAndWhite()
    tesseract.recognize()
    
    // 7. Note that the image recognition is synchronous so at this point, the text is available. You then put the recognized text into your textView and make the view editable so your user can edit it as she likes.
    textView.text = tesseract.recognizedText
    textView.editable = true
    
    // 8. Finally, remove the activity indicator to signal that the OCR is complete and to let the user edit their poem.
    removeActivityIndicator()
  }
  
  @IBAction func swapText(sender: AnyObject) {
    
    // 1. If the textView is empty, there’s no text to swap so simply bail out of the method.
    if textView.text.isEmpty {
      return
    }
    
    // 2. Otherwise, find all occurrences of the string you’ve typed into findTextField in the textView and replace them with the string you’ve entered in replaceTextField.
    textView.text =
      textView.text.stringByReplacingOccurrencesOfString(findTextField.text!,
        withString: replaceTextField.text!)
    
    // 3. Next, clear out the values in findTextField and replaceTextField once the replacements are complete.
    findTextField.text = nil
    replaceTextField.text = nil
    
    // 4. Finally, resign the keyboard and move the view back into the correct position. As before in takePhoto(), you’re ensuring the view stays positioned correctly when the keyboard goes away.
    view.endEditing(true)
    moveViewDown()
  }
  
  @IBAction func sharePoem(sender: AnyObject) {
    
    // 1. If the textView is empty, don’t share anything.
    if textView.text.isEmpty {
      return
    }
    
    // 2. Otherwise, create an new instance of UIActivityViewController, put the text from the text view inside an array and pass it in as the activity item to be shared.
    let activityViewController = UIActivityViewController(activityItems:
      [textView.text], applicationActivities: nil)
    
    // 3. UIActivityViewController has a long list of built-in activity types. You can exclude UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr, and UIActivityTypePostToVimeo since they don’t make much sense in this context.
    let excludeActivities = [
      UIActivityTypeAssignToContact,
      UIActivityTypeSaveToCameraRoll,
      UIActivityTypeAddToReadingList,
      UIActivityTypePostToFlickr,
      UIActivityTypePostToVimeo]
    activityViewController.excludedActivityTypes = excludeActivities
    
    // 4. Finally, present your UIActivityViewController and let the user share their creation where they wish.
    presentViewController(activityViewController, animated: true,
      completion: nil)
  }
  
  
  // Activity Indicator methods
  
  func addActivityIndicator() {
    activityIndicator = UIActivityIndicatorView(frame: view.bounds)
    activityIndicator.activityIndicatorViewStyle = .WhiteLarge
    activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.25)
    activityIndicator.startAnimating()
    view.addSubview(activityIndicator)
  }
  
  func removeActivityIndicator() {
    activityIndicator.removeFromSuperview()
    activityIndicator = nil
  }
  
  
  // The remaining methods handle the keyboard resignation/
  // move the view so that the first responders aren't hidden
  
  func moveViewUp() {
    if topMarginConstraint.constant != originalTopMargin {
      return
    }
    
    topMarginConstraint.constant -= 135
    UIView.animateWithDuration(0.3, animations: { () -> Void in
      self.view.layoutIfNeeded()
    })
  }
  
  func moveViewDown() {
    if topMarginConstraint.constant == originalTopMargin {
      return
    }

    topMarginConstraint.constant = originalTopMargin
    UIView.animateWithDuration(0.3, animations: { () -> Void in
      self.view.layoutIfNeeded()
    })

  }
  
  @IBAction func backgroundTapped(sender: AnyObject) {
    view.endEditing(true)
    moveViewDown()
  }
}

extension ViewController: UITextFieldDelegate {
  func textFieldDidBeginEditing(textField: UITextField) {
    moveViewUp()
  }
  
  @IBAction func textFieldEndEditing(sender: AnyObject) {
    view.endEditing(true)
    moveViewDown()
  }
  
  func textViewDidBeginEditing(textView: UITextView) {
    moveViewDown()
  }
}

extension ViewController: UIImagePickerControllerDelegate {
  
  func imagePickerController(picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [String : AnyObject]) {
      
      // imagePickerController(_:didFinishPickingMediaWithInfo:) is a UIImagePickerDelegate method that returns the selected image information in an info dictionary object. You get the selected photo from info using the UIImagePickerControllerOriginalImage key and then scale it using scaleImage(_:maxDimension:).
      // You call addActivityIndicator() to disable user interaction and display an activity indicator to the user while Tesseract does its work. You then dismiss your UIImagePicker and pass the image to performImageRecognition() (which you’ll implement next!) for processing.
      
      let selectedPhoto = info[UIImagePickerControllerOriginalImage] as! UIImage
      let scaledImage = scaleImage(selectedPhoto, maxDimension: 640)
      
      addActivityIndicator()
      
      dismissViewControllerAnimated(true, completion: {
        self.performImageRecognition(scaledImage)
      })
  }
}
