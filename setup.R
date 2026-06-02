# setup.R
# Shared setup file for data analysis projects.
# Load via: devtools::source_url("https://raw.githubusercontent.com/yourname/yourrepo/refs/heads/main/setup.R")

# ── knitr options ──────────────────────────────────────────────────────────────
knitr::opts_chunk$set(
  dev      = c("png", "pdf"),   # save figures in both formats
  fig.path = "./figures/"       # all figures go here
)

# ── output directories ─────────────────────────────────────────────────────────
dir.create("output",      recursive = TRUE, showWarnings = FALSE)
dir.create("figures/png", recursive = TRUE, showWarnings = FALSE)
dir.create("figures/pdf", recursive = TRUE, showWarnings = FALSE)

# ── ggplot2 theme & color defaults ────────────────────────────────────────────
library(ggplot2)

theme_set(theme_minimal(12))

# discrete scales
options(ggplot2.discrete.colour = scale_color_viridis_d)
options(ggplot2.discrete.fill   = scale_fill_viridis_d)

# continuous scales
options(ggplot2.continuous.colour = scale_color_viridis_c)
options(ggplot2.continuous.fill   = scale_fill_viridis_c)

# ── custom plot utilities ──────────────────────────────────────────────────────
# loads helper functions (save_plot, etc.) from the massspec repo
devtools::source_url(
  "https://raw.githubusercontent.com/joowkim/massspec/refs/heads/main/plot_utils.R"
)

message("setup.R loaded successfully")
