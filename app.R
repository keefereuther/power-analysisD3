# Load required libraries
library(shiny)
library(shinythemes)
library(pwr)
library(ggplot2)

# Define UI
ui <- fluidPage(
  theme = shinytheme("cosmo"),
  
  # Add CSS styling directly in the file
  tags$head(
    tags$style(HTML("
      /* Sample size calculator panel */
      .sample-size-panel {
        background-color: #f8f9fa; 
        border: 1px solid #dee2e6; 
        border-radius: 5px; 
        padding: 15px; 
        margin-top: 20px; 
        margin-bottom: 20px; 
        box-shadow: 0 2px 4px rgba(0,0,0,0.05);
      }
      
      /* Enhanced section headers with horizontal bar */
      .section-header {
        background-color: #2c3e50;
        color: white;
        padding: 10px 15px;
        margin: 20px -15px 15px -15px;
        font-weight: 600;
        font-size: 1.15em;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        border-radius: 0;
        position: relative;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }
      
      /* Optional focus highlight for subsections */
      .subsection-focus {
        background-color: #f8f9fa;
        border-radius: 4px;
        padding: 10px;
        border-left: 3px solid #3498db;
        margin-bottom: 15px;
      }
      
      /* Enhanced subsection styling with callout */
      .subsection-header {
        color: #2c3e50;
        font-weight: 600;
        font-size: 1.05em;
        margin: 15px 0 10px 0;
        padding-bottom: 5px;
        border-bottom: 2px solid #3498db;
        position: relative;
        padding-left: 12px;
      }
      
      /* Add left accent bar to subsection headers */
      .subsection-header:before {
        content: '';
        position: absolute;
        left: 0;
        top: 0;
        bottom: 5px;
        width: 4px;
        background-color: #3498db;
        border-radius: 2px;
      }
      
      /* Guiding questions panel */
      .guiding-questions {
        background-color: #e8f4f8;
        border-left: 4px solid #5bc0de;
        padding: 15px;
        margin: 15px 0 25px 0;
        border-radius: 0 4px 4px 0;
      }
      
      .guiding-questions h4 {
        color: #31708f;
        margin-top: 0;
        font-weight: 600;
      }
      
      .guiding-questions p {
        color: #31708f;
        margin-bottom: 8px;
      }
      
      /* Style for the expander link */
      .expander-link {
        color: #3498db;
        cursor: pointer;
        text-decoration: none;
        font-weight: 500;
      }
      
      .expander-link:hover {
        text-decoration: underline;
        color: #2980b9;
      }
    "))
  ),
  
  # Title panel with your name and website
  titlePanel(div(
    h2("Statistical Power Analysis", class = "app-title"),
    h4(HTML("Interactive tool for understanding statistical power and sample size"), 
      class = "app-subtitle"),
    hr(),
    h5(HTML("Developed by <a href='https://reutherlab.netlify.app' target='_blank'>Keefe Reuther</a>"), 
      class = "app-subtitle")
  )),
  
    # Always visible Instructions
  div(class = "guiding-questions",
    h4("Instructions"),
    p("By modifying a single parameter and keeping all other parameters constant, you can infer how that parameter affects power."),
  ),

  # Always visible guiding questions
  div(class = "guiding-questions",
    h4("Guiding Questions"),
    p("1. What happens to power as sample size increases? Why?"),
    p("2. What sample size do we need to achieve a power of 0.8 with a standard deviation of 1, a difference in means of 0.5, and an alpha of 0.05?"),
    p("3. How does sample size change in the above scenario if we changed our alpha to 0.0001? Why?"),
    p("4. What happens to the sample size necessary to achieve a 0.80 power if we switch to a one-tailed test? Why don't we always use a one-tailed test?"),
    p("5. How does increasing the effect size affect the power of the test? Why is effect size an important factor?"),
    p("6. How does changing the significance level (α) affect both the probability of a Type I error and the power of the test? What trade-offs are involved?"),
    p("7. Why do you think power increases when you switch from a two-sample t-test to a paired t-test?")
  ),
  
  sidebarLayout(
    sidebarPanel(
      # Test Type Selection
      div(class = "sidebar-section", 
        h3(class = "section-header", "Test Type"),
        selectInput("test_type", "Choose Analysis",
                  choices = c("Two-sample t-test" = "two_sample", 
                              "Paired t-test" = "paired",
                              "One-way ANOVA" = "anova", 
                              "Linear Regression" = "regression"))
      ),
      
      # Common Parameters
      div(class = "sidebar-section",
        h3(class = "section-header", "Basic Settings"),
        
        div(class = "subsection-focus",
          h4(class = "subsection-header", "Sample Size"),
          numericInput("n", "n", 30, min = 2, max = 1000, step = 1),
          helpText("Number of observations per group")
        ),
        
        div(class = "subsection-focus",
          h4(class = "subsection-header", "Significance Level"),
          numericInput("alpha", "α", 0.05, min = 0.001, max = 0.5, step = 0.01),
          helpText("Probability of Type I error (false positive)")
        )
      ),
      
      # T-test parameters
      conditionalPanel(
        condition = "input.test_type == 'two_sample' || input.test_type == 'paired'",
        div(class = "sidebar-section",
          h3(class = "section-header", "T-Test Settings"),
          
          div(class = "subsection-focus",
            h4(class = "subsection-header", "Effect Size (Cohen's d)"),
            numericInput("effect_size_ttest", "Effect Size (Cohen's d):", 
                        min = 0.1, max = 2, value = 0.5, step = 0.1),
            helpText("Typical values: small: 0.2, medium: 0.5, large: 0.8")
          ),
          
          div(class = "subsection-focus",
            h4(class = "subsection-header", "Test Direction"),
            checkboxInput("one_tailed", "One-tailed", FALSE),
            helpText("Check if testing for effect in only one direction")
          )
        )
      ),
      
      # ANOVA parameters
      conditionalPanel(
        condition = "input.test_type == 'anova'",
        div(class = "sidebar-section",
          h3(class = "section-header", "ANOVA Settings"),
          
          div(class = "subsection-focus",
            h4(class = "subsection-header", "Groups"),
            numericInput("k", "k", 3, min = 2, max = 20, step = 1),
            helpText("Number of groups to compare")
          ),
          
          div(class = "subsection-focus",
            h4(class = "subsection-header", "Effect Size (Cohen's f)"),
            numericInput("effect_size_anova", "Effect Size (Cohen's f):", 
                        min = 0.1, max = 2, value = 0.25, step = 0.05),
            helpText("Typical values: small: 0.1, medium: 0.25, large: 0.4")
          )
        )
      ),
      
      # Regression parameters
      conditionalPanel(
        condition = "input.test_type == 'regression'",
        div(class = "sidebar-section",
          h3(class = "section-header", "Regression Settings"),
          
          div(class = "subsection-focus",
            h4(class = "subsection-header", "Predictors"),
            numericInput("predictors", "Number", 2, min = 1, max = 50, step = 1),
            helpText("Count of independent variables")
          ),
          
          div(class = "subsection-focus",
            h4(class = "subsection-header", "Effect Size"),
            numericInput("r2", "R²", 0.2, min = 0.01, max = 0.99, step = 0.01),
            helpText("0.02 = small, 0.13 = medium, 0.26 = large")
          )
        )
      ),
      
      # Sample size calculator with special styling
      div(class = "sample-size-panel",
        h3(class = "section-header", "Power Calculator"),
        
        p("Find the required sample size to achieve your desired statistical power:",
          class = "help-block"),
        
        div(class = "subsection-focus",
          h4(class = "subsection-header", "Target Power"),
          numericInput("target_power", "1-β", 0.8, min = 0.1, max = 0.99, step = 0.05),
          helpText("Desired probability of detecting a true effect")
        ),
        
        div(class = "subsection-focus",
          h4(class = "subsection-header", "Calculate"),
          actionButton("calculate_n", "Find Required Sample Size", class = "btn-primary"),
          br(),
          textOutput("sample_size_result")
        )
      )
    ),
    
    mainPanel(
      # Power Analysis Results
      h3(class = "section-header", "Power Analysis Results"),
      verbatimTextOutput("solutionText"),
      
      # Test distribution visualization
      h3(class = "section-header", "Test Statistic Distribution"),
      plotOutput("plotDistribution"),
      
      # Power Analysis Plot
      h3(class = "section-header", "Power Curve"),
      plotOutput("plotCombined"),
      
      # Sample Data Visualization
      h3(class = "section-header", "Sample Data Visualization"),
      plotOutput("plotData"),
      
      # Code display section
      checkboxInput("show_code", "Show R code to replicate analysis", FALSE),
      conditionalPanel(
        condition = "input.show_code == true",
        verbatimTextOutput("plotCode")
      ),
      
      # Export options
      div(
        h3(class = "section-header", "Export Results"),
        fluidRow(
          column(4, downloadButton("downloadReport", "Download Report", class = "btn-info btn-block")),
          column(4, downloadButton("downloadPlot", "Download Plot", class = "btn-info btn-block")),
          column(4, downloadButton("downloadData", "Download Sample Data", class = "btn-info btn-block"))
        )
      ),
      
      # Add horizontal rule and footer
      tags$hr(style = "margin-top: 40px; margin-bottom: 20px;"),
      
      p(HTML("&copy; 2025 Reuther Lab • <a href='https://reutherlab.netlify.app' target='_blank'>reutherlab.netlify.app</a> • Licensed under <a href='https://www.gnu.org/licenses/gpl-3.0.html' target='_blank'>GNU GPL v3.0</a>"), 
        style = "text-align: center; color: #777; font-size: 0.9em;")
    )
  )
)

# Define server
server <- function(input, output, session) {
  # Input validation
  observe({
    # Sample size validation
    if (input$n <= 0) {
      showNotification("Sample size must be positive", type = "error")
    }
    
    # Effect size validations
    if (input$test_type %in% c("two_sample", "paired")) {
      if (input$effect_size_ttest <= 0) {
        showNotification("Effect size must be positive", type = "error")
      }
    } else if (input$test_type == "anova") {
      if (input$k < 2) {
        showNotification("Number of groups must be at least 2", type = "error")
      }
      if (input$effect_size_anova <= 0) {
        showNotification("Effect size must be positive", type = "error")
      }
    } else if (input$test_type == "regression") {
      if (input$predictors < 1) {
        showNotification("Number of predictors must be at least 1", type = "error")
      }
      if (input$r2 <= 0 || input$r2 >= 1) {
        showNotification("R² must be between 0 and 1", type = "error")
      }
    }
    
    # Alpha validation
    if (input$alpha <= 0 || input$alpha >= 1) {
      showNotification("Significance level must be between 0 and 1", type = "error")
    }
    
    # Target power validation
    if (input$target_power <= 0 || input$target_power >= 1) {
      showNotification("Target power must be between 0 and 1", type = "error")
    }
  })
  
  # Calculate effect size based on test type
  effect_size <- reactive({
    test_type <- input$test_type
    
    if (test_type == "two_sample" || test_type == "paired") {
      # Cohen's d = difference in means / standard deviation
      # This is a standardized measure of effect size used for t-tests
      # Values around 0.2, 0.5, and 0.8 are considered small, medium, and large effects respectively
      return(input$effect_size_ttest)
    } else if (test_type == "anova") {
      # Cohen's f is used for ANOVA
      # f = 0.1, 0.25, and 0.4 are considered small, medium, and large effects respectively
      # This represents the standardized variation of group means
      return(input$effect_size_anova)
    } else if (test_type == "regression") {
      # For regression, we use f² which is related to R²
      # f² = R² / (1 - R²)
      # This represents the proportion of variance explained relative to unexplained variance
      r2 <- input$r2
      return(r2 / (1 - r2))
    }
  })
  
  # Calculate degrees of freedom based on test type
  df <- reactive({
    test_type <- input$test_type
    n <- input$n
    
    if (test_type == "two_sample") {
      # For two-sample t-test: df = n₁ + n₂ - 2
      # Assuming equal sample sizes, df = 2n - 2
      return(2 * n - 2)
    } else if (test_type == "paired") {
      # For paired t-test: df = n - 1
      # This represents the number of pairs minus 1
      return(n - 1)
    } else if (test_type == "anova") {
      # For ANOVA, we have two df values:
      # df₁ = k - 1 (between groups df, where k is the number of groups)
      # df₂ = k(n - 1) (within groups df, with n observations per group)
      k <- input$k
      return(list(df1 = k - 1, df2 = k * (n - 1)))
    } else if (test_type == "regression") {
      # For regression:
      # df₁ = p (number of predictors)
      # df₂ = n - p - 1 (sample size minus predictors minus 1)
      p <- input$predictors
      return(list(df1 = p, df2 = n - p - 1))
    }
  })
  
  # Calculate critical value based on test type
  critical_value <- reactive({
    test_type <- input$test_type
    alpha <- input$alpha
    
    if (test_type == "two_sample" || test_type == "paired") {
      # For t-tests, critical value comes from t-distribution
      degrees <- df()
      if (input$one_tailed) {
        # One-tailed test requires just 1-α percentile
        return(qt(1 - alpha, df = degrees))
      } else {
        # Two-tailed test requires 1-α/2 percentile (more conservative)
        # This accounts for rejecting in either direction (positive or negative)
        return(qt(1 - alpha/2, df = degrees))
      }
    } else if (test_type == "anova") {
      # For ANOVA, critical value comes from F-distribution
      # F-tests are always one-tailed (right-tailed) tests
      degrees <- df()
      return(qf(1 - alpha, df1 = degrees$df1, df2 = degrees$df2))
    } else if (test_type == "regression") {
      # For regression F-test
      # This tests whether the predictors significantly explain the variance
      degrees <- df()
      return(qf(1 - alpha, df1 = degrees$df1, df2 = degrees$df2))
    }
  })
  
  # Safe power calculation function with error handling
  safe_calculate_power <- function() {
    tryCatch({
      test_type <- input$test_type
      n <- input$n
      alpha <- input$alpha
      
      # Input validation
      validate(
        need(n > 0, "Sample size must be positive"),
        need(alpha > 0 && alpha < 1, "Significance level must be between 0 and 1")
      )
      
      if (test_type %in% c("two_sample", "paired")) {
        d <- effect_size()
        validate(
          need(!is.na(d) && is.finite(d), "Invalid effect size calculated")
        )
        
        # Calculate power
        if (test_type == "two_sample") {
          result <- pwr.t.test(n = n, d = d, sig.level = alpha, 
                          type = "two.sample", 
                          alternative = ifelse(input$one_tailed, "greater", "two.sided"))$power
        } else {
          result <- pwr.t.test(n = n, d = d, sig.level = alpha, 
                          type = "paired", 
                          alternative = ifelse(input$one_tailed, "greater", "two.sided"))$power
        }
      } else if (test_type == "anova") {
        # For ANOVA
        k <- input$k
        f <- input$effect_size_anova
        validate(
          need(k >= 2, "Number of groups must be at least 2"),
          need(f > 0, "Effect size must be positive")
        )
        result <- pwr.anova.test(k = k, n = n, f = f, sig.level = alpha)$power
      } else if (test_type == "regression") {
        # For linear regression
        predictors <- input$predictors
        f2 <- effect_size()
        
        validate(
          need(predictors >= 1, "Number of predictors must be at least 1"),
          need(input$r2 > 0 && input$r2 < 1, "R² must be between 0 and 1")
        )
        
        # Check sample size vs. predictors BEFORE attempting power calculation
        if (n <= predictors + 1) {
          return(NA)  # Not enough data points relative to predictors
        }
        
        # Now it's safe to calculate power
        result <- pwr.f2.test(u = predictors, v = n - predictors - 1, 
                         f2 = input$r2 / (1 - input$r2), sig.level = alpha)$power
      } else {
        result <- NA
      }
      
      validate(
        need(!is.na(result) && is.finite(result), "Power calculation failed. Please check your inputs.")
      )
      
      return(result)
    }, 
    error = function(e) {
      # Log the error for debugging purposes
      message("Error in power calculation: ", e$message)
      return(NA)
    })
  }
  
  # Replace calculate_power with safe_calculate_power where needed
  calculate_power <- reactive({
    safe_calculate_power()
  })
  
  # Generate sample data for visualization
  generate_sample_data <- reactive({
    test_type <- input$test_type
    n <- input$n
    
    if (test_type == "two_sample") {
      # Generate data for a two-sample t-test
      d <- effect_size()
      sigma <- 1  # Assuming standard deviation of 1 for simplicity
      delta <- d * sigma
      group1 <- rnorm(n, mean = 0, sd = sigma)
      group2 <- rnorm(n, mean = delta, sd = sigma)
      data.frame(
        value = c(group1, group2),
        group = factor(rep(c("Group 1", "Group 2"), each = n))
      )
    } else if (test_type == "paired") {
      # Generate data for a paired t-test
      d <- effect_size()
      sigma <- 1  # Assuming standard deviation of 1 for simplicity
      delta <- d * sigma
      pre <- rnorm(n, mean = 0, sd = sigma)
      post <- pre + rnorm(n, mean = delta, sd = sigma * 0.5)
      data.frame(
        id = rep(1:n, 2),
        value = c(pre, post),
        time = factor(rep(c("Pre", "Post"), each = n))
      )
    } else if (test_type == "anova") {
      # Generate data for a one-way ANOVA
      k <- input$k
      f <- input$effect_size_anova
      sigma <- 1  # Assuming standard deviation of 1 for simplicity
      
      # Calculate means for each group based on the effect size
      # For simplicity, we'll create equal spacing between group means
      group_means <- seq(-f * sigma * (k-1)/2, f * sigma * (k-1)/2, length.out = k)
      
      # Generate data for each group
      data <- data.frame()
      for (i in 1:k) {
        group_data <- data.frame(
          value = rnorm(n, mean = group_means[i], sd = sigma),
          group = paste("Group", i)
        )
        data <- rbind(data, group_data)
      }
      data$group <- factor(data$group)
      data
    } else if (test_type == "regression") {
      # Generate data for linear regression
      predictors <- input$predictors
      r2 <- input$r2
      
      # Generate a design matrix with random predictors
      X <- matrix(rnorm(n * predictors), ncol = predictors)
      
      # Generate coefficients
      beta <- rnorm(predictors)
      
      # Calculate signal component
      signal <- X %*% beta
      
      # Scale signal to have variance 1
      signal <- scale(signal)[,1]
      
      # Calculate noise component based on R² value
      # If R² is the proportion of variance explained, then
      # Var(Y) = Var(signal) + Var(noise)
      # R² = Var(signal) / Var(Y)
      noise_var <- (1 - r2) / r2
      noise <- rnorm(n, sd = sqrt(noise_var))
      
      # Generate response variable
      y <- signal + noise
      
      # Create a data frame
      data <- data.frame(y = y)
      for (i in 1:predictors) {
        data[[paste0("x", i)]] <- X[,i]
      }
      data
    }
  })
  
  # Output text summary
  output$solutionText <- renderText({
    # Get calculated power
    power <- calculate_power()
    
    # Get parameters
    test_type <- input$test_type
    n <- input$n
    alpha <- input$alpha
    
    # Common parameters
    result <- switch(test_type,
                    "two_sample" = "Power Analysis for a Two-Sample t-Test",
                    "paired" = "Power Analysis for a Paired t-Test",
                    "anova" = "Power Analysis for a One-Way ANOVA",
                    "regression" = "Power Analysis for Linear Regression")
    
    result <- paste0(result, "\n\n")
    result <- paste0(result, "Computed Power = ", round(power, 4), "\n")
    result <- paste0(result, "Parameters:\n")
    result <- paste0(result, "  Sample Size per group (n): ", n, "\n")
    
    # Test-specific parameters
    if (test_type == "two_sample" || test_type == "paired") {
      result <- paste0(result, "  Effect Size (Cohen's d): ", round(input$effect_size_ttest, 4), "\n")
      result <- paste0(result, "  Test type: ", ifelse(input$one_tailed, "One-tailed", "Two-tailed"), "\n")
    } else if (test_type == "anova") {
      result <- paste0(result, "  Number of groups (k): ", input$k, "\n")
      result <- paste0(result, "  Effect Size (Cohen's f): ", round(input$effect_size_anova, 4), "\n")
    } else if (test_type == "regression") {
      result <- paste0(result, "  Number of predictors: ", input$predictors, "\n")
      result <- paste0(result, "  R²: ", round(input$r2, 4), "\n")
      f2 <- input$r2 / (1 - input$r2)
      result <- paste0(result, "  Effect size (f²): ", round(f2, 4), "\n")
    }
    
    # Common parameters
    result <- paste0(result, "  Significance level (α): ", round(alpha, 3), "\n")
    
    # Interpretation
    result <- paste0(result, "\nInterpretation:\n")
    if (power < 0.8) {
      result <- paste0(result, "  The current power (", round(power*100, 1), 
                      "%) is below the commonly recommended 80% threshold.\n",
                      "  Consider increasing sample size or expecting a larger effect size.")
    } else {
      result <- paste0(result, "  The current power (", round(power*100, 1), 
                      "%) meets or exceeds the commonly recommended 80% threshold.")
    }
    
    return(result)
  })
  
  # Plot the test statistic distribution
  output$plotDistribution <- renderPlot({
    test_type <- input$test_type
    alpha <- input$alpha
    n <- input$n
    power <- calculate_power()
    
    # Set up plot parameters
    par(mar = c(5, 5, 4, 2) + 0.1)
    
    if (test_type == "two_sample" || test_type == "paired") {
      # T-distribution
      degrees <- df()
      crit <- critical_value()
      
      # Determine non-centrality parameter (delta)
      d <- effect_size()
      sigma <- 1  # Assuming standard deviation of 1 for simplicity
      delta <- d * sigma
      
      # Calculate non-centrality parameter
      if (test_type == "two_sample") {
        ncp <- d * sqrt(n/2)
      } else {
        ncp <- d * sqrt(n)
      }
      
      # Create plot range
      if (input$one_tailed) {
        x_range <- seq(-4, max(8, crit + 5), length.out = 1000)
      } else {
        x_range <- seq(min(-8, -crit - 5), max(8, crit + 5), length.out = 1000)
      }
      
      # Calculate density values
      y_h0 <- dt(x_range, df = degrees)
      y_h1 <- dt(x_range, df = degrees, ncp = ncp)
      
      # Determine maximum y value for scaling
      max_y <- max(c(y_h0, y_h1)) * 1.1
      
      # Plot null hypothesis distribution
      plot(x_range, y_h0, type = "l", lwd = 2, col = "blue",
           xlab = "t-statistic", ylab = "Density",
           main = "t-Distribution with Test Decision Regions",
           cex.lab = 1.2, cex.axis = 1.2, cex.main = 1.3,
           ylim = c(0, max_y))
      
      # Add alternative hypothesis distribution
      lines(x_range, y_h1, lwd = 2, col = "red", lty = 2)
      
      # Add critical regions
      if (input$one_tailed) {
        # One-tailed critical region
        x_crit <- seq(crit, max(x_range), length.out = 200)
        y_crit <- dt(x_crit, df = degrees)
        polygon(c(crit, x_crit, max(x_range)), c(0, y_crit, 0), col = rgb(1, 0, 0, 0.2))
        
        # Type II error region
        x_beta <- seq(min(x_range), crit, length.out = 200)
        y_beta <- dt(x_beta, df = degrees, ncp = ncp)
        polygon(c(min(x_range), x_beta, crit), c(0, y_beta, 0), col = rgb(0, 0, 1, 0.2))
        
        # Power region
        x_power <- seq(crit, max(x_range), length.out = 200)
        y_power <- dt(x_power, df = degrees, ncp = ncp)
        polygon(c(crit, x_power, max(x_range)), c(0, y_power, 0), col = rgb(0, 1, 0, 0.2))
      } else {
        # Two-tailed critical regions
        crit_pos <- crit
        crit_neg <- -crit
        
        # Add positive critical region
        x_crit_pos <- seq(crit_pos, max(x_range), length.out = 200)
        y_crit_pos <- dt(x_crit_pos, df = degrees)
        polygon(c(crit_pos, x_crit_pos, max(x_range)), c(0, y_crit_pos, 0), col = rgb(1, 0, 0, 0.2))
        
        # Add negative critical region
        x_crit_neg <- seq(min(x_range), crit_neg, length.out = 200)
        y_crit_neg <- dt(x_crit_neg, df = degrees)
        polygon(c(min(x_range), x_crit_neg, crit_neg), c(0, y_crit_neg, 0), col = rgb(1, 0, 0, 0.2))
        
        # Type II error region (middle)
        x_beta <- seq(crit_neg, crit_pos, length.out = 200)
        y_beta <- dt(x_beta, df = degrees, ncp = ncp)
        polygon(c(crit_neg, x_beta, crit_pos), c(0, y_beta, 0), col = rgb(0, 0, 1, 0.2))
        
        # Power regions
        x_power_pos <- seq(crit_pos, max(x_range), length.out = 200)
        y_power_pos <- dt(x_power_pos, df = degrees, ncp = ncp)
        polygon(c(crit_pos, x_power_pos, max(x_range)), c(0, y_power_pos, 0), col = rgb(0, 1, 0, 0.2))
        
        x_power_neg <- seq(min(x_range), crit_neg, length.out = 200)
        y_power_neg <- dt(x_power_neg, df = degrees, ncp = ncp)
        polygon(c(min(x_range), x_power_neg, crit_neg), c(0, y_power_neg, 0), col = rgb(0, 1, 0, 0.2))
      }
      
      # Add legend
      legend("topright", legend = c("Null Distribution", "Alternative Distribution",
                                    "Type I Error (α)", "Type II Error (β)", "Power (1-β)"),
             col = c("blue", "red", rgb(1, 0, 0, 0.5), rgb(0, 0, 1, 0.5), rgb(0, 1, 0, 0.5)),
             lty = c(1, 2, 1, 1, 1), lwd = c(2, 2, 8, 8, 8), bty = "n", cex = 1.1)
      
      # Add vertical lines for critical values
      if (input$one_tailed) {
        abline(v = crit, lty = 3, lwd = 2)
        text(crit, max_y/2, paste0("Critical\nt = ", round(crit, 2)), pos = 4, cex = 1.1)
      } else {
        abline(v = crit, lty = 3, lwd = 2)
        abline(v = -crit, lty = 3, lwd = 2)
        text(crit, max_y/2, paste0("Critical\nt = ", round(crit, 2)), pos = 4, cex = 1.1)
        text(-crit, max_y/2, paste0("Critical\nt = ", round(-crit, 2)), pos = 2, cex = 1.1)
      }
    } else if (test_type == "anova" || test_type == "regression") {
      # F-distribution for ANOVA and regression
      degrees <- df()
      df1 <- degrees$df1
      df2 <- degrees$df2
      crit <- critical_value()
      
      # Determine non-centrality parameter based on test type
      if (test_type == "anova") {
        f <- input$effect_size_anova
        k <- input$k
        ncp <- n * k * f^2
      } else {
        # Regression
        r2 <- input$r2
        f2 <- r2 / (1 - r2)
        predictors <- input$predictors
        ncp <- f2 * (n - predictors - 1)
      }
      
      # Create plot range for F distribution - be more careful with the range
      x_max <- max(20, crit * 3)
      x_range <- seq(0.001, x_max, length.out = 1000)  # Start from small positive value
      
      # Calculate density values for F distribution with safety checks
      y_h0 <- stats::df(x_range, df1 = df1, df2 = df2)
      y_h1 <- stats::df(x_range, df1 = df1, df2 = df2, ncp = ncp)
      
      # Replace any NaN or Inf values
      y_h0[is.nan(y_h0) | is.infinite(y_h0)] <- 0
      y_h1[is.nan(y_h1) | is.infinite(y_h1)] <- 0
      
      # Determine maximum y value for scaling with safety check
      max_y <- max(c(y_h0, y_h1), na.rm = TRUE) * 1.1
      if (is.infinite(max_y) || is.nan(max_y) || max_y <= 0) max_y <- 1
      
      # Plot null hypothesis distribution
      plot(x_range, y_h0, type = "l", lwd = 2, col = "blue",
           xlab = "F-statistic", ylab = "Density",
           main = "F-Distribution with Test Decision Regions",
           cex.lab = 1.2, cex.axis = 1.2, cex.main = 1.3,
           ylim = c(0, max_y))
      
      # Add alternative hypothesis distribution
      lines(x_range, y_h1, lwd = 2, col = "red", lty = 2)
      
      # Add critical region (right tail only for F-test)
      x_crit <- seq(crit, max(x_range), length.out = 200)
      y_crit <- stats::df(x_crit, df1 = df1, df2 = df2)
      y_crit[is.nan(y_crit) | is.infinite(y_crit)] <- 0
      polygon(c(crit, x_crit, max(x_range)), c(0, y_crit, 0), col = rgb(1, 0, 0, 0.2))
      
      # Type II error region
      x_beta <- seq(min(x_range), crit, length.out = 200)
      y_beta <- stats::df(x_beta, df1 = df1, df2 = df2, ncp = ncp)
      y_beta[is.nan(y_beta) | is.infinite(y_beta)] <- 0
      polygon(c(min(x_range), x_beta, crit), c(0, y_beta, 0), col = rgb(0, 0, 1, 0.2))
      
      # Power region
      x_power <- seq(crit, max(x_range), length.out = 200)
      y_power <- stats::df(x_power, df1 = df1, df2 = df2, ncp = ncp)
      y_power[is.nan(y_power) | is.infinite(y_power)] <- 0
      polygon(c(crit, x_power, max(x_range)), c(0, y_power, 0), col = rgb(0, 1, 0, 0.2))
      
      # Add legend
      legend("topright", legend = c("Null Distribution", "Alternative Distribution",
                                  "Type I Error (α)", "Type II Error (β)", "Power (1-β)"),
             col = c("blue", "red", rgb(1, 0, 0, 0.5), rgb(0, 0, 1, 0.5), rgb(0, 1, 0, 0.5)),
             lty = c(1, 2, 1, 1, 1), lwd = c(2, 2, 8, 8, 8), bty = "n", cex = 1.1)
      
      # Add vertical line for critical value
      abline(v = crit, lty = 3, lwd = 2)
      text(crit, max_y/2, paste0("Critical F = ", round(crit, 2)), pos = 4, cex = 1.1)
    }
    
    # Add power value information
    text_x <- ifelse(test_type %in% c("anova", "regression"), max(x_range) * 0.6, 
                    ifelse(input$one_tailed, max(x_range) * 0.6, max(x_range) * 0.3))
    text_y <- max_y * 0.8
    
    text(text_x, text_y, paste("Power =", round(power, 3)), cex = 1.3, font = 2)
  })
  
  # Plot the power curve with improved labels and annotations
  output$plotCombined <- renderPlot({
    # Get current parameters
    n <- input$n
    test_type <- input$test_type
    alpha <- input$alpha
    
    # Determine the minimum sample size based on test type
    min_n <- switch(test_type,
                   "two_sample" = 2,
                   "paired" = 2,
                   "anova" = 2,
                   "regression" = input$predictors + 2)
    
    # Create adaptive sample size range based on current n
    if (n <= 20) {
      # For small sample sizes, use fine-grained steps
      n_range <- seq(min_n, max(100, 3*n), by = 1)
    } else if (n <= 50) {
      # For medium sample sizes
      n_range <- seq(min_n, max(150, 2*n), by = 2)
    } else if (n <= 200) {
      # For larger sample sizes
      n_range <- seq(min_n, max(300, 1.5*n), by = 5)
    } else {
      # For very large sample sizes
      n_range <- seq(min_n, max(500, 1.2*n), by = 10)
    }
    
    # Ensure n_range includes the current n
    if (!n %in% n_range) {
      n_range <- sort(c(n_range, n))
    }
    
    # Calculate power for each sample size
    power_values <- sapply(n_range, function(n_val) {
      if (test_type == "two_sample") {
        pwr.t.test(n = n_val, d = input$effect_size_ttest, sig.level = alpha,
                 type = "two.sample",
                 alternative = ifelse(input$one_tailed, "greater", "two.sided"))$power
      } else if (test_type == "paired") {
        pwr.t.test(n = n_val, d = input$effect_size_ttest, sig.level = alpha,
                 type = "paired",
                 alternative = ifelse(input$one_tailed, "greater", "two.sided"))$power
      } else if (test_type == "anova") {
        if (n_val < 2) return(NA) # Avoid errors with tiny sample sizes
        pwr.anova.test(k = input$k, n = n_val, f = input$effect_size_anova, sig.level = alpha)$power
      } else if (test_type == "regression") {
        # For regression, we need at least predictors + 1 observations
        if (n_val <= input$predictors + 1) return(NA)
        pwr.f2.test(u = input$predictors, v = n_val - input$predictors - 1,
                  f2 = input$r2/(1-input$r2), sig.level = alpha)$power
      }
    })
    
    # Create a data frame for plotting
    power_df <- data.frame(n = n_range, power = power_values)
    power_df <- power_df[!is.na(power_df$power), ] # Remove NA values
    
    # Calculate current power for annotation
    current_power <- calculate_power()
    power_label <- round(current_power, 3)
    
    # Create the plot with enhanced annotations
    ggplot(power_df, aes(x = n, y = power)) +
      # Add grid lines first so they're in the background
      geom_hline(yintercept = seq(0, 1, 0.1), color = "gray90", linewidth = 0.3) +
      geom_vline(xintercept = seq(0, max(n_range), 
                by = ifelse(max(n_range) > 200, 50, 20)), 
                color = "gray90", linewidth = 0.3) +
      
      # Add the power curve - use the data frame mapping
      geom_line(color = "#3498db", linewidth = 1.5) +
      
      # Add 0.8 power reference line
      geom_hline(yintercept = 0.8, linetype = "dashed", color = "#e74c3c", linewidth = 1) +
      
      # Use annotate for point and labels instead of geom with aes
      # Mark the current sample size point
      annotate("point", x = input$n, y = current_power, 
               color = "red", size = 5, shape = 16) +
      
      # Add filled annotation for 0.8 power line
      annotate("label", x = max(n_range)*0.15, y = 0.83, 
              label = "Recommended Power = 0.8", 
              color = "#e74c3c", fill = "white", size = 5,
              fontface = "bold", label.size = 0.5) +
      
      # Add filled annotation for current sample point
      annotate("label", x = min(input$n + 0.1*max(n_range), max(n_range)*0.7), 
              y = min(current_power + 0.1, 0.95), 
              label = paste0("Current sample size: ", input$n, 
                           "\nCurrent power: ", power_label),
              color = "black", fill = "#FFF9C4", size = 5,
              fontface = "bold", label.size = 0.5) +
      
      # Enhanced labels
      labs(
        title = "Power Curve: Effect of Sample Size on Statistical Power",
        x = "Sample Size (n)",
        y = "Power (1-β)"
      ) +
      
      # Improved scales
      scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.1),
                        labels = scales::label_percent(accuracy = 1, scale = 100)) +
      
      # Enhanced theme
      theme_minimal() +
      theme(
        plot.title = element_text(face = "bold", size = 18, hjust = 0.5),
        axis.title = element_text(face = "bold", size = 16),
        axis.text = element_text(size = 14),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_blank(), # Removed default grid lines as we added custom ones
        plot.margin = margin(20, 20, 20, 20)
      )
  })
  
  # Sample data visualization
  output$plotData <- renderPlot({
    data <- generate_sample_data()
    test_type <- input$test_type
    
    if (test_type == "two_sample") {
      # Boxplot for two-sample t-test
      boxplot(value ~ group, data = data, col = c("lightblue", "lightgreen"),
             main = "Sample Data for Two-Sample t-Test",
             ylab = "Value")
      
      # Add means
      means <- aggregate(value ~ group, data = data, mean)
      stripchart(value ~ group, data = data, 
                vertical = TRUE, method = "jitter", 
                pch = 16, col = c("blue", "darkgreen"),
                add = TRUE)
      points(1:2, means$value, pch = 18, cex = 2, col = "red")
      
    } else if (test_type == "paired") {
      # Plot for paired t-test
      boxplot(value ~ time, data = data, col = c("lightblue", "lightgreen"),
             main = "Sample Data for Paired t-Test",
             ylab = "Value")
      
      # Add means
      means <- aggregate(value ~ time, data = data, mean)
      
      # Add individual points
      stripchart(value ~ time, data = data, 
                vertical = TRUE, method = "jitter", 
                pch = 16, col = "darkgray",
                add = TRUE)
      
      # Add lines connecting pairs
      for (i in 1:length(unique(data$id))) {
        pair_data <- data[data$id == i, ]
        lines(1:2, pair_data$value, col = "gray", lwd = 0.5)
      }
      
      # Add mean points
      points(1:2, means$value, pch = 18, cex = 2, col = "red")
      
    } else if (test_type == "anova") {
      # Boxplot for ANOVA
      boxplot(value ~ group, data = data, col = "lightblue",
             main = "Sample Data for One-Way ANOVA",
             ylab = "Value")
      
      # Add means
      means <- aggregate(value ~ group, data = data, mean)
      
      # Add individual points
      stripchart(value ~ group, data = data, 
                vertical = TRUE, method = "jitter", 
                pch = 16, col = "darkgray",
                add = TRUE)
      
      # Add mean points
      points(1:length(unique(data$group)), means$value, pch = 18, cex = 2, col = "red")
      
    } else if (test_type == "regression") {
      # Plot for regression
      p <- input$predictors
      if (p == 1) {
        # Simple linear regression
        plot(data$x1, data$y, pch = 16, col = "blue",
             main = "Sample Data for Linear Regression",
             xlab = "Predictor (X)", ylab = "Response (Y)")
        
        # Add regression line
        mod <- lm(y ~ x1, data = data)
        abline(mod, col = "red", lwd = 2)
        
        # Add confidence interval
        new_x <- seq(min(data$x1), max(data$x1), length.out = 100)
        pred <- predict(mod, newdata = data.frame(x1 = new_x), interval = "confidence")
        lines(new_x, pred[, "lwr"], col = "darkgray", lty = 2)
        lines(new_x, pred[, "upr"], col = "darkgray", lty = 2)
        
      } else {
        # For multiple regression, just show the predicted vs actual values
        mod <- lm(y ~ ., data = data)
        predicted <- predict(mod)
        
        plot(predicted, data$y, pch = 16, col = "blue",
             main = "Predicted vs. Actual Values (Multiple Regression)",
             xlab = "Predicted Values", ylab = "Actual Values")
        
        # Add diagonal line
        abline(0, 1, col = "red", lwd = 2)
        
        # Add text with R-squared
        r2 <- summary(mod)$r.squared
        text(min(predicted) + 0.2 * (max(predicted) - min(predicted)),
             max(data$y) - 0.1 * (max(data$y) - min(data$y)),
             paste("R² =", round(r2, 3)),
             pos = 4, cex = 1.2)
      }
    }
  })
  
  # Generate R code for replication
  output$plotCode <- renderText({
    test_type <- input$test_type
    n <- input$n
    alpha <- input$alpha
    
    # Common header code
    code <- paste0("# R code to replicate this power analysis\n",
               "library(pwr)\n",
               "library(ggplot2)\n\n",
               "# Parameters\n")
    
    # Add test-specific parameters
    if (test_type == "two_sample") {
      code <- paste0(code,
                   "n <- ", n, " # Sample size per group\n",
                   "d <- ", input$effect_size_ttest, " # Effect size (Cohen's d)\n",
                   "alpha <- ", alpha, " # Significance level\n",
                   "alternative <- \"", ifelse(input$one_tailed, "greater", "two.sided"), "\" # Test direction\n\n",
                   "# 1. Calculate power\n",
                   "power_result <- pwr.t.test(n = n, d = d, sig.level = alpha, type = \"two.sample\", alternative = alternative)\n",
                   "print(power_result)\n\n",
                   "# 2. Generate sample data for visualization\n",
                   "set.seed(123) # For reproducibility\n",
                   "group1 <- rnorm(n, mean = 0, sd = 1)\n",
                   "group2 <- rnorm(n, mean = d, sd = 1)\n",
                   "data <- data.frame(\n",
                   "  value = c(group1, group2),\n",
                   "  group = factor(rep(c(\"Group 1\", \"Group 2\"), each = n))\n",
                   ")\n\n",
                   "# 3. Create boxplot with jittered points\n",
                   "ggplot(data, aes(x = group, y = value, fill = group)) +\n",
                   "  geom_boxplot(alpha = 0.7, outlier.shape = NA) +\n",
                   "  geom_jitter(width = 0.2, alpha = 0.5) +\n",
                   "  labs(title = \"Sample Data Visualization\",\n",
                   "       subtitle = paste0(\"Two groups with d = \", d),\n",
                   "       x = \"Group\", y = \"Value\") +\n",
                   "  theme_minimal() +\n",
                   "  theme(legend.position = \"none\")\n\n",
                   "# 4. Create power curve\n",
                   "n_range <- seq(2, max(100, 3*n), by = 1)\n",
                   "power_values <- sapply(n_range, function(n_val) {\n",
                   "  pwr.t.test(n = n_val, d = d, sig.level = alpha, \n",
                   "            type = \"two.sample\", alternative = alternative)$power\n",
                   "})\n\n",
                   "power_df <- data.frame(n = n_range, power = power_values)\n",
                   "ggplot(power_df, aes(x = n, y = power)) +\n",
                   "  geom_line(color = \"#3498db\", linewidth = 1.5) +\n",
                   "  geom_hline(yintercept = 0.8, linetype = \"dashed\", color = \"#e74c3c\") +\n",
                   "  annotate(\"point\", x = n, y = power_result$power, color = \"red\", size = 4) +\n",
                   "  labs(title = \"Power Curve\", x = \"Sample Size (n)\", y = \"Power (1-β)\") +\n",
                   "  theme_minimal()")
    
    } else if (test_type == "paired") {
      code <- paste0(code,
                   "n <- ", n, " # Number of pairs\n",
                   "d <- ", input$effect_size_paired, " # Effect size (Cohen's d)\n",
                   "alpha <- ", alpha, " # Significance level\n",
                   "alternative <- \"", ifelse(input$one_tailed, "greater", "two.sided"), "\" # Test direction\n\n",
                   "# 1. Calculate power\n",
                   "power_result <- pwr.t.test(n = n, d = d, sig.level = alpha, type = \"paired\", alternative = alternative)\n",
                   "print(power_result)\n\n",
                   "# 2. Generate sample data for visualization\n",
                   "set.seed(123) # For reproducibility\n",
                   "pre <- rnorm(n, mean = 0, sd = 1)\n",
                   "post <- pre + rnorm(n, mean = d, sd = 0.5) # Correlated data\n",
                   "data <- data.frame(\n",
                   "  id = rep(1:n, 2),\n",
                   "  value = c(pre, post),\n",
                   "  time = factor(rep(c(\"Pre\", \"Post\"), each = n))\n",
                   ")\n\n",
                   "# 3. Create visualization for paired data\n",
                   "# Plot 1: Boxplot with paired lines\n",
                   "ggplot(data, aes(x = time, y = value)) +\n",
                   "  geom_boxplot(aes(fill = time), alpha = 0.7, outlier.shape = NA) +\n",
                   "  geom_point(alpha = 0.5) +\n",
                   "  # Add lines connecting the paired measurements\n",
                   "  geom_line(aes(group = id), alpha = 0.3) +\n",
                   "  labs(title = \"Sample Paired Data Visualization\",\n", 
                   "       subtitle = paste0(\"Effect size = \", d),\n",
                   "       x = \"Time\", y = \"Value\") +\n",
                   "  theme_minimal() +\n",
                   "  theme(legend.position = \"none\")\n\n",
                   "# 4. Create power curve\n",
                   "n_range <- seq(2, max(100, 3*n), by = 1)\n",
                   "power_values <- sapply(n_range, function(n_val) {\n",
                   "  pwr.t.test(n = n_val, d = d, sig.level = alpha, \n",
                   "            type = \"paired\", alternative = alternative)$power\n",
                   "})\n\n",
                   "power_df <- data.frame(n = n_range, power = power_values)\n",
                   "ggplot(power_df, aes(x = n, y = power)) +\n",
                   "  geom_line(color = \"#3498db\", linewidth = 1.5) +\n",
                   "  geom_hline(yintercept = 0.8, linetype = \"dashed\", color = \"#e74c3c\") +\n",
                   "  annotate(\"point\", x = n, y = power_result$power, color = \"red\", size = 4) +\n",
                   "  labs(title = \"Power Curve\", x = \"Sample Size (n)\", y = \"Power (1-β)\") +\n",
                   "  theme_minimal()")
    
    } else if (test_type == "anova") {
      code <- paste0(code,
                   "k <- ", input$k, " # Number of groups\n",
                   "n <- ", n, " # Sample size per group\n",
                   "f <- ", input$effect_size_anova, " # Effect size (Cohen's f)\n",
                   "alpha <- ", alpha, " # Significance level\n\n",
                   "# 1. Calculate power\n",
                   "power_result <- pwr.anova.test(k = k, n = n, f = f, sig.level = alpha)\n",
                   "print(power_result)\n\n",
                   "# 2. Generate sample data for visualization\n",
                   "set.seed(123) # For reproducibility\n",
                   "group_means <- seq(-f * (k-1)/2, f * (k-1)/2, length.out = k)\n",
                   "data <- data.frame()\n",
                   "for (i in 1:k) {\n",
                   "  group_data <- data.frame(\n",
                   "    value = rnorm(n, mean = group_means[i], sd = 1),\n",
                   "    group = paste(\"Group\", i)\n",
                   "  )\n",
                   "  data <- rbind(data, group_data)\n",
                   "}\n",
                   "data$group <- factor(data$group)\n\n",
                   "# 3. Create visualization for ANOVA data\n",
                   "ggplot(data, aes(x = group, y = value, fill = group)) +\n",
                   "  geom_boxplot(alpha = 0.7, outlier.shape = NA) +\n",
                   "  geom_jitter(width = 0.2, alpha = 0.5) +\n",
                   "  labs(title = \"Sample Data for One-Way ANOVA\",\n",
                   "       subtitle = paste0(k, \" groups with f = \", f),\n",
                   "       x = \"Group\", y = \"Value\") +\n",
                   "  theme_minimal() +\n",
                   "  theme(legend.position = \"none\")\n\n",
                   "# 4. Create power curve\n",
                   "n_range <- seq(2, max(100, 3*n), by = 1)\n",
                   "power_values <- sapply(n_range, function(n_val) {\n",
                   "  pwr.anova.test(k = k, n = n_val, f = f, sig.level = alpha)$power\n",
                   "})\n\n",
                   "power_df <- data.frame(n = n_range, power = power_values)\n",
                   "ggplot(power_df, aes(x = n, y = power)) +\n",
                   "  geom_line(color = \"#3498db\", linewidth = 1.5) +\n",
                   "  geom_hline(yintercept = 0.8, linetype = \"dashed\", color = \"#e74c3c\") +\n",
                   "  annotate(\"point\", x = n, y = power_result$power, color = \"red\", size = 4) +\n",
                   "  labs(title = \"Power Curve\", x = \"Sample Size (n)\", y = \"Power (1-β)\") +\n",
                   "  theme_minimal()")
    
    } else if (test_type == "regression") {
      code <- paste0(code,
                   "n <- ", n, " # Total sample size\n",
                   "predictors <- ", input$predictors, " # Number of predictors\n",
                   "r2 <- ", input$r2, " # R-squared value\n",
                   "f2 <- r2 / (1 - r2) # Convert to f-squared\n",
                   "alpha <- ", alpha, " # Significance level\n\n",
                   "# 1. Calculate power\n",
                   "power_result <- pwr.f2.test(u = predictors, v = n - predictors - 1, f2 = f2, sig.level = alpha)\n",
                   "print(power_result)\n\n",
                   "# 2. Generate sample data for visualization\n",
                   "set.seed(123) # For reproducibility\n",
                   "# Generate a design matrix with random predictors\n",
                   "X <- matrix(rnorm(n * predictors), ncol = predictors)\n",
                   "# Generate coefficients\n",
                   "beta <- rnorm(predictors)\n",
                   "# Calculate signal component\n",
                   "signal <- X %*% beta\n",
                   "# Scale signal to have variance 1\n",
                   "signal <- scale(signal)[,1]\n",
                   "# Calculate noise component based on R² value\n",
                   "noise_var <- (1 - r2) / r2\n",
                   "noise <- rnorm(n, sd = sqrt(noise_var))\n",
                   "# Generate response variable\n",
                   "y <- signal + noise\n",
                   "# Create a data frame\n",
                   "data <- data.frame(y = y)\n",
                   "for (i in 1:predictors) {\n",
                   "  data[[paste0(\"x\", i)]] <- X[,i]\n",
                   "}\n\n",
                   "# 3. Create regression visualization\n",
                   "if (predictors == 1) {\n",
                   "  # Simple scatterplot for single predictor\n",
                   "  ggplot(data, aes(x = x1, y = y)) +\n",
                   "    geom_point(alpha = 0.7) +\n",
                   "    geom_smooth(method = \"lm\", color = \"#3498db\") +\n",
                   "    labs(title = \"Linear Regression Sample Data\",\n",
                   "         subtitle = paste0(\"R² = \", round(r2, 3), \", f² = \", round(f2, 3)),\n",
                   "         x = \"Predictor\", y = \"Response\") +\n",
                   "    theme_minimal()\n",
                   "} else {\n",
                   "  # Pairs plot for multiple predictors (first 4 if more than 4)\n",
                   "  # Using base R for pairs plot - easier for multiple predictors\n",
                   "  pairs(data[, c(1, 2:min(5, predictors+1))],\n",
                   "        main = paste0(\"Linear Regression Sample Data (R² = \", round(r2, 3), \")\"),\n",
                   "        pch = 16, col = adjustcolor(\"#3498db\", alpha.f = 0.6))\n",
                   "  \n",
                   "  # Observed vs. Fitted plot\n",
                   "  model <- lm(y ~ ., data = data)\n",
                   "  fitted_values <- fitted(model)\n",
                   "  plot_data <- data.frame(observed = data$y, fitted = fitted_values)\n",
                   "  \n",
                   "  ggplot(plot_data, aes(x = fitted, y = observed)) +\n",
                   "    geom_point(alpha = 0.7) +\n",
                   "    geom_abline(slope = 1, intercept = 0, color = \"red\", linetype = \"dashed\") +\n",
                   "    labs(title = \"Observed vs. Fitted Values\",\n",
                   "         subtitle = paste0(\"R² = \", round(r2, 3), \", f² = \", round(f2, 3)),\n",
                   "         x = \"Fitted Values\", y = \"Observed Values\") +\n",
                   "    theme_minimal()\n",
                   "}\n\n",
                   "# 4. Create power curve\n",
                   "n_range <- seq(predictors + 2, max(100, 3*n), by = 1)\n",
                   "power_values <- sapply(n_range, function(n_val) {\n",
                   "  pwr.f2.test(u = predictors, v = n_val - predictors - 1, f2 = f2, sig.level = alpha)$power\n",
                   "})\n\n",
                   "power_df <- data.frame(n = n_range, power = power_values)\n",
                   "ggplot(power_df, aes(x = n, y = power)) +\n",
                   "  geom_line(color = \"#3498db\", linewidth = 1.5) +\n",
                   "  geom_hline(yintercept = 0.8, linetype = \"dashed\", color = \"#e74c3c\") +\n",
                   "  annotate(\"point\", x = n, y = power_result$power, color = \"red\", size = 4) +\n",
                   "  labs(title = \"Power Curve\", x = \"Sample Size (n)\", y = \"Power (1-β)\") +\n",
                   "  theme_minimal()")
    }
    
    return(code)
  })
  
  # Required sample size calculation 
  observeEvent(input$calculate_n, {
    test_type <- input$test_type
    alpha <- input$alpha
    target_power <- input$target_power
    
    # Calculate required sample size based on test type
    if (test_type == "two_sample" || test_type == "paired") {
      d <- input$effect_size_ttest
      result <- pwr.t.test(d = d, sig.level = alpha, power = target_power,
                          type = ifelse(test_type == "two_sample", "two.sample", "paired"),
                          alternative = ifelse(input$one_tailed, "greater", "two.sided"))
      n_required <- ceiling(result$n)
    } else if (test_type == "anova") {
      k <- input$k
      f <- input$effect_size_anova
      result <- pwr.anova.test(k = k, f = f, sig.level = alpha, power = target_power)
      n_required <- ceiling(result$n)
    } else if (test_type == "regression") {
      predictors <- input$predictors
      r2 <- input$r2
      f2 <- r2 / (1 - r2)
      
      # We need to solve for v (degrees of freedom) and then calculate n
      result <- pwr.f2.test(u = predictors, f2 = f2, sig.level = alpha, power = target_power)
      n_required <- ceiling(result$v + predictors + 1)
    }
    
    # Display the result
    output$sample_size_result <- renderText({
      paste0("Required sample size to achieve ", target_power * 100, "% power: n = ", n_required)
    })
    
    # Update the sample size input
    updateNumericInput(session, "n", value = n_required)
  })
  
  # Download handlers
  output$downloadReport <- downloadHandler(
    filename = function() {
      paste("power-analysis-report-", format(Sys.time(), "%Y-%m-%d"), ".txt", sep="")
    },
    content = function(file) {
      # Create a plain text report with proper formatting
      text <- isolate({
        # Get the current power analysis results
        test_type <- input$test_type
        n <- input$n
        alpha <- input$alpha
        power <- calculate_power()
        
        # Build a text report
        report <- c(
          "POWER ANALYSIS REPORT",
          "===========================================",
          "",
          switch(test_type,
                "two_sample" = "Power Analysis for a Two-Sample t-Test",
                "paired" = "Power Analysis for a Paired t-Test",
                "anova" = "Power Analysis for a One-Way ANOVA",
                "regression" = "Power Analysis for Linear Regression"),
          "",
          paste("Computed Power =", round(power, 4)),
          "",
          "Parameters:",
          paste("  Sample Size per group (n):", n),
          paste("  Significance level (α):", round(alpha, 3))
        )
        
        # Add test-specific parameters
        if (test_type == "two_sample" || test_type == "paired") {
          report <- c(report,
                     paste("  Effect Size (Cohen's d):", round(input$effect_size_ttest, 4)),
                     paste("  Test type:", ifelse(input$one_tailed, "One-tailed", "Two-tailed"))
          )
        } else if (test_type == "anova") {
          report <- c(report,
                     paste("  Number of groups (k):", input$k),
                     paste("  Effect size (Cohen's f):", round(input$effect_size_anova, 4))
          )
        } else if (test_type == "regression") {
          f2 <- input$r2 / (1 - input$r2)
          report <- c(report,
                     paste("  Number of predictors:", input$predictors),
                     paste("  R²:", round(input$r2, 4)),
                     paste("  Effect size (f²):", round(f2, 4))
          )
        }
        
        # Add interpretation
        report <- c(report,
                   "",
                   "Interpretation:",
                   if (power < 0.8) {
                     paste("  The current power (", round(power*100, 1), 
                          "%) is below the commonly recommended 80% threshold.",
                          "Consider increasing sample size or expecting a larger effect size.", sep="")
                   } else {
                     paste("  The current power (", round(power*100, 1), 
                          "%) meets or exceeds the commonly recommended 80% threshold.", sep="")
                   },
                   "",
                   paste("Report generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
                   paste("Generated by Statistical Power Analysis Tool")
        )
        
        # Join all lines with line breaks
        paste(report, collapse = "\n")
      })
      
      # Write the plain text to file
      writeLines(text, file)
    },
    contentType = "text/plain" # Explicitly set content type to text/plain
  )
  
  output$downloadPlot <- downloadHandler(
    filename = function() {
      paste("power-analysis-plot-", format(Sys.time(), "%Y-%m-%d"), ".png", sep="")
    },
    content = function(file) {
      # Use a higher resolution for better quality
      png(file, width = 1200, height = 800, res = 120)
      
      # Recreate the power curve plot
      test_type <- isolate(input$test_type)
      alpha <- isolate(input$alpha)
      n <- isolate(input$n)
      
      # Create sequence of sample sizes
      n_range <- seq(5, max(100, n*2), by = 1)
      
      # Calculate power for each sample size (same as in plotCombined)
      powers <- sapply(n_range, function(n_val) {
        if (test_type == "two_sample") {
          d <- isolate(input$effect_size_ttest)
          result <- pwr.t.test(n = n_val, d = d, sig.level = alpha, 
                               type = "two.sample", 
                               alternative = ifelse(isolate(input$one_tailed), "greater", "two.sided"))$power
        } else if (test_type == "paired") {
          d <- isolate(input$effect_size_paired)
          result <- pwr.t.test(n = n_val, d = d, sig.level = alpha, 
                               type = "paired", 
                               alternative = ifelse(isolate(input$one_tailed), "greater", "two.sided"))$power
        } else if (test_type == "anova") {
          k <- isolate(input$k)
          f <- isolate(input$effect_size_anova)
          result <- pwr.anova.test(k = k, n = n_val, f = f, sig.level = alpha)$power
        } else if (test_type == "regression") {
          predictors <- isolate(input$predictors)
          r2 <- isolate(input$r2)
          f2 <- r2 / (1 - r2)
          result <- pwr.f2.test(u = predictors, v = n_val - predictors - 1, 
                              f2 = f2, sig.level = alpha)$power
        }
        return(result)
      })
      
      # Plot the power curve with improved formatting
      par(mar = c(5, 5, 4, 2) + 0.1, bg = "white")
      plot(n_range, powers, type = "l", lwd = 3, col = "steelblue",
           xlab = "Sample Size", ylab = "Power",
           main = paste("Power Curve for", switch(test_type,
                                                "two_sample" = "Two-Sample t-Test",
                                                "paired" = "Paired t-Test",
                                                "anova" = "One-Way ANOVA",
                                                "regression" = "Linear Regression")),
           xlim = c(0, max(n_range)),
           ylim = c(0, 1),
           cex.axis = 1.2,
           cex.lab = 1.3,
           cex.main = 1.5)
      
      # Add reference line at 0.8 power
      abline(h = 0.8, lty = 2, col = "darkred", lwd = 2)
      text(max(n_range) * 0.9, 0.82, "80% Power", col = "darkred", cex = 1.2)
      
      # Add vertical line at current sample size
      abline(v = n, lty = 2, col = "darkgreen", lwd = 2)
      text(n + max(n_range)/20, 0.5, paste("n =", n), col = "darkgreen", pos = 4, cex = 1.2)
      
      # Add grid
      grid(lty = 1, col = "lightgray")
      
      # Add info text
      legend("bottomright", 
             legend = c(
               paste("Effect size:", round(isolate(effect_size()), 3)),
               paste("Significance level (α):", alpha)
             ),
             bty = "n", cex = 1.1)
      
      dev.off()
    }
  )
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("power-analysis-sample-data-", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      # Get the sample data
      data <- generate_sample_data()
      
      # Add metadata as additional columns rather than comment lines
      # This keeps the CSV format valid while preserving the information
      test_type <- input$test_type
      n <- input$n
      
      # Create metadata dataframe
      metadata <- data.frame(
        variable = c("Test Type", "Sample Size", "Alpha", "Power"),
        value = c(
          switch(test_type,
                "two_sample" = "Two-Sample t-Test",
                "paired" = "Paired t-Test",
                "anova" = "One-Way ANOVA",
                "regression" = "Linear Regression"),
          as.character(n),
          as.character(input$alpha),
          as.character(round(calculate_power(), 4))
        )
      )
      
      # Add test-specific metadata
      if (test_type %in% c("two_sample", "paired")) {
        test_meta <- data.frame(
          variable = c("Effect Size (Cohen's d)"),
          value = c(
            as.character(input$effect_size_ttest)
          )
        )
        metadata <- rbind(metadata, test_meta)
      } else if (test_type == "anova") {
        test_meta <- data.frame(
          variable = c("Number of Groups", "Effect Size (Cohen's f)"),
          value = c(
            as.character(input$k),
            as.character(input$effect_size_anova)
          )
        )
        metadata <- rbind(metadata, test_meta)
      } else if (test_type == "regression") {
        test_meta <- data.frame(
          variable = c("Number of Predictors", "R²", "Effect Size (f²)"),
          value = c(
            as.character(input$predictors),
            as.character(round(input$r2, 4)),
            as.character(round(input$r2/(1-input$r2), 4))
          )
        )
        metadata <- rbind(metadata, test_meta)
      }
      
      # Write both data frames to the same file
      # First write the metadata with a header
      write.csv(metadata, file, row.names = FALSE, quote = TRUE)
      
      # Add a separator row
      write.table(data.frame(NOTE = rep("", ncol(metadata))), 
                 file, 
                 append = TRUE, 
                 col.names = FALSE, 
                 row.names = FALSE,
                 sep = ",")
      
      write.table(data.frame(NOTE = c("DATA SECTION BELOW", 
                                    paste("Generated on", Sys.Date()))), 
                 file, 
                 append = TRUE, 
                 col.names = FALSE, 
                 row.names = FALSE,
                 sep = ",")
      write.table(data.frame(NOTE = rep("", ncol(metadata))), 
                 file, 
                 append = TRUE, 
                 col.names = FALSE, 
                 row.names = FALSE,
                 sep = ",")
               
      # Now write the actual data
      # Use write.table instead of write.csv for more control when appending
      write.table(data, 
                 file, 
                 append = TRUE, 
                 sep = ",", 
                 row.names = FALSE, 
                 col.names = TRUE,
                 quote = TRUE)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)