library(tidyverse)
library(ggplot2)
library(ggrepel)

# Read data
df <- read.csv("/home/dan_pham/Public/NIPT_data/results/test4_results/result.csv")

# Flag samples with low SeqFF
df <- df %>% 
  mutate(flag_low_seqff = ff..SeqFF. < 4)

# Calculate correlation and R2
cor_value <- cor(df$ff..SeqFF., df$FF...., use = "complete.obs")
R2_value <- cor_value^2

# Plot
ggplot(df, aes(x = ff..SeqFF., y = FF....)) +
  geom_point(aes(color = flag_low_seqff), size = 3) +
  scale_color_manual(values = c("FALSE" = "black", "TRUE" = "red")) +
  geom_smooth(method = "lm", se = FALSE) +
  
  # Label only the red samples
  ggrepel::geom_text_repel(
    data = df %>% filter(flag_low_seqff),
    aes(label = sample),
    color = "red",
    size = 4,
    max.overlaps = Inf
  ) +
  
  annotate(
    "text",
    x = max(df$ff..SeqFF., na.rm = TRUE),
    y = min(df$FF...., na.rm = TRUE),
    label = paste0("R² = ", round(R2_value, 4)),
    hjust = 1, vjust = 0,
    size = 5
  ) +
  
  theme_minimal(base_size = 14) +
  labs(
    title = "Correlation Plot: SeqFF predicted vs FF CapitalBio",
    x = "SeqFF.",
    y = "FF CapitalBio"
  )

