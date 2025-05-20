import UIKit

class AlarmTableViewCell: UITableViewCell {
    @IBOutlet weak var arkaPlanView: UIView!
    @IBOutlet weak var saatLabel: UILabel!
    @IBOutlet weak var etiketLabel: UILabel!
    @IBOutlet weak var gunlerLabel: UILabel!
    @IBOutlet weak var aktifSwitch: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        arkaPlanView.layer.cornerRadius = 20
        arkaPlanView.layer.masksToBounds = true
        arkaPlanView.backgroundColor = .white
        self.backgroundColor = .clear
    }
} 