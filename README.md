
# Differential Expression Analysis App (Shiny)

This is a Shiny/R application for differential-expression analysis using T-test, based on [VolcaNoseR](https://github.com/JoachimGoedhart/VolcaNoseR/). The app is designed for proteomics data (e.g., MaxLFQ output) and supports robust group-wise comparison, flexible column selection, and user-friendly data exploration.

---

## Features

- Upload or use a default `proteinGroups.txt` file (tab-separated, MaxLFQ output)
- Dynamically select columns for two groups using prefix and filter patterns
- Default group filters for quick start (e.g., `43_|44_|45_|46_|47_|48_` and `37_|38_|39_|40_|41_|42_`)
- Interactive selection of columns for each group
- Real-time display of available columns and sample data
- Row-wise t-test (via custom `testT` function) between selected groups
- Download results with filename encoding all selection/filter parameters
- Downloaded filename format: 
	`proteinGroups_SEL-<selection>_G1-<group1filter>_G2-<group2filter>_testT.csv`
	(all non-alphanumeric characters removed from selection/filter strings)
- Interactive table, histogram, and heatmap of selected data

---

## Step-by-Step Usage

### 1. Setup

#### Requirements
- R (>= 4.0 recommended)
- R packages: `shiny`, `DT`, `ggplot2`, etc.

#### Install dependencies
```r
install.packages(c('shiny', 'DT', 'ggplot2'))
```

#### Clone the repository
```bash
git clone https://github.com/animesh/diffExpr
cd diffExpr
```

#### (Optional) Download example data
```bash
wget https://ftp.pride.ebi.ac.uk/pride/data/archive/2023/03/PXD037288/txt.zip
unzip txt.zip
# Place proteinGroups.txt in the app directory
```

---

### 2. Running the App

In R or RStudio:
```r
shiny::runApp('app.R', host='0.0.0.0', port=8081)
```
Or click "Run App" in RStudio.

---

### 3. Using the App

#### a. Data Input
- By default, the app loads `proteinGroups.txt` if present.
- You can upload your own file using the file input.

#### b. Column Selection
- **Select columns starting with**: Enter a prefix (e.g., `LFQ.intensity`) to filter columns by name.
- **Filter columns (Group 1/2)**: Enter patterns (e.g., `43_|44_|45_|46_|47_|48_`) to further filter columns for each group. Only alphanumeric characters are used in the download filename.
- Use the checkboxes to select/deselect columns for each group.

#### c. Data Exploration
- The app displays available columns and a sample row for reference.
- Interactive table shows t-test results for each protein/row.
- Histogram and heatmap visualizations are provided for selected data.

#### d. Downloading Results
- Click the **Download** button to save the t-test results as a CSV file.
- The filename will encode your current selection and filter settings, e.g.:
	`proteinGroups_SEL-LFQ_intensity_G1-434445464748_G2-373839404142_testT.csv`

---

## Example Workflow

1. Start the app and load your data.
2. Set "Select columns starting with" to `LFQ.intensity` (or your desired prefix).
3. Set Group 1 filter to `43_|44_|45_|46_|47_|48_` and Group 2 filter to `37_|38_|39_|40_|41_|42_` (or your sample groups).
4. Adjust column selections as needed using the checkboxes.
5. Review the available columns and sample data.
6. View the t-test results, histogram, and heatmap.
7. Click **Download** to save your results. The filename will reflect your selections.

---

## Notes

- Only alphanumeric characters from your filter and selection inputs are used in the download filename.
- The app is robust to missing or empty selections; error messages will guide you if no columns are selected.
- The statistical test is performed using a custom `testT` function (see `R/test.r`).

---

## Credits & Inspiration

This app is inspired by and builds on:
- [VolcaNoseR](https://github.com/JoachimGoedhart/VolcaNoseR)
- [VolcanoR](https://github.com/vovalive/volcanoR)
- [Volcanoshiny](https://github.com/hardingnj/volcanoshiny)
- [VolcanoPlot_shiny_app](https://github.com/stemicha/VolcanoPlot_shiny_app)

Maintainer: [Animesh Sharma](mailto:sharma.animesh@gmail.com?subject=diffExprApp)

---

