//
//  DistributedNotificationObserver.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-08-21.
//

import Foundation
import Combine

extension Notification.Name {
    static let screenSaverWillStop = Notification.Name("com.apple.screensaver.willstop")
}

final class DistributedNotificationObserver: ObservableObject {
    private let _publisher = PassthroughSubject<Notification, Never>()
    var publisher: AnyPublisher<Notification, Never> {
        _publisher.eraseToAnyPublisher()
    }
    
    init(name: Notification.Name) {
        DistributedNotificationCenter.default()
            .addObserver(self, selector: #selector(handle(notification:)), name: name, object: nil)
    }
    
    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    @objc private func handle(notification: Notification) {
        _publisher.send(notification)
    }
}
