# ------------------- Setup -------------------
rm(list = ls())
library(dplyr)
library(MatchIt)
library(broom)
library(cobalt)
library(ggplot2)
library(tableone)

# ------------------- Load Data -------------------
setwd("filepath") # remember to set your working directory
raw <- read.csv("data/simulated.csv")

# ------------------- Summary Statistics -------------------
cat("\n--- Summary Statistics by Treatment Group ---\n")
vars <- c("composite_score", "first_year_gpa", "uni_rank_average")
table1 <- CreateTableOne(vars = vars, strata = "treatment", data = raw, test = TRUE)
print(table1, smd = TRUE)

# ------------------- Distribution Tables -------------------
cat("\n--- Subject Area by Treatment ---\n")
print(addmargins(table(raw$treatment, raw$subject_area)))

cat("\n--- Region by Treatment ---\n")
print(addmargins(table(raw$treatment, raw$region)))

cat("\n--- Gender by Treatment ---\n")
print(addmargins(table(raw$treatment, raw$gender)))

# ------------------- Matching -------------------
match_data <- raw %>%
  select(treatment, composite_score, gender, region, subject_area,
         first_year_gpa, uni_rank_average) %>%
  na.omit()

cat("\n--- Pre-Matching Covariate Balance ---\n")
print(match_data %>% group_by(treatment) %>% summarise(across(composite_score, list(mean = mean, sd = sd))))

m.out <- matchit(treatment ~ composite_score + gender + region + subject_area,
                 data = match_data, method = "nearest", distance = "logit", ratio = 1)
matched_data <- match.data(m.out)

cat("\n--- Post-Matching Balance Summary ---\n")
print(summary(m.out))

# ------------------- Estimate Treatment Effects -------------------
cat("\n--- ATT on GPA (Unadjusted) ---\n")
att_gpa <- lm(first_year_gpa ~ treatment, data = matched_data)
print(summary(att_gpa))

cat("\n--- ATT on GPA (Covariate-Adjusted) ---\n")
att_gpa_covadj <- lm(first_year_gpa ~ treatment + composite_score + gender + region + subject_area, data = matched_data)
print(summary(att_gpa_covadj))

cat("\n--- ATT on University Rank (Unadjusted) ---\n")
att_rank <- lm(uni_rank_average ~ treatment, data = matched_data)
print(summary(att_rank))

cat("\n--- ATT on University Rank (Covariate-Adjusted) ---\n")
att_rank_covadj <- lm(uni_rank_average ~ treatment + composite_score + gender + region + subject_area, data = matched_data)
print(summary(att_rank_covadj))

# ------------------- Heterogeneity by Region -------------------
cat("\n--- Treatment Effect on GPA by Region ---\n")
att_by_region <- raw %>%
  group_by(region) %>%
  do(tidy(lm(first_year_gpa ~ treatment, data = .))) %>%
  filter(term == "treatment") %>%
  mutate(lower_ci = estimate - 1.96 * std.error,
         upper_ci = estimate + 1.96 * std.error) %>%
  select(region, estimate, std.error, lower_ci, upper_ci, p.value)
print(att_by_region)

cat("\n--- Treatment Effect on University Rank by Region ---\n")
att_rank_by_region <- raw %>%
  group_by(region) %>%
  do(tidy(lm(uni_rank_average ~ treatment, data = .))) %>%
  filter(term == "treatment") %>%
  mutate(lower_ci = estimate - 1.96 * std.error,
         upper_ci = estimate + 1.96 * std.error) %>%
  select(region, estimate, std.error, lower_ci, upper_ci, p.value)
print(att_rank_by_region)

# ------------------- Heterogeneity by Subject Area -------------------
cat("\n--- Treatment Effect on GPA by Subject Area ---\n")
att_by_subject <- raw %>%
  group_by(subject_area) %>%
  do(tidy(lm(first_year_gpa ~ treatment, data = .))) %>%
  filter(term == "treatment") %>%
  mutate(lower_ci = estimate - 1.96 * std.error,
         upper_ci = estimate + 1.96 * std.error) %>%
  select(subject_area, estimate, std.error, lower_ci, upper_ci, p.value)
print(att_by_subject)

cat("\n--- Treatment Effect on University Rank by Subject Area ---\n")
att_rank_by_subject <- raw %>%
  group_by(subject_area) %>%
  do(tidy(lm(uni_rank_average ~ treatment, data = .))) %>%
  filter(term == "treatment") %>%
  mutate(lower_ci = estimate - 1.96 * std.error,
         upper_ci = estimate + 1.96 * std.error) %>%
  select(subject_area, estimate, std.error, lower_ci, upper_ci, p.value)
print(att_rank_by_subject)

# ------------------- End of Script -------------------

