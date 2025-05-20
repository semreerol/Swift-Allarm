import UIKit

protocol TekrarSecimiDelegate: AnyObject {
    func gunlerSecildi(_ gunler: [String])
}

class tekrarViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //weak var delegate: TekrarSecimiDelegate?

    @IBOutlet weak var tableView: UITableView!
    weak var delegate: TekrarSecimiDelegate?
    // Haftanın günleri
    let days = ["","Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]

    // Seçilen günlerin indexPath yerine doğrudan isimleri
    var gunlerSecildi: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = true
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return days.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DayCell", for: indexPath)
        let day = days[indexPath.row]
        print(day)
        cell.textLabel?.text = day

        // Checkmark durumu
        cell.accessoryType = gunlerSecildi.contains(day) ? .checkmark : .none

        return cell
    }

    // MARK: - TableView Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let day = days[indexPath.row]
        if !gunlerSecildi.contains(day) {
            gunlerSecildi.append(day)
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let day = days[indexPath.row]
        if let index = gunlerSecildi.firstIndex(of: day) {
            gunlerSecildi.remove(at: index)
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }

    // MARK: - Kaydet Butonu

    @IBAction func alarmTekrarKaydetButton(_ sender: UIBarButtonItem) {
        delegate?.gunlerSecildi(gunlerSecildi)  // Seçilen günleri ilet
        navigationController?.popViewController(animated: true)
    }
}
