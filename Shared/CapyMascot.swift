import SwiftUI

/// Resolution-independent mascot; smooth from the app's small widget to iPad.
struct CapyMascot: View {
    var animated = true
    @State private var bounce = false

    var body: some View {
        ZStack {
            Ellipse().fill(Color(red: 0.69, green: 0.80, blue: 0.58))
                .frame(width: 126, height: 20).offset(y: 71)
            Ellipse().fill(Color(red: 0.60, green: 0.34, blue: 0.22))
                .frame(width: 28,height: 35).offset(x: -48,y: -40)
            Ellipse().fill(Color(red: 0.60, green: 0.34, blue: 0.22))
                .frame(width: 28,height: 35).offset(x: 47,y: -39)
            RoundedRectangle(cornerRadius: 44)
                .fill(Color(red: 0.90, green: 0.65, blue: 0.44))
                .frame(width: 118,height: 122)
            Circle().fill(.white.opacity(0.6))
                .frame(width: 18,height: 10).offset(x: -34,y: 17)
            Circle().fill(.white.opacity(0.6))
                .frame(width: 18,height: 10).offset(x: 39,y: 17)
            Circle().fill(Color(red: 0.25,green: 0.19,blue: 0.16))
                .frame(width: 7,height: 7).offset(x: -20,y: -9)
            Circle().fill(Color(red: 0.25,green: 0.19,blue: 0.16))
                .frame(width: 7,height: 7).offset(x: 23,y: -9)
            Ellipse().fill(Color(red: 0.74, green: 0.49, blue: 0.34))
                .frame(width: 36,height: 26).offset(x: 16,y: 6)
            Image(systemName: "pause.fill")
                .font(.system(size: 24,weight: .black))
                .foregroundStyle(.white)
                .frame(width: 70,height: 46)
                .background(Color(red: 0.43,green: 0.65,blue: 0.44),in: RoundedRectangle(cornerRadius: 14))
                .offset(y: 48)
            Image(systemName:"leaf.fill").font(.system(size: 28))
                .foregroundStyle(Color(red: 0.39, green: 0.65, blue: 0.35))
                .rotationEffect(.degrees(-35)).offset(x: 8,y: -79)
        }
        .frame(width: 170,height: 185)
        .offset(y: bounce ? -6 : 2)
        .animation(animated ? .easeInOut(duration: 1.55).repeatForever(autoreverses: true) : nil,value: bounce)
        .onAppear { bounce = animated }
        .accessibilityLabel("BaraPause capybara mascot")
    }
}
