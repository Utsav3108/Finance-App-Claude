import Testing
import Foundation
@testable import FinanceAppWithClaude

@MainActor
struct TransactionDetailViewModelTests {
    private func makeTransaction(reviewed: Bool = false) -> Transaction {
        Transaction(id: "t1", title: "Whole Foods", amount: -54.20, date: Date(timeIntervalSince1970: 1_700_000_000),
                    category: .groceries, isReviewed: reviewed)
    }

    @Test func markReviewedSucceeds() async {
        let tx = makeTransaction()
        let service = MockTransactionService(fetchResult: .success([tx]))
        let vm = TransactionDetailViewModel(transaction: tx, transactionService: service)

        let ok = await vm.setReviewed(true)

        #expect(ok)
        #expect(vm.isReviewed)
        #expect(vm.error == nil)
        #expect(!vm.isUpdating)
        #expect(service.reviewedCalls.count == 1)
        #expect(service.reviewedCalls.first?.id == "t1")
        #expect(service.reviewedCalls.first?.isReviewed == true)
    }

    @Test func failureRollsBackAndSurfacesError() async {
        let tx = makeTransaction()
        let service = MockTransactionService(fetchResult: .success([tx]))
        service.setSetReviewedResult(.failure(TransactionServiceError.persistenceFailed))
        let vm = TransactionDetailViewModel(transaction: tx, transactionService: service)

        let ok = await vm.setReviewed(true)

        #expect(!ok)
        #expect(!vm.isReviewed)
        #expect(vm.error?.isRetryable == true)
        #expect(!vm.isUpdating)
    }

    @Test func successAfterFailureClearsError() async {
        let tx = makeTransaction()
        let service = MockTransactionService(fetchResult: .success([tx]))
        service.setSetReviewedResult(.failure(TransactionServiceError.persistenceFailed))
        let vm = TransactionDetailViewModel(transaction: tx, transactionService: service)
        _ = await vm.setReviewed(true)
        service.setSetReviewedResult(nil)

        let ok = await vm.setReviewed(true)

        #expect(ok)
        #expect(vm.isReviewed)
        #expect(vm.error == nil)
    }

    @Test func settingSameStateIsIdempotent() async {
        let tx = makeTransaction(reviewed: true)
        let service = MockTransactionService(fetchResult: .success([tx]))
        let vm = TransactionDetailViewModel(transaction: tx, transactionService: service)

        _ = await vm.setReviewed(true)
        _ = await vm.setReviewed(true)

        #expect(vm.isReviewed)
        #expect(service.reviewedCalls.allSatisfy { $0.isReviewed && $0.id == "t1" })
    }

    @Test func toggleSendsOppositeValue() async {
        let tx = makeTransaction(reviewed: true)
        let service = MockTransactionService(fetchResult: .success([tx]))
        let vm = TransactionDetailViewModel(transaction: tx, transactionService: service)

        let ok = await vm.toggleReviewed()

        #expect(ok)
        #expect(!vm.isReviewed)
        #expect(service.reviewedCalls.first?.isReviewed == false)
    }
}
