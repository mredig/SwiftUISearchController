import SwiftUI

@main
struct SwiftUISearchControllerApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
}

extension View {
	func debugAction(_ closure: (Self) -> Void) -> Self {
		#if DEBUG
		closure(self)
		#endif
		return self
	}

	func debugAction(_ closure: () -> Void) -> Self {
		#if DEBUG
		closure()
		#endif
		return self
	}

	func debugBorder(color: Color) -> some View {
		#if DEBUG
		return self.border(color)
		#else
		return self
		#endif
	}
}
