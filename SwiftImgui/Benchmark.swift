import Foundation

private var store = [String: (Int, Double)]()

func benchmark(title: String, median: Bool = false, operation: () -> Void ) {
  let startTime = CFAbsoluteTimeGetCurrent()
  operation()
  let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000 * 1000
  var result = Double()
  
  if median {
    if var temp = store[title] {
      temp.0 += 1
      temp.1 += timeElapsed
      
      result = temp.1 / Double(temp.0)
      
      store[title] = temp
    } else {
      result = timeElapsed
      store[title] = (1, timeElapsed)
    }
  } else {
    result = timeElapsed
  }
  
  print("\(title): \(String(format: "%.3f", result)) us")
}
