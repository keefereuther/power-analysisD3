/**
 * Statistical Power Calculations
 * Uses jStat for accurate distribution calculations
 * Implements the same logic as R's pwr package
 */

const Statistics = {
    /**
     * Calculate degrees of freedom based on test type
     */
    calculateDF(testType, n, params) {
        if (testType === 'two_sample') {
            return 2 * n - 2;
        } else if (testType === 'paired') {
            return n - 1;
        } else if (testType === 'anova') {
            const k = params.k || 3;
            return {
                df1: k - 1,
                df2: k * (n - 1)
            };
        } else if (testType === 'regression') {
            const predictors = params.predictors || 2;
            return {
                df1: predictors,
                df2: n - predictors - 1
            };
        }
        return null;
    },

    /**
     * Calculate critical value based on test type and alpha
     */
    calculateCriticalValue(testType, alpha, df, params) {
        if (testType === 'two_sample' || testType === 'paired') {
            const oneTailed = params.oneTailed || false;
            if (oneTailed) {
                return jStat.studentt.inv(1 - alpha, df);
            } else {
                return jStat.studentt.inv(1 - alpha / 2, df);
            }
        } else if (testType === 'anova' || testType === 'regression') {
            return jStat.centralF.inv(1 - alpha, df.df1, df.df2);
        }
        return null;
    },

    /**
     * Calculate non-centrality parameter for t-test
     */
    calculateNCP_T(testType, d, n) {
        if (testType === 'two_sample') {
            return d * Math.sqrt(n / 2);
        } else if (testType === 'paired') {
            return d * Math.sqrt(n);
        }
        return 0;
    },

    /**
     * Calculate non-centrality parameter for ANOVA
     */
    calculateNCP_F_ANOVA(f, k, n) {
        return n * k * f * f;
    },

    /**
     * Calculate non-centrality parameter for Regression
     */
    calculateNCP_F_Regression(f2, n, predictors) {
        return f2 * (n - predictors - 1);
    },

    /**
     * Calculate power for two-sample or paired t-test
     */
    calculatePower_T(testType, n, d, alpha, oneTailed) {
        const df = this.calculateDF(testType, n);
        const ncp = this.calculateNCP_T(testType, d, n);
        const crit = this.calculateCriticalValue(testType, alpha, df, { oneTailed });

        if (oneTailed) {
            // One-tailed: power is probability that t > crit under H1
            // Use non-central t-distribution
            if (ncp === 0) {
                return 1 - jStat.studentt.cdf(crit, df);
            } else {
                return 1 - jStat.noncentralt.cdf(crit, df, ncp);
            }
        } else {
            // Two-tailed: power is probability that |t| > crit under H1
            if (ncp === 0) {
                return 1 - (jStat.studentt.cdf(crit, df) - jStat.studentt.cdf(-crit, df));
            } else {
                return 1 - (jStat.noncentralt.cdf(crit, df, ncp) - jStat.noncentralt.cdf(-crit, df, ncp));
            }
        }
    },

    /**
     * Calculate power for ANOVA
     */
    calculatePower_ANOVA(k, n, f, alpha) {
        const df = this.calculateDF('anova', n, { k });
        const ncp = this.calculateNCP_F_ANOVA(f, k, n);
        const crit = this.calculateCriticalValue('anova', alpha, df);

        // F-test is always one-tailed (right-tailed)
        return 1 - jStat.noncentralf.cdf(crit, df.df1, df.df2, ncp);
    },

    /**
     * Calculate power for Regression
     */
    calculatePower_Regression(n, predictors, r2, alpha) {
        if (n <= predictors + 1) {
            return NaN; // Not enough degrees of freedom
        }

        const df = this.calculateDF('regression', n, { predictors });
        const f2 = r2 / (1 - r2);
        const ncp = this.calculateNCP_F_Regression(f2, n, predictors);
        const crit = this.calculateCriticalValue('regression', alpha, df);

        // F-test is always one-tailed (right-tailed)
        return 1 - jStat.noncentralf.cdf(crit, df.df1, df.df2, ncp);
    },

    /**
     * Main power calculation function
     */
    calculatePower(testType, params) {
        const { n, alpha } = params;

        // Validation
        if (n <= 0 || alpha <= 0 || alpha >= 1) {
            return NaN;
        }

        try {
            if (testType === 'two_sample' || testType === 'paired') {
                const d = params.effectSize || 0.5;
                const oneTailed = params.oneTailed || false;
                if (d <= 0) return NaN;
                return this.calculatePower_T(testType, n, d, alpha, oneTailed);
            } else if (testType === 'anova') {
                const k = params.k || 3;
                const f = params.effectSize || 0.25;
                if (k < 2 || f <= 0) return NaN;
                return this.calculatePower_ANOVA(k, n, f, alpha);
            } else if (testType === 'regression') {
                const predictors = params.predictors || 2;
                const r2 = params.r2 || 0.2;
                if (predictors < 1 || r2 <= 0 || r2 >= 1) return NaN;
                if (n <= predictors + 1) return NaN;
                return this.calculatePower_Regression(n, predictors, r2, alpha);
            }
        } catch (e) {
            console.error('Power calculation error:', e);
            return NaN;
        }

        return NaN;
    },

    /**
     * Find required sample size for target power (inverse power calculation)
     * Uses binary search for accuracy
     */
    findSampleSize(testType, targetPower, params) {
        const alpha = params.alpha || 0.05;
        let minN, maxN;

        // Set reasonable bounds based on test type
        if (testType === 'two_sample' || testType === 'paired') {
            minN = 2;
            maxN = 10000;
        } else if (testType === 'anova') {
            minN = 2;
            maxN = 5000;
        } else if (testType === 'regression') {
            const predictors = params.predictors || 2;
            minN = predictors + 2;
            maxN = 5000;
        } else {
            return null;
        }

        // Binary search for sample size
        let low = minN;
        let high = maxN;
        let bestN = null;
        const tolerance = 0.001;

        while (high - low > 1) {
            const mid = Math.floor((low + high) / 2);
            const testParams = { ...params, n: mid, alpha };
            const power = this.calculatePower(testType, testParams);

            if (isNaN(power) || power < targetPower) {
                low = mid;
            } else {
                high = mid;
                bestN = mid;
            }
        }

        // Refine with smaller increments if needed
        if (bestN !== null) {
            // Check if we can go lower
            for (let n = Math.max(minN, bestN - 10); n < bestN; n++) {
                const testParams = { ...params, n, alpha };
                const power = this.calculatePower(testType, testParams);
                if (!isNaN(power) && power >= targetPower) {
                    bestN = n;
                }
            }
        }

        return bestN || Math.ceil((low + high) / 2);
    },

    /**
     * Generate power curve data (power vs sample size)
     */
    generatePowerCurve(testType, params, minN, maxN, step = 1) {
        const data = [];
        const alpha = params.alpha || 0.05;

        for (let n = minN; n <= maxN; n += step) {
            const testParams = { ...params, n, alpha };
            const power = this.calculatePower(testType, testParams);
            
            if (!isNaN(power) && isFinite(power)) {
                data.push({ n, power });
            }
        }

        return data;
    },

    /**
     * Calculate density values for t-distribution
     */
    tDensity(x, df, ncp = 0) {
        if (ncp === 0) {
            return jStat.studentt.pdf(x, df);
        } else {
            // Non-central t-distribution
            // jStat uses noncentralt.pdf for non-central t
            return jStat.noncentralt.pdf(x, df, ncp);
        }
    },

    /**
     * Calculate density values for F-distribution
     */
    fDensity(x, df1, df2, ncp = 0) {
        if (ncp === 0) {
            return jStat.centralF.pdf(x, df1, df2);
        } else {
            return jStat.noncentralf.pdf(x, df1, df2, ncp);
        }
    },

    /**
     * Generate distribution data for plotting
     */
    generateDistributionData(testType, params) {
        const { n, alpha } = params;
        const df = this.calculateDF(testType, n, params);
        const crit = this.calculateCriticalValue(testType, alpha, df, params);

        if (testType === 'two_sample' || testType === 'paired') {
            const d = params.effectSize || 0.5;
            const oneTailed = params.oneTailed || false;
            const ncp = this.calculateNCP_T(testType, d, n);

            // Generate x values
            const xMin = oneTailed ? -4 : -Math.max(8, Math.abs(crit) + 5);
            const xMax = Math.max(8, crit + 5);
            const xRange = d3.range(xMin, xMax, (xMax - xMin) / 1000);

            const h0Data = xRange.map(x => ({
                x,
                y: this.tDensity(x, df, 0)
            }));

            const h1Data = xRange.map(x => ({
                x,
                y: this.tDensity(x, df, ncp)
            }));

            return {
                type: 't',
                df,
                crit,
                ncp,
                oneTailed,
                xRange: [xMin, xMax],
                h0Data,
                h1Data
            };
        } else if (testType === 'anova' || testType === 'regression') {
            let ncp;
            if (testType === 'anova') {
                const k = params.k || 3;
                const f = params.effectSize || 0.25;
                ncp = this.calculateNCP_F_ANOVA(f, k, n);
            } else {
                const predictors = params.predictors || 2;
                const r2 = params.r2 || 0.2;
                const f2 = r2 / (1 - r2);
                ncp = this.calculateNCP_F_Regression(f2, n, predictors);
            }

            const xMax = Math.max(20, crit * 3);
            const xRange = d3.range(0.001, xMax, xMax / 1000);

            const h0Data = xRange.map(x => ({
                x,
                y: this.fDensity(x, df.df1, df.df2, 0)
            }));

            const h1Data = xRange.map(x => ({
                x,
                y: this.fDensity(x, df.df1, df.df2, ncp)
            }));

            return {
                type: 'f',
                df,
                crit,
                ncp,
                xRange: [0, xMax],
                h0Data,
                h1Data
            };
        }

        return null;
    }
};

