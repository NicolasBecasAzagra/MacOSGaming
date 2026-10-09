import SwiftUI

public struct ReadinessGaugeView: View {
    public let score: Int

    public init(score: Int) {
        self.score = score
    }

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 10)
                    .frame(width: 110, height: 110)

                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(score, 0), 100)) / 100.0)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 110, height: 110)
                    .animation(.easeInOut(duration: 0.6), value: score)

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                    Text("/ 100")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Text(scoreTierText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(scoreColor)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(12)
    }

    private var scoreColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .blue
        } else if score >= 40 {
            return .orange
        } else {
            return .red
        }
    }

    private var scoreTierText: String {
        if score >= 80 {
            return "Excelente para Gaming"
        } else if score >= 60 {
            return "Preparado para Gaming"
        } else if score >= 40 {
            return "Rendimiento Limitado"
        } else {
            return "Requiere Configuración"
        }
    }
}
