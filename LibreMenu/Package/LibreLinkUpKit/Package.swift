// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "LibreLinkUpKit",
  platforms: [.iOS("17.0"), .watchOS(.v10), .macOS("10.15")],
  products: [
    .library(name: "LibreLinkUpKit", targets: ["LibreLinkUpKit"]),
  ],
  dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.0")),
  ],
  targets: [
    .target(
      name: "LibreLinkUpKit",
      dependencies: ["Alamofire"],
      path: "Source"
    ),
  ]
)
