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
        // Initial question should be name
        XCTAssertEqual(viewModel.currentQuestion, .name)
        
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
        

    }
    
    /// Test question navigation
    func testQuestionNavigation() {
        // Start at name
        XCTAssertEqual(viewModel.currentQuestion, .name)
        
        // Set a valid name
        viewModel.userName = "Test User"
        
        // Should be able to proceed
        XCTAssertTrue(viewModel.canProceed)
        
        // Proceed to next question (birthdate)
        viewModel.proceedToNextQuestion()
        XCTAssertEqual(viewModel.currentQuestion, .birthdate)
        
        // Cannot proceed with invalid birthdate
        XCTAssertFalse(viewModel.canProceed)
        
        // Set a valid birthdate for an adult
        let calendar = Calendar.current
        let adultBirthdate = calendar.date(byAdding: .year, value: -30, to: Date())!
        viewModel.birthdate = adultBirthdate
        XCTAssertTrue(viewModel.canProceed)
        
        // Proceed to next question
        viewModel.proceedToNextQuestion()
        XCTAssertEqual(viewModel.currentQuestion, .stressLevel)
    }
    
    /// Test cannot proceed with invalid data
    func testCannotProceedWithInvalidData() {
        // Start at name with empty name
        XCTAssertEqual(viewModel.currentQuestion, .name)
        
        // Should not be able to proceed (empty name)
        XCTAssertFalse(viewModel.canProceed)
        
        // Move to birthdate question manually and test invalid age
        viewModel.currentQuestion = .birthdate
        let calendar = Calendar.current
        let childBirthdate = calendar.date(byAdding: .year, value: -15, to: Date())!
        viewModel.birthdate = childBirthdate
        
        // Should not be able to proceed (too young)
        XCTAssertFalse(viewModel.canProceed)
    }
    
    /// Test moving back through questions
    func testMoveBackThroughQuestions() {
        // Start at name
        XCTAssertEqual(viewModel.currentQuestion, .name)
        
        // Cannot move back from first question
        XCTAssertFalse(viewModel.canMoveBack)
        
        // Set valid inputs and move to birthdate question
        viewModel.userName = "Test User"
        viewModel.proceedToNextQuestion()
        
        // Now should be on birthdate question and can move back
        XCTAssertEqual(viewModel.currentQuestion, .birthdate)
        XCTAssertTrue(viewModel.canMoveBack)
        
        // Move back to name
        viewModel.moveBackToPreviousQuestion()
        XCTAssertEqual(viewModel.currentQuestion, .name)
    }
} 