
import XCTest
import AsyncShell

final class AsyncShellTests: XCTestCase {
  
  func test_pwd() async throws {
    
    let result = try await shell("pwd")
    
    print(result)
  }
  
  func test_ls() async throws {
    
    let result = try await shell("ls")
    
    print(result)
  }
}
