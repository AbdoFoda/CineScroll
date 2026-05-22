import CoreGraphics

/// Fixed dimensions and ratios for media and hero regions.
enum CineSize {
    static let posterAspectWidth: CGFloat = 2
    static let posterAspectHeight: CGFloat = 3

    static let suggestionPosterWidth: CGFloat = 36
    static let suggestionPosterHeight: CGFloat = 54

    static let detailHeroHeight: CGFloat = 280
    static let detailHeroGradientHeight: CGFloat = 140

    static let initialPlaceholderCardCount = 10

    /// Minimum title area height so grid rows stay even with 1- vs 2-line titles.
    static let movieCardTitleMinHeight: CGFloat = 40

    /// Diameter of an actor avatar circle in the cast carousel.
    static let castAvatarSize: CGFloat = 72
}
