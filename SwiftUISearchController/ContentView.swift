import SwiftUI

struct ContentView: View {
	@StateObject private var searchQueryData = SearchBar.QueryData()

	var body: some View {
		NavigationView {
			List {
				Text("Selected Scope: \(searchQueryData.selectedSearchScope ?? "")")
				ForEach(listContents(), id: \.self) { num in
					Button(num) {
						let token = UISearchToken(icon: UIImage(systemName: "number"), text: num)
						token.representedObject = num
						searchQueryData.searchTokens.append(token)
						searchQueryData.searchScopes.append(num)
					}
				}
			}
			.navigationBarSearch(searchQueryData)
			.navigationBarTitleDisplayMode(.inline)
		}
		.onAppear(perform: {
			searchQueryData.searchScopes = ["fo", "fum"]
			searchQueryData.selectedSearchScope = "fum"
		})
	}

	private func listContents() -> [String] {
		let nums = Array(1...100)
		let letters = nums.map { "\($0)" }

		guard !searchQueryData.searchText.isEmpty || !searchQueryData.searchTokens.isEmpty else { return letters }

		let textResult = letters.filter { $0.contains(searchQueryData.searchText) }
		let tokenResults = searchQueryData.searchTokens.reduce(Set<String>()) {
			guard let num = $1.representedObject as? String else { return $0 }
			let tokenResult = letters.filter { candidate in candidate.contains(num) }
			return $0.union(tokenResult)
		}
		let totalResult = tokenResults.union(textResult)
		return totalResult.sorted {
			guard let a = Int($0), let b = Int($1) else { return false }
			return a < b
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			ContentView()
			ContentView()
				.preferredColorScheme(.dark)
		}
	}
}
