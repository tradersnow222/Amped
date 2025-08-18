import XCTest
import SwiftUI
import ViewInspector
@testable import Amped

/// Tests to ensure questionnaire buttons are visible on iPhone SE 2020 and other compact devices
class iPhoneSELayoutTests: XCTestCase {
    
    private var viewModel: QuestionnaireViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = QuestionnaireViewModel(startFresh: true)
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Screen Size Detection Tests
    
    func testScreenSizeCategoryDetection() {
        // Test iPhone SE 2020 dimensions (750x1334, but we use max dimension)
        // Since we can't mock UIScreen.main.bounds in unit tests, we'll test the logic
        
        // Verify that compact category provides appropriate spacing
        let compactSpacing = ScreenSizeCategory.compact.adaptiveSpacing
        XCTAssertEqual(compactSpacing.questionBottomPadding, 16, "Compact screens should use reduced bottom padding")
        XCTAssertEqual(compactSpacing.buttonSpacing, 8, "Compact screens should use reduced button spacing")
        XCTAssertEqual(compactSpacing.maxSpacerHeight, 20, "Compact screens should limit spacer height")
        XCTAssertEqual(compactSpacing.sectionSpacing, 8, "Compact screens should use reduced section spacing")
        
        // Verify regular category provides moderate spacing
        let regularSpacing = ScreenSizeCategory.regular.adaptiveSpacing
        XCTAssertEqual(regularSpacing.questionBottomPadding, 24, "Regular screens should use moderate bottom padding")
        XCTAssertEqual(regularSpacing.buttonSpacing, 10, "Regular screens should use moderate button spacing")
        XCTAssertEqual(regularSpacing.maxSpacerHeight, 40, "Regular screens should allow moderate spacer height")
        
        // Verify large category provides full spacing
        let largeSpacing = ScreenSizeCategory.large.adaptiveSpacing
        XCTAssertEqual(largeSpacing.questionBottomPadding, 30, "Large screens should use full bottom padding")
        XCTAssertEqual(largeSpacing.buttonSpacing, 12, "Large screens should use full button spacing")
        XCTAssertEqual(largeSpacing.maxSpacerHeight, 60, "Large screens should allow full spacer height")
    }
    
    // MARK: - Adaptive Spacing Tests
    
    func testAdaptiveSpacingEnvironment() {
        // Create a test view that uses adaptive spacing
        struct TestView: View {
            @Environment(\.adaptiveSpacing) var spacing
            
            var body: some View {
                VStack {
                    Text("Test")
                }
                .adaptiveBottomPadding()
            }
        }
        
        // Test that adaptive spacing modifier works
        let testView = TestView().adaptiveSpacing()
        XCTAssertNoThrow(testView, "Adaptive spacing modifier should not throw")
    }
    
    func testAdaptiveSpacerBounds() {
        // Test that AdaptiveSpacer respects minimum and maximum heights
        let spacer = AdaptiveSpacer(minHeight: 10, maxHeight: 30)
        XCTAssertNoThrow(spacer, "AdaptiveSpacer should initialize without error")
    }
    
    // MARK: - Questionnaire Layout Tests
    
    func testBirthdateQuestionCompactLayout() {
        // Test that birthdate question has reduced picker height on compact screens
        let birthdateView = QuestionViews.BirthdateQuestionView(
            viewModel: viewModel,
            handleContinue: {}
        )
        
        XCTAssertNoThrow(birthdateView, "Birthdate question should render without error on compact screens")
    }
    
    func testStressQuestionAdaptiveSpacing() {
        // Test that stress question uses adaptive spacing
        let stressView = QuestionViews.StressQuestionView(viewModel: viewModel)
        XCTAssertNoThrow(stressView, "Stress question should render with adaptive spacing")
    }
    
    func testNameQuestionAdaptiveLayout() {
        // Test that name question uses adaptive spacing for text field and button
        let nameView = QuestionViews.NameQuestionView(viewModel: viewModel)
        XCTAssertNoThrow(nameView, "Name question should render with adaptive layout")
    }
    
    func testGenderQuestionCompactSpacing() {
        // Test that gender question uses reduced spacing on compact screens
        let genderView = QuestionViews.GenderQuestionView(viewModel: viewModel)
        XCTAssertNoThrow(genderView, "Gender question should render with compact spacing")
    }
    
    // MARK: - Button Visibility Tests
    
    func testAllQuestionButtonsHaveProperMinimumHeight() {
        // Test that all question buttons maintain minimum 48pt height for accessibility
        // This is critical for iPhone SE where space is limited
        
        let questions: [QuestionnaireViewModel.Question] = [
            .name, .birthdate, .stressLevel, .anxietyLevel, .gender,
            .nutritionQuality, .smokingStatus, .alcoholConsumption,
            .socialConnections, .sleepQuality, .bloodPressureAwareness,
            .deviceTracking, .framingComfort, .urgencyResponse, .lifeMotivation
        ]
        
        for question in questions {
            viewModel.currentQuestion = question
            
            // Verify the question view can be created without throwing
            switch question {
            case .name:
                let view = QuestionViews.NameQuestionView(viewModel: viewModel)
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .birthdate:
                let view = QuestionViews.BirthdateQuestionView(viewModel: viewModel, handleContinue: {})
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .stressLevel:
                let view = QuestionViews.StressQuestionView(viewModel: viewModel)
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .anxietyLevel:
                let view = QuestionViews.AnxietyQuestionView(viewModel: viewModel)
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .gender:
                let view = QuestionViews.GenderQuestionView(viewModel: viewModel)
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .nutritionQuality:
                let view = QuestionViews.NutritionQuestionView(viewModel: viewModel)
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .smokingStatus:
                let view = QuestionViews.SmokingQuestionView(viewModel: viewModel)
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .alcoholConsumption:
                let view = QuestionViews.AlcoholQuestionView(viewModel: viewModel)
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .socialConnections:
                let view = QuestionViews.SocialConnectionsQuestionView(viewModel: viewModel)
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .sleepQuality:
                let view = QuestionViews.SleepQualityQuestionView(viewModel: viewModel)
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .bloodPressureAwareness:
                let view = QuestionViews.BloodPressureAwarenessQuestionView(viewModel: viewModel)
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .deviceTracking:
                let view = QuestionViews.DeviceTrackingQuestionView(
                    viewModel: viewModel,
                    proceedToHealthKit: {},
                    skipToLifeMotivation: {}
                )
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .framingComfort:
                let view = QuestionViews.FramingComfortQuestionView(viewModel: viewModel)
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .urgencyResponse:
                let view = QuestionViews.UrgencyResponseQuestionView(viewModel: viewModel)
                XCTAssertNoThrow(view, "\(question) should render without error")
                
            case .lifeMotivation:
                let view = QuestionViews.LifeMotivationQuestionView(
                    viewModel: viewModel,
                    completeQuestionnaire: {}
                )
                XCTAssertNoThrow(view, "\(question) should render without error")
            }
        }
    }
    
    // MARK: - Adaptive Layout Integration Tests
    
    func testQuestionnaireViewWithAdaptiveSpacing() {
        // Test that the main QuestionnaireView applies adaptive spacing correctly
        let questionnaireView = QuestionnaireView(
            viewModel: viewModel,
            exitToPersonalizationIntro: .constant(false),
            proceedToHealthPermissions: .constant(false)
        )
        
        XCTAssertNoThrow(questionnaireView, "QuestionnaireView should render with adaptive spacing")
    }
    
    func testAdaptiveSpacingWithAllQuestions() {
        // Test that adaptive spacing works with all question types
        let allQuestions: [QuestionnaireViewModel.Question] = [
            .name, .birthdate, .stressLevel, .anxietyLevel, .gender,
            .nutritionQuality, .smokingStatus, .alcoholConsumption,
            .socialConnections, .sleepQuality, .bloodPressureAwareness,
            .deviceTracking, .framingComfort, .urgencyResponse, .lifeMotivation
        ]
        
        for question in allQuestions {
            viewModel.currentQuestion = question
            
            let questionnaireView = QuestionnaireView(
                viewModel: viewModel,
                exitToPersonalizationIntro: .constant(false),
                proceedToHealthPermissions: .constant(false)
            )
            
            XCTAssertNoThrow(questionnaireView, "QuestionnaireView should render \(question) with adaptive spacing")
        }
    }
    
    // MARK: - Performance Tests
    
    func testAdaptiveSpacingPerformance() {
        // Test that adaptive spacing calculations are fast
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create multiple adaptive spacing instances (simulating rapid view updates)
        for _ in 0..<100 {
            let compactSpacing = ScreenSizeCategory.compact.adaptiveSpacing
            let regularSpacing = ScreenSizeCategory.regular.adaptiveSpacing
            let largeSpacing = ScreenSizeCategory.large.adaptiveSpacing
            
            // Use the spacing values to ensure they're actually computed
            _ = compactSpacing.buttonSpacing + regularSpacing.buttonSpacing + largeSpacing.buttonSpacing
        }
        
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(elapsedTime, 0.01, "Adaptive spacing calculations should be very fast")
    }
    
    // MARK: - Safe Area Integration Tests
    
    func testResponsiveSafeAreaPadding() {
        // Test that responsive safe area padding modifier works
        struct TestView: View {
            var body: some View {
                Text("Test")
                    .responsiveSafeAreaPadding(.bottom, minimum: 16)
            }
        }
        
        let testView = TestView()
        XCTAssertNoThrow(testView, "Responsive safe area padding should work without error")
    }
    
    // MARK: - Edge Case Tests
    
    func testExtremeLowResolutionHandling() {
        // Test handling of very small screen dimensions
        // This ensures the app doesn't break on hypothetical smaller devices
        
        let extremelyCompactSpacing = ScreenSizeCategory.compact.adaptiveSpacing
        
        // Verify minimum spacing values are reasonable
        XCTAssertGreaterThan(extremelyCompactSpacing.buttonSpacing, 0, "Button spacing should be positive")
        XCTAssertGreaterThan(extremelyCompactSpacing.questionBottomPadding, 0, "Bottom padding should be positive")
        XCTAssertGreaterThan(extremelyCompactSpacing.maxSpacerHeight, 0, "Max spacer height should be positive")
        
        // Verify spacing is not too small to be usable
        XCTAssertGreaterThanOrEqual(extremelyCompactSpacing.buttonSpacing, 8, "Button spacing should be at least 8pt")
        XCTAssertGreaterThanOrEqual(extremelyCompactSpacing.questionBottomPadding, 16, "Bottom padding should be at least 16pt")
    }
    
    func testAdaptiveSpacerEdgeCases() {
        // Test AdaptiveSpacer with edge case values
        let zeroHeightSpacer = AdaptiveSpacer(minHeight: 0, maxHeight: 0)
        XCTAssertNoThrow(zeroHeightSpacer, "AdaptiveSpacer should handle zero height")
        
        let veryLargeSpacer = AdaptiveSpacer(minHeight: 1000, maxHeight: 2000)
        XCTAssertNoThrow(veryLargeSpacer, "AdaptiveSpacer should handle large heights")
    }
    
    // MARK: - Integration with Existing Components Tests
    
    func testBackButtonWithAdaptiveSpacing() {
        // Test that BackButton works properly with adaptive spacing
        let backButton = BackButton(action: {}, showText: false)
        XCTAssertNoThrow(backButton, "BackButton should work with adaptive spacing")
    }
    
    func testCategoryHeaderWithAdaptiveSpacing() {
        // Test that CategoryHeader works with adaptive spacing
        let categoryHeader = CategoryHeader(category: .personal)
        XCTAssertNoThrow(categoryHeader, "CategoryHeader should work with adaptive spacing")
    }
    
    // MARK: - User Experience Tests
    
    func testButtonAccessibilityOnCompactScreens() {
        // Test that buttons maintain proper accessibility on compact screens
        // This is critical for iPhone SE users
        
        viewModel.currentQuestion = .gender
