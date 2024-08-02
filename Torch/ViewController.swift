//
//  ViewController.swift
//  Torch
//
//  Created by Deszip on 04.07.2024.
//

import UIKit

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var resultsTable: UITableView?
    @IBOutlet weak var console: UITextView!

    var index: SpotlightIndex?
    var results: [String] = []

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        index = SpotlightIndex() { self.log($0) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        index?.add(chunks: ["Sun and moon", "Sol and luna"])
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.index?.search(searchText) { results in
            DispatchQueue.main.async {
                self.results = results
                self.resultsTable?.reloadData()
            }
        }
    }

    // MARK: - Console

    private func log(_ text: String) {
        DispatchQueue.main.async {
            self.console.text = self.console.text + text + "\n"
            self.console.scrollRangeToVisible(NSMakeRange(self.console.text.lengthOfBytes(using: .utf8) - 1, 1))
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReesultCell", for: indexPath)
        cell.textLabel?.text = self.results[indexPath.item]

        return cell
    }

}
