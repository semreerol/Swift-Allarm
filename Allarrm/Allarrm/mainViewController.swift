//
//  mainViewController.swift
//  Allarrm
//
//  Created by Selman Emre Erol on 3.05.2025.
//

import UIKit
import UserNotifications
import CoreData

class mainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, AlarmEkleDelegate, AlarmEkraniDelegate {
    
    @IBOutlet weak var alarmListesi: UITableView!
    var alarmlar: [Alarm] = []
    private var alarmTimer: Timer?
    
    // Core Data için context
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alarmListesi.delegate = self
        alarmListesi.dataSource = self
        startAlarmCheck()
        
        // Kayıtlı alarmları yükle
        loadAlarms()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Bildirim izni verildi")
            } else {
                print("Bildirim izni reddedildi: \(String(describing: error))")
            }
        }
    }
    
    private func startAlarmCheck() {
        // Her dakika kontrol et
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkAlarms()
        }
    }
    
    private func checkAlarms() {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentWeekday = calendar.component(.weekday, from: now) - 1 // 0 = Pazar
        let comps = calendar.dateComponents([.year, .month, .day], from: now)

        for (index, alarm) in alarmlar.enumerated() {
            // Sadece aktif alarmları kontrol et
            guard alarm.aktif else { continue }
            
            let alarmHour = calendar.component(.hour, from: alarm.saat)
            let alarmMinute = calendar.component(.minute, from: alarm.saat)
            
            // Saat ve dakika eşleşiyor mu kontrol et
            if currentHour == alarmHour && currentMinute == alarmMinute {
                // Gün kontrolü
                let gunler = ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
                let currentGun = gunler[currentWeekday]
                
                if alarm.gunler.contains(currentGun) {
                    // Alarmı silmeden sadece alarm ekranını göster
                    var dateComponents = DateComponents()
                    dateComponents.year = comps.year
                    dateComponents.month = comps.month
                    dateComponents.day = comps.day
                    dateComponents.hour = alarmHour
                    dateComponents.minute = alarmMinute
                    let alarmDate = calendar.date(from: dateComponents) ?? now
                    var alarmWithCorrectDate = alarm
                    alarmWithCorrectDate.saat = alarmDate
                    showAlarmScreen(for: alarmWithCorrectDate)
                    // Bildirim gönder
                    let content = UNMutableNotificationContent()
                    content.title = "Alarm"
                    content.body = alarm.etiket.isEmpty ? "Alarm Zamanı!" : alarm.etiket
                    content.sound = UNNotificationSound(named: UNNotificationSoundName("\(alarm.sesAdi).mp3"))
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Bildirim gönderilemedi: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Alarm Ekranı Gösterme
    // mainViewController.swift içinde...

    func showAlarmScreen(for alarm: Alarm) {
        DispatchQueue.main.async {
            guard let topVC = UIApplication.shared.visibleViewController else {
                print("ViewController bulunamadı")
                return
            }

            if topVC is AlarmEkraniViewController {
                print("Alarm ekranı zaten açık")
                return
            }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let alarmVC = storyboard.instantiateViewController(withIdentifier: "AlarmEkraniViewController") as? AlarmEkraniViewController {
                alarmVC.alarm = alarm
                alarmVC.delegate = self
                alarmVC.modalPresentationStyle = .fullScreen
                topVC.present(alarmVC, animated: true)
            }
        }
    }
    
    
    // Kayıtlı alarmları yükle
    private func loadAlarms() {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AlarmEntity")
        
        do {
            let alarmEntities = try context.fetch(fetchRequest)
            alarmlar = alarmEntities.compactMap { entity in
                guard let saat = entity.value(forKey: "saat") as? Date,
                      let etiket = entity.value(forKey: "etiket") as? String,
                      let gunler = entity.value(forKey: "gunler") as? [String],
                      let erteleme = entity.value(forKey: "erteleme") as? Bool,
                      let aktif = entity.value(forKey: "aktif") as? Bool else {
                    return nil
                }
                
                return Alarm(
                    saat: saat,
                    etiket: etiket,
                    gunler: gunler,
                    erteleme: erteleme,
                    aktif: aktif
                )
            }
            alarmListesi.reloadData()
        } catch {
            print("Alarmlar yüklenemedi: \(error)")
        }
    }
    
    // Alarmı Core Data'ya kaydet
    private func saveAlarm(_ alarm: Alarm) {
        guard let entity = NSEntityDescription.entity(forEntityName: "AlarmEntity", in: context) else { return }
        
        let alarmEntity = NSManagedObject(entity: entity, insertInto: context)
        alarmEntity.setValue(alarm.saat, forKey: "saat")
        alarmEntity.setValue(alarm.etiket, forKey: "etiket")
        alarmEntity.setValue(alarm.gunler, forKey: "gunler")
        alarmEntity.setValue(alarm.erteleme, forKey: "erteleme")
        alarmEntity.setValue(alarm.aktif, forKey: "aktif")
        
        do {
            try context.save()
            print("Alarm kaydedildi")
        } catch {
            print("Alarm kaydedilemedi: \(error)")
        }
    }
    
    // Alarmı Core Data'dan sil
    private func deleteAlarm(_ alarm: Alarm) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AlarmEntity")
        fetchRequest.predicate = NSPredicate(format: "saat == %@ AND etiket == %@", alarm.saat as NSDate, alarm.etiket)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let alarmEntity = results.first {
                context.delete(alarmEntity)
                try context.save()
                print("Alarm silindi")
            }
        } catch {
            print("Alarm silinemedi: \(error)")
        }
    }
    
    // Alarmı Core Data'da güncelle
    private func updateAlarm(_ alarm: Alarm) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AlarmEntity")
        fetchRequest.predicate = NSPredicate(format: "saat == %@ AND etiket == %@", alarm.saat as NSDate, alarm.etiket)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let alarmEntity = results.first {
                alarmEntity.setValue(alarm.aktif, forKey: "aktif")
                try context.save()
                print("Alarm güncellendi")
            }
        } catch {
            print("Alarm güncellenemedi: \(error)")
        }
    }
    
    func alarmOlusturuldu(_ alarm: Alarm) {
        alarmlar.append(alarm)
        alarmListesi.reloadData()
        
        // Bildirimleri ayarla
        let bildirimMerkezi = UNUserNotificationCenter.current()
        
        // Her seçili gün için bildirim oluştur
        for gun in alarm.gunler {
            let icerik = UNMutableNotificationContent()
            icerik.title = "Alarm"
            icerik.body = alarm.etiket
            icerik.sound = UNNotificationSound(named: UNNotificationSoundName("\(alarm.sesAdi).mp3"))
            
            // Alarm bilgilerini userInfo'ya ekle
            icerik.userInfo = [
                "etiket": alarm.etiket,
                "saat": alarm.saat.timeIntervalSince1970,
                "gunler": alarm.gunler,
                "erteleme": alarm.erteleme,
                "aktif": alarm.aktif
            ]
            
            // Bildirim tetikleyicisini ayarla
            var dateComponents = DateComponents()
            let calendar = Calendar.current
            let alarmSaat = calendar.component(.hour, from: alarm.saat)
            let alarmDakika = calendar.component(.minute, from: alarm.saat)
            
            // Günü ayarla
            switch gun {
            case "Pazartesi": dateComponents.weekday = 2
            case "Salı": dateComponents.weekday = 3
            case "Çarşamba": dateComponents.weekday = 4
            case "Perşembe": dateComponents.weekday = 5
            case "Cuma": dateComponents.weekday = 6
            case "Cumartesi": dateComponents.weekday = 7
            case "Pazar": dateComponents.weekday = 1
            default: break
            }
            
            dateComponents.hour = alarmSaat
            dateComponents.minute = alarmDakika
            
            let tetikleyici = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            // Benzersiz bir tanımlayıcı oluştur
            let bildirimID = "\(alarm.etiket)_\(gun)_\(alarmSaat):\(alarmDakika)"
            
            let istek = UNNotificationRequest(identifier: bildirimID, content: icerik, trigger: tetikleyici)

            bildirimMerkezi.add(istek) { hata in
                if let hata = hata {
                    print("Bildirim hatası: \(hata.localizedDescription)")
                }
            }
        }
        
        // Alarmı Core Data'ya kaydet
        saveAlarm(alarm)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "alarmEkleSegue",
           let hedefVC = segue.destination as? alarmEkleViewController {
            hedefVC.delegate = self
        }
    }
    
    // MARK: - Alarm Ekleme Butonu
    @IBAction func alarmEkle(_ sender: UIBarButtonItem) {
        // Bu fonksiyon segue ile çalıştığı için boş kalabilir
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if alarmlar.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "Henüz alarm eklemediniz.\n+ simgesine dokunarak başlayın."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .gray
            emptyLabel.numberOfLines = 0
            emptyLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
        return alarmlar.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let alarm = alarmlar[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmCell", for: indexPath) as! AlarmTableViewCell

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        cell.saatLabel.text = dateFormatter.string(from: alarm.saat)
        cell.etiketLabel.text = alarm.etiket.isEmpty ? "Alarm" : alarm.etiket
        cell.gunlerLabel.text = alarm.gunler.joined(separator: ", ")
        cell.aktifSwitch.isOn = alarm.aktif
        cell.arkaPlanView.layer.cornerRadius = 20
        cell.arkaPlanView.layer.masksToBounds = true
        cell.arkaPlanView.backgroundColor = .white
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.backgroundColor = .clear
        cell.backgroundColor = .clear
    }
    
    // Silme işlemi için gerekli fonksiyonlar
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Alarmı diziden kaldır
            let silinecekAlarm = alarmlar[indexPath.row]
            alarmlar.remove(at: indexPath.row)
            
            // Alarmı Core Data'dan sil
            deleteAlarm(silinecekAlarm)
            
            // Bildirimleri temizle
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            // Kalan alarmlar için bildirimleri yeniden planla
            for alarm in alarmlar {
                let content = UNMutableNotificationContent()
                content.title = "Alarm"
                content.body = alarm.etiket.isEmpty ? "Alarm Zamanı!" : alarm.etiket
                content.sound = UNNotificationSound(named: UNNotificationSoundName("\(alarm.sesAdi).mp3"))

                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: alarm.saat)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                let uuid = UUID().uuidString
                let request = UNNotificationRequest(identifier: uuid, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Bildirim eklenemedi: \(error)")
                    }
                }
            }
            
            // Tabloyu güncelle
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // Silme butonunun metnini özelleştirme
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Sil"
    }
    
    // MARK: - AlarmEkraniDelegate
    func alarmDurduruldu(_ alarm: Alarm) {
        // Alarmı güncelle
        if let index = alarmlar.firstIndex(where: { $0.saat == alarm.saat && $0.etiket == alarm.etiket }) {
            var updatedAlarm = alarm
            updatedAlarm.aktif = false
            alarmlar[index] = updatedAlarm
            updateAlarm(updatedAlarm)
            alarmListesi.reloadData()
        }
    }
    
    deinit {
        alarmTimer?.invalidate()
    }
}
