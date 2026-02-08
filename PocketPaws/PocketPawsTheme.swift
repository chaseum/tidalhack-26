import SwiftUI

// MARK: - Theme Modifiers
struct PetPalCard: ViewModifier {
    var radius: CGFloat = DesignTokens.Radius.m
    var shadow: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(DesignTokens.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignTokens.Colors.surface,
                                DesignTokens.Colors.surface.opacity(0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(shadow ? 0.1 : 0.05),
                radius: shadow ? 20 : 10,
                x: 0,
                y: shadow ? 5 : 2
            )
    }
}

extension View {
    func petPalCard(radius: CGFloat = DesignTokens.Radius.m, shadow: Bool = false) -> some View {
        modifier(PetPalCard(radius: radius, shadow: shadow))
    }
}

// MARK: - Reusable Components
struct PetPalBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: DesignTokens.Colors.backgroundGradient),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                TrianglePattern(size: proxy.size)
                    .opacity(0.3)
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    Spacer(minLength: proxy.size.height * 0.52)

                    SoftWaveShape()
                        .fill(DesignTokens.Colors.waveTop.opacity(0.9))
                        .frame(height: 160)

                    SoftWaveShape()
                        .fill(DesignTokens.Colors.waveBottom)
                        .frame(height: 250)
                        .offset(y: -88)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

struct CircularIconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.primary, DesignTokens.Colors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.65), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

private struct TrianglePattern: View {
    let size: CGSize

    var body: some View {
        let columns = max(Int(size.width), 1)

        ZStack {
            ForEach(0..<30, id: \.self) { index in
                let triangleSize = triangleDimension(for: index)
                let trianglePosition = trianglePosition(for: index, width: columns)

                TriangleShape()
                    .fill(triangleColor(for: index))
                    .frame(width: triangleSize.width, height: triangleSize.height)
                    .rotationEffect(.degrees(Double((index * 29) % 360)))
                    .position(x: trianglePosition.x, y: trianglePosition.y)
            }
        }
    }

    private func triangleColor(for index: Int) -> Color {
        index.isMultiple(of: 2)
            ? DesignTokens.Colors.primary.opacity(0.14)
            : DesignTokens.Colors.secondary.opacity(0.16)
    }

    private func triangleDimension(for index: Int) -> CGSize {
        CGSize(
            width: CGFloat(16 + (index % 5) * 7),
            height: CGFloat(12 + (index % 4) * 7)
        )
    }

    private func trianglePosition(for index: Int, width: Int) -> CGPoint {
        CGPoint(
            x: CGFloat((index * 61) % width),
            y: CGFloat(40 + (index / 5) * 56 + (index % 3) * 8)
        )
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct SoftWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.45))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.33, y: rect.height * 0.56),
            control1: CGPoint(x: rect.width * 0.10, y: rect.height * 0.18),
            control2: CGPoint(x: rect.width * 0.20, y: rect.height * 0.82)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.68, y: rect.height * 0.40),
            control1: CGPoint(x: rect.width * 0.46, y: rect.height * 0.26),
            control2: CGPoint(x: rect.width * 0.56, y: rect.height * 0.66)
        )
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.53),
            control1: CGPoint(x: rect.width * 0.80, y: rect.height * 0.18),
            control2: CGPoint(x: rect.width * 0.90, y: rect.height * 0.82)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Previews
struct ThemePreviews_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            PetPalBackground()

            VStack(spacing: DesignTokens.Spacing.l) {
                HStack(spacing: DesignTokens.Spacing.m) {
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(DesignTokens.Colors.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pixel")
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        LevelChip(level: 12)
                    }

                    Spacer()

                    CircularIconButton(icon: "bell.fill") {
                        print("Notify clicked")
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                    Text("Daily Quest")
                        .font(DesignTokens.Typography.headline)
                    Text("Take Pixel for a 15-minute walk to earn 50 XP.")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .petPalCard(shadow: true)
                .padding(.horizontal)

                HStack(spacing: DesignTokens.Spacing.l) {
                    CircularIconButton(icon: "camera.fill") {}
                    CircularIconButton(icon: "heart.fill") {}
                    CircularIconButton(icon: "leaf.fill") {}
                }

                Spacer()
            }
            .padding(.top, DesignTokens.Spacing.xl)
        }
    }
}
