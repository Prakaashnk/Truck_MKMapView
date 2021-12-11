//
//  TrucksListViewController.swift
//  Trucks
//
//  Created by PrakashNK on 08/12/21.
//

import UIKit
import RxSwift
import RxCocoa
import MapKit

class TrucksListViewController: UIViewController {
    
    @IBOutlet weak var trucksListMapView: MKMapView!
    @IBOutlet weak var trucksListTable: UITableView!
    
    var isListView: Bool = true
    var isSearching: Bool = false
    
    var viewModel = TrucksListViewModel()
    let disposeBag = DisposeBag()
    
     var truckSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.showsCancelButton = true
        searchBar.searchBarStyle = .default
        searchBar.placeholder = " Search Here....."
        searchBar.sizeToFit()
        return searchBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBinding()
        setupNavigationBarItems()
        setupSearchBar()
    }
}

//
extension TrucksListViewController {
    private func setupNavigationBarItems(){
        let menuBarButton = UIBarButtonItem(image:UIImage(named: "baseline_menu_black_24pt"), style: .plain, target: self, action: nil)
        self.navigationItem.leftBarButtonItem =  menuBarButton
        let refreshButton = UIBarButtonItem(image:UIImage(named: "baseline_loop_black_24pt"), style: .plain, target: self, action: nil)
        let searchButton = UIBarButtonItem(image:UIImage(named: "baseline_search_black_24pt"), style: .plain, target: self, action: #selector(didTapSearch))
        let toggleImage = (isListView) ? UIImage(named: "baseline_map_black_32pt") : UIImage(named: "baseline_list_black_24pt")
        let toggleButton = UIBarButtonItem(image: toggleImage, style: .plain, target: self, action: #selector(didTapToggle))
        if isListView {
            self.navigationItem.rightBarButtonItems =  [toggleButton, searchButton , refreshButton]
        }
        else {
            self.navigationItem.rightBarButtonItems =  [toggleButton , refreshButton]
        }
        self.title = "Trucks"
    }
    
    
    private func setupSearchBar() {
        truckSearchBar.delegate = self
        trucksListTable.tableHeaderView = (isSearching) ? truckSearchBar : UIView()
    }
    private func setupBinding() {
        trucksListTable.register(TruckCell.nib, forCellReuseIdentifier: TruckCell.identifier)
        viewModel.items.bind(to: trucksListTable.rx.items(cellIdentifier: TruckCell.identifier, cellType: TruckCell.self)) {  (row,truck,cell) in
            cell.viewModel = truck
        }.disposed(by: disposeBag)
        viewModel.getTrucks()
    }
     
    func makeAnnotations() {
        trucksListMapView.removeAnnotations(self.trucksListMapView.annotations)
        for index in 0..<viewModel.filteredTrucks.count {
            let truck = viewModel.filteredTrucks[index]
            let annotation = TruckAnnotation(tag: index)
            if let lat = truck.lastWaypoint?.lat, let lng = truck.lastWaypoint?.lng {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                annotation.coordinate = coordinate
            }
            annotation.title = truck.truckNumber
            self.trucksListMapView.addAnnotation(annotation)
        }
        self.trucksListMapView.fitAllAnnotations()
    }
}

extension TrucksListViewController {
    
    @objc func didTapToggle() {
        truckSearchBar.resignFirstResponder()
        trucksListTable.isHidden = isListView
        trucksListMapView.isHidden = !isListView
        isListView = !isListView
        if !isListView {
            makeAnnotations()
        }
        setupNavigationBarItems()
    }
    
    @objc func didTapSearch() {
        isSearching = !isSearching
        trucksListTable.reloadData()
        setupSearchBar()
    }
    
}

extension TrucksListViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        isSearching = false
        setupSearchBar()
        viewModel.getTrucks()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        viewModel.getTrucksBySearch(searchString: searchBar.text ?? "")
        searchBar.resignFirstResponder()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.getTrucksBySearch(searchString: searchBar.text ?? "")
    }
    
}

extension TrucksListViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "TruckPin"
        if annotation is MKUserLocation {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            if let annote = annotation as? TruckAnnotation {
                let truck = viewModel.filteredTrucks[annote.tag]
                annotationView?.set(image: UIImage(named: "baseline_local_shipping_black_24pt")!, with: getTruckcolor(truck: truck))
            }
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
}
