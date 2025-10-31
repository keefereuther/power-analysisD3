# Statistical Power Analysis

An interactive D3.js web application for teaching and understanding statistical power analysis and sample size calculations. This educational tool provides real-time visualizations and accurate statistical calculations for power analysis in hypothesis testing.

## 🌐 Live Demo

**View the application:** [https://keefereuther.github.io/power-analysisD3/](https://keefereuther.github.io/power-analysisD3/)

## 📋 Overview

This interactive web application helps students and researchers understand how statistical power is affected by various parameters such as sample size, effect size, significance level, and test type. The application uses D3.js for dynamic visualizations and jStat for mathematically accurate statistical calculations.

## ✨ Features

### Interactive Power Calculations
- Calculate statistical power for **two-sample t-tests** using accurate non-central t-distribution calculations
- Real-time updates as parameters change
- Support for one-tailed and two-tailed tests

### Visualizations

1. **Test Statistic Distribution Plot**
   - Visualizes null and alternative hypothesis distributions
   - Shows critical regions, Type I error (α), Type II error (β), and power (1-β)
   - Legend positioned in upper-right corner for clarity
   - Displays current power value

2. **Power Curve**
   - Interactive visualization showing how sample size affects statistical power
   - Highlights current sample size and power
   - Includes reference line for target power (typically 0.8)
   - Annotations for easy interpretation

3. **Sample Data Visualization**
   - Generates and displays synthetic data matching your parameters
   - Box plots showing data distributions for different groups
   - Helps visualize the effect size in simulated datasets

### Sample Size Calculator
- Find the required sample size to achieve a target power (default: 80%)
- Real-time calculation using iterative methods
- Displays results immediately

### User Interface
- **Collapsible sections**: Organize interface with expandable/collapsible panels
- **Compact layout**: All settings consolidated in a single "Basic Settings" panel
- **Responsive design**: Works on desktop and tablet devices

## 🚀 Getting Started

### Option 1: Use the Live Version

Simply visit the [GitHub Pages site](https://keefereuther.github.io/power-analysisD3/) - no installation needed!

### Option 2: Run Locally

1. Clone the repository:
```bash
git clone https://github.com/keefereuther/power-analysisD3.git
cd power-analysisD3
```

2. Start a local web server:

**Using Python:**
```bash
python3 -m http.server 8000
```

**Using Node.js:**
```bash
npx http-server -p 8000
```

**Using PHP:**
```bash
php -S localhost:8000
```

3. Open your browser and navigate to:
```
http://localhost:8000
```

## 📁 Project Structure

```
power-analysisD3/
├── index.html          # Main HTML file
├── css/
│   └── style.css      # Application styling
├── js/
│   ├── main.js        # Main application logic and event handlers
│   ├── statistics.js  # Statistical calculations (power, critical values, etc.)
│   ├── visualizations.js # D3.js visualization functions
│   ├── dataGeneration.js # Sample data generation
│   └── exports.js     # Export functionality (unused)
├── LICENSE            # AGPL-3.0 License
└── README.md          # This file
```

## 🎓 Educational Use

This tool is designed for educational purposes to help students understand:

1. **How sample size affects power**: Increase sample size and observe power changes
2. **Effect size impact**: Larger effect sizes require smaller sample sizes
3. **Significance level trade-offs**: Changing α affects both Type I error and power
4. **One vs. two-tailed tests**: Compare power between test types
5. **Distribution visualization**: See null and alternative distributions overlap

### Guiding Questions Included

The application includes guiding questions to help students explore:
- What happens to power as sample size increases?
- How does effect size affect required sample size?
- What are the trade-offs of changing significance level?
- Why use one-tailed vs. two-tailed tests?

## 🔧 Technologies

- **D3.js v7**: Data-driven document manipulation and visualization
- **jStat v1.9.5**: Mathematical statistics library for accurate calculations
  - Non-central t-distributions
  - F-distributions
  - CDF and PDF calculations
- **Vanilla JavaScript**: No frameworks - pure ES6+ JavaScript
- **HTML5/CSS3**: Modern web standards with CSS transitions and animations

## 📊 Statistical Methods

The application uses mathematically accurate methods:

- **Power calculation**: Uses non-central t-distribution for accurate power estimation
- **Critical values**: Calculated using inverse CDF of t-distribution
- **Non-centrality parameter**: Computed from effect size and sample size
- **Sample size calculation**: Iterative search algorithm to find required n

### Supported Test Types

Currently implemented:
- ✅ Two-sample t-test (independent samples)

Future implementations (commented out in code):
- Paired t-test
- One-way ANOVA
- Linear Regression

## 🎨 Features and UI

### Collapsible Sections
- All output sections are collapsible for a cleaner interface
- Default state: Only "Basic Settings" and "Test Statistic Distribution" are expanded
- Click section headers to expand/collapse

### Compact Settings Panel
- All input parameters consolidated in one panel:
  - Test Type
  - Sample Size (n)
  - Significance Level (α)
  - Effect Size (Cohen's d)
  - One-tailed test checkbox
  - Target Power calculator

## 🛠️ Development

### Code Organization

The application is organized into modular JavaScript files:

- **`main.js`**: Application state, event handling, UI updates
- **`statistics.js`**: All statistical calculations using jStat
- **`visualizations.js`**: D3.js plotting functions
- **`dataGeneration.js`**: Synthetic data generation for visualization

### Key Functions

**Power Calculation:**
```javascript
Statistics.calculatePower(testType, params)
```

**Visualization:**
```javascript
Visualizations.plotDistribution(containerId, distData, power, testType)
Visualizations.plotPowerCurve(containerId, powerData, currentN, currentPower)
Visualizations.plotSampleData(containerId, data, testType)
```

## 📝 License

This project is licensed under the **GNU Affero General Public License v3.0** (AGPL-3.0).

See the [LICENSE](LICENSE) file for details.

## 👤 Author

**Keefe Reuther**

- Website: [reutherlab.netlify.app](https://reutherlab.netlify.app)
- GitHub: [@keefereuther](https://github.com/keefereuther)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 🙏 Acknowledgments

- Built with [D3.js](https://d3js.org/)
- Statistical calculations powered by [jStat](https://jstat.github.io/)
- Inspired by R Shiny applications for statistical education

## 📚 Resources

- [Statistical Power Analysis](https://en.wikipedia.org/wiki/Statistical_power)
- [Cohen's d Effect Size](https://en.wikipedia.org/wiki/Effect_size#Cohen's_d)
- [Type I and Type II Errors](https://en.wikipedia.org/wiki/Type_I_and_type_II_errors)

---

**Note**: This is an educational tool. For actual research power analysis, consider consulting with a statistician or using established statistical software packages.
