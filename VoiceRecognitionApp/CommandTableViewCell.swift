//
//  CommandTableViewCell.swift
//  VoiceRecognitionApp
//
//  Created by BC on 2017-02-23.
//  Copyright © 2017 BC. All rights reserved.
//

import UIKit

class CommandTableViewCell: UITableViewCell{

    
    
    @IBOutlet weak var commandNameLabel: UILabel!
    @IBOutlet weak var playSampleButton: UIButton!

    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func playSampleButtonPressed(_ sender: Any) {
        
    }
}
