# London Gentrification Analysis

A data mining class project analyzing gentrification patterns across Greater London by combining housing price data, census demographics, and a published classification methodology. **Placed 2nd out of 9 teams** (50% of final course grade).

## Project Overview

The project started from a London housing-price Kaggle dataset, then was reframed to test a socioeconomic question: **where has gentrification actually occurred in London, and what socioeconomic factors distinguish gentrified wards from non-gentrified ones?**

We applied a published gentrification classification methodology (Hwang's Measure, based on Freeman et al. 2023/2024, *Urban Affairs Review*) combining:
- Income growth thresholds relative to city-wide medians
- Educational attainment growth
- Housing price growth (per sqm)

We used this measure to classify all 701 London wards as gentrified / not gentrified, then trained classifiers (Lasso Logistic Regression, Random Forest, XGBoost) to identify which demographic and housing features best predict gentrification status.

### Key Findings
- Our classification independently overlapped with **79.4%** of wards reported as gentrified by an external publication (Tower Hamlets area analysis).
- **Occupational composition** (professional/managerial employment ratios) was the single strongest predictor — more important than pure geography.
- Distinct regional patterns: **East London** gentrification is associated with newer housing stock, higher White British population share, and increased homeownership. **West London** gentrification is associated with more traditional housing types, an aging-up population shift, and higher deprivation baselines.
- Best-performing classifier: Random Forest (Accuracy 0.80, AUC-ROC 0.85).

See `docs/Final_Presentation.pdf` for the full write-up and `docs/Project_Proposal.pdf` for the original project proposal.

## Repository Structure

```
├── docs/                    Presentations, proposal, and research memos
│   ├── Project_Proposal.pdf         Initial proposal (housing price prediction framing)
│   ├── Final_Presentation.pdf       Final deliverable (gentrification framing)
│   ├── London_EDA_Report.pdf        Exploratory data analysis report
│   ├── London_Variable_Notes.pdf    Variable dictionary / dataset notes
│   ├── UK_Administrative_Divisions_Notes.pdf   Background on UK ward/borough structure
│   ├── Spatial_Clustering_Memo.pdf  Internal working notes on clustering approach
│   └── House_Price_Model_Memo.pdf   Internal working notes on price modeling
│
├── code/                    Analysis code
│   ├── london_eda.R / .Rmd          Main EDA and data wrangling (R)
│   ├── Clustering_2011.ipynb        Ward clustering, 2011 data (Python)
│   ├── GBM.ipynb                    Gradient boosting feature importance
│   ├── GBM_Clustering_2021_Price_pct_change.ipynb
│   └── exploratory_nba_eda.R / exploratory_basketball_eda.Rmd
│                                     Early-stage exploration of an alternative
│                                     (ultimately unused) NBA dataset direction
│
├── results/
│   ├── html/                 Rendered analysis notebooks (clustering, GBM,
│   │                         classifier outputs) — open directly in a browser
│   └── images/                Exported plots: feature importance, confusion
│                               matrices, ward maps
│
└── data/                    Datasets (see Data Sources below for full-size files)
    ├── census/               2021 UK Census tables by LSOA/ward, split by theme
    │   ├── labour_market/
    │   ├── demography_migration/
    │   ├── qualifications_health/
    │   ├── ethnicity_language/
    │   └── housing/
    ├── kaggle_house_price/   Kaggle London house price data (parquet)
    └── other/                Postcode districts, gentrification ward labels,
                               EU referendum results, parliamentary profile data
```

## Data Sources

Some source files were too large for this repository (GitHub's file size limits) and are not included. Download them directly from the original sources if you want to reproduce the full pipeline:

| Dataset | Source |
|---|---|
| London house price data (full, ungrouped) | [Kaggle: jakewright/house-price-data](https://www.kaggle.com/datasets/jakewright/house-price-data/data) |
| London postcodes (geographic lookup) | [doogal.co.uk/london_postcodes](https://www.doogal.co.uk/london_postcodes) |
| 2021 Census — ethnicity, language, identity, religion (ward-level) | [data.london.gov.uk](https://data.london.gov.uk/dataset/2021-census-wards-ethnicity-language-identity-religion) |
| 2021 Census — labour market (ward-level) | [data.london.gov.uk](https://data.london.gov.uk/dataset/2021-census-wards-labour-market) |
| 2021 Census — qualifications, health, disability, care (LSOA-level) | [data.london.gov.uk](https://data.london.gov.uk/dataset/2021-census-lsoa-qualifications-health-disability-and-care) |
| Personal income by tax year | [gov.uk](https://www.gov.uk/government/collections/personal-income-by-tax-year) |
| ONS household income (LSOA) | [ons.gov.uk, dataset TS067](https://www.ons.gov.uk/datasets/TS067/editions/2021/versions/1) |
| London Underground station/line data | [Imperial TSL notebook](https://transport-systems.imperial.ac.uk/tf/notebooks/n05_studying_the_london_underground.html), [TfL Open Data](https://tfl.gov.uk/info-for/open-data-users/our-open-data) |

## Methodology Summary

**Gentrification classification (Hwang's Measure):**
1. **Gentrifiable**: ward is centrally located AND ward median household income > city-wide median.
2. **Gentrifying**: ward's growth in (a) college-educated population share OR (b) median household income exceeds the city-wide growth rate.
3. **Gentrified**: ward's median house price growth (per sqm) exceeds the city-wide growth rate.

A ward satisfying all three conditions across the 2011→2021 window is classified as gentrified.

**Classifiers trained** to predict gentrification status from ward-level features (occupation structure, income, housing type, transport access, deprivation index, demographics):
- L1 (Lasso) Logistic Regression
- Random Forest
- XGBoost

## Limitations

- No direct displacement tracking — the analysis identifies *where* gentrification occurred, not where displaced residents went.
- Median-based thresholds are sensitive to how "city-wide" comparison groups are defined.
- Missing contextual urban development data (e.g., planning permissions, major infrastructure timing beyond the Elizabeth Line).
- Only two census snapshots (2011, 2021) — no continuous time series, limiting causal claims about *when* within that decade change occurred.

## Academic Reference

Freeman, L., Hwang, J., Haupert, T., & Zhang, I. (2023). Where Do They Go? The Destinations of Residents Moving from Gentrifying Neighborhoods. *Urban Affairs Review*, 60(1), 304–348. https://doi.org/10.1177/10780874231169921

Glass, Ruth. *London: Aspects of Change*. MacGibbon & Kee, 1964. (Origin of the term "gentrification.")
