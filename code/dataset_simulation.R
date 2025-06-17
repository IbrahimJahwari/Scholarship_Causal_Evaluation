# ------------------- Setup -------------------
rm(list = ls())
set.seed(123)

# ------------------- Packages -------------------
library(dplyr)
library(readr)
library(stringr)
library(tidyr)

# ------------------- Parameters -------------------
n <- 1000
treat_pct <- 0.20
interview_pct <- 0.40

# ------------------- Load University Rankings -------------------
setwd("filepath") # remember to set your working directory
rankings <- read.csv("data/rankings.csv")

# ------------------- Region & Subject Assignment -------------------
governorates <- c("Muscat", "Dhofar", "Al Batinah North", "Al Batinah South",
                  "Al Dakhiliyah", "Ash Sharqiyah North", "Ash Sharqiyah South",
                  "Al Dhahirah", "Al Wusta", "Musandam", "Al Buraimi")
gov_weights <- c(0.30, 0.12, 0.13, 0.08, 0.08, 0.06, 0.05, 0.05, 0.04, 0.04, 0.05)
names(gov_weights) <- governorates

region <- sample(governorates, n, replace = TRUE, prob = gov_weights)
gender <- sample(c("Male", "Female"), n, replace = TRUE)
subjects <- c("engineering_tech", "arts_humanities", "lifesciences_medicine", 
              "natural_sciences", "socialsciences_management")
subject_area <- sample(subjects, n, replace = TRUE)

# ------------------- Score Generation -------------------
test_scores <- replicate(10, rnorm(n, mean = 75, sd = 10))
behavior_scores <- replicate(10, rnorm(n, mean = 70, sd = 8))
all_scores <- cbind(test_scores, behavior_scores)

# ------------------- Composite Score -------------------
pca_result <- prcomp(all_scores, center = TRUE, scale. = TRUE)
composite_score <- as.numeric(pca_result$x[, 1])

# ------------------- Treatment Assignment -------------------
cutoff_value <- quantile(composite_score, probs = 1 - interview_pct)
interview_pool <- which(composite_score >= cutoff_value)
if (length(interview_pool) < treat_pct * n) stop("Not enough eligible students for treatment.")
treated_indices <- sample(interview_pool, size = treat_pct * n, replace = FALSE)
treatment <- rep(0, n)
treatment[treated_indices] <- 1

# ------------------- Regional Disadvantage Index -------------------
region_disadvantage_raw <- 1 / gov_weights
region_disadvantage_scaled <- scale(region_disadvantage_raw)
names(region_disadvantage_scaled) <- names(gov_weights)
region_index <- region_disadvantage_scaled[region]
region_index_capped <- pmin(pmax(region_index, -2), 2)

# ------------------- GPA Generation -------------------
base_gpa <- 3.5
treat_effect <- 0.05 + 0.05 * pmax(region_index_capped, 0)
treatment_boost <- ifelse(treatment == 1, treat_effect, 0)
mean_gpa <- base_gpa + 0.05 * region_index + treatment_boost
first_year_gpa <- rnorm(n, mean = mean_gpa, sd = 0.15)
first_year_gpa <- round(pmin(pmax(first_year_gpa, 2.0), 4.0), 2)

# ------------------- University Assignment -------------------
rankings <- rankings %>%
  filter(!is.na(Overall)) %>%
  mutate(University = tolower(str_squish(str_trim(University))))

high_rank_unis <- rankings %>% filter(Overall >= 1 & Overall <= 200)
mid_rank_unis  <- rankings %>% filter(Overall >= 1 & Overall <= 350)

assign_university <- function(treat, region_idx) {
  pool <- if (treat == 1) high_rank_unis else mid_rank_unis
  base_score <- log(max(pool$Overall) + 1) - log(pool$Overall + 1)
  alpha <- if (treat == 1) 1.2 + 0.2 * pmax(region_idx, 0) else 0.9 + 0.1 * pmax(region_idx, 0)
  probs <- base_score ^ alpha
  probs <- probs / sum(probs)
  chosen <- sample(pool$University, 1, prob = probs)
  return(tolower(str_squish(str_trim(chosen))))
}

university <- mapply(assign_university, treatment, region_index_capped)

# ------------------- Final Dataset -------------------
sim <- data.frame(
  student_id = 1:n,
  gender = gender,
  region = region,
  subject_area = subject_area,
  composite_score = composite_score,
  treatment = treatment,
  first_year_gpa = first_year_gpa,
  university = university
)

for (i in 1:10) {
  sim[[paste0("test_", i)]] <- test_scores[, i]
  sim[[paste0("behavior_", i)]] <- behavior_scores[, i]
}

# ------------------- Merge with Rankings -------------------
rankings_clean <- rankings %>%
  rename(university = University, overall = Overall)

rankings_long <- rankings_clean %>%
  select(university, overall, engineering_tech, arts_humanities,
         lifesciences_medicine, natural_sciences, socialsciences_management) %>%
  pivot_longer(cols = c(engineering_tech, arts_humanities,
                        lifesciences_medicine, natural_sciences,
                        socialsciences_management),
               names_to = "subject_area", values_to = "rank")

sim <- sim %>%
  left_join(rankings_long, by = c("university", "subject_area")) %>%
  mutate(
    uni_overall_rank = overall,
    uni_subject_rank = rank,
    uni_rank_average = rowMeans(cbind(overall, rank), na.rm = TRUE)
  )

# ------------------- Save -------------------
write.csv(sim, "data/simulated.csv", row.names = FALSE)

# ------------------- Summary Check -------------------
cat("Treatment breakdown:\n")
print(table(sim$treatment))
cat("\nSubject distribution:\n")
print(table(sim$subject_area))
cat("\nRegion distribution:\n")
print(table(sim$region))
cat("\nGender distribution:\n")
print(table(sim$gender))


