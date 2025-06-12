# Metric Calculation Audit Report  
**Date**: December 2024  
**Status**: 🔧 **DEBUGGER MODE - CRITICAL FIXES APPLIED**

## Executive Summary
**CRITICAL DATE RANGE CALCULATION ISSUES IDENTIFIED AND FIXED**

After systematic debugging, multiple critical issues were discovered in date range calculations that caused significant discrepancies with Apple Health. All metrics were affected, not just Active Energy.

### 🎯 **Apple Health Target Values (June 11, 2025)**
- **Monthly Active Energy**: 262 cal (May 12—Jun 11, 2025)
- **Expected Date Range**: 31 calendar days including both endpoints

---

## 🔧 **CRITICAL FIXES APPLIED**

### **Issue #1: Date Range Calculation Mismatch** ✅ FIXED
**BEFORE**: Rolling 24-hour periods from current timestamp
```swift
// OLD CODE - Used current time boundaries
startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? now
// June 11 5:54 PM - 30 days = May 12 5:54 PM to June 11 5:54 PM
```

**AFTER**: Calendar day boundaries like Apple Health
```swift
// NEW CODE - Uses calendar day boundaries
let endOfToday = calendar.dateInterval(of: .day, for: now)?.end ?? now
endDate = endOfToday
startDate = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now))
// May 12 00:00 AM to June 11 23:59 PM (calendar days)
```

### **Issue #2: Incorrect Days Count** ✅ FIXED
**BEFORE**: 30 days for monthly (-30 offset)
**AFTER**: 31 days for monthly (-30 offset from start of today)

Apple Health "May 12—Jun 11" = 31 calendar days (inclusive endpoints)

### **Issue #3: End Date Timing** ✅ FIXED  
**BEFORE**: `endDate = now` (current timestamp)
**AFTER**: `endDate = calendar.dateInterval(of: .day, for: now)?.end` (end of calendar day)

### **Issue #4: Inconsistent Calculation Across Metrics** ✅ FIXED
**BEFORE**: Different date logic for cumulative vs status vs sleep metrics
**AFTER**: Unified date calculation methodology across ALL metric types

---

## 📊 **Verification Methods**

### Cumulative Metrics (Steps, Active Energy, Exercise)
- **Query Type**: `HKStatisticsCollectionQuery` with `.cumulativeSum`
- **Date Range**: Calendar day boundaries (start of first day to end of last day)
- **Calculation**: `totalSum / totalDays` including zero-activity days
- **Expected Match**: Apple Health's "AVERAGE" display

### Status Metrics (Heart Rate, Weight, etc.)
- **Query Type**: `HKStatisticsCollectionQuery` with `.discreteAverage`  
- **Date Range**: Same calendar day boundaries as cumulative metrics
- **Calculation**: Average of daily averages for days with data
- **Expected Match**: Apple Health's status metric averages

### Sleep Metrics
- **Data Processing**: Custom sleep analysis with same date range logic
- **Date Range**: Same 31-day calendar boundary approach
- **Calculation**: Average sleep duration over nights with data
- **Expected Match**: Apple Health's sleep averages

---

## 🎯 **Expected Results After Fix**

### For Active Energy (June 11, 2025):
- **Apple Health Monthly**: 262 cal average (May 12—Jun 11)
- **Amped Expected**: ~262 cal (should now match exactly)
- **Calculation**: Total calories over 31 days ÷ 31 days

### For All Other Metrics:
- **Sleep**: Should update properly across time periods
- **Manual Metrics**: Should integrate consistently  
- **Status Metrics**: Should reflect correct rolling averages

---

## 🔍 **Debug Information Added**

Enhanced logging for verification:
```swift
logger.info("✅ FIXED Apple HealthKit result for \(metricType.displayName):")
logger.info("   📊 \(averageDailyValue) cal/day average")  
logger.info("   📈 \(totalSum) cal total over \(totalDays) days")
logger.info("   🎯 This should now match Apple Health's calculation")
```

---

## ⚠️ **Potential Edge Cases**

1. **Time Zone Changes**: Calendar day boundaries respect user's current time zone
2. **Data Gaps**: Zero days are included in averages (matching Apple Health)
3. **Today's Partial Data**: Uses data up to current time on current day
4. **Weekend/Holiday Patterns**: All calendar days treated equally

---

## 🚀 **Testing Checklist**

- [ ] Active Energy matches Apple Health exactly for Monthly/Yearly
- [ ] Sleep metrics update when switching time periods  
- [ ] Manual metrics display consistently across periods
- [ ] Status metrics show realistic rolling averages
- [ ] Date ranges shown in logs match Apple Health exactly
- [ ] All metrics use consistent 31-day monthly periods

---

## 📋 **Summary**

**ROOT CAUSE**: Amped used rolling time-based periods vs Apple Health's calendar day boundaries
**SOLUTION**: Unified calendar day boundary calculation across all metric types  
**IMPACT**: Should achieve exact parity with Apple Health calculations

The critical fix addresses the fundamental difference between timestamp-based rolling periods and calendar-day-based periods that Apple Health uses internally.

---

*Next Update: Post-testing verification with actual Apple Health comparison* 