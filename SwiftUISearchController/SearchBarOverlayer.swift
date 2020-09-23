import SwiftUI
import Combine


//extension View {
//	public func navigationBarSearch(_ searchText: Binding<String>) -> some View {
//		overlay(SearchBarOverlayer(searchText: searchText).frame(width: 0, height: 0))
//	}
//}

/**

This doesn't actually draw anything on screen, but instead reaches into the UIKit background and inserts a search controller into the parent navigation controller.

Utilized via adding a `.overlay` to a view within the hierarchy you wish to inject a UISearchBar into. For example:

``` swift
SearchBarOverlayer(searchText: searchText)
	.frame(width: 0, height: 0)
```

Inspired by this [SO post](https://stackoverflow.com/a/62363466/2985369)
*/
struct SearchBarOverlayer: UIViewControllerRepresentable {
	let searchQueryData: SearchBarQueryData

	func makeUIViewController(context: Context) -> SearchBarWrapperController {
		SearchBarWrapperController()
	}

	func updateUIViewController(_ controller: SearchBarWrapperController, context: Context) {
		controller.searchController = context.coordinator.searchController
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(parent: self)
	}

	class Coordinator: NSObject, UISearchResultsUpdating {
		let parent: SearchBarOverlayer
		let searchController: UISearchController

		private var subs: Set<AnyCancellable> = []

		init(parent: SearchBarOverlayer) {
			self.parent = parent
			self.searchController = UISearchController(searchResultsController: nil)

			super.init()

			searchController.searchResultsUpdater = self
			searchController.hidesNavigationBarDuringPresentation = true
			searchController.obscuresBackgroundDuringPresentation = false

			parent.searchQueryData.objectWillChange.receive(on: RunLoop.main).sink(receiveValue: { [weak self] _ in
				guard let self = self else { return }
				let collector = self.parent.searchQueryData
				let searchBar = self.searchController.searchBar

				if collector != searchBar {
					collector.apply(to: searchBar)
				}

			})
			.store(in: &subs)
		}

		deinit {
			subs.forEach { $0.cancel() }
		}

		// MARK: - UISearchResultsUpdating
		func updateSearchResults(for searchController: UISearchController) {
			let collector = parent.searchQueryData

			if collector != searchController.searchBar {
				collector.update(from: searchController.searchBar)
			}
		}
	}

	class SearchBarWrapperController: UIViewController {
		// insert our search controller into the parent UIKit nav controller
		var searchController: UISearchController? {
			get { parent?.navigationItem.searchController }
			set { parent?.navigationItem.searchController = newValue }
		}
	}
}



class SearchBarQueryData: ObservableObject {
	@Published var searchText: String = ""
	@Published var searchTokens: [UISearchToken] = []
	@Published var searchScopes: [String] = []
	@Published var selectedSearchScope: String?

	/// Not thread safe. Make sure this is always called on main thread!
	var state = State.waiting
	enum State {
		case waiting
		case updating
		case applying
	}

	func apply(to searchBar: UISearchBar) {
		guard state == .waiting else { return }
		defer { state = .waiting }
		state = .applying

		searchBar.text = searchText
		searchBar.searchTextField.tokens = searchTokens
		searchBar.scopeButtonTitles = searchScopes
		searchBar.selectedScopeButtonIndex = searchScopes.firstIndex(of: selectedSearchScope ?? "") ?? -1
	}

	func update(from searchBar: UISearchBar) {
		guard state == .waiting else { return }
		defer { state = .waiting }
		state = .updating

		searchText = searchBar.text ?? ""
		searchTokens = searchBar.searchTextField.tokens
		searchScopes = searchBar.scopeButtonTitles ?? []

		if searchBar.selectedScopeButtonIndex >= 0, let scopes = searchBar.scopeButtonTitles {
			selectedSearchScope = scopes[searchBar.selectedScopeButtonIndex]
		} else {
			selectedSearchScope = nil
		}

	}

	static func == (lhs: SearchBarQueryData, rhs: UISearchBar) -> Bool {
		let selectedOnBar: String?
		if rhs.selectedScopeButtonIndex >= 0, let scopes = rhs.scopeButtonTitles {
			selectedOnBar = scopes[rhs.selectedScopeButtonIndex]
		} else {
			selectedOnBar = nil
		}

		return lhs.searchText == rhs.text &&
			lhs.searchTokens == rhs.searchTextField.tokens &&
			lhs.searchScopes == rhs.scopeButtonTitles &&
			lhs.selectedSearchScope == selectedOnBar
	}

	static func != (lhs: SearchBarQueryData, rhs: UISearchBar) -> Bool {
		!(lhs == rhs)
	}
}