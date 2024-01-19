//
//  ScreenshotInvisibleContainerProtocol.swift
//  
//
//  Created by Князьков Илья on 02.03.2022.
//

import Foundation
import UIKit

public protocol ScreenshotInvisibleContainerProtocol: UIView {

    func eraseOldAndAddNewContent(_ newContent: UIView)
    func setupContainerAsHideContentInScreenshots()
    func setupContainerAsDisplayContentInScreenshots()
    
}
