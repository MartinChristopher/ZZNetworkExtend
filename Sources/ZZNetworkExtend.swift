//
//  ZZNetworkExtend.swift
//

import UIKit
import Alamofire

public enum ZZNetworkUploadType {
    case image
    case audio
    case video
}

public class ZZNetworkExtend: NSObject {
    
    public static var requestTimeout: TimeInterval = 10.0
    
    public static func requestWith(url: String, method: HTTPMethod, headers: HTTPHeaders, parameters: [String: Any], success: (([String: Any]) -> Void)?, failure: ((AFError?) -> Void)?) {
        AF.request(url, method: method, parameters: parameters, encoding: ZZNetworkEncoding(), headers: headers).response(responseSerializer: ZZNetworkResponseSerializer()) { response in
            switch response.result {
            case .success(let data):
                success?(data as [String: Any])
            case .failure(let error):
                failure?(error.asAFError)
            }
        }
    }
    
    public static func uploadWith(url: String, type: ZZNetworkUploadType, headers: HTTPHeaders, data: Data, upload: ((Progress) -> Void)?, success: (([String: Any]) -> Void)?, failure: ((AFError?) -> Void)?) {
        guard let request = try? URLRequest(url: url, method: .post, headers: headers) else { return }
        AF.upload(multipartFormData: { multipartFormData in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMddHHmmss"
            let timeStr = formatter.string(from: Date())
            switch type {
            case .image:
                multipartFormData.append(data, withName: "file", fileName: "\(timeStr).png", mimeType: "image/jpeg")
            case .audio:
                multipartFormData.append(data, withName: "file", fileName: "\(timeStr).mp3", mimeType: "audio/mpeg")
            case .video:
                multipartFormData.append(data, withName: "file", fileName: "\(timeStr).mp4", mimeType: "video/mp4")
            }
        }, with: request).uploadProgress { progress in
            upload?(progress)
        }.response(responseSerializer: ZZNetworkResponseSerializer()) { response in
            switch response.result {
            case .success(let data):
                success?(data as [String: Any])
            case .failure(let error):
                failure?(error.asAFError)
            }
        }
    }
    
}
// 自定义编码
public struct ZZNetworkEncoding: ParameterEncoding {
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        guard var urlRequest = urlRequest.urlRequest else {
            return URLRequest(url: URL(string: "")!)
        }
        urlRequest.timeoutInterval = ZZNetworkExtend.requestTimeout
        if urlRequest.method == .get {
            return try URLEncoding.default.encode(urlRequest, with: parameters)
        }
        else {
            let data = try JSONSerialization.data(withJSONObject: parameters ?? [:])
            urlRequest.httpBody = data
            return urlRequest
        }
    }
    
}
// 自定义解析
public final class ZZNetworkResponseSerializer: ResponseSerializer {
    
    public typealias SerializedObject = [String: Any]
    
    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> SerializedObject {
        guard error == nil else {
            throw error!
        }
        guard let data = data,
              let dic = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? [String: Any] else {
            if emptyResponseAllowed(forRequest: request, response: response) {
                return [:]
            }
            else {
                throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
        }
        return dic
    }
    
}
