import UIKit
import AVFoundation
import UserNotifications

protocol AlarmEkraniDelegate: AnyObject {
    func alarmDurduruldu(_ alarm: Alarm)
}

class AlarmEkraniViewController: UIViewController {
    
    @IBOutlet weak var alarmEtiketiLabel: UILabel!
    @IBOutlet weak var saatLabel: UILabel!
    @IBOutlet weak var durdurButton: UIButton!
    
    var alarm: Alarm?
    var sesOynatici: AVAudioPlayer?
    weak var delegate: AlarmEkraniDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        alarmiBaslat()
    }
    
    private func setupUI() {
        guard let alarm = alarm else { return }
        
        // Alarm etiketini ayarla
        alarmEtiketiLabel.text = alarm.etiket.isEmpty ? "Alarm" : alarm.etiket
        
        // Saati ayarla
        print("Alarm saati (Date): \(alarm.saat)")
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let formattedTime = formatter.string(from: alarm.saat)
        print("Formatlanmış saat: \(formattedTime)")
        saatLabel.text = formattedTime
        
        // Durdur butonunu ayarla
        durdurButton.layer.cornerRadius = 25
        durdurButton.backgroundColor = .systemRed
        durdurButton.setTitleColor(.white, for: .normal)
    }
    
    private func alarmiBaslat() {
        guard let alarm = alarm else { return }
        
        // Ses dosyasını yükle ve çal
        if let sesURL = Bundle.main.url(forResource: alarm.sesAdi, withExtension: "mp3") {
            do {
                sesOynatici = try AVAudioPlayer(contentsOf: sesURL)
                sesOynatici?.numberOfLoops = -1 // Sonsuz döngü
                sesOynatici?.play()
            } catch {
                print("Ses çalma hatası: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func durdurButtonTapped(_ sender: UIButton) {
        // Sesi durdur
        sesOynatici?.stop()
        
        // Bildirimleri temizle
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Delegate'i bilgilendir
        if let alarm = alarm {
            delegate?.alarmDurduruldu(alarm)
        }
        
        // Ana sayfaya dön
        self.dismiss(animated: true)
    }
} 