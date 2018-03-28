//
//  ViewController.swift
//  WhatFlower
//
//  Created by Thomas Amaranto on 23/03/18.
//  Copyright © 2018 Thomas Amaranto. All rights reserved.
//

import UIKit
import Vision
import CoreML
import Alamofire
import SwiftyJSON
import SDWebImage
import ChameleonFramework


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    
    
    //Linked outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoTextView: UITextView!
    
    
    //Networking constants
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.barTintColor = HexColor("1A2C47")
        view.backgroundColor = HexColor("5565AD")
        //5565AD
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //imagePicker Setup
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
    }
    
    
    //MARK: - imagePickerController Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else { fatalError("Could not convert to CIImage") }
            classifyImage(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    
    //MARK: - Funzione di analisi dell'immagine tramite il modello FlowerClassifier
    
    func classifyImage(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else { fatalError("Failed to load CoreML Model.")}
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let classification = request.results?.first as? VNClassificationObservation else { fatalError("Model failed to process image.")}
            
            self.navigationItem.title = classification.identifier.capitalized
            self.getInfoFromWikipedia(url: self.wikipediaURL, flowerName: classification.identifier)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print("Error performing request")
        }
    }
    
    
    //MARK: - Networking
    
    func getInfoFromWikipedia(url: String, flowerName: String) {
        
        let queryParameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(url, method: .get, parameters: queryParameters).responseJSON {
            (response) in
            
            if response.result.isSuccess {
                print("Data received")
                
                let wikipediaJSON : JSON = JSON(response.result.value!)
                print(wikipediaJSON)
                self.JSONParser(json: wikipediaJSON)
                
            }
                
            else {
                print("Error retrieving data")
                self.infoTextView.text = "I'm sorry, but I can't retrieve data from Wikipedia 😔"
            }
        }
        
    }
    
    
    
    //MARK: - JSON parser
    
    func JSONParser(json: JSON) {
        
        let pageID = json["query"]["pageids"][0].stringValue
        let flowerDescription = json["query"]["pages"][pageID]["extract"].stringValue
        
        
        
        let flowerImageURL = json["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
        
        
        imageView.sd_setImage(with: URL(string: flowerImageURL)) { (uiimage, _, _, _) in
            let imageColor = UIColor(averageColorFrom: uiimage!)
            self.navigationController?.navigationBar.barTintColor = imageColor
            self.navigationController?.navigationBar.tintColor = ContrastColorOf(imageColor, returnFlat: true)
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : ContrastColorOf(imageColor, returnFlat: true)]
            self.view.backgroundColor = imageColor.lighten(byPercentage: 0.2)
            
            self.infoTextView.textColor = ContrastColorOf(imageColor, returnFlat: true)
        }
        infoTextView.isHidden = false
        infoTextView.text = flowerDescription
        print(flowerDescription)
    }
    
    //MARK: - UI Updater
    
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Fotocamera", style: .default , handler: { _ in
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Libreria foto", style: .default, handler: { _ in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}
