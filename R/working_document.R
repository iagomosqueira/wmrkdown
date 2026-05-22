# working_document.R - DESC
# /home/mosqu003/Projects/WMR/wmrkdown/wmrkdown/R/working_document.R

# Copyright (c) WMR, 2026.
# Author: Iago MOSQUEIRA <iago.mosqueira@wur.nl>
#
# Distributed under the terms of the EUPL-1.2

#' Custom report format
#'
#' @param ... Additional arguments passed to bookdown output formats
#'
#' @export

working_document <- function(left_header = "", right_header = "", ...) {

  includes <- rmarkdown::includes(
    in_header = header_file(left_header, right_header)
  )

  bookdown::pdf_document2(
    toc = TRUE,
    number_sections = TRUE,
    fig_caption = TRUE,
    latex_engine = "pdflatex",
    includes = includes,
    ...
  )
}

header_file <- function(left, right) {

  tf <- tempfile(fileext = ".tex")

  writeLines(
    c(
      "\\usepackage{fancyhdr}",
      "\\pagestyle{fancy}",
      paste0("\\fancyhead[L]{", left, "}"),
      paste0("\\fancyhead[R]{", right, "}")
    ),
    tf
  )

  return(tf)
}
