# Builds R/sysdata.rda: the content-control schema of the wmreport template.
# Rerun this script whenever the template in
# inst/rmarkdown/templates/wmreport/resources/ changes.

template <- "inst/rmarkdown/templates/wmreport/resources/Template-report-_ENG_-v36-_A_4_3_2_.docx"

ns <- c(w  = "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
  mc = "http://schemas.openxmlformats.org/markup-compatibility/2006")

d <- tempfile("dx")
dir.create(d)
zip::unzip(template, exdir = d)
x <- xml2::read_xml(file.path(d, "word", "document.xml"))

sdts <- xml2::xml_find_all(x, "//w:sdt", ns)
rows <- list()
counts <- list()
last <- list()

for (i in seq_along(sdts)) {
  s <- sdts[[i]]
  ts <- xml2::xml_find_all(s, "./w:sdtContent//w:t", ns)
  if (!length(ts)) next
  txt <- trimws(paste(xml2::xml_text(ts), collapse = ""))
  if (!nzchar(txt) || nchar(txt) > 100) next

  fb <- length(xml2::xml_find_all(s, "ancestor::mc:Fallback", ns)) > 0
  if (fb && !is.null(last[[txt]])) {
    id <- last[[txt]]
  } else {
    n <- if (is.null(counts[[txt]])) 1L else counts[[txt]] + 1L
    counts[[txt]] <- n
    id <- paste0(txt, "#", n)
    last[[txt]] <- id
  }

  rows[[length(rows) + 1L]] <- data.frame(pos = i, text = txt, id = id,
    stringsAsFactors = FALSE)
}

wmreport_schema <- do.call(rbind, rows)
save(wmreport_schema, file = "R/sysdata.rda", compress = "xz")
message("Saved ", nrow(wmreport_schema), " content controls to R/sysdata.rda")
