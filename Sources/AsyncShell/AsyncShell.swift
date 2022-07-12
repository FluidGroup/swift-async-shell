
import Foundation

actor ProcessContext {
  
  private var outputData = Data()
  private var errorData = Data()
  
  func appendOutput(_ data: Data) {
    outputData.append(data)
  }
  
  func appendError(_ data: Data) {
    errorData.append(data)
  }
  
  func outputString() -> String {
    guard let output = String(data: outputData, encoding: .utf8) else {
      return ""
    }
    
    guard !output.hasSuffix("\n") else {
      let endIndex = output.index(before: output.endIndex)
      return String(output[..<endIndex])
    }
    
    return output
  }
  
  func errorString() -> String {
    guard let output = String(data: errorData, encoding: .utf8) else {
      return ""
    }
    
    guard !output.hasSuffix("\n") else {
      let endIndex = output.index(before: output.endIndex)
      return String(output[..<endIndex])
    }
    
    return output
  }
}

public struct ShellError: Error {
  
  
}

public func shell(_ command: String) async throws -> String {
  try await Process().launchBash(with: command)
}

extension Process {
  
  func launchBash(with command: String) async throws -> String {
          
    launchPath = "/bin/bash"
    arguments = ["-c", command]
    
    let context = ProcessContext()
    
    let outputPipe = Pipe()
    standardOutput = outputPipe
    
    let errorPipe = Pipe()
    standardError = errorPipe
    
    outputPipe.fileHandleForReading.readabilityHandler = { handler in
      let data = handler.availableData
      Task {
        await context.appendOutput(data)
      }
    }
    
    errorPipe.fileHandleForReading.readabilityHandler = { handler in
      let data = handler.availableData
      Task {
        await context.appendError(data)
      }
    }
    
    try run()
    
    waitUntilExit()
    
    outputPipe.fileHandleForReading.readabilityHandler = nil
    errorPipe.fileHandleForReading.readabilityHandler = nil
            
    if terminationStatus != 0 {
      return await context.errorString()
    }
    
    return await context.outputString()
   
  }
  
}
