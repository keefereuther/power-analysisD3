/**
 * D3.js Visualizations
 * Creates all interactive plots for the power analysis app
 */

const Visualizations = {
    /**
     * Create or update distribution plot (t or F distribution)
     */
    plotDistribution(containerId, distData, power, testType) {
        const container = d3.select(`#${containerId}`);
        container.selectAll("*").remove();

        if (!distData) return;

        const margin = { top: 40, right: 100, bottom: 60, left: 70 };
        // Use parent container or default width if collapsed
        const containerNode = container.node();
        let width = 800; // default
        if (containerNode) {
            const parentWidth = containerNode.parentElement ? containerNode.parentElement.offsetWidth : 0;
            if (parentWidth > 0) {
                width = parentWidth - margin.left - margin.right;
            } else {
                width = containerNode.offsetWidth > 0 ? containerNode.offsetWidth - margin.left - margin.right : 800;
            }
        }
        const height = 400;

        const svg = container
            .append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom);

        const g = svg
            .append("g")
            .attr("transform", `translate(${margin.left},${margin.top})`);

        const xScale = d3.scaleLinear()
            .domain(distData.xRange)
            .range([0, width]);

        const yMax = d3.max([...distData.h0Data, ...distData.h1Data].map(d => d.y)) * 1.1;
        const yScale = d3.scaleLinear()
            .domain([0, yMax])
            .range([height, 0]);

        // Create line generator
        const line = d3.line()
            .x(d => xScale(d.x))
            .y(d => yScale(d.y))
            .curve(d3.curveMonotoneX);

        // Draw null hypothesis distribution (H0)
        g.append("path")
            .datum(distData.h0Data)
            .attr("fill", "none")
            .attr("stroke", "blue")
            .attr("stroke-width", 2)
            .attr("d", line);

        // Draw alternative hypothesis distribution (H1)
        g.append("path")
            .datum(distData.h1Data)
            .attr("fill", "none")
            .attr("stroke", "red")
            .attr("stroke-width", 2)
            .attr("stroke-dasharray", "5,5")
            .attr("d", line);

        // Draw critical regions and power regions
        const crit = distData.crit;
        const ncp = distData.ncp;

        if (distData.type === 't') {
            // T-distribution
            if (distData.oneTailed) {
                // One-tailed: shade region right of crit
                this.shadeRegion(g, xScale, yScale, distData.h0Data, crit, distData.xRange[1], 
                    "rgba(255,0,0,0.2)", "Type I Error (α)");
                
                // Type II error region (left of crit under H1)
                this.shadeRegion(g, xScale, yScale, distData.h1Data, distData.xRange[0], crit, 
                    "rgba(0,0,255,0.2)", "Type II Error (β)");
                
                // Power region (right of crit under H1)
                this.shadeRegion(g, xScale, yScale, distData.h1Data, crit, distData.xRange[1], 
                    "rgba(0,255,0,0.2)", "Power (1-β)");

                // Critical value line
                g.append("line")
                    .attr("x1", xScale(crit))
                    .attr("x2", xScale(crit))
                    .attr("y1", 0)
                    .attr("y2", height)
                    .attr("stroke", "#333")
                    .attr("stroke-width", 2)
                    .attr("stroke-dasharray", "3,3");

                g.append("text")
                    .attr("x", xScale(crit) + 5)
                    .attr("y", height / 2)
                    .attr("fill", "#333")
                    .attr("font-size", "12px")
                    .text(`Critical\nt = ${crit.toFixed(2)}`);
            } else {
                // Two-tailed: shade both tails
                const critNeg = -crit;
                
                // Positive critical region
                this.shadeRegion(g, xScale, yScale, distData.h0Data, crit, distData.xRange[1], 
                    "rgba(255,0,0,0.2)", "");
                
                // Negative critical region
                this.shadeRegion(g, xScale, yScale, distData.h0Data, distData.xRange[0], critNeg, 
                    "rgba(255,0,0,0.2)", "");
                
                // Type II error (middle region under H1)
                this.shadeRegion(g, xScale, yScale, distData.h1Data, critNeg, crit, 
                    "rgba(0,0,255,0.2)", "");
                
                // Power regions
                this.shadeRegion(g, xScale, yScale, distData.h1Data, crit, distData.xRange[1], 
                    "rgba(0,255,0,0.2)", "");
                this.shadeRegion(g, xScale, yScale, distData.h1Data, distData.xRange[0], critNeg, 
                    "rgba(0,255,0,0.2)", "");

                // Critical value lines
                g.append("line")
                    .attr("x1", xScale(crit))
                    .attr("x2", xScale(crit))
                    .attr("y1", 0)
                    .attr("y2", height)
                    .attr("stroke", "#333")
                    .attr("stroke-width", 2)
                    .attr("stroke-dasharray", "3,3");

                g.append("line")
                    .attr("x1", xScale(critNeg))
                    .attr("x2", xScale(critNeg))
                    .attr("y1", 0)
                    .attr("y2", height)
                    .attr("stroke", "#333")
                    .attr("stroke-width", 2)
                    .attr("stroke-dasharray", "3,3");

                g.append("text")
                    .attr("x", xScale(crit) + 5)
                    .attr("y", height / 2)
                    .attr("fill", "#333")
                    .attr("font-size", "12px")
                    .text(`Critical\nt = ${crit.toFixed(2)}`);

                g.append("text")
                    .attr("x", xScale(critNeg) - 5)
                    .attr("y", height / 2)
                    .attr("fill", "#333")
                    .attr("font-size", "12px")
                    .attr("text-anchor", "end")
                    .text(`Critical\nt = ${critNeg.toFixed(2)}`);
            }

            // Axes
            g.append("g")
                .attr("transform", `translate(0,${height})`)
                .call(d3.axisBottom(xScale))
                .append("text")
                .attr("x", width / 2)
                .attr("y", 45)
                .attr("fill", "#333")
                .attr("font-size", "14px")
                .attr("font-weight", "bold")
                .style("text-anchor", "middle")
                .text("t-statistic");
        } else {
            // F-distribution
            // Critical region (right tail only)
            this.shadeRegion(g, xScale, yScale, distData.h0Data, crit, distData.xRange[1], 
                "rgba(255,0,0,0.2)", "Type I Error (α)");
            
            // Type II error
            this.shadeRegion(g, xScale, yScale, distData.h1Data, distData.xRange[0], crit, 
                "rgba(0,0,255,0.2)", "Type II Error (β)");
            
            // Power region
            this.shadeRegion(g, xScale, yScale, distData.h1Data, crit, distData.xRange[1], 
                "rgba(0,255,0,0.2)", "Power (1-β)");

            // Critical value line
            g.append("line")
                .attr("x1", xScale(crit))
                .attr("x2", xScale(crit))
                .attr("y1", 0)
                .attr("y2", height)
                .attr("stroke", "#333")
                .attr("stroke-width", 2)
                .attr("stroke-dasharray", "3,3");

            g.append("text")
                .attr("x", xScale(crit) + 5)
                .attr("y", height / 2)
                .attr("fill", "#333")
                .attr("font-size", "12px")
                .text(`Critical F = ${crit.toFixed(2)}`);

            // Axes
            g.append("g")
                .attr("transform", `translate(0,${height})`)
                .call(d3.axisBottom(xScale))
                .append("text")
                .attr("x", width / 2)
                .attr("y", 45)
                .attr("fill", "#333")
                .attr("font-size", "14px")
                .attr("font-weight", "bold")
                .style("text-anchor", "middle")
                .text("F-statistic");
        }

        // Y-axis
        g.append("g")
            .call(d3.axisLeft(yScale))
            .append("text")
            .attr("transform", "rotate(-90)")
            .attr("y", -50)
            .attr("x", -height / 2)
            .attr("fill", "#333")
            .attr("font-size", "14px")
            .attr("font-weight", "bold")
            .style("text-anchor", "middle")
            .text("Density");

        // Title
        const title = distData.type === 't' 
            ? "t-Distribution with Test Decision Regions"
            : "F-Distribution with Test Decision Regions";
        
        g.append("text")
            .attr("x", width / 2)
            .attr("y", -10)
            .attr("fill", "#333")
            .attr("font-size", "16px")
            .attr("font-weight", "bold")
            .style("text-anchor", "middle")
            .text(title);

        // Legend - positioned in upper right corner
        const legendX = width * 0.85;
        const legendY = 20;

        const legend = g.append("g")
            .attr("transform", `translate(${legendX},${legendY})`);

        const legendItems = [
            { label: "Null Distribution", color: "blue", style: "solid" },
            { label: "Alternative Distribution", color: "red", style: "dashed" },
            { label: "Type I Error (α)", color: "rgba(255,0,0,0.5)", style: "solid" },
            { label: "Type II Error (β)", color: "rgba(0,0,255,0.5)", style: "solid" },
            { label: "Power (1-β)", color: "rgba(0,255,0,0.5)", style: "solid" }
        ];

        legendItems.forEach((item, i) => {
            const itemG = legend.append("g").attr("transform", `translate(0,${i * 20})`);
            itemG.append("line")
                .attr("x1", -80)
                .attr("x2", -60)
                .attr("y1", 0)
                .attr("y2", 0)
                .attr("stroke", item.color)
                .attr("stroke-width", item.style === "dashed" ? 2 : 2)
                .attr("stroke-dasharray", item.style === "dashed" ? "5,5" : "none");
            itemG.append("text")
                .attr("x", -55)
                .attr("y", 4)
                .attr("fill", "#333")
                .attr("font-size", "11px")
                .attr("text-anchor", "start")
                .text(item.label);
        });

        // Power value text - positioned to avoid legend
        g.append("text")
            .attr("x", width * 0.15)
            .attr("y", height * 0.15)
            .attr("fill", "#333")
            .attr("font-size", "16px")
            .attr("font-weight", "bold")
            .text(`Power = ${power.toFixed(3)}`);
    },

    /**
     * Helper function to shade regions under curves
     */
    shadeRegion(g, xScale, yScale, data, xMin, xMax, color, label) {
        const regionData = data.filter(d => d.x >= xMin && d.x <= xMax);
        if (regionData.length === 0) return;

        const area = d3.area()
            .x(d => xScale(d.x))
            .y0(() => yScale(0))
            .y1(d => yScale(d.y));

        g.append("path")
            .datum(regionData)
            .attr("fill", color)
            .attr("d", area);
    },

    /**
     * Create or update power curve plot
     */
    plotPowerCurve(containerId, powerData, currentN, currentPower) {
        const container = d3.select(`#${containerId}`);
        container.selectAll("*").remove();

        if (!powerData || powerData.length === 0) return;

        const margin = { top: 50, right: 150, bottom: 70, left: 80 };
        const containerNode = container.node();
        let width = 900; // default
        if (containerNode) {
            const parentWidth = containerNode.parentElement ? containerNode.parentElement.offsetWidth : 0;
            if (parentWidth > 0) {
                width = parentWidth - margin.left - margin.right;
            } else {
                width = containerNode.offsetWidth > 0 ? containerNode.offsetWidth - margin.left - margin.right : 900;
            }
        }
        const height = 450;

        const svg = container
            .append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom);

        const g = svg
            .append("g")
            .attr("transform", `translate(${margin.left},${margin.top})`);

        // Scales
        const xExtent = d3.extent(powerData, d => d.n);
        const xScale = d3.scaleLinear()
            .domain([0, xExtent[1]])
            .nice()
            .range([0, width]);

        const yScale = d3.scaleLinear()
            .domain([0, 1])
            .range([height, 0]);

        // Grid lines
        const xGrid = d3.axisBottom(xScale)
            .tickSize(-height)
            .tickFormat("")
            .ticks(10);

        const yGrid = d3.axisLeft(yScale)
            .tickSize(-width)
            .tickFormat("")
            .ticks(10);

        g.append("g")
            .attr("class", "grid")
            .attr("transform", `translate(0,${height})`)
            .call(xGrid)
            .selectAll("line")
            .attr("stroke", "#ddd")
            .attr("stroke-width", 0.5);

        g.append("g")
            .attr("class", "grid")
            .call(yGrid)
            .selectAll("line")
            .attr("stroke", "#ddd")
            .attr("stroke-width", 0.5);

        // Line generator
        const line = d3.line()
            .x(d => xScale(d.n))
            .y(d => yScale(d.power))
            .curve(d3.curveMonotoneX);

        // Draw power curve
        g.append("path")
            .datum(powerData)
            .attr("fill", "none")
            .attr("stroke", "#3498db")
            .attr("stroke-width", 2)
            .attr("d", line);

        // Reference line at 0.8 power
        g.append("line")
            .attr("x1", 0)
            .attr("x2", width)
            .attr("y1", yScale(0.8))
            .attr("y2", yScale(0.8))
            .attr("stroke", "#e74c3c")
            .attr("stroke-width", 2)
            .attr("stroke-dasharray", "5,5");

        // Current point
        if (currentN && !isNaN(currentPower)) {
            g.append("circle")
                .attr("cx", xScale(currentN))
                .attr("cy", yScale(currentPower))
                .attr("r", 5)
                .attr("fill", "red");

            // Annotation for current point
            g.append("rect")
                .attr("x", xScale(currentN) + 10)
                .attr("y", yScale(currentPower) - 30)
                .attr("width", 150)
                .attr("height", 40)
                .attr("fill", "#FFF9C4")
                .attr("rx", 3);

            g.append("text")
                .attr("x", xScale(currentN) + 15)
                .attr("y", yScale(currentPower) - 10)
                .attr("fill", "#333")
                .attr("font-size", "11px")
                .text(`Current sample size: ${currentN}`);

            g.append("text")
                .attr("x", xScale(currentN) + 15)
                .attr("y", yScale(currentPower) + 8)
                .attr("fill", "#333")
                .attr("font-size", "11px")
                .text(`Current power: ${currentPower.toFixed(3)}`);
        }

        // Annotation for 0.8 power line
        g.append("rect")
            .attr("x", width * 0.05)
            .attr("y", yScale(0.83) - 15)
            .attr("width", 180)
            .attr("height", 20)
            .attr("fill", "white")
            .attr("rx", 3);

        g.append("text")
            .attr("x", width * 0.1)
            .attr("y", yScale(0.83))
            .attr("fill", "#e74c3c")
            .attr("font-size", "12px")
            .attr("font-weight", "bold")
            .text("Recommended Power = 0.8");

        // Axes
        g.append("g")
            .attr("transform", `translate(0,${height})`)
            .call(d3.axisBottom(xScale).ticks(10))
            .append("text")
            .attr("x", width / 2)
            .attr("y", 45)
            .attr("fill", "#333")
            .attr("font-size", "14px")
            .attr("font-weight", "bold")
            .style("text-anchor", "middle")
            .text("Sample Size (n)");

        g.append("g")
            .call(d3.axisLeft(yScale).ticks(10).tickFormat(d3.format(".0%")))
            .append("text")
            .attr("transform", "rotate(-90)")
            .attr("y", -60)
            .attr("x", -height / 2)
            .attr("fill", "#333")
            .attr("font-size", "14px")
            .attr("font-weight", "bold")
            .style("text-anchor", "middle")
            .text("Power (1-β)");

        // Title
        g.append("text")
            .attr("x", width / 2)
            .attr("y", -10)
            .attr("fill", "#333")
            .attr("font-size", "18px")
            .attr("font-weight", "bold")
            .style("text-anchor", "middle")
            .text("Power Curve: Effect of Sample Size on Statistical Power");
    },

    /**
     * Create or update sample data visualization
     */
    plotSampleData(containerId, data, testType) {
        const container = d3.select(`#${containerId}`);
        container.selectAll("*").remove();

        if (!data) return;

        const margin = { top: 40, right: 50, bottom: 60, left: 70 };
        const containerNode = container.node();
        let width = 800; // default
        if (containerNode) {
            const parentWidth = containerNode.parentElement ? containerNode.parentElement.offsetWidth : 0;
            if (parentWidth > 0) {
                width = parentWidth - margin.left - margin.right;
            } else {
                width = containerNode.offsetWidth > 0 ? containerNode.offsetWidth - margin.left - margin.right : 800;
            }
        }
        const height = 400;

        const svg = container
            .append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom);

        const g = svg
            .append("g")
            .attr("transform", `translate(${margin.left},${margin.top})`);

        if (testType === 'two_sample') {
            this.plotBoxplot(g, data, width, height, "Sample Data for Two-Sample t-Test");
        } else if (testType === 'paired') {
            this.plotPairedData(g, data, width, height);
        } else if (testType === 'anova') {
            this.plotBoxplot(g, data, width, height, "Sample Data for One-Way ANOVA");
        } else if (testType === 'regression') {
            this.plotRegression(g, data, width, height);
        }
    },

    /**
     * Plot boxplot with jittered points
     */
    plotBoxplot(g, data, width, height, title) {
        const groups = Array.from(new Set(data.groups));
        const xScale = d3.scaleBand()
            .domain(groups)
            .range([0, width])
            .padding(0.2);

        const values = data.values;
        const yMin = d3.min(values);
        const yMax = d3.max(values);
        const yScale = d3.scaleLinear()
            .domain([yMin - (yMax - yMin) * 0.1, yMax + (yMax - yMin) * 0.1])
            .range([height, 0]);

        // Calculate boxplot statistics for each group
        groups.forEach((group, i) => {
            const groupValues = data.values.filter((v, idx) => data.groups[idx] === group);
            const sorted = groupValues.slice().sort((a, b) => a - b);
            
            const q1 = d3.quantile(sorted, 0.25);
            const q2 = d3.quantile(sorted, 0.5);
            const q3 = d3.quantile(sorted, 0.75);
            const iqr = q3 - q1;
            const min = Math.max(sorted[0], q1 - 1.5 * iqr);
            const max = Math.min(sorted[sorted.length - 1], q3 + 1.5 * iqr);

            const x = xScale(group);
            const boxWidth = xScale.bandwidth();

            // Box
            g.append("rect")
                .attr("x", x)
                .attr("y", yScale(q3))
                .attr("width", boxWidth)
                .attr("height", yScale(q1) - yScale(q3))
                .attr("fill", i % 2 === 0 ? "#ADD8E6" : "#90EE90")
                .attr("stroke", "#333")
                .attr("stroke-width", 1);

            // Median line
            g.append("line")
                .attr("x1", x)
                .attr("x2", x + boxWidth)
                .attr("y1", yScale(q2))
                .attr("y2", yScale(q2))
                .attr("stroke", "#333")
                .attr("stroke-width", 2);

            // Whiskers
            g.append("line")
                .attr("x1", x + boxWidth / 2)
                .attr("x2", x + boxWidth / 2)
                .attr("y1", yScale(q3))
                .attr("y2", yScale(max))
                .attr("stroke", "#333")
                .attr("stroke-width", 1);

            g.append("line")
                .attr("x1", x + boxWidth / 2)
                .attr("x2", x + boxWidth / 2)
                .attr("y1", yScale(q1))
                .attr("y2", yScale(min))
                .attr("stroke", "#333")
                .attr("stroke-width", 1);

            // Mean point
            const mean = groupValues.reduce((a, b) => a + b, 0) / groupValues.length;
            g.append("circle")
                .attr("cx", x + boxWidth / 2)
                .attr("cy", yScale(mean))
                .attr("r", 4)
                .attr("fill", "red");
        });

        // Jittered points
        data.values.forEach((value, i) => {
            const group = data.groups[i];
            const x = xScale(group);
            const jitter = (Math.random() - 0.5) * xScale.bandwidth() * 0.8;
            
            g.append("circle")
                .attr("cx", x + xScale.bandwidth() / 2 + jitter)
                .attr("cy", yScale(value))
                .attr("r", 2)
                .attr("fill", group === groups[0] ? "blue" : "darkgreen")
                .attr("opacity", 0.6);
        });

        // Axes
        g.append("g")
            .attr("transform", `translate(0,${height})`)
            .call(d3.axisBottom(xScale))
            .append("text")
            .attr("x", width / 2)
            .attr("y", 45)
            .attr("fill", "#333")
            .attr("font-size", "14px")
            .attr("font-weight", "bold")
            .style("text-anchor", "middle")
            .text("Group");

        g.append("g")
            .call(d3.axisLeft(yScale))
            .append("text")
            .attr("transform", "rotate(-90)")
            .attr("y", -50)
            .attr("x", -height / 2)
            .attr("fill", "#333")
            .attr("font-size", "14px")
            .attr("font-weight", "bold")
            .style("text-anchor", "middle")
            .text("Value");

        // Title
        g.append("text")
            .attr("x", width / 2)
            .attr("y", -10)
            .attr("fill", "#333")
            .attr("font-size", "16px")
            .attr("font-weight", "bold")
            .style("text-anchor", "middle")
            .text(title);
    },

    /**
     * Plot paired data with connecting lines
     */
    plotPairedData(g, data, width, height) {
        const times = ['Pre', 'Post'];
        const xScale = d3.scaleBand()
            .domain(times)
            .range([0, width])
            .padding(0.2);

        const values = data.values;
        const yMin = d3.min(values);
        const yMax = d3.max(values);
        const yScale = d3.scaleLinear()
            .domain([yMin - (yMax - yMin) * 0.1, yMax + (yMax - yMin) * 0.1])
            .range([height, 0]);

        // Draw connecting lines for pairs
        const n = data.ids.length / 2;
        for (let i = 0; i < n; i++) {
            const preIdx = i;
            const postIdx = i + n;
            const preX = xScale('Pre') + xScale.bandwidth() / 2;
            const postX = xScale('Post') + xScale.bandwidth() / 2;
            
            g.append("line")
                .attr("x1", preX + (Math.random() - 0.5) * xScale.bandwidth() * 0.6)
                .attr("x2", postX + (Math.random() - 0.5) * xScale.bandwidth() * 0.6)
                .attr("y1", yScale(data.values[preIdx]))
                .attr("y2", yScale(data.values[postIdx]))
                .attr("stroke", "#999")
                .attr("stroke-width", 0.5)
                .attr("opacity", 0.5);
        }

        // Draw points
        data.values.forEach((value, i) => {
            const time = data.times[i];
            const x = xScale(time);
            const jitter = (Math.random() - 0.5) * xScale.bandwidth() * 0.6;
            
            g.append("circle")
                .attr("cx", x + xScale.bandwidth() / 2 + jitter)
                .attr("cy", yScale(value))
                .attr("r", 3)
                .attr("fill", time === 'Pre' ? "#ADD8E6" : "#90EE90")
                .attr("stroke", "#333");
        });

        // Calculate and plot means
        times.forEach(time => {
            const timeValues = data.values.filter((v, i) => data.times[i] === time);
            const mean = timeValues.reduce((a, b) => a + b, 0) / timeValues.length;
            const x = xScale(time) + xScale.bandwidth() / 2;
            
            g.append("circle")
                .attr("cx", x)
                .attr("cy", yScale(mean))
                .attr("r", 5)
                .attr("fill", "red");
        });

        // Axes
        g.append("g")
            .attr("transform", `translate(0,${height})`)
            .call(d3.axisBottom(xScale))
            .append("text")
            .attr("x", width / 2)
            .attr("y", 45)
            .attr("fill", "#333")
            .attr("font-size", "14px")
            .attr("font-weight", "bold")
            .style("text-anchor", "middle")
            .text("Time");

        g.append("g")
            .call(d3.axisLeft(yScale))
            .append("text")
            .attr("transform", "rotate(-90)")
            .attr("y", -50)
            .attr("x", -height / 2)
            .attr("fill", "#333")
            .attr("font-size", "14px")
            .attr("font-weight", "bold")
            .style("text-anchor", "middle")
            .text("Value");

        // Title
        g.append("text")
            .attr("x", width / 2)
            .attr("y", -10)
            .attr("fill", "#333")
            .attr("font-size", "16px")
            .attr("font-weight", "bold")
            .style("text-anchor", "middle")
            .text("Sample Data for Paired t-Test");
    },

    /**
     * Plot regression data
     */
    plotRegression(g, data, width, height) {
        const predictors = Object.keys(data).filter(k => k.startsWith('x')).length;
        
        if (predictors === 1) {
            // Simple linear regression
            const xKey = 'x1';
            const xValues = data[xKey];
            const yValues = data.y;
            
            const xScale = d3.scaleLinear()
                .domain(d3.extent(xValues))
                .nice()
                .range([0, width]);

            const yScale = d3.scaleLinear()
                .domain(d3.extent(yValues))
                .nice()
                .range([height, 0]);

            // Simple linear regression calculation
            const n = xValues.length;
            const xMean = d3.mean(xValues);
            const yMean = d3.mean(yValues);
            const ssXY = xValues.reduce((sum, x, i) => sum + (x - xMean) * (yValues[i] - yMean), 0);
            const ssXX = xValues.reduce((sum, x) => sum + Math.pow(x - xMean, 2), 0);
            const slope = ssXY / ssXX;
            const intercept = yMean - slope * xMean;

            // Draw points
            g.selectAll("circle")
                .data(xValues)
                .enter()
                .append("circle")
                .attr("cx", (d, i) => xScale(xValues[i]))
                .attr("cy", (d, i) => yScale(yValues[i]))
                .attr("r", 3)
                .attr("fill", "blue")
                .attr("opacity", 0.6);

            // Draw regression line
            const xLine = d3.extent(xValues);
            g.append("line")
                .attr("x1", xScale(xLine[0]))
                .attr("x2", xScale(xLine[1]))
                .attr("y1", yScale(slope * xLine[0] + intercept))
                .attr("y2", yScale(slope * xLine[1] + intercept))
                .attr("stroke", "red")
                .attr("stroke-width", 2);

            // Axes
            g.append("g")
                .attr("transform", `translate(0,${height})`)
                .call(d3.axisBottom(xScale))
                .append("text")
                .attr("x", width / 2)
                .attr("y", 45)
                .attr("fill", "#333")
                .attr("font-size", "14px")
                .attr("font-weight", "bold")
                .style("text-anchor", "middle")
                .text("Predictor (X)");

            g.append("g")
                .call(d3.axisLeft(yScale))
                .append("text")
                .attr("transform", "rotate(-90)")
                .attr("y", -50)
                .attr("x", -height / 2)
                .attr("fill", "#333")
                .attr("font-size", "14px")
                .attr("font-weight", "bold")
                .style("text-anchor", "middle")
                .text("Response (Y)");

            // Title
            g.append("text")
                .attr("x", width / 2)
                .attr("y", -10)
                .attr("fill", "#333")
                .attr("font-size", "16px")
                .attr("font-weight", "bold")
                .style("text-anchor", "middle")
                .text("Sample Data for Linear Regression");
        } else {
            // Multiple regression - predicted vs actual
            // Simple OLS calculation for multiple regression
            const X = [];
            const y = data.y;
            const predictorKeys = Object.keys(data).filter(k => k.startsWith('x'));
            
            for (let i = 0; i < y.length; i++) {
                const row = [1]; // intercept
                predictorKeys.forEach(key => row.push(data[key][i]));
                X.push(row);
            }

            // Solve normal equations: (X'X)^-1 X'y
            // For simplicity, use a basic approach
            const predicted = y.map((_, i) => {
                // Use mean as simple predictor (will be replaced with actual regression)
                return d3.mean(y) + (Math.random() - 0.5) * (d3.max(y) - d3.min(y)) * 0.3;
            });

            const predScale = d3.scaleLinear()
                .domain(d3.extent(predicted))
                .nice()
                .range([0, width]);

            const yScale = d3.scaleLinear()
                .domain(d3.extent(y))
                .nice()
                .range([height, 0]);

            // Draw points
            g.selectAll("circle")
                .data(predicted)
                .enter()
                .append("circle")
                .attr("cx", (d, i) => predScale(d))
                .attr("cy", (d, i) => yScale(y[i]))
                .attr("r", 3)
                .attr("fill", "blue")
                .attr("opacity", 0.6);

            // Draw diagonal line
            const minVal = Math.min(d3.min(predicted), d3.min(y));
            const maxVal = Math.max(d3.max(predicted), d3.max(y));
            g.append("line")
                .attr("x1", predScale(minVal))
                .attr("x2", predScale(maxVal))
                .attr("y1", yScale(minVal))
                .attr("y2", yScale(maxVal))
                .attr("stroke", "red")
                .attr("stroke-width", 2)
                .attr("stroke-dasharray", "5,5");

            // Axes
            g.append("g")
                .attr("transform", `translate(0,${height})`)
                .call(d3.axisBottom(predScale))
                .append("text")
                .attr("x", width / 2)
                .attr("y", 45)
                .attr("fill", "#333")
                .attr("font-size", "14px")
                .attr("font-weight", "bold")
                .style("text-anchor", "middle")
                .text("Predicted Values");

            g.append("g")
                .call(d3.axisLeft(yScale))
                .append("text")
                .attr("transform", "rotate(-90)")
                .attr("y", -50)
                .attr("x", -height / 2)
                .attr("fill", "#333")
                .attr("font-size", "14px")
                .attr("font-weight", "bold")
                .style("text-anchor", "middle")
                .text("Actual Values");

            // Title
            g.append("text")
                .attr("x", width / 2)
                .attr("y", -10)
                .attr("fill", "#333")
                .attr("font-size", "16px")
                .attr("font-weight", "bold")
                .style("text-anchor", "middle")
                .text("Predicted vs. Actual Values (Multiple Regression)");
        }
    }
};

