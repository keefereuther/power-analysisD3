/**
 * Sample Data Generation
 * Generates synthetic datasets matching the R implementation
 */

const DataGeneration = {
    /**
     * Generate random numbers from normal distribution (Box-Muller transform)
     */
    rnorm(n, mean = 0, sd = 1) {
        const values = [];
        for (let i = 0; i < n; i++) {
            // Box-Muller transform for normal random numbers
            const u1 = Math.random();
            const u2 = Math.random();
            const z = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
            values.push(z * sd + mean);
        }
        return values;
    },

    /**
     * Generate data for two-sample t-test
     */
    generateTwoSampleData(n, d) {
        const sigma = 1; // Assuming standard deviation of 1
        const delta = d * sigma;
        
        const group1 = this.rnorm(n, 0, sigma);
        const group2 = this.rnorm(n, delta, sigma);
        
        return {
            values: [...group1, ...group2],
            groups: [...Array(n).fill('Group 1'), ...Array(n).fill('Group 2')],
            group1,
            group2
        };
    },

    /**
     * Generate data for paired t-test
     */
    generatePairedData(n, d) {
        const sigma = 1;
        const delta = d * sigma;
        
        const pre = this.rnorm(n, 0, sigma);
        // Post values are correlated with pre values
        const post = pre.map((p, i) => p + this.rnorm(1, delta, sigma * 0.5)[0]);
        
        return {
            ids: [...Array(n).keys()].map(i => i + 1).flatMap(id => [id, id]),
            values: [...pre, ...post],
            times: [...Array(n).fill('Pre'), ...Array(n).fill('Post')],
            pairs: pre.map((p, i) => ({ id: i + 1, pre: p, post: post[i] }))
        };
    },

    /**
     * Generate data for one-way ANOVA
     */
    generateANOVAData(n, k, f) {
        const sigma = 1;
        
        // Calculate means for each group based on effect size
        const groupMeans = [];
        for (let i = 0; i < k; i++) {
            const mean = -f * sigma * (k - 1) / 2 + (f * sigma * (k - 1) / (k - 1)) * i;
            groupMeans.push(mean);
        }
        
        const values = [];
        const groups = [];
        
        for (let i = 0; i < k; i++) {
            const groupData = this.rnorm(n, groupMeans[i], sigma);
            values.push(...groupData);
            groups.push(...Array(n).fill(`Group ${i + 1}`));
        }
        
        return {
            values,
            groups,
            groupMeans: groupMeans.map((mean, i) => ({ group: `Group ${i + 1}`, mean }))
        };
    },

    /**
     * Generate data for linear regression
     */
    generateRegressionData(n, predictors, r2) {
        // Generate design matrix with random predictors
        const X = [];
        for (let i = 0; i < n; i++) {
            const row = this.rnorm(predictors);
            X.push(row);
        }
        
        // Generate coefficients
        const beta = this.rnorm(predictors);
        
        // Calculate signal component (X * beta)
        const signal = X.map(row => {
            return row.reduce((sum, x, j) => sum + x * beta[j], 0);
        });
        
        // Scale signal to have variance 1
        const signalMean = signal.reduce((a, b) => a + b, 0) / n;
        const signalVariance = signal.reduce((sum, s) => sum + Math.pow(s - signalMean, 2), 0) / (n - 1);
        const scaledSignal = signal.map(s => (s - signalMean) / Math.sqrt(signalVariance));
        
        // Calculate noise component based on R² value
        // R² = Var(signal) / Var(Y), so Var(noise) = Var(signal) * (1 - R²) / R²
        const noiseVar = (1 - r2) / r2;
        const noise = this.rnorm(n, 0, Math.sqrt(noiseVar));
        
        // Generate response variable
        const y = scaledSignal.map((s, i) => s + noise[i]);
        
        // Create data object
        const data = {
            y: y
        };
        
        // Add predictors
        for (let i = 0; i < predictors; i++) {
            data[`x${i + 1}`] = X.map(row => row[i]);
        }
        
        return data;
    },

    /**
     * Main data generation function
     */
    generateData(testType, params) {
        const n = params.n || 30;
        
        if (testType === 'two_sample') {
            const d = params.effectSize || 0.5;
            return this.generateTwoSampleData(n, d);
        } else if (testType === 'paired') {
            const d = params.effectSize || 0.5;
            return this.generatePairedData(n, d);
        } else if (testType === 'anova') {
            const k = params.k || 3;
            const f = params.effectSize || 0.25;
            return this.generateANOVAData(n, k, f);
        } else if (testType === 'regression') {
            const predictors = params.predictors || 2;
            const r2 = params.r2 || 0.2;
            return this.generateRegressionData(n, predictors, r2);
        }
        
        return null;
    }
};

