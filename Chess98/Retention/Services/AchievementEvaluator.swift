import Foundation

enum AchievementEvaluator {
    /// Returns achievements from the catalog whose predicate is now true and
    /// which aren't in `alreadyUnlocked`.
    static func newlyUnlocked(
        in context: AchievementContext,
        alreadyUnlocked: Set<String>
    ) -> [Achievement] {
        AchievementCatalog.all
            .filter { !alreadyUnlocked.contains($0.id) && $0.predicate(context) }
    }
}
