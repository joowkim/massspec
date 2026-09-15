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

theme_set(theme_classic(12))

# Pick the discrete color/fill palette for ggplot2.
# palette: "viridis" (default), "default", any RColorBrewer palette name
#          (e.g. "Pastel1", "Pastel2", "Set3", "Set1", "Dark2"),
#          or any paletteer palette as "package::palette_name"
#          (e.g. "colorblindr::OkabeIto", "rcartocolor::Safe")
set_discrete_palette <- function(palette = "viridis") {
  if (palette == "viridis") {
    options(ggplot2.discrete.colour = scale_color_viridis_d)
    options(ggplot2.discrete.fill   = scale_fill_viridis_d)
  ## ggplot defult color palette
  } else if (palette == "default") {
    options(ggplot2.discrete.colour = NULL)
    options(ggplot2.discrete.fill   = NULL)
  } else if (grepl("::", palette)) {
    # paletteer palette, given as "package::palette_name"
    # wrap in function(...) so ggplot2 calls this later, instead of us
    # building the scale object right now
    options(ggplot2.discrete.colour = function(...) scale_color_paletteer_d(palette, ...))
    options(ggplot2.discrete.fill   = function(...) scale_fill_paletteer_d(palette, ...))
  } else {
    # RColorBrewer palette name
    # wrap in function(...) so ggplot2 calls this later, instead of us
    # building the scale object right now
    options(ggplot2.discrete.colour = function(...) scale_color_brewer(palette = palette, ...))
    options(ggplot2.discrete.fill   = function(...) scale_fill_brewer(palette = palette, ...))
  }
  message("Discrete palette set to: ", palette)
}
 
 
# set default discrete palette on load
set_discrete_palette("viridis")
 
# continuous scales
options(ggplot2.continuous.colour = scale_color_viridis_c)
options(ggplot2.continuous.fill   = scale_fill_viridis_c)
 
# ── custom plot utilities ──────────────────────────────────────────────────────
# loads helper functions (save_plot, etc.) from the massspec repo
devtools::source_url(
  "https://raw.githubusercontent.com/joowkim/massspec/refs/heads/main/plot_utils.R"
)
 
message("setup.R loaded successfully")
message("if you want to go with a different qualitative color palette, e.g. Pastel1, Pastel2, Set3, or default")
message("set_discrete_palette('Pastel1')")
message("for a colorblind-safe palette via paletteer, e.g.:")
message("set_discrete_palette('colorblindr::OkabeIto')")
message('to see more color schemes, go over https://emilhvitfeldt.github.io/r-color-palettes/discrete.html#category=Package%20-%20colorBlindness')
