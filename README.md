# Statistical Power Analysis

An interactive D3.js web application for understanding statistical power and sample size calculations. This tool provides visualizations and calculations for:

- Two-sample t-tests
- Paired t-tests
- One-way ANOVA
- Linear Regression

## Features

- **Interactive Power Calculations**: Calculate statistical power for various test types using accurate jStat statistical library
- **Visual Distributions**: View t and F distributions with critical regions, Type I/II error regions, and power regions
- **Power Curves**: Visualize how sample size affects statistical power
- **Sample Data Visualization**: See synthetic datasets matching your parameters
- **Sample Size Calculator**: Find the required sample size to achieve your target power

## Usage

Simply open `index.html` in a web browser, or visit the [GitHub Pages site](https://yourusername.github.io/power_analysisD3/) (after deployment).

## Deployment to GitHub Pages

1. Push this repository to GitHub
2. Go to your repository settings
3. Navigate to "Pages" in the left sidebar
4. Under "Source", select your main branch (usually `main` or `master`)
5. Click "Save"
6. Your site will be available at `https://yourusername.github.io/power_analysisD3/`

## Technologies

- **D3.js v7**: Data visualization
- **jStat**: Statistical calculations and distributions
- **Vanilla JavaScript**: No frameworks required

## Development

This is a static web application. To run locally:

```bash
# Using Python
python3 -m http.server 8000

# Or using Node.js
npx http-server -p 8000
```

Then open `http://localhost:8000` in your browser.

## License

Licensed under GNU GPL v3.0

## Credits

Developed by [Keefe Reuther](https://reutherlab.netlify.app)

