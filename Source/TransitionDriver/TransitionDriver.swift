//
//  TransitionDriver.swift
//  TestCollectionView
//
//  Created by Alex K. on 11/05/16.
//  Copyright © 2016 Alex K. All rights reserved.
//

import UIKit

class TransitionDriver {
  
  // MARK: Vars
  
  private let view: UIView
  
  // for push animation
  private var copyCell: BasePageCollectionCell?
  private var currentCell: BasePageCollectionCell?
  private var backImageView: UIImageView?
  
  private var leftCell: UICollectionViewCell?
  private var rightCell: UICollectionViewCell?
  private var step: CGFloat = 0
  
  private var frontViewFrame = CGRect.zero
  private var backViewFrame = CGRect.zero
  
  init(view: UIView) {
    self.view = view
  }
}

// MARK: control

extension TransitionDriver {
  
  func pushTransitionAnimationIndex(currentIndex: Int,
                                    collecitionView: UICollectionView,
                                    backImage: UIImage?,
                                    completion: UIView -> Void) {
    
    guard case let cell as BasePageCollectionCell = collecitionView.cellForItemAtIndexPath(NSIndexPath(forRow: currentIndex, inSection: 0)),
      let copyView = cell.copyCell() else { return }
    copyCell = copyView
    
    // move cells
    moveCellsCurrentIndex(currentIndex, collectionView: collecitionView)
    
    currentCell = cell
    cell.hidden = true
    
    configurateCell(copyView, backImage: backImage)
    backImageView = addImageToView(copyView.backContainerView, image: backImage)
    
    openBackViewConfigureConstraints(copyView)
    openFrontViewConfigureConstraints(copyView)
    
    // corner animation 
    copyView.backContainerView.animationCornerRadius(0, duration: 0.4)
    copyView.frontContainerView.animationCornerRadius(0, duration: 0.4)
    
    // constraints animation
    UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseInOut, animations: {
      self.view.layoutIfNeeded()
      self.backImageView?.alpha = 1
      self.copyCell?.shadowView?.alpha = 0
      for case let item in copyView.frontContainerView.subviews where item.accessibilityIdentifier == "hide" {
        item.alpha = 0
      }
    }, completion: { success in
      let data = NSKeyedArchiver.archivedDataWithRootObject(copyView.frontContainerView)
      guard case let headerView as UIView = NSKeyedUnarchiver.unarchiveObjectWithData(data) else {
        fatalError("must copy")
      }
      completion(headerView)
    })
  }
  
  func popTransitionAnimationContantOffset(offset: CGFloat, backImage: UIImage?) {
    guard let currentCell = self.copyCell else {
      return
    }
    
    backImageView?.image = backImage
    // configuration start position
    configureCellBeforeClose(currentCell, offset: offset)
    
    closeBackViewConfigurationConstraints(currentCell)
    closeFrontViewConfigurationConstraints(currentCell)
    
    // corner animation
    copyCell?.backContainerView.animationCornerRadius(currentCell.backContainerView.layer.cornerRadius, duration: 0.4)
    copyCell?.frontContainerView.animationCornerRadius(currentCell.frontContainerView.layer.cornerRadius, duration: 0.4)
    
    UIView.animateWithDuration(0.4) {
      self.rightCell?.center.x -= self.step
      self.leftCell?.center.x  += self.step
    }
    
    UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseInOut, animations: {
      self.view.layoutIfNeeded()
      self.backImageView?.alpha = 0
      self.copyCell?.shadowView?.alpha = 1
 
      for case let item as UILabel in currentCell.frontContainerView.subviews where item.accessibilityIdentifier == "hide" {
        item.alpha = 1
      }
      
      }, completion: { success in
         self.currentCell?.hidden = false
         self.removeCurrentCell()
    })
  }
}

// MARK: Helpers

extension TransitionDriver {
  
  private func removeCurrentCell()  {
    if case let currentCell as UIView = self.copyCell {
      currentCell.removeFromSuperview()
    }
  }
  
  private func configurateCell(cell: BasePageCollectionCell, backImage: UIImage?) {
    cell.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(cell)
    
    // add constraints
    [(NSLayoutAttribute.Width, cell.bounds.size.width), (NSLayoutAttribute.Height, cell.bounds.size.height)].forEach { info in
      cell >>>- {
        $0.attribute = info.0
        $0.constant  = info.1
      }
    }
    
    [NSLayoutAttribute.CenterX, .CenterY].forEach { attribute in
      (view, cell) >>>- { $0.attribute = attribute }
    }
    cell.layoutIfNeeded()
  }
  
  private func addImageToView(view: UIView, image: UIImage?) -> UIImageView? {
    guard let image = image else { return nil }
    
    let imageView = Init(UIImageView(image: image)) {
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.alpha = 0
    }
    view.addSubview(imageView)
    
    // add constraints
    [NSLayoutAttribute.Left, .Right, .Top, .Bottom].forEach { attribute in
      (view, imageView) >>>- { $0.attribute = attribute }
    }
    imageView.layoutIfNeeded()
    
    return imageView
  }
  
  private func moveCellsCurrentIndex(currentIndex: Int, collectionView: UICollectionView) {
    self.leftCell = nil
    self.rightCell = nil
    
    if let leftCell = collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: currentIndex - 1, inSection: 0)) {
      let step = leftCell.frame.size.width + (leftCell.frame.origin.x - collectionView.contentOffset.x)
      UIView.animateWithDuration(0.2, animations: {
        leftCell.center.x -= step
      })
      self.leftCell = leftCell
      self.step = step
    }
    
    if let rightCell = collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: currentIndex + 1, inSection: 0)) {
      let step = collectionView.frame.size.width - (rightCell.frame.origin.x - collectionView.contentOffset.x)
      UIView.animateWithDuration(0.2, animations: {
        rightCell.center.x += step
      })
      self.rightCell = rightCell
      self.step = step
    }
  }

}

// MARK: animations

extension TransitionDriver {
  
  private func openFrontViewConfigureConstraints(cell: BasePageCollectionCell) {
    
    if let heightConstraint = cell.frontContainerView.getConstraint(.Height) {
      frontViewFrame.size.height = heightConstraint.constant
      heightConstraint.constant = 236
    }
    
    if let widthConstraint = cell.frontContainerView.getConstraint(.Width) {
      frontViewFrame.size.width = widthConstraint.constant
      widthConstraint.constant = view.bounds.size.width
    }
    
    frontViewFrame.origin.y = cell.frontConstraintY.constant
    cell.frontConstraintY.constant = -view.bounds.size.height / 2 + 236 / 2
  }
  
  private func openBackViewConfigureConstraints(cell: BasePageCollectionCell) {
    
    if let heightConstraint = cell.backContainerView.getConstraint(.Height) {
      backViewFrame.size.height = heightConstraint.constant
      heightConstraint.constant = view.bounds.size.height - 236
    }
    
    if let widthConstraint = cell.backContainerView.getConstraint(.Width) {
      backViewFrame.size.width = widthConstraint.constant
      widthConstraint.constant  = view.bounds.size.width
    }
    
    backViewFrame.origin.y = cell.backConstraintY.constant
    cell.backConstraintY.constant = view.bounds.size.height / 2 - (view.bounds.size.height - 236) / 2
  }
  
  private func closeBackViewConfigurationConstraints(cell: BasePageCollectionCell?) {
    guard let cell = cell else { return }
    
    let heightConstraint = cell.backContainerView.getConstraint(.Height)
    heightConstraint?.constant = backViewFrame.size.height
    
    let widthConstraint = cell.backContainerView.getConstraint(.Width)
    widthConstraint?.constant  = backViewFrame.size.width
    
    cell.backConstraintY.constant = backViewFrame.origin.y
  }
  
  private func closeFrontViewConfigurationConstraints(cell: BasePageCollectionCell?) {
    guard let cell = cell else { return }
    
    if let heightConstraint = cell.frontContainerView.getConstraint(.Height) {
      heightConstraint.constant = frontViewFrame.size.height
    }
    
    if let widthConstraint = cell.frontContainerView.getConstraint(.Width) {
      widthConstraint.constant = frontViewFrame.size.width
    }
    
    cell.frontConstraintY.constant = frontViewFrame.origin.y
  }
  
  private func configureCellBeforeClose(cell: BasePageCollectionCell, offset: CGFloat) {
    cell.frontConstraintY.constant -= offset
    cell.backConstraintY.constant -= offset / 2.0
    if let heightConstraint = cell.backContainerView.getConstraint(.Height) {
      heightConstraint.constant += offset
    }
    cell.contentView.layoutIfNeeded()
  }

}