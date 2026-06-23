# this function take a prcomp object as input.
plot_pca <- function(pca_obj,
                     pc_comp1 = "PC1",
                     pc_comp2 = "PC2",
                     meta_df,
                     sample_id = "Sample",
                     color = NULL,
                     shape = NULL,
                     label = NULL,
                     title = "PCA plot (log2 intensities)") {

  # get PCA scores
  pca_scores <- pca_obj$x |> as.data.frame() |> rownames_to_column(sample_id)

  # get explained variance (%)
  pca_eigen_val <- round(summary(pca_obj)$importance[2, ] * 100, 1)

  # merge PCA scores and metadata
  pca_merged_df <- left_join(pca_scores, meta_df, by = sample_id)

  # aes() uses NSE, so bare column names can't come from string variables directly.
  # .data[[col]] is the tidyverse pronoun that lets us index a column by string at evaluation time.
  # modifyList() merges additional aesthetics (color, shape) into the base mapping when provided.
  aes_mapping <- aes(x = .data[[pc_comp1]], y = .data[[pc_comp2]])
  if (!is.null(color)) aes_mapping <- modifyList(aes_mapping, aes(color = .data[[color]]))
  if (!is.null(shape)) aes_mapping <- modifyList(aes_mapping, aes(shape = .data[[shape]]))

  # construct base plot
  p <- ggplot(pca_merged_df, aes_mapping) +
    geom_point(size = 3) +
    xlab(paste0(pc_comp1, ": ", pca_eigen_val[[pc_comp1]], "%")) +
    ylab(paste0(pc_comp2, ": ", pca_eigen_val[[pc_comp2]], "%")) +
    ggtitle(title) +
    theme_minimal() +
    theme(aspect.ratio = 1, text = element_text(size = 15))

  if (!is.null(color)) p <- p + scale_color_viridis_d()

  if (!is.null(label)) {
    p <- p + ggrepel::geom_text_repel(aes(label = .data[[label]]), box.padding = 0.5, max.overlaps = 20)
  }

  return(p)
}


plot_topN_sig_genes <- function(topN_vector,
                                normalize_mat,
                                sample_name_vector,
                                scale_rows = TRUE,
                                cluster_rows = TRUE,
                                cluster_cols = TRUE,
                                show_rownames = TRUE,
                                show_colnames = TRUE,
                                annotation_col = NULL,
                                title = "Top Significant Genes/Proteins",
                                legend_title = "Mean centered"
                                ) {
  
  # Sanity checks
  missing_genes <- setdiff(topN_vector, rownames(normalize_mat))
  missing_samples <- setdiff(sample_name_vector, colnames(normalize_mat))
  
  if (length(missing_genes) > 0) {
    warning("These genes were not found in matrix: ", paste(missing_genes, collapse = ", "))
  }
  if (length(missing_samples) > 0) {
    warning("These samples were not found in matrix: ", paste(missing_samples, collapse = ", "))
  }
  
  # Subset matrix
  selected_mat <- normalize_mat[topN_vector, sample_name_vector, drop = FALSE]
  
  # Mean-center (optional)
  if (scale_rows) {
    selected_mat <- t(scale(t(selected_mat), center = TRUE, scale = FALSE))
  }
  
  # Define color palette centered at 0
  color_limits <- range(selected_mat, na.rm = TRUE)
  color_mid <- 0
  color_breaks <- seq(color_limits[1], color_limits[2], length.out = 100)
  # colors <- colorRampPalette(c("blue", "white", "red"))(100)
  
  heatmap_legend_param = list(title = legend_title)
  
  # Plot heatmap
 p <- ComplexHeatmap::pheatmap(
    mat = selected_mat,
    # color = colors,
    breaks = color_breaks,
    cluster_rows = cluster_rows,
    cluster_cols = cluster_cols,
    show_rownames = show_rownames,
    show_colnames = show_colnames,
    annotation_col = annotation_col,
    main = title,
    heatmap_legend_param = heatmap_legend_param,
    fontsize_row = 10,
    fontsize_col = 10,
  )
  
 return (p)
}


plot_volcano <- function(df, uniq_id, logfc_id, pval_id, pval_cutoff = 0.05, top_n = 10, title = "Volcano plot") {

  # drop NA p-values
  df <- df |> drop_na(all_of(pval_id))

  # define significance
  df$Sig <- ifelse(df[[pval_id]] < pval_cutoff, "Sig", "NS")

  # compute -log10 p-value
  df$neg_log10_pval <- -log10(df[[pval_id]])

  # get top N significant genes for labeling
  top_genes <- df |> arrange(.data[[pval_id]]) |> slice_head(n = top_n)

  # volcano plot
  plt <- ggplot(df, aes(x = .data[[logfc_id]], y = neg_log10_pval)) +
    geom_point(aes(color = Sig), size = 0.6) +
    scale_color_manual(values = c("NS" = "black", "Sig" = "salmon")) +
    geom_text_repel(
      data = top_genes,
      aes(label = .data[[uniq_id]]),
      max.overlaps = Inf,
      size = 3
    ) +
    theme_minimal() +
    ylab(stringr::str_glue("-log10({pval_id})")) +
    xlab(logfc_id) + 
    ggtitle(title)
  
  return (plt)
}


plot_rle <- function(normal_mat, meta, sample_name) {
  
  ## log2 intensities matrix needed
  df <- normal_mat |> 
    as.data.frame() |> 
    pivot_longer(
      cols = everything(),
      names_to = "Sample",
      values_to = "log2_intensity"
    ) |>
    left_join(meta, by = sample_name)

  p <- ggboxplot(
        df,
        x = "Sample",
        y = "log2_intensity",
        color = "Group",
        x.text.angle = 45,
        ggtheme = theme_minimal(),
        outliers = FALSE,
        bxp.errorbar = TRUE
      ) +
      geom_hline(yintercept = 0, color = "red") +
      scale_y_continuous(
        limits = c(-3, 3),
        breaks = seq(-3, 3, by = 1)
      ) +
      ylab("Median centered log2 intensities")

  return(p)
}

prepare_de_results <- function(result_df,
                               pval_cutoff     = NULL,
                               adj_pval_cutoff = NULL,
                               logfc_cutoff    = NULL) {
  res_df <- result_df |>
    dplyr::rename(
      Moderated_t_statistic = t,
      p_value               = P.Value,
      adjusted_p_value      = adj.P.Val,
      B_statistic           = B
    ) |>
    dplyr::select(-Sig)

  # apply optional filters; NULL means no filtering
  if (!is.null(pval_cutoff))     res_df <- res_df |> dplyr::filter(p_value < pval_cutoff)
  if (!is.null(adj_pval_cutoff)) res_df <- res_df |> dplyr::filter(adjusted_p_value < adj_pval_cutoff)
  if (!is.null(logfc_cutoff))    res_df <- res_df |> dplyr::filter(abs(logFC) > logfc_cutoff)

  return (res_df)
}

run_contrast <- function(fit2, coef_name) {
  res_df <- topTable(fit2, coef = coef_name, number = Inf, sort.by = "P") |>
    as.data.frame() |>
    rownames_to_column(var = "prot_accessions") |>
    dplyr::rename(Nprecur = NPrec) |>
    dplyr::relocate(Nprecur, .after = genes) |>
    mutate(Sig = if_else(`adj.P.Val` < 0.05, "Sig", "Not sig"))

  return (res_df)
}

plot_missing <- function(data, title = "Missing Values") {

  n <- nrow(data)
  df <- data.frame(
    feature     = names(data),
    pct_missing = sapply(data, function(x) sum(is.na(x)) / n * 100)
  )

  plt <- ggplot2::ggplot(df, ggplot2::aes(x = feature, y = pct_missing)) +
    ggplot2::geom_bar(stat = "identity", fill = "#3266ad", width = 0.7) +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%.1f%%", pct_missing)),
      hjust = -0.1, size = 3.2, color = "grey30"
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, 110),
      labels = function(x) paste0(x, "%")
    ) +
    ggplot2::coord_flip() +
    ggplot2::labs(title = title, x = NULL, y = "% Missing") +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank()) +
    ggplot2::theme_minimal()

  return (plt)
}

filter_by_pepcount <- function(df, prot_col, pep_col, min_peps = 2) {
  pep_counts <- df |>
    dplyr::distinct(.data[[prot_col]], .data[[pep_col]]) |>
    dplyr::count(.data[[prot_col]])

  keep <- pep_counts |>
    dplyr::filter(n >= min_peps) |>
    dplyr::pull(.data[[prot_col]])

  df |>
    dplyr::filter(.data[[prot_col]] %in% keep)
}

static_md_plot <- function(dat_df, hline_y) {

  plt <-  ggplot(dat_df) + geom_point(aes(x = AveExpr, y=logFC, color=Sig)) +
    geom_hline(yintercept = hline_y, color = 'red') +
    scale_color_manual(values = c("black", "salmon")) +
    ylim(-4, 4) +
    xlim(0, 20) +
    xlab("average log expression")

  return (plt)

}


sig_logfc_bar_plot <- function(res_df, topN) {
  # top N upregulated proteins by logFC
  top_up_df <- res_df |>
    arrange(desc(logFC)) |>
    head(topN) |>
    dplyr::select(prot_accessions, logFC, Sig)

  # top N downregulated proteins by logFC
  top_down_df <- res_df |>
    arrange(logFC) |>
    head(topN) |>
    dplyr::select(prot_accessions, logFC, Sig)

  top_n_df <- bind_rows(top_up_df, top_down_df) |>
    mutate(prot_accessions = reorder(prot_accessions, logFC))

  plt <- ggplot(top_n_df) +
    geom_col(aes(x = logFC, y = prot_accessions, fill = Sig)) +
    scale_fill_manual(values = c("Not sig" = "black", "Sig" = "salmon")) +
    labs(
      title = paste0("Top ", topN, " up and down regulated proteins"),
      x = "logFC",
      y = "Accession"
    )

  return(plt)
}
