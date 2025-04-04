import XCTest
@testable import Amped

/// Unit tests for the QuestionnaireViewModel
final class QuestionnaireViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    /// Subject under test
    var viewModel: QuestionnaireViewModel!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        viewModel = QuestionnaireViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Test initial state
    func testInitialState() {
        // Initial question should be birthdate
        XCTAssertEqual(viewModel.currentQuestion, .birthdate)
        
        // Gender should be nil initially
        XCTAssertNil(viewModel.selectedGender)
        
        // Cannot proceed without valid inputs
        XCTAssertFalse(viewModel.canProceed)
    }
    
    /// Test gender selection
    func testGenderSelection() {
        // Set current question to gender question
        viewModel.currentQuestion = .gender
        
        // Initially, gender is nil and cannot proceed
        XCTAssertNil(viewModel.selectedGender)
        XCTAssertFalse(viewModel.canProceed)
        
        // After selecting a gender, can proceed
        viewModel.selectedGender = .male
        XCTAssertEqual(viewModel.selectedGender, .male)
        XCTAssertTrue(viewModel.canProceed)
        
        // Try another gender
        viewModel.selectedGender = .female
        XCTAssertEqual(viewModel.selectedGender, .female)
        XCTAssertTrue(viewModel.canProceed)
        
        // Try prefer not to say
        viewModel.selectedGender = .preferNotToSay
        XCTAssertEqual(viewModel.selectedGender, .preferNotToSay)
        XCTAssertTrue(viewModel.canProceed)
    }
    
    /// Test question navigation
    func testQuestionNavigation() {
        // Start at birthdate
        XCTAssertEqual(viewModel.currentQuestion, .birthdate)
        
        // Set a valid birthdate for an adult
        let calendar = Calendar.current
        let adultBirthdate = calendar.date(byAdding: .year, value: -30, to: Date())!
        viewModel.birthdate = adultBirthdate
        
        // Should be able to proceed
        XCTAssertTrue(viewModel.canProceed)
        
        // Proceed to next question (gender)
        viewModel.proceedToNextQuestion()
        XCTAssertEqual(viewModel.currentQuestion, .gender)
        
        // Cannot proceed with nil gender
        XCTAssertFalse(viewModel.canProceed)
        
        // Select a gender
        viewModel.selectedGender = .female
        XCTAssertTrue(viewModel.canProceed)
        
        // Proceed to next question
        viewModel.proceedToNextQuestion()
        XCTAssertEqual(viewModel.currentQuestion, .nutritionQuality)
    }
    
    /// Test cannot proceed with invalid data
    func testCannotProceedWithInvalidData() {
        // Start at birthdate with invalid age
        let calendar = Calendar.current
        let childBirthdate = calendar.date(byAdding: .year, value: -15, to: Date())!
        viewModel.birthdate = childBirthdate
        
        // Should not be able to proceed (too young)
        XCTAssertFalse(viewModel.canProceed)
        
        // Move to gender question manually (though this wouldn't happen in the app)
        viewModel.currentQuestion = .gender
        
        // Cannot proceed with nil gender
        XCTAssertFalse(viewModel.canProceed)
    }
    
    /// Test moving back through questions
    func testMoveBackThroughQuestions() {
        // Start at birthdate
        XCTAssertEqual(viewModel.currentQuestion, .birthdate)
        
        // Cannot move back from first question
        XCTAssertFalse(viewModel.canMoveBack)
        
        // Set valid inputs and move to gender question
        let calendar = Calendar.current
        viewModel.birthdate = calendar.date(byAdding: .year, value: -30, to: Date())!
        viewModel.proceedToNextQuestion()
        
        // Now should be on gender question and can move back
        XCTAssertEqual(viewModel.currentQuestion, .gender)
        XCTAssertTrue(viewModel.canMoveBack)
        
        // Move back to birthdate
        viewModel.moveBackToPreviousQuestion()
        XCTAssertEqual(viewModel.currentQuestion, .birthdate)
    }
} 