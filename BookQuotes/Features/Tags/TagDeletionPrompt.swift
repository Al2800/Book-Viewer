struct TagDeletionPrompt {
    let quoteCount: Int

    let title = "Delete Tag?"
    let destructiveActionTitle = "Delete Tag"

    var message: String {
        "This will remove the tag from all \(quoteCount) quote\(quoteCount == 1 ? "" : "s"). This cannot be undone."
    }
}
