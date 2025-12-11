//
//  AbasharTheme.swift
//  Abshar
//
//  Created by Danyah ALbarqawi on 11/12/2025.
//

import SwiftUI

// MARK: - Theme Colors
extension Color {
    static let absherBackground = Color(red: 26/255, green: 26/255, blue: 26/255)
    static let absherCard = Color(red: 47/255, green: 49/255, blue: 51/255)
    static let absherMint = Color(red: 155/255, green: 231/255, blue: 197/255)
}

// MARK: - Custom Font
fileprivate let absherFontName = "DINNextLTArabic-Regular"

extension Font {
    static func absher(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(absherFontName, size: size).weight(weight)
    }
}

// MARK: - Service Card
struct ServiceCard: View {
    var icon: String
    var title: String
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.absherMint)
                
                Text(title)
                    .font(.absher(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(Color.absherCard)
            .cornerRadius(22)
        }
    }
}

// MARK: - Tab Item
struct TabItem: View {
    var icon: String
    var title: String
    var isActive: Bool = false
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isActive ? .absherMint : .gray)
                
                Text(title)
                    .font(.absher(size: 12))
                    .foregroundColor(isActive ? .absherMint : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
        }
    }
}

