# wmreport.R - DESC
# wmrkdown/R/wmreport.R

# Copyright (c) WMR, 2026.
# Author: Iago MOSQUEIRA <iago.mosqueira@wur.nl>
#
# Distributed under the terms of the EUPL-1.2

# wmrreport {{{

#' Output format for WMR report docx
#'
#' An `rmarkdown` output format that renders an R Markdown report and places
#' its body inside the WMR report cover template. Use it as the
#' `output_format` of `rmarkdown::render()`:
#'
#' ```r
#' rmarkdown::render("report.Rmd", output_format = wmreport())
#' ```
#'
#' The cover content controls are filled from the YAML front matter of the Rmd
#' and from `fields`, and the body is merged in at `body_marker`.
#'
#' @param ... Cover values, named by field name, overriding those read from the
#'   Rmd YAML front matter, e.g. `report_number = "RN-1"`. Any front matter key
#'   that is a field name below is used directly, and the keys in `yaml_map` are
#'   renamed to their target field. Names must be one of the field names below:
#'   \describe{
#'     \item{report_number}{Report number.}
#'     \item{title}{Report title.}
#'     \item{subtitle}{Report subtitle.}
#'     \item{author}{Author(s).}
#'     \item{institute_1}{First institute.}
#'     \item{institute_2}{Second institute.}
#'     \item{place}{Place of publication.}
#'     \item{month}{Month of publication.}
#'     \item{year}{Year of publication.}
#'     \item{n_tables}{Number of tables.}
#'     \item{n_references}{Number of references.}
#'     \item{student_name}{Name of the student(s).}
#'     \item{student_number}{Student number, if applicable.}
#'     \item{study_program}{Study program.}
#'     \item{study_spec}{Study specialisation.}
#'     \item{university_dept}{University and department.}
#'     \item{supervisors}{Supervisors within Wageningen Marine Research.}
#'     \item{wmr_dept_loc}{Wageningen Marine Research department and location.}
#'     \item{date_cover}{Date shown on the cover.}
#'     \item{client}{Client.}
#'     \item{client_attn}{Client contact name.}
#'     \item{client_address}{Client address.}
#'     \item{client_zipcode}{Client zipcode.}
#'     \item{client_place}{Client place.}
#'     \item{bas_code}{BAS code (projects funded by the Ministry of LVVN).}
#'     \item{project_number}{Project number.}
#'     \item{reviewer_name}{Name of the researcher who read the report.}
#'     \item{reviewer_function}{Function of the reviewer.}
#'     \item{reviewer_date}{Date of review.}
#'     \item{approver_name}{Name of the management team member responsible for
#'       the scientific content.}
#'     \item{approver_function}{Function of the approver.}
#'     \item{approver_date}{Date of approval.}
#'   }
#' @param yaml_map Named character vector mapping YAML keys of the Rmd front
#'   matter (the names) to field names (the values, see `...`). Only used
#'   when `content` is an `.Rmd` file. Possible YAML keys and their default
#'   targets:
#'   \describe{
#'     \item{title}{Mapped to `title`.}
#'     \item{subtitle}{Mapped to `subtitle`.}
#'     \item{author}{Mapped to `author`. Lists of names are joined with commas.}
#'     \item{date}{Mapped to `date_cover`. Inline R such as `` `r Sys.Date()` ``
#'       is evaluated.}
#'   }
#'   Any of the field names above can be used as a target.
#' @param body_marker Text of the template paragraph that the body replaces.
#' @param update_toc If `TRUE`, the docx is flagged so Word updates fields
#'   (such as the table of contents) when it is opened.
#' @param number_sections Passed to `bookdown::word_document2()`.
#' @param reference_docx Optional reference docx for the body styles.
#'
#' @return An `rmarkdown` output format.
#'
#' @details The content-control layout of the template is read from the
#'   build-time schema `wmreport_schema` (see `data-raw/wmreport_schema.R`).
#'   Rerun that script when the template changes.
#' @export
wmreport <- function(..., yaml_map = NULL, body_marker = NULL,
  update_toc = NULL, number_sections = FALSE, reference_docx = NULL) {

  fields <- list(...)
  extra <- Filter(Negate(is.null),
    list(yaml_map = yaml_map, body_marker = body_marker, update_toc = update_toc))

  lua <- tempfile(fileext = ".lua")
  writeLines(c("function Meta(m)",
               "  m.title = nil; m.subtitle = nil; m.author = nil; m.date = nil",
               "  return m",
               "end",
               "function Para(p)",
               "  if #p.content == 1 and p.content[1].t == 'Math' and p.content[1].mathtype == 'DisplayMath' then",
               "    return pandoc.Div({p}, pandoc.Attr('', {}, {['custom-style'] = 'Equation'}))",
               "  end",
               "  if #p.content == 1 and p.content[1].t == 'Image' then",
               "    return pandoc.Div({p}, pandoc.Attr('', {}, {['custom-style'] = 'Figure'}))",
               "  end",
               "end"), lua)

  fmt_args <- list(number_sections = number_sections,
                   pandoc_args     = c("--lua-filter", lua))
  if (!is.null(reference_docx)) fmt_args$reference_docx <- reference_docx
  fmt <- do.call(bookdown::word_document2, fmt_args)

  prev <- fmt$post_processor
  fmt$post_processor <- function(metadata, input_file, output_file, clean, verbose) {
    if (!is.null(prev))
      output_file <- prev(metadata, input_file, output_file, clean, verbose)
    body <- tempfile(fileext = ".docx")
    file.copy(output_file, body, overwrite = TRUE)
    do.call(assemble_wmreport, c(list(content = body, output = output_file,
      yaml_source = input_file), fields, extra))
    output_file
  }

  fmt
}

# Builds the docx from a rendered body and the template; used by wmreport().
assemble_wmreport <- function(content, output, ...,
  yaml_map = c(title    = "title",
    subtitle = "subtitle",
    author   = "author",
    date     = "date_cover"),
  body_marker     = "BODY_HERE",
  update_toc      = FALSE,
  number_sections = FALSE,
  reference_docx  = NULL,  yaml_source     = NULL) {

  fields <- list(...)

  # GET template  
  template <- system.file("rmarkdown", "templates", "wmreport",
    "resources", "Template-report-_ENG_-v36-_A_4_3_2_.docx", package = "wmrkdown")

  #
  ns <- c(w  = "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
    r  = "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    wp = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
    mc = "http://schemas.openxmlformats.org/markup-compatibility/2006")

  # friendly name -> positional id (the only place that knows the template layout)
  field_map <- c(
    report_number     = "reportnumber#1",
    title             = "Click here to add a title#1",
    subtitle          = "Click here to add a subtitle#1",
    author            = "Click here to add one or more authors#1",
    institute_1       = "Instituut 1#1",
    institute_2       = "Instituut 2#1",
    place             = "place#1",
    month             = "month#1",
    year              = "year#1",
    n_tables          = "number of tables#1",
    n_references      = "number of ref.#1",
    student_name      = "name of the students#1",
    student_number    = "if applicable#1",
    study_program     = "study program#1",
    study_spec        = "study specialisation#1",
    university_dept   = "University and department#1",
    supervisors       = "supervisors within Wageningen Marine Research#1",
    wmr_dept_loc      = "Wageningen Marine Research department and location#1",
    date_cover        = "date#1",
    client            = "client#1",
    client_attn       = "name#1",
    client_address    = "address#1",
    client_zipcode    = "zipcode#1",
    client_place      = "place#2",
    bas_code          = "BAS code (applied to projects funded by the Ministry of LVVN#1",
    project_number    = "projectnumber#1",
    reviewer_name     = "name Researcher who read the report#1",
    reviewer_function = "function#1",
    reviewer_date     = "date#2",
    approver_name     = "name Management team member being responsible for the scientific content of this report#1",
    approver_function = "function#2",
    approver_date     = "date#3"
  )

  # ---- helpers --------------------------------------------------------------
  unpack <- function(docx) {
    d <- tempfile("dx")                      # short path, fresh each call
    dir.create(d)
    zip::unzip(docx, exdir = d)
    d
  }
  repack <- function(dir, docx) {
    if (file.exists(docx)) file.remove(docx)
    zip::zipr(docx, list.files(dir, all.files = TRUE, no.. = TRUE), root = dir)
  }
  yaml_fields <- function(file) {
    y <- tryCatch(rmarkdown::yaml_front_matter(file), error = function(e) list())
    out <- list()
    # yaml_map renames keys (e.g. date -> date_cover); any other key that is
    # a field name is used as is
    keys <- union(names(yaml_map), names(field_map))
    for (k in intersect(keys, names(y))) {
      v <- y[[k]]
      if (is.null(v)) next
      target <- if (k %in% names(yaml_map)) yaml_map[[k]] else k
      if (is.list(v)) {   # list of strings, or entries like "- name: X"
        v <- vapply(v, function(a) if (is.list(a)) as.character(a$name) else as.character(a), "")
      }
      v <- paste(as.character(v), collapse = ", ")
      if (grepl("^`r .*`$", v)) {   # inline R in YAML, e.g. "`r Sys.Date()`"
        v <- as.character(eval(parse(text = sub("^`r (.*)`$", "\\1", v)),
                                envir = globalenv()))
      }
      out[[target]] <- v
    }
    out
  }

  # inline merge of body into template at marker paragraph (no altChunk, so
  # Word updates the body's fields with the rest of the document)
  merge_body <- function(filled_docx, body_docx, marker, out) {
    td <- unpack(filled_docx); bd <- unpack(body_docx)
    tdoc <- read_xml(file.path(td, "word", "document.xml"))
    bdoc <- read_xml(file.path(bd, "word", "document.xml"))

    mk <- xml_find_first(tdoc, sprintf("//w:p[.//w:t[contains(., '%s')]]", marker), ns)
    if (inherits(mk, "xml_missing")) stop("Marker '", marker, "' not found as a paragraph")

    # renumber body bookmarks past the template's ids; some body bookmarks
    # carry no w:id, so pair starts and ends in document order with a stack
    bm_max <- max(0L, as.integer(xml_attr(xml_find_all(tdoc, "//w:bookmarkStart | //w:bookmarkEnd", ns),
                                          "w:id", ns = ns)), na.rm = TRUE)
    bm_next <- bm_max + 1L
    stk <- list()
    for (b in xml_find_all(bdoc, "//w:bookmarkStart | //w:bookmarkEnd", ns)) {
      old <- xml_attr(b, "w:id", ns = ns)
      if (xml_name(b) == "bookmarkStart") {
        stk[[length(stk) + 1L]] <- list(old = old, new = bm_next)
        xml_set_attr(b, "w:id", as.character(bm_next), ns)
        bm_next <- bm_next + 1L
      } else {
        hit <- which(vapply(stk, function(s) identical(s$old, old), logical(1)))
        k <- if (length(hit)) max(hit) else length(stk)
        xml_set_attr(b, "w:id", as.character(stk[[k]]$new), ns)
        stk[[k]] <- NULL
      }
    }

    nodes <- xml_children(xml_find_first(bdoc, "//w:body", ns))
    nodes <- nodes[xml_name(nodes) != "sectPr"]

    # the body's References section goes under the template's References title
    ptext  <- function(n) paste(xml_text(xml_find_all(n, ".//w:t", ns)), collapse = "")
    pstyle <- function(n) {
      s <- xml_attr(xml_find_first(n, "./w:pPr/w:pStyle", ns), "w:val", ns = ns)
      if (is.na(s)) "" else s
    }
    is_p <- xml_name(nodes) == "p"
    h <- which(is_p & vapply(nodes, ptext, "") == "References" &
                 vapply(nodes, pstyle, "") == "Heading1")
    refs <- nodes[0]
    if (length(h)) {
      h <- h[1]
      stop_at <- which(is_p & vapply(nodes, pstyle, "") == "Heading1")
      stop_at <- stop_at[stop_at > h]
      end <- if (length(stop_at)) stop_at[1] - 1L else length(nodes)
      idx <- seq(h + 1L, length.out = max(0L, end - h))
      refs <- nodes[idx]
      nodes <- nodes[-c(h:(h + length(idx)))]
    }

    # remap r:* relationship references used by the body
    rl  <- xml_children(read_xml(file.path(bd, "word", "_rels", "document.xml.rels")))
    rel <- data.frame(id = xml_attr(rl, "Id"), type = xml_attr(rl, "Type"),
                      target = xml_attr(rl, "Target"), mode = xml_attr(rl, "TargetMode"),
                      stringsAsFactors = FALSE)
    map <- character(0); new_rels <- character(0); k <- 0L
    dir.create(file.path(td, "word", "media"), showWarnings = FALSE)
    max_dp <- suppressWarnings(max(as.integer(
      xml_attr(xml_find_all(tdoc, "//wp:docPr", ns), "id")), 0L, na.rm = TRUE))

    for (nd in c(nodes, refs)) {
      for (e in xml_find_all(nd, ".//*[@r:embed or @r:id or @r:link]", ns)) {
        drop <- FALSE
        for (a in c("embed", "id", "link")) {
          old <- xml_attr(e, paste0("r:", a), ns = ns)
          if (is.na(old)) next
          i <- match(old, rel$id)
          if (is.na(i)) { warning("Unknown relationship ", old); drop <- TRUE; next }
          if (!(old %in% names(map))) {
            k <- k + 1L; nid <- paste0("rIdBody", k)
            if (!is.na(rel$mode[i]) && rel$mode[i] == "External") {
              new_rels <- c(new_rels, sprintf(
                '<Relationship Id="%s" Type="%s" Target="%s" TargetMode="External"/>',
                nid, rel$type[i], rel$target[i]))
            } else if (grepl("/image$", rel$type[i])) {
              tgt <- paste0("media/body_", k, "_", basename(rel$target[i]))
              file.copy(file.path(bd, "word", rel$target[i]),
                        file.path(td, "word", tgt), overwrite = TRUE)
              new_rels <- c(new_rels, sprintf(
                '<Relationship Id="%s" Type="%s" Target="%s"/>', nid, rel$type[i], tgt))
            } else {
              warning("Unsupported relationship, element dropped: ", rel$type[i])
              drop <- TRUE; next
            }
            map[old] <- nid
          }
          if (!drop) xml_set_attr(e, paste0("r:", a), map[[old]], ns)
        }
        if (drop) xml_remove(e)
      }
      for (dp in xml_find_all(nd, ".//wp:docPr", ns)) {
        max_dp <- max_dp + 1L
        xml_set_attr(dp, "id", as.character(max_dp))
      }
    }
    if (length(new_rels)) {
      rf  <- file.path(td, "word", "_rels", "document.xml.rels")
      txt <- sub("</Relationships>", paste0(paste(new_rels, collapse = ""), "</Relationships>"),
                 paste(readLines(rf, warn = FALSE, encoding = "UTF-8"), collapse = "\n"),
                 fixed = TRUE)
      writeLines(txt, rf, useBytes = TRUE)
    }

    # content types for copied image extensions
    ct  <- file.path(td, "[Content_Types].xml")
    ctt <- paste(readLines(ct, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    mime <- c(png = "image/png", jpg = "image/jpeg", jpeg = "image/jpeg",
              gif = "image/gif", emf = "image/x-emf", wmf = "image/x-wmf", svg = "image/svg+xml")
    for (e in unique(tolower(tools::file_ext(list.files(file.path(td, "word", "media")))))) {
      if (e %in% names(mime) && !grepl(sprintf('Extension="%s"', e), ctt, ignore.case = TRUE))
        ctt <- sub("</Types>", sprintf('<Default Extension="%s" ContentType="%s"/></Types>', e, mime[[e]]),
                   ctt, fixed = TRUE)
    }
    writeLines(ctt, ct, useBytes = TRUE)

    # styles used by the body but missing in the template
    tst  <- read_xml(file.path(td, "word", "styles.xml"))
    bst  <- read_xml(file.path(bd, "word", "styles.xml"))
    have <- xml_attr(xml_find_all(tst, "//w:style", ns), "w:styleId", ns = ns)
    sroot <- xml_find_first(tst, "/w:styles", ns)
    for (s in xml_find_all(bst, "//w:style", ns)) {
      if (!(xml_attr(s, "w:styleId", ns = ns) %in% have)) xml_add_child(sroot, s, .copy = TRUE)
    }
    # exact 26pt line height clips descenders on the 22pt cover title
    ttl <- xml_find_first(tst, "//w:style[@w:styleId='Title']/w:pPr/w:spacing", ns)
    if (!inherits(ttl, "xml_missing")) {
      xml_set_attr(ttl, "w:lineRule", "auto")
      xml_set_attr(ttl, "w:line", "240")
    }
    write_xml(tst, file.path(td, "word", "styles.xml"))

    # insert body before the marker, then drop the marker
    for (nd in nodes) xml_add_sibling(mk, nd, .where = "before", .copy = TRUE)
    xml_remove(mk)

    # template References section: drop its placeholder entries, add the body's
    tref <- xml_find_first(tdoc, paste0(
      "//w:p[w:pPr/w:pStyle[@w:val='Kop1ongenummerd'] and normalize-space(.)='References']"), ns)
    if (!inherits(tref, "xml_missing")) {
      for (sb in xml_find_all(tref, "following-sibling::*", ns)) {
        if (pstyle(sb) == "Kop1ongenummerd") break
        if (xml_name(sb) == "p" && inherits(xml_find_first(sb, ".//w:sectPr", ns), "xml_missing")) xml_remove(sb)
      }
      prev <- tref
      for (nd in refs) prev <- xml_add_sibling(prev, nd, .where = "after", .copy = TRUE)
    }
    write_xml(tdoc, file.path(td, "word", "document.xml"))

    repack(td, out)
  }

  # ---- YAML defaults (explicit `fields` win) ----------------------------------
  ext <- tolower(tools::file_ext(content))
  yaml_src <- if (ext == "rmd") content else yaml_source
  if (!is.null(yaml_src)) fields <- modifyList(yaml_fields(yaml_src), fields)

  # ---- checks -----------------------------------------------------------------
  if (length(fields) && (is.null(names(fields)) || any(!nzchar(names(fields)))))
    stop("`fields` must be a fully named list")
  bad <- setdiff(names(fields), names(field_map))
  if (length(bad))
    stop("Unknown field(s): ", paste(bad, collapse = ", "),
         "\nValid: ", paste(names(field_map), collapse = ", "))
  if (!file.exists(template)) stop("Template not found: ", template)

  # ---- 1. body docx -----------------------------------------------------------
  if (ext == "docx") {
    body_docx <- content
  } else if (ext == "rmd") {
    # drop title/subtitle/author/date from the body: the cover carries them
    lua <- tempfile(fileext = ".lua")
    writeLines(c("function Meta(m)",
                 "  m.title = nil; m.subtitle = nil; m.author = nil; m.date = nil",
                 "  return m",
                 "end",
                 "function Para(p)",
                 "  if #p.content == 1 and p.content[1].t == 'Math' and p.content[1].mathtype == 'DisplayMath' then",
                 "    return pandoc.Div({p}, pandoc.Attr('', {}, {['custom-style'] = 'Equation'}))",
                 "  end",
                 "  if #p.content == 1 and p.content[1].t == 'Image' then",
                 "    return pandoc.Div({p}, pandoc.Attr('', {}, {['custom-style'] = 'Figure'}))",
                 "  end",
                 "end"), lua)

    fmt_args <- list(number_sections = number_sections,
                     pandoc_args     = c("--lua-filter", lua))
    if (!is.null(reference_docx)) fmt_args$reference_docx <- reference_docx
    fmt <- do.call(bookdown::word_document2, fmt_args)

    body_docx <- tempfile(fileext = ".docx")
    # an explicit output_format overrides the `output:` field in the Rmd YAML
    rmarkdown::render(content, output_format = fmt,
                      output_file = body_docx, quiet = TRUE,
                      envir = new.env(parent = globalenv()))
  } else if (ext == "qmd") {
    stop("Render the .qmd to docx first and pass the .docx")
  } else stop("`content` must be .docx or .Rmd")
  if (!file.exists(body_docx)) stop("Body docx was not created")

  # ---- 2. fill content controls in document.xml -------------------------------
  values <- setNames(as.list(unlist(fields)), field_map[names(fields)])
  dir    <- unpack(template)
  part   <- file.path(dir, "word", "document.xml")
  x      <- read_xml(part)
  sdts   <- xml_find_all(x, "//w:sdt", ns)
  seen   <- wmreport_schema$id
  filled <- character(0)

  for (r in seq_len(nrow(wmreport_schema))) {
    s  <- sdts[[wmreport_schema$pos[r]]]
    ts <- xml_find_all(s, "./w:sdtContent//w:t", ns)
    txt <- trimws(paste(xml_text(ts), collapse = ""))
    if (!identical(txt, wmreport_schema$text[r]))
      stop("Template layout changed; rerun data-raw/wmreport_schema.R")

    id  <- wmreport_schema$id[r]
    val <- values[[id]]
    if (is.null(val)) next
    xml_text(ts[[1]]) <- as.character(val)
    if (length(ts) > 1) xml_remove(ts[-1])
    xml_remove(xml_find_all(s, "./w:sdtPr/w:showingPlcHdr", ns))
    xml_remove(xml_find_all(s, ".//w:rStyle[@w:val='PlaceholderText']", ns))
    filled <- c(filled, id)
  }
  write_xml(x, part)

  missing_ids <- setdiff(names(values), seen)
  if (length(missing_ids))
    stop("These ids were not found in the template (layout changed?): ",
         paste(missing_ids, collapse = ", "))

  filled_docx <- tempfile(fileext = ".docx")
  repack(dir, filled_docx)

  # ---- 3. merge body at the marker --------------------------------------------
  merged <- tempfile(fileext = ".docx")
  merge_body(filled_docx, body_docx, body_marker, merged)

  # ---- 4. ask Word to rebuild the TOC on open ----------------------------------
  if (update_toc) {
    dir <- unpack(merged)
    sf  <- file.path(dir, "word", "settings.xml")
    st  <- paste(readLines(sf, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    if (!grepl("updateFields", st, fixed = TRUE)) {
      tag <- '<w:updateFields w:val="true"/>'
      # schema order: updateFields must come before these elements
      m <- regexpr("<w:(hdrShapeDefaults|footnotePr|endnotePr|compat)[ >/]", st)
      st <- if (m > 0) paste0(substr(st, 1, m - 1), tag, substr(st, m, nchar(st)))
            else sub("</w:settings>", paste0(tag, "</w:settings>"), st, fixed = TRUE)
      writeLines(st, sf, useBytes = TRUE)
    }
    repack(dir, merged)
  }

  # MESSAGE on fields being filled
  file.copy(merged, output, overwrite = TRUE)
  message("Written: ", output, "\nFilled: ", length(filled), " of ",
          length(unique(seen)), " fields. Untouched: ",
          paste(setdiff(unique(seen), filled), collapse = "; "))

  invisible(output)
}
# }}}
