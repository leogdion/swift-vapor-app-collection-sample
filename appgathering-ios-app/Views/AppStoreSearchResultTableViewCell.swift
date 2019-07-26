//
//  AppStoreSearchResultTableViewCell.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/15/19.
//

import UIKit

class AppStoreSearchResultTableViewCell: UITableViewCell {
  @IBOutlet var subtitleLabel: UILabel!
  @IBOutlet var nameLabel: UILabel!
  @IBOutlet var artworkView: UIImageView!
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override func prepareForReuse() {
    artworkView.image = nil
  }
}
