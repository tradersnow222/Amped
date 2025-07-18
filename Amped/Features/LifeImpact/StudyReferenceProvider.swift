import Foundation

/// Provides scientific study references for health metrics
struct StudyReferenceProvider {
    
    /// Get study reference for a specific health metric type
    static func getStudyReference(for metricType: HealthMetricType) -> StudyReference? {
        // In a real implementation, this would fetch from a database or API
        // For the MVP, we'll provide mock references for a few key metrics
        switch metricType {
        case .steps:
            return StudyReference(
                title: "Association of Step Volume and Intensity With All-Cause Mortality in Older Women",
                authors: "I-Min Lee, Eric J. Shiroma, Masamitsu Kamada, David R. Bassett, Charles E. Matthews, Julie E. Buring",
                journalName: "JAMA Internal Medicine",
                publicationYear: 2019,
                doi: "10.1001/jamainternmed.2019.0899",
                url: URL(string: "https://jamanetwork.com/journals/jamainternalmedicine/fullarticle/2734709"),
                summary: "Taking more steps per day was associated with lower mortality rates until approximately 7500 steps/day. Higher step intensity was not associated with lower mortality rates after adjusting for total steps per day."
            )
            
        case .sleepHours:
            return StudyReference(
                title: "Sleep Duration and All-Cause Mortality: A Systematic Review and Meta-Analysis of Prospective Studies",
                authors: "Francesco P. Cappuccio, Lanfranco D'Elia, Pasquale Strazzullo, Michelle A. Miller",
                journalName: "Sleep",
                publicationYear: 2010,
                doi: "10.1093/sleep/33.5.585",
                url: URL(string: "https://academic.oup.com/sleep/article/33/5/585/2454478"),
                summary: "Both short and long duration of sleep are significant predictors of death in prospective studies. 7-8 hours of sleep per night was associated with the lowest mortality risk."
            )
            
        case .exerciseMinutes:
            return StudyReference(
                title: "Association of Leisure-Time Physical Activity With Risk of 26 Types of Cancer in 1.44 Million Adults",
                authors: "Moore SC, Lee IM, Weiderpass E, et al.",
                journalName: "JAMA Internal Medicine",
                publicationYear: 2016,
                doi: "10.1001/jamainternmed.2016.1548",
                url: URL(string: "https://jamanetwork.com/journals/jamainternalmedicine/fullarticle/2521826"),
                summary: "Leisure-time physical activity was associated with lower risk of 13 types of cancer. Health care professionals should encourage adults to adopt and maintain physical activity at recommended levels to lower risks of multiple cancers."
            )
            
        case .heartRateVariability:
            return StudyReference(
                title: "Heart Rate Variability as a Biomarker for Autonomic Nervous System Response Differences Between Children with Chronic Pain and Healthy Control Children",
                authors: "Evans S, Seidman LC, Tsao JC, Lung KC, Zeltzer LK, Naliboff BD",
                journalName: "Journal of Pain Research",
                publicationYear: 2013,
                doi: "10.2147/JPR.S43849",
                url: URL(string: "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3691463/"),
                summary: "Higher HRV is associated with better cardiovascular health and resilience to stress. Low HRV is linked to increased risk of cardiovascular events and all-cause mortality."
            )
            
        case .restingHeartRate:
            return StudyReference(
                title: "Resting Heart Rate and Risk of Cardiovascular Diseases and All-Cause Death: A Prospective Study",
                authors: "Zhang D, Shen X, Qi X",
                journalName: "Heart",
                publicationYear: 2016,
                doi: "10.1136/heartjnl-2015-308651",
                url: URL(string: "https://heart.bmj.com/content/102/7/530"),
                summary: "Elevated resting heart rate is associated with increased risk of cardiovascular diseases and all-cause mortality. Each 10 beats per minute increase in resting heart rate was associated with a 9% increase in all-cause mortality."
            )
            
        case .nutritionQuality:
            return StudyReference(
                title: "Association of Dietary Patterns with Risk of Chronic Disease and Mortality",
                authors: "Schwingshackl L, Hoffmann G",
                journalName: "Advances in Nutrition",
                publicationYear: 2015,
                doi: "10.3945/an.114.007617",
                url: URL(string: "https://academic.oup.com/advances/article/6/2/192/4558024"),
                summary: "High-quality dietary patterns were associated with reduced risk of all-cause mortality, cardiovascular disease, cancer, and type 2 diabetes."
            )
            
        case .smokingStatus:
            return StudyReference(
                title: "Smoking and All-Cause Mortality in Older Adults: 18-Year Follow-up of a Cohort Study",
                authors: "Carter BD, Abnet CC, Feskanich D, et al.",
                journalName: "JAMA",
                publicationYear: 2015,
                doi: "10.1001/jama.2015.1617",
                url: URL(string: "https://jamanetwork.com/journals/jama/fullarticle/2108262"),
                summary: "Smoking is associated with substantially increased risks of death from cancer, vascular disease, and respiratory disease. Even light smoking significantly increases mortality risk."
            )
            
        case .socialConnectionsQuality:
            return StudyReference(
                title: "Social Relationships and Mortality Risk: A Meta-analytic Review",
                authors: "Holt-Lunstad J, Smith TB, Layton JB",
                journalName: "PLOS Medicine",
                publicationYear: 2010,
                doi: "10.1371/journal.pmed.1000316",
                url: URL(string: "https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1000316"),
                summary: "Strong social relationships increased the likelihood of survival by 50%. The magnitude of this effect is comparable to quitting smoking and exceeds the influence of obesity and physical inactivity."
            )
            
        case .alcoholConsumption:
            return StudyReference(
                title: "Alcohol Consumption and Mortality Among Women",
                authors: "Thun MJ, Peto R, Lopez AD, et al.",
                journalName: "New England Journal of Medicine",
                publicationYear: 1997,
                doi: "10.1056/NEJM199712113372401",
                url: URL(string: "https://www.nejm.org/doi/full/10.1056/NEJM199712113372401"),
                summary: "Light to moderate alcohol consumption was associated with reduced risk of death from cardiovascular disease, but increased consumption was associated with increased risk of death from cancer and other causes."
            )
            
        default:
            // In a complete implementation, all metric types would have references
            return nil
        }
    }
} 