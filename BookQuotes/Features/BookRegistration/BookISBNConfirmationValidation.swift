import Foundation

struct BookISBNConfirmationValidation {
    let title: String
    let author: String

    var isTitleValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isAuthorValid: Bool {
        !author.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isValid: Bool {
        isTitleValid && isAuthorValid
    }
}
