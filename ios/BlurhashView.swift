//
//  BlurhashView.swift
//  Blurhash
//
//  Created by Marc Rousavy on 15.06.20.
//  Copyright © 2020 Facebook. All rights reserved.
//

import Foundation
import UIKit

let LOG_ID = "BlurhashView"

class BlurhashCache {
	var blurhash: NSString
	var decodeWidth: NSNumber
	var decodeHeight: NSNumber
	var decodePunch: NSNumber
	var image: UIImage
	
	init(blurhash: NSString, decodeWidth: NSNumber, decodeHeight: NSNumber, decodePunch: NSNumber, image: UIImage) {
		self.blurhash = blurhash
		self.decodeWidth = decodeWidth
		self.decodeHeight = decodeHeight
		self.decodePunch = decodePunch
		self.image = image
	}
	
	func isDifferent(blurhash: NSString, decodeWidth: NSNumber, decodeHeight: NSNumber, decodePunch: NSNumber) -> Bool {
		return self.blurhash != blurhash || self.decodeWidth != decodeWidth || self.decodeHeight != decodeHeight || self.decodePunch != decodePunch
	}
}

class BlurhashView: UIView {
	@objc var blurhash: NSString?
	@objc var decodeWidth: NSNumber?
	@objc var decodeHeight: NSNumber?
	@objc var decodePunch: NSNumber = 1
	var lastState: BlurhashCache?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
	  fatalError("init(coder:) has not been implemented")
	}
	
	func decodeImage() -> UIImage? {
		guard let blurhash = self.blurhash, let decodeWidth = self.decodeWidth, let decodeHeight = self.decodeHeight else {
			return nil
		}
		if (self.lastState?.isDifferent(blurhash: blurhash, decodeWidth: decodeWidth, decodeHeight: decodeHeight, decodePunch: self.decodePunch) == false) {
			print("\(LOG_ID): Using cached image from last state!")
			return self.lastState?.image
		}
		print("\(LOG_ID): Re-rendering image on \(Thread.isMainThread ? "main" : "separate") thread!")
		let size = CGSize(width: decodeWidth.intValue, height: decodeHeight.intValue)
		let start = DispatchTime.now()
		let nullableImage = UIImage(blurHash: blurhash as String, size: size, punch: self.decodePunch.floatValue)
		let end = DispatchTime.now()
		print("\(LOG_ID): Image decoding took: \((end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000) milliseconds")
		guard let image = nullableImage else {
			return nil
		}
		self.lastState = BlurhashCache(blurhash: blurhash, decodeWidth: decodeWidth, decodeHeight: decodeHeight, decodePunch: self.decodePunch, image: image)
		return image
	}
	
	func renderBlurhashView() {
		// TODO: background thread decoding?
		guard let image = self.decodeImage() else {
			return
		}

		// Run View Setter on main thread again
		// image.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.subviews.forEach({ $0.removeFromSuperview() })
		// TODO: Dynamic width/height
		let imageContainer = UIImageView(image: image)
		imageContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.addSubview(imageContainer)
		print("\(LOG_ID): Set UIImageView's Image source!")
	}
	
	override func didSetProps(_ changedProps: [String]!) {
		self.renderBlurhashView()
	}
}
