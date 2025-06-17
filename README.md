# Sweden's Nuclear Energy Production

This repository contains code and documentation for a research project evaluating the effect of a competitive international scholarship program awarded to high-performing students in Oman. The analysis uses matching methods to estimate causal impacts on university access and first-year academic performance.

**See the output file for the full PDF report.** 

## Description

The program provides full financial support along with academic and application counseling. Using a matched sample of treated and non-treated students, the analysis estimates the Average Treatment Effect on the Treated (ATET) for two main outcomes: the global rank of the university attended and the student's first-year GPA.

Note: This project is based on a real-world consulting engagement. Due to data confidentiality restrictions, all data used here are simulated. The structure and relationships in the simulated dataset (vaguely) mirror the real data used in the original analysis. The data generation process is documented in the included dataset_simulation.R script.

## Repository Structure
```
Scholarship_Evaluation/
├── code/
│   ├── scholarship.Rmd        #  Main report with code, results, and narrative (knit to PDF)
│   ├── scholarship.R          # Core script for matching and regression models
│   └── dataset_simulation.R   # Script used to simulate realistic student-level data
│
├── data/
│   ├── simulated.csv           # Simulated dataset mimicking real structure
│   └── rankings.csv            # University QS Overall and Subject rankings 2025 
│
├── output/
│   └── scholarship.pdf         # Final PDF version of the report
│
├── LICENSE                     # MIT License governing reuse and distribution
└── README.md                   # Project overview and reproduction instructions
```

## How to Reproduce

1. Refer to `data/README.md` for instructions on generating the raw datasets.
2. Run `code/data_simulation.R` to generate dataset using `data/simulated.csv` and `data/rankings.csv`.
3. Use `scholarship.R` or knit `scholarship.Rmd` to reproduce the analysis and results.

## Software Requirements

This project uses R (version 4.0 or later) and the following packages: MatchIt, dplyr, tidyr, ggplot2, broom, kableExtra, gridExtra

## License

This project is released under the MIT License. See the `LICENSE` file for details.

## Author

Ibrahim Al Jahwari

Contact: ibrahim.aljahwari23.19@takatufscholars.om
