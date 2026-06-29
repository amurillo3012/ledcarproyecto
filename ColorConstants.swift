import SwiftUI

// MARK: - Color Constants
struct AppColors {
    // PRIMARIOS
    static let primary = Color(#colorLiteral(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)) // Cyan
    static let secondary = Color(#colorLiteral(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)) // Red
    
    // FONDOS
    static let backgroundDark = Color(#colorLiteral(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0))
    static let backgroundDarker = Color(#colorLiteral(red: 0.12, green: 0.08, blue: 0.15, alpha: 1.0))
    static let surfaceLight = Color.white.opacity(0.05)
    static let surfaceDark = Color.black.opacity(0.3)
    
    // ESTADO
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // TEXTO
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    
    // EFECTOS
    static let gradient1 = LinearGradient(
        gradient: Gradient(colors: [
            Color(#colorLiteral(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)),
            Color(#colorLiteral(red: 0.12, green: 0.08, blue: 0.15, alpha: 1))
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Tipografía
struct AppTypography {
    static let titleLarge = Font.system(size: 26, weight: .bold)
    static let titleMedium = Font.system(size: 20, weight: .semibold)
    static let titleSmall = Font.system(size: 18, weight: .semibold)
    
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)
    static let bodySmall = Font.system(size: 12, weight: .regular)
    
    static let captionLarge = Font.system(size: 12, weight: .semibold)
    static let captionSmall = Font.caption
}

// MARK: - Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Corner Radius
struct AppRadius {
    static let small: CGFloat = 6
    static let medium: CGFloat = 10
    static let large: CGFloat = 16
    static let circle: CGFloat = .infinity
}

// MARK: - Shadows
struct AppShadows {
    static let small = Shadow(
        color: Color.black.opacity(0.1),
        radius: 2,
        x: 0,
        y: 1
    )
    
    static let medium = Shadow(
        color: Color.black.opacity(0.15),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let large = Shadow(
        color: Color.black.opacity(0.2),
        radius: 8,
        x: 0,
        y: 4
    )
}

// Helper struct for shadows
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}
