# presentation.R - WUR-styled Beamer presentation
# wmrkdown/R/presentation.R

# Copyright (c) WMR, 2026.
# Author: Iago MOSQUEIRA <iago.mosqueira@wur.nl>
#
# Distributed under the terms of the EUPL-1.2

# presentation {{{

#' WUR Beamer Presentation Format
#'
#' Create a Beamer presentation with Wageningen University & Research (WUR) styling.
#'
#' @param toc Logical. Whether to include a table of contents slide. Default: FALSE.
#' @param slide_level Integer. The heading level that defines individual slides.
#'   Default: 2.
#' @param incremental Logical. Whether to render slide content incrementally.
#'   Default: FALSE.
#' @param fig_width Numeric. Default width of figures in inches. Default: 10.
#' @param fig_height Numeric. Default height of figures in inches. Default: 7.
#' @param fig_crop Logical. Whether to crop figures. Default: TRUE.
#' @param fig_caption Logical. Whether to render figure captions. Default: TRUE.
#' @param dev Character. Graphics device to use ('pdf', 'png', 'jpg', etc.).
#'   Default: 'pdf'.
#' @param df_print Character. Method to print data frames ('default', 'kable', 'tibble').
#'   Default: 'default'.
#' @param fonttheme Character. Font theme for the presentation. Default: 'default'.
#' @param colortheme Character. Color theme for the presentation. Default: 'dove'.
#' @param highlight Character. Syntax highlighting style ('default', 'tango', 'kate', etc.).
#'   Default: 'tango'.
#' @param keep_tex Logical. Whether to keep the intermediate .tex file. Default: FALSE.
#' @param latex_engine Character. LaTeX engine to use ('pdflatex', 'xelatex', 'lualatex').
#'   Default: 'xelatex'.
#' @param citation_package Character. Citation package to use. One of 'default',
#'   'natbib', or 'biblatex'. Default: 'default'.
#' @param includes List. Additional files to include in the document header.
#'   Default: NULL.
#' @param md_extensions Character vector. Markdown extensions to enable. Default: NULL.
#' @param pandoc_args Character vector. Additional arguments to pass to Pandoc.
#'   Default: NULL.
#'
#' @return An R Markdown output format object suitable for use in R Markdown documents.
#'   When used in an R Markdown YAML header, produces a Beamer presentation in PDF format
#'   with WUR branding and styling.
#'
#' @details
#' This function creates a Beamer presentation format with WUR-specific styling by loading
#' a custom LaTeX template from the wmrdown package. It wraps the standard
#' \code{\link[rmarkdown]{beamer_presentation}} function with WUR-specific defaults.
#'
#' The function requires:
#' \itemize{
#'   \item The wmrdown package (for the WUR template)
#'   \item The rmarkdown package
#'   \item A working LaTeX installation with Beamer support
#'   \item The specified \code{latex_engine} (xelatex by default)
#' }
#'
#' @examples
#' \dontrun{
#' # Draft a presentation Rmd
#' draft("test.Rmd", template="wur", package="wmrkdown", edit=FALSE)
#' # Convert to pdf
#'  render("test/test.Rmd")
#' }
#'
#' @seealso
#' \code{\link[rmarkdown]{beamer_presentation}} for the underlying function
#' and additional output format options.
#'
#' @author Iago Mosqueira (WMR)
#'
#' @keywords internal

presentation <- function(toc = FALSE,
  slide_level = 2,
  incremental = FALSE,
  fig_width = 10,
  fig_height = 7,
  fig_crop = TRUE,
  fig_caption = TRUE,
  dev = 'pdf',
  df_print = "default",
  fonttheme = "default",
  colortheme = "dove",
  highlight = "tango",
  keep_tex = FALSE,
  latex_engine = "xelatex",
  citation_package = c("default", "natbib", "biblatex"),
  includes = NULL,
  md_extensions = NULL,
  pandoc_args = NULL,
  logo = system.file("rmarkdown", "templates", "presentation", "resources",
    "footer_wur.png", package = "wmrkdown"),
  front = system.file("rmarkdown", "templates", "presentation", "resources",
    "logo_wur.png", package = "wmrkdown"),
  titlegraphic = NULL,
  finalgraphic = NULL) {

  template <- system.file("rmarkdown", "templates", "presentation",
    "resources", "template.tex", package = "wmrkdown")

  # Build default pandoc variable args for branding image paths.
  # logo and front are WUR-specific and are always set via --variable.
  default_args <- c(
    rmarkdown::pandoc_variable_arg("logo", logo),
    rmarkdown::pandoc_variable_arg("front", front)
  )

  # titlegraphic is intentionally NOT added as a --variable by default.
  # Pandoc --variable takes precedence over document metadata, so adding it
  # unconditionally would silently override any titlegraphic set in the
  # top-level YAML of the Rmd. Only forward it when the caller explicitly
  # provides a value through the output options.
  if (!is.null(titlegraphic)) {
    default_args <- c(default_args,
      rmarkdown::pandoc_variable_arg("titlegraphic", titlegraphic))
  }

  if (!is.null(finalgraphic)) {
    default_args <- c(default_args,
      rmarkdown::pandoc_variable_arg("finalgraphic", finalgraphic))
  }

  rmarkdown::beamer_presentation(template = template,
    toc = toc,
    slide_level = slide_level,
    incremental = incremental,
    fig_width = fig_width,
    fig_height = fig_height,
    fig_crop = fig_crop,
    fig_caption = fig_caption,
    dev = dev,
    df_print = df_print,
    theme = "default",
    fonttheme = fonttheme,
    colortheme = colortheme,
    highlight = highlight,
    keep_tex = keep_tex,
    latex_engine = latex_engine,
    citation_package = citation_package,
    includes = includes,
    md_extensions = md_extensions,
    pandoc_args = c(default_args, pandoc_args))
}

# }}}


knitr_fun <- function(name) utils::getFromNamespace(name, 'knitr')

output_asis <- knitr_fun('output_asis')
