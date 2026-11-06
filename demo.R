# demo.R - Demonstration of wmrkdown::presentation
# 
# This script demonstrates how to:
# 1. Create a new WUR-styled Beamer presentation using wmrkdown
# 2. Render it to PDF

# Load required packages
library(rmarkdown)
library(wmrkdown)

# Create a temporary directory for the demo
demo_dir <- tempdir()
demo_file <- file.path(demo_dir, "demo_presentation.Rmd")

cat("Creating demo presentation at:", demo_file, "\n")

# Method 1: Use rmarkdown::draft() to create from template
# This creates a new Rmd file from the wmrkdown presentation template
rmarkdown::draft(
  file = demo_file,
  template = "presentation",
  package = "wmrkdown",
  edit = FALSE
)

cat("\n✓ Created presentation Rmd file\n")
cat("  Location:", demo_file, "\n")

# Fix the skeleton template - replace the broken include_graphics call with a working example
cat("\nFixing template for demo...\n")
rmd_content <- readLines(demo_file)

# Replace the include_graphics line with a simple plot
rmd_content <- gsub(
  'include_graphics\\("report/\\.png"\\)',
  'plot(1:10, main="Example Plot")',
  rmd_content
)

writeLines(rmd_content, demo_file)
cat("✓ Template fixed\n")

# View the created file structure
cat("\nContents of demo directory:\n")
print(list.files(demo_dir, pattern = "demo_presentation", full.names = TRUE))

# Method 2: Render the presentation to PDF
cat("\n" , rep("-", 50), "\n", sep = "")
cat("Rendering presentation to PDF...\n")
cat(rep("-", 50), "\n", sep = "")

output_file <- rmarkdown::render(
  input = demo_file,
  quiet = FALSE
)

cat("\n✓ Presentation rendered successfully!\n")
cat("  PDF output:", output_file, "\n")

# Open the PDF automatically based on OS
cat("\nOpening PDF...\n")
if (.Platform$OS.type == "windows") {
  # Windows
  shell.exec(output_file)
} else if (Sys.info()["sysname"] == "Darwin") {
  # macOS
  system2("open", shQuote(output_file))
} else {
  # Linux
  system2("xdg-open", shQuote(output_file))
}
cat("✓ PDF opened in default viewer\n")

cat("\n" , rep("=", 50), "\n", sep = "")
cat("DEMO COMPLETE\n")
cat(rep("=", 50), "\n", sep = "")
cat("\nSummary:\n")
cat("  - Template used: wmrkdown::presentation\n")
cat("  - Source Rmd:   ", demo_file, "\n")
cat("  - Output PDF:   ", output_file, "\n")
cat("\nYou can now open the PDF to view the rendered presentation.\n")
