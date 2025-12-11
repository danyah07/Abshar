//
//  AppNavigator.swift
//  Abshar
//
//  Created by Danyah ALbarqawi on 11/12/2025.
//

import Foundation
internal import Combine


import Foundation
internal import Combine

enum AppScreen: String, CaseIterable {
    case home = "home"
    case services = "services"
    case identity = "identity"
    case passport = "passport"
    case driving = "driving"
    case visa = "visa"
    case traffic = "traffic"
    case civil = "civil"
    
    var arabicName: String {
        switch self {
        case .home: return "الرئيسية"
        case .services: return "خدماتي"
        case .identity: return "خدمات الهوية الوطنية"
        case .passport: return "تجديد جواز السفر"
        case .driving: return "تجديد رخصة القيادة"
        case .visa: return "التأشيرات"
        case .traffic: return "تسجيل حادث بسيط"
        case .civil: return "الأحوال المدنية"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .services: return "person.crop.circle"
        case .identity: return "square.stack.3d.up.fill"
        case .passport: return "globe.europe.africa.fill"
        case .driving: return "creditcard.fill"
        case .visa: return "airplane"
        case .traffic: return "car.fill"
        case .civil: return "person.3.fill"
        }
    }
}

class AppNavigator: ObservableObject {
    @Published var currentScreen: AppScreen = .home
    @Published var selectedTab: Int = 4  // الرئيسية
    
    func navigate(to screenName: String) {
        if let screen = AppScreen(rawValue: screenName.lowercased()) {
            DispatchQueue.main.async {
                self.currentScreen = screen
                
                // Update tab based on screen
                switch screen {
                case .home:
                    self.selectedTab = 4
                case .services:
                    self.selectedTab = 3
                default:
                    break
                }
            }
        }
    }
    
    func goHome() {
        DispatchQueue.main.async {
            self.currentScreen = .home
            self.selectedTab = 4
        }
    }
}
