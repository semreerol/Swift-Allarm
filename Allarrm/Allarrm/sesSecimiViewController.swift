import UIKit
import AVFoundation

protocol SesSecimiDelegate: AnyObject {
    func sesSecildi(_ sesAdi: String)
}

class sesSecimiViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    weak var delegate: SesSecimiDelegate?
    
    // Kullanılabilir alarm sesleri
    let alarmSesleri = [
        "Varsayılan",
        "Uyarı",
        "Bildirim",
        "Mesaj",
        "E-posta",
        "Takvim"
    ]
    
    var secilenSes: String = "Varsayılan"
    private var player: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = true
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarmSesleri.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SesCell", for: indexPath)
        let ses = alarmSesleri[indexPath.row]
        cell.textLabel?.text = ses
        
        // Seçili sesi işaretle
        cell.accessoryType = ses == secilenSes ? .checkmark : .none
        
        return cell
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let secilenSesAdi = alarmSesleri[indexPath.row]
        secilenSes = secilenSesAdi
        
        // Önceki sesi durdur
        player?.stop()
        
        // Seçili sesi çal
        if secilenSesAdi != "Varsayılan" {
            let systemSoundID: SystemSoundID
            
            switch secilenSesAdi {
            case "Uyarı":
                systemSoundID = 1005 // Uyarı sesi
            case "Bildirim":
                systemSoundID = 1007 // Bildirim sesi
            case "Mesaj":
                systemSoundID = 1003 // Mesaj sesi
            case "E-posta":
                systemSoundID = 1000 // E-posta sesi
            case "Takvim":
                systemSoundID = 1004 // Takvim sesi
            default:
                systemSoundID = 1005 // Varsayılan olarak uyarı sesi
            }
            
            AudioServicesPlaySystemSound(systemSoundID)
        }
        
        // Seçimi güncelle
        tableView.reloadData()
    }
    
    // MARK: - Kaydet Butonu
    @IBAction func sesKaydetButton(_ sender: UIBarButtonItem) {
        // Sesi durdur
        player?.stop()
        
        delegate?.sesSecildi(secilenSes)
        navigationController?.popViewController(animated: true)
    }
} 