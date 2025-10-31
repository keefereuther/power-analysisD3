/**
 * Main Application
 * Coordinates all components and handles reactivity
 */

// Application state
const AppState = {
    testType: 'two_sample',
    n: 30,
    alpha: 0.05,
    effectSize: 0.5,
    oneTailed: false,
    k: 3,
    predictors: 2,
    r2: 0.2,
    targetPower: 0.8
};

// Initialize application
document.addEventListener('DOMContentLoaded', function() {
    initializeUI();
    setupEventListeners();
    setupCollapsibleSections();
    // Delay updateAll slightly to ensure DOM is fully ready
    setTimeout(function() {
        updateAll();
    }, 100);
});

/**
 * Initialize UI elements
 */
function initializeUI() {
    // Set initial test type
    document.getElementById('test_type').value = AppState.testType;
    updateTestTypePanels();

    // Set initial values
    document.getElementById('n').value = AppState.n;
    document.getElementById('alpha').value = AppState.alpha;
    document.getElementById('effect_size_ttest').value = AppState.effectSize;
    document.getElementById('one_tailed').checked = AppState.oneTailed;
    document.getElementById('k').value = AppState.k;
    document.getElementById('effect_size_anova').value = 0.25;
    document.getElementById('predictors').value = AppState.predictors;
    document.getElementById('r2').value = AppState.r2;
    document.getElementById('target_power').value = AppState.targetPower;
}

/**
 * Setup event listeners for all inputs
 */
function setupEventListeners() {
    // Test type change
    document.getElementById('test_type').addEventListener('change', function() {
        AppState.testType = this.value;
        updateTestTypePanels();
        updateAll();
    });

    // Basic settings
    document.getElementById('n').addEventListener('input', function() {
        const value = parseInt(this.value);
        if (!isNaN(value) && value > 0) {
            AppState.n = value;
            updateAll();
        }
    });

    document.getElementById('alpha').addEventListener('input', function() {
        const value = parseFloat(this.value);
        if (!isNaN(value) && value > 0 && value < 1) {
            AppState.alpha = value;
            updateAll();
        }
    });

    // T-test settings
    document.getElementById('effect_size_ttest').addEventListener('input', function() {
        const value = parseFloat(this.value);
        if (!isNaN(value) && value > 0) {
            AppState.effectSize = value;
            updateAll();
        }
    });

    document.getElementById('one_tailed').addEventListener('change', function() {
        AppState.oneTailed = this.checked;
        updateAll();
    });

    // ANOVA settings
    document.getElementById('k').addEventListener('input', function() {
        const value = parseInt(this.value);
        if (!isNaN(value) && value >= 2) {
            AppState.k = value;
            updateAll();
        }
    });

    document.getElementById('effect_size_anova').addEventListener('input', function() {
        const value = parseFloat(this.value);
        if (!isNaN(value) && value > 0) {
            // For ANOVA, we need to store this separately
            if (AppState.testType === 'anova') {
                AppState.effectSize = value;
            }
            updateAll();
        }
    });

    // Regression settings
    document.getElementById('predictors').addEventListener('input', function() {
        const value = parseInt(this.value);
        if (!isNaN(value) && value >= 1) {
            AppState.predictors = value;
            updateAll();
        }
    });

    document.getElementById('r2').addEventListener('input', function() {
        const value = parseFloat(this.value);
        if (!isNaN(value) && value > 0 && value < 1) {
            AppState.r2 = value;
            updateAll();
        }
    });

    // Target power
    document.getElementById('target_power').addEventListener('input', function() {
        const value = parseFloat(this.value);
        if (!isNaN(value) && value > 0 && value < 1) {
            AppState.targetPower = value;
        }
    });

    // Calculate sample size button
    document.getElementById('calculate_n').addEventListener('click', function() {
        calculateRequiredSampleSize();
    });
}

/**
 * Setup collapsible/toggle functionality for all sections
 */
function setupCollapsibleSections() {
    // Setup toggles for all collapsible sections
    const collapsibles = document.querySelectorAll('.collapsible');
    
    collapsibles.forEach(function(collapsible) {
        // Only add listener if not already added
        if (collapsible.dataset.listenerAdded === 'true') {
            return;
        }
        collapsible.dataset.listenerAdded = 'true';
        
        collapsible.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            
            const content = this.nextElementSibling;
            if (!content || !content.classList.contains('section-content')) {
                return;
            }
            
            const isCollapsed = content.classList.contains('collapsed');
            
            if (isCollapsed) {
                content.classList.remove('collapsed');
                this.classList.remove('collapsed');
                // If this is a visualization section, re-render to fix dimensions after expansion
                const plotId = content.querySelector('[id^="plot"]')?.id;
                if (plotId) {
                    // Small delay to ensure CSS transition completes, then re-render
                    setTimeout(function() {
                        updateAll();
                    }, 350);
                }
            } else {
                content.classList.add('collapsed');
                this.classList.add('collapsed');
            }
        });
    });
}

/**
 * Update test type specific panels visibility
 */
function updateTestTypePanels() {
    // Since all settings are now in Basic Settings, this function is mostly obsolete
    // But we keep it for potential future use
    const anovaSettings = document.getElementById('anova-settings');
    const regressionSettings = document.getElementById('regression-settings');
    
    // These sections are always hidden now since we only support two-sample t-test
    if (anovaSettings) anovaSettings.style.display = 'none';
    if (regressionSettings) regressionSettings.style.display = 'none';
}

/**
 * Get current parameters object
 */
function getCurrentParams() {
    const params = {
        n: AppState.n,
        alpha: AppState.alpha
    };

    if (AppState.testType === 'two_sample' || AppState.testType === 'paired') {
        params.effectSize = AppState.effectSize;
        params.oneTailed = AppState.oneTailed;
    } else if (AppState.testType === 'anova') {
        params.k = AppState.k;
        params.effectSize = parseFloat(document.getElementById('effect_size_anova').value);
    } else if (AppState.testType === 'regression') {
        params.predictors = AppState.predictors;
        params.r2 = AppState.r2;
    }

    return params;
}

/**
 * Update all visualizations and outputs
 */
function updateAll() {
    try {
        const params = getCurrentParams();
        
        // Validate inputs
        if (!validateInputs(params)) {
            return;
        }

        // Calculate power
        const power = Statistics.calculatePower(AppState.testType, params);
        
        if (isNaN(power) || !isFinite(power)) {
            displayError('Power calculation failed. Please check your inputs.');
            return;
        }

        // Update text output
        updateSolutionText(params, power);

        // Update distribution plot - always render for proper sizing
        const distData = Statistics.generateDistributionData(AppState.testType, params);
        if (distData) {
            const distContainer = document.getElementById('plotDistribution');
            if (distContainer) {
                const distSection = distContainer.closest('.section-content');
                const wasCollapsed = distSection && distSection.classList.contains('collapsed');
                // Always render - D3 can render to hidden containers
                Visualizations.plotDistribution('plotDistribution', distData, power, AppState.testType);
            }
        }

        // Update power curve
        updatePowerCurve(params, power);

        // Update sample data plot - always render for proper sizing
        const sampleData = DataGeneration.generateData(AppState.testType, params);
        if (sampleData) {
            const dataContainer = document.getElementById('plotData');
            if (dataContainer) {
                const dataSection = dataContainer.closest('.section-content');
                const wasCollapsed = dataSection && dataSection.classList.contains('collapsed');
                // Always render - D3 can render to hidden containers
                Visualizations.plotSampleData('plotData', sampleData, AppState.testType);
            }
        }

        // Clear any error messages
        clearErrors();
    } catch (error) {
        console.error('Error updating visualizations:', error);
        displayError('An error occurred while updating visualizations.');
    }
}

/**
 * Validate input parameters
 */
function validateInputs(params) {
    if (params.n <= 0) {
        displayError('Sample size must be positive');
        return false;
    }

    if (params.alpha <= 0 || params.alpha >= 1) {
        displayError('Significance level must be between 0 and 1');
        return false;
    }

    if (AppState.testType === 'two_sample' || AppState.testType === 'paired') {
        if (params.effectSize <= 0) {
            displayError('Effect size must be positive');
            return false;
        }
    } else if (AppState.testType === 'anova') {
        if (params.k < 2) {
            displayError('Number of groups must be at least 2');
            return false;
        }
        if (params.effectSize <= 0) {
            displayError('Effect size must be positive');
            return false;
        }
    } else if (AppState.testType === 'regression') {
        if (params.predictors < 1) {
            displayError('Number of predictors must be at least 1');
            return false;
        }
        if (params.r2 <= 0 || params.r2 >= 1) {
            displayError('R² must be between 0 and 1');
            return false;
        }
        if (params.n <= params.predictors + 1) {
            displayError('Sample size must be greater than number of predictors + 1');
            return false;
        }
    }

    return true;
}

/**
 * Update solution text output
 */
function updateSolutionText(params, power) {
    const testNames = {
        'two_sample': 'Power Analysis for a Two-Sample t-Test',
        'paired': 'Power Analysis for a Paired t-Test',
        'anova': 'Power Analysis for a One-Way ANOVA',
        'regression': 'Power Analysis for Linear Regression'
    };

    let text = testNames[AppState.testType] + '\n\n';
    text += `Computed Power = ${power.toFixed(4)}\n`;
    text += 'Parameters:\n';
    text += `  Sample Size per group (n): ${params.n}\n`;

    if (AppState.testType === 'two_sample' || AppState.testType === 'paired') {
        text += `  Effect Size (Cohen's d): ${params.effectSize.toFixed(4)}\n`;
        text += `  Test type: ${params.oneTailed ? 'One-tailed' : 'Two-tailed'}\n`;
    } else if (AppState.testType === 'anova') {
        text += `  Number of groups (k): ${params.k}\n`;
        text += `  Effect Size (Cohen's f): ${params.effectSize.toFixed(4)}\n`;
    } else if (AppState.testType === 'regression') {
        text += `  Number of predictors: ${params.predictors}\n`;
        text += `  R²: ${params.r2.toFixed(4)}\n`;
        const f2 = params.r2 / (1 - params.r2);
        text += `  Effect size (f²): ${f2.toFixed(4)}\n`;
    }

    text += `  Significance level (α): ${params.alpha.toFixed(3)}\n`;
    text += '\nInterpretation:\n';
    
    if (power < 0.8) {
        text += `  The current power (${(power * 100).toFixed(1)}%) is below the commonly recommended 80% threshold.\n`;
        text += '  Consider increasing sample size or expecting a larger effect size.';
    } else {
        text += `  The current power (${(power * 100).toFixed(1)}%) meets or exceeds the commonly recommended 80% threshold.`;
    }

    document.getElementById('solutionText').textContent = text;
}

/**
 * Update power curve visualization
 */
function updatePowerCurve(params, currentPower) {
    // Determine sample size range
    let minN, maxN, step;
    
    const n = params.n;
    if (n <= 20) {
        minN = AppState.testType === 'regression' ? params.predictors + 2 : 2;
        maxN = Math.max(100, 3 * n);
        step = 1;
    } else if (n <= 50) {
        minN = AppState.testType === 'regression' ? params.predictors + 2 : 2;
        maxN = Math.max(150, 2 * n);
        step = 2;
    } else if (n <= 200) {
        minN = AppState.testType === 'regression' ? params.predictors + 2 : 2;
        maxN = Math.max(300, Math.floor(1.5 * n));
        step = 5;
    } else {
        minN = AppState.testType === 'regression' ? params.predictors + 2 : 2;
        maxN = Math.max(500, Math.floor(1.2 * n));
        step = 10;
    }

    // Ensure current n is in range
    if (n < minN) minN = Math.max(2, n - 10);
    if (n > maxN) maxN = n + 50;

    // Generate power curve data
    const powerData = Statistics.generatePowerCurve(AppState.testType, params, minN, maxN, step);
    
    // Ensure current point is included
    const hasCurrentPoint = powerData.some(d => d.n === n);
    if (!hasCurrentPoint && !isNaN(currentPower) && isFinite(currentPower)) {
        powerData.push({ n, power: currentPower });
        powerData.sort((a, b) => a.n - b.n);
    }

    // Always render - D3 can render to hidden containers
    Visualizations.plotPowerCurve('plotCombined', powerData, n, currentPower);
}

/**
 * Calculate required sample size for target power
 */
function calculateRequiredSampleSize() {
    const params = getCurrentParams();
    const targetPower = AppState.targetPower;

    if (targetPower <= 0 || targetPower >= 1) {
        displayError('Target power must be between 0 and 1');
        return;
    }

    try {
        const nRequired = Statistics.findSampleSize(AppState.testType, targetPower, params);
        
        if (nRequired === null || isNaN(nRequired)) {
            document.getElementById('sample_size_result').textContent = 
                'Unable to calculate required sample size. Please check your inputs.';
            return;
        }

        document.getElementById('sample_size_result').textContent = 
            `Required sample size to achieve ${(targetPower * 100).toFixed(0)}% power: n = ${nRequired}`;

        // Update the sample size input
        AppState.n = nRequired;
        document.getElementById('n').value = nRequired;
        updateAll();
    } catch (error) {
        console.error('Error calculating sample size:', error);
        displayError('Error calculating required sample size.');
    }
}

/**
 * Generate JavaScript code for replication
 */
function generateCode() {
    const params = getCurrentParams();
    const power = Statistics.calculatePower(AppState.testType, params);
    
    let code = '// JavaScript code to replicate this power analysis\n';
    code += '// Using jStat for statistical calculations\n\n';
    code += '// Parameters\n';

    if (AppState.testType === 'two_sample') {
        code += `const n = ${params.n}; // Sample size per group\n`;
        code += `const d = ${params.effectSize}; // Effect size (Cohen's d)\n`;
        code += `const alpha = ${params.alpha}; // Significance level\n`;
        code += `const alternative = "${params.oneTailed ? 'one-tailed' : 'two-tailed'}"; // Test direction\n\n`;
        code += '// Calculate power using Statistics module\n';
        code += `const power = Statistics.calculatePower('two_sample', { n, d, alpha, oneTailed: ${params.oneTailed} });\n`;
        code += `console.log(\`Power = \${power.toFixed(4)}\`);\n`;
    } else if (AppState.testType === 'paired') {
        code += `const n = ${params.n}; // Number of pairs\n`;
        code += `const d = ${params.effectSize}; // Effect size (Cohen's d)\n`;
        code += `const alpha = ${params.alpha}; // Significance level\n\n`;
        code += '// Calculate power using Statistics module\n';
        code += `const power = Statistics.calculatePower('paired', { n, d, alpha, oneTailed: ${params.oneTailed} });\n`;
        code += `console.log(\`Power = \${power.toFixed(4)}\`);\n`;
    } else if (AppState.testType === 'anova') {
        code += `const k = ${params.k}; // Number of groups\n`;
        code += `const n = ${params.n}; // Sample size per group\n`;
        code += `const f = ${params.effectSize}; // Effect size (Cohen's f)\n`;
        code += `const alpha = ${params.alpha}; // Significance level\n\n`;
        code += '// Calculate power using Statistics module\n';
        code += `const power = Statistics.calculatePower('anova', { k, n, f, alpha });\n`;
        code += `console.log(\`Power = \${power.toFixed(4)}\`);\n`;
    } else if (AppState.testType === 'regression') {
        code += `const n = ${params.n}; // Total sample size\n`;
        code += `const predictors = ${params.predictors}; // Number of predictors\n`;
        code += `const r2 = ${params.r2}; // R-squared value\n`;
        code += `const f2 = r2 / (1 - r2); // Convert to f-squared\n`;
        code += `const alpha = ${params.alpha}; // Significance level\n\n`;
        code += '// Calculate power using Statistics module\n';
        code += `const power = Statistics.calculatePower('regression', { n, predictors, r2, alpha });\n`;
        code += `console.log(\`Power = \${power.toFixed(4)}\`);\n`;
    }

    document.getElementById('plotCode').textContent = code;
}

/**
 * Display error message
 */
function displayError(message) {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.textContent = message;
    
    const container = document.querySelector('.main-panel');
    const existingError = container.querySelector('.error-message');
    if (existingError) {
        existingError.remove();
    }
    
    container.insertBefore(errorDiv, container.firstChild);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        errorDiv.remove();
    }, 5000);
}

/**
 * Clear error messages
 */
function clearErrors() {
    const errors = document.querySelectorAll('.error-message');
    errors.forEach(err => err.remove());
}

