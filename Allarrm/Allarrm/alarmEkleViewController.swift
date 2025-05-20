//
//  alarmEkleViewController.swift
//  Allarrm
//
//  Created by Selman Emre Erol on 3.05.2025.
//

//Son düzenlenmiş halini kopyalıyorum şimdi 

import UIKit

protocol AlarmEkleDelegate: AnyObject {
    func alarmOlusturuldu(_ alarm: Alarm)
}

class alarmEkleViewController: UIViewController, TekrarSecimiDelegate, SesSecimiDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var kaydetButton: UIButton!
    
    // MARK: - Veriler
    var secilenSaat: Date?
    var secilenGunler: [String] = []
    var alarmEtiketiMetni: String = ""
    var ertelemeAcikMi: Bool = false
    var secilenSes: String = "Varsayılan"
    
    weak var delegate: AlarmEkleDelegate?
    @IBOutlet weak var alarmEtiketiTextField: UITextField!
    @IBOutlet weak var ertelemeLabel: UILabel!
    @IBOutlet weak var ertelemeSwitch: UISwitch!
    @IBOutlet weak var gunlerLabel: UILabel!
    @IBOutlet weak var sesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateSesLabel()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(klavyeyiKapat))
        view.addGestureRecognizer(tapGesture)
        alarmEtiketiTextField.delegate = self
    }
    
    @IBAction func savebutton(_ sender: UIButton) {
        print("Kaydet butonuna basıldı")
        print("Seçilen saat: \(secilenSaat ?? Date())")
        print("Seçilen günler: \(secilenGunler)")
        print("Alarm etiketi: \(alarmEtiketiMetni)")
        print("Erteleme durumu: \(ertelemeAcikMi)")
        print("Seçilen ses: \(secilenSes)")
        
        alarmEtiketiMetni = alarmEtiketiTextField.text ?? ""
        ertelemeAcikMi = ertelemeSwitch.isOn
        
        let yeniAlarm = Alarm(
            saat: secilenSaat ?? Date(),
            etiket: alarmEtiketiMetni,
            gunler: secilenGunler,
            erteleme: ertelemeAcikMi,
            aktif: true,
            sesAdi: secilenSes
        )
        
        delegate?.alarmOlusturuldu(yeniAlarm)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Saat Seçimi
    @IBAction func datePicker(_ sender: UIDatePicker) {
        secilenSaat = sender.date
    }
    
    @IBAction func sesSecimiButton(_ sender: UIButton) {
        performSegue(withIdentifier: "sesSecimiSegue", sender: self)
    }
    
    // MARK: - Tekrar Butonu (Gün Seçimi)
    @IBAction func tekrarButton(_ sender: UIButton, forEvent event: UIEvent) {
        performSegue(withIdentifier: "tekrarSecimiSegue", sender: self)
    }
    // MARK: - Alarm Etiketi
    @IBAction func alarmEtiket(_ sender: UITextField, forEvent event: UIEvent) {
        alarmEtiketiMetni = sender.text ?? ""
    }
    
    // MARK: - Erteleme
    @IBAction func ertelemeSwitch(_ sender: UISwitch, forEvent event: UIEvent) {
        ertelemeAcikMi = sender.isOn
    }
    
    // MARK: - Gün Seçimi Delegate Metodu
    func gunlerSecildi(_ gunler: [String]) {
        secilenGunler = gunler
        gunlerLabel.text = gunler.joined(separator: ", ")
        print("Alarm için seçilen günler: \(gunler)")
    }
    
    // MARK: - Ses Seçimi Delegate Metodu
    func sesSecildi(_ sesAdi: String) {
        secilenSes = sesAdi
        updateSesLabel()
        print("Alarm için seçilen ses: \(sesAdi)")
    }
    
    private func updateSesLabel() {
        sesLabel.text = "Seçilen Ses: \(secilenSes)"
    }
    
    // MARK: - Segue Ayarları
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tekrarSecimiSegue",
           let hedefVC = segue.destination as? tekrarViewController {
            hedefVC.delegate = self
        } else if segue.identifier == "sesSecimiSegue",
                  let hedefVC = segue.destination as? sesSecimiViewController {
            hedefVC.delegate = self
        }
    }
    
    @objc func klavyeyiKapat() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
