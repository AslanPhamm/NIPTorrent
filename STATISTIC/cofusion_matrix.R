library(tidyverse)
library(ggplot2)

## ---- 1. Read data ----
df <- read.csv("/home/dan_pham/Public/NIPT_data/results/test4_results/result.csv",
               check.names = FALSE)

# FIX duplicated names
names(df) <- make.names(names(df), unique = TRUE)

## Check names to confirm
print(names(df))

## ---- 2. Define reference & prediction columns ----
ref_col  <- "Z13"
pred_col <- "Z13.1"

## ---- 3. Create Ref & Pred ----
df_Z13 <- df %>%
  mutate(
    Ref  = if_else(.data[[ref_col]]  >= 3, "Ref+",  "Ref-"),
    Pred = if_else(.data[[pred_col]] >= 3, "Pred+", "Pred-")
  )

## ---- 4. Confusion matrix ----
cm <- table(
  Reference  = factor(df_Z13$Ref, levels=c("Ref+","Ref-")),
  Prediction = factor(df_Z13$Pred, levels=c("Pred+","Pred-"))
)

cm_df <- as.data.frame(cm)
cm_df$Percent <- round(cm_df$Freq / sum(cm_df$Freq) * 100, 1)
cm_df$Label   <- paste0(cm_df$Freq, "\n(", cm_df$Percent, "%)")

## ---- 5. Plot ----
ggplot(cm_df, aes(Prediction, Reference)) +
  geom_tile(aes(fill = Freq), color = "white") +
  annotate("rect",
             xmin = 0.5, xmax = 2.5,
             ymin = 0.5, ymax = 2.5,
             fill = NA, color = "black", linewidth = 1.2) +
  annotate("segment",
           x = 0.5, xend = 2.5,
           y = 1.5, yend = 1.5,
           linetype = "dotted", linewidth = 1) +
  annotate("segment",
           x = 1.5, xend = 1.5,
           y = 0.5, yend = 2.5,
           linetype = "dotted", linewidth = 1) +
  geom_text(aes(label = Label), size = 6, fontface = "bold") +
  scale_fill_gradient(low = "grey", high = "darkblue") +
  labs(
    title = "Z13 Confusion Matrix (Filter trim50Q15 vs CapitalBio", 
    x = "Predicted Label",
    y = "True Label",
    fontface = "bold",
    fill = "Count"
  ) +
  theme_minimal(base_size = 14)
