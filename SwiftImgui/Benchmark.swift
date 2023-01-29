import Foundation

var formatter: NumberFormatter {
  let value = NumberFormatter()
  value.maximumFractionDigits = 3
  value.minimumFractionDigits = 3
  return value
}

func benchmark(title: String, operation: () -> Void ) {
  let startTime = CFAbsoluteTimeGetCurrent()
  operation()
  let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000 * 1000
  print("\(title): \(String(format: "%.3f", timeElapsed)) us")
}
