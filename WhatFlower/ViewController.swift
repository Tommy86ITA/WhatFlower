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


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    
    
    //Linked outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoTextView: UITextView!
    
    
    //Networking constants
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //imagePicker Setup
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        
    }
    
    
    //MARK: - imagePickerController Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else { fatalError("Could not convert ti CIImage") }
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
            //print(firstResult.confidence)
            
            
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
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
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

            infoTextView.text = flowerDescription
        print(flowerDescription)

    }
    
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        
        present(imagePicker, animated: true, completion: nil)
    }
    
}

