//
//  ViewController.swift
//  Torch
//
//  Created by Deszip on 04.07.2024.
//

import UIKit

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var resultsTable: UITableView?

    let index = SpotlightIndex()
    var results: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        index.add(text: "Sun and moon")
        index.add(text: "Sol and luna")
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.index.search(searchText) { results in
            DispatchQueue.main.async {
                self.results = results
                self.resultsTable?.reloadData()
            }
        }
    }

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

