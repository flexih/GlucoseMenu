import Alamofire
import Foundation

public enum EndPoint {
  public enum Region: String, CaseIterable {
    case global
    case ap
    case au
    case ca
    case cn
    case de
    case eu
    case eu2
    case fr
    case jp
    case la
    case ru
    case ae
    case us

    public var regionName: String {
      switch self {
      case .global:
        return "Global"
      case .ae:
        return "United Arab Emirates"
      case .ap:
        return "Asia/Pacific"
      case .au:
        return "Australia"
      case .ca:
        return "Canada"
      case .de:
        return "Germany"
      case .eu:
        return "Europe"
      case .eu2:
        return "Great Britain"
      case .fr:
        return "France"
      case .jp:
        return "Japan"
      case .la:
        return "Latin America"
      case .us:
        return "United States"
      case .cn:
        return "China"
      case .ru:
        return "Russia"
      }
    }

    var baseURL: String {
      switch self {
      case .global:
        return "https://api.libreview.io"
      case .cn:
        return "https://api-cn.myfreestyle.cn"
      case .ru:
        return "https://api.libreview.ru"
      default:
        return "https://api-\(rawValue).libreview.io"
      }
    }
  }

  case auth
  case connection(patientId: String)
  case connections

  var path: String {
    switch self {
    case .auth:
      return "/llu/auth/login"
    case let .connection(patientId):
      return "/llu/connections/\(patientId)/graph"
    case .connections:
      return "/llu/connections"
    }
  }

  public func fullURL(with region: Region) -> String {
    var components = URLComponents(string: region.baseURL)!
    components.path = path
    return components.string!
  }

  public var method: HTTPMethod {
    switch self {
    case .auth:
      .post
    default:
      .get
    }
  }
}
