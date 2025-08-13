//
//  IconToggle.swift
//  CodeLume
//
//  Created by Lyke on 2025/3/21.
//

//import SwiftUI
//
//struct IconToggle: View {
//    let iconName: String
//    let title: LocalizedStringKey
//    @Binding var isOn: Bool
//    var iconSize: CGFloat = 20
//    var iconColor: Color = .primary
//    var onChange: ((Bool) -> Void)? = nil
//    
//    var body: some View {
//        Toggle(isOn: $isOn) {
//            HStack {
//                Image(systemName: iconName)
//                    .frame(width: iconSize, height: iconSize)
//                    .foregroundColor(iconColor)
//                    .alignmentGuide(.firstTextBaseline) { d in
//                        d[.bottom] + 4
//                    }
//                Text(title)
//                Spacer()
//            }
//        }
//        .toggleStyle(.switch)
//        .onChange(of: isOn) { oldValue, newValue in
//            onChange?(newValue)
//        }
//    }
//}
