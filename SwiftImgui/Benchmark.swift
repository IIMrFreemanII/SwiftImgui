import Foundation

func benchmark(title: String, operation: () -> Void ) {
  let startTime = CFAbsoluteTimeGetCurrent()
  operation()
  let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000 * 1000
  print("\(title): \(String(format: "%.3f", timeElapsed)) us")
}
