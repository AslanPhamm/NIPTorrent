# Path to your file
df <- read.csv("/home/dan_pham/Public/NIPTorrent/STATISTIC/DATA/LIST OF REF/sample.csv")

# Check which REF2 exist in REF3
df$occur <- df$REF2 %in% df$REF3

# Occur list
occur_list <- df[df$occur == TRUE, "REF2"]
write.csv(occur_list, "/home/dan_pham/Public/NIPTorrent/STATISTIC/DATA/LIST OF REF/occur.csv",
          row.names = FALSE, quote = FALSE)

# Missing list
missing_list <- df[df$occur == FALSE, "REF2"]
write.csv(missing_list, "/home/dan_pham/Public/NIPTorrent/STATISTIC/DATA/LIST OF REF/missing.csv",
          row.names = FALSE, quote = FALSE)