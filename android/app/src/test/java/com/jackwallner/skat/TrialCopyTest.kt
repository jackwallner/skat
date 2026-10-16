package com.jackwallner.skat

import com.jackwallner.skat.data.PaywallPlan
import com.jackwallner.skat.data.PaywallPricing
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

/** The free week is only promised when Play offers it to this account (iOS `PaywallPricing.terms`, plus Play trial eligibility). */
class TrialCopyTest {
    @Test
    fun termsNameTheFreeWeekOnlyWhenOffered() {
        assertEquals(
            "Abrechnung: 5,49 € / Monat, inklusive 7 Tagen kostenlos. Verlängert sich automatisch bis zur Kündigung in Google Play.",
            PaywallPricing.terms("5,49 € / Monat", PaywallPlan.MONTHLY, freeTrial = true),
        )
        assertEquals(
            "Abrechnung: 5,49 € / Monat. Verlängert sich automatisch bis zur Kündigung in Google Play.",
            PaywallPricing.terms("5,49 € / Monat", PaywallPlan.MONTHLY, freeTrial = false),
        )
        assertFalse(PaywallPricing.terms(null, PaywallPlan.YEARLY, freeTrial = false).contains("kostenlos", ignoreCase = true))
    }

    @Test
    fun ctaNamesTheTrialOnlyWhenOffered() {
        assertEquals("7-Tage-Test starten", PaywallPlan.MONTHLY.ctaTitle(true))
        assertEquals("Abonnieren", PaywallPlan.YEARLY.ctaTitle(false))
        assertFalse(PaywallPlan.LIFETIME.ctaTitle(true).contains("Test"))
    }
}
