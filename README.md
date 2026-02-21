
# wmrkdown

<!-- badges: start -->
<!-- badges: end -->

The goal of wmrkdown is to provide `rmarkdown` versions of various WMR document templates. Currently, a template exists for creating a WUR-style presentation using markdown (md) or R markdown (Rmd).

## Installation

You can install wmrkdown from [WUR git](https://git.wur.nl/wmrkdown/wmrkdown) with:

``` r
devtools::install_git("https://git.wur.nl/wmrkdown/wmrkdown")
```

Make sure the required dependencies are available in your system:

``` r
install.packages(c("rmarkdown", "knitr"))
``` 

If you do not have LaTeX installed in your system, you can dio use via the tinytex packages

```r
install.packages("tinytex")
tinytex::install_tinytex()
```

## Example

To create a new presentation, called "example", you can call

``` r
library(wmrkdown)

draft("example.Rmd",
  template="wur", package="wmrkdown")
```

A folder caled `example` will be created containing the following files:

- `example.Rmd`, the R markdown file for you to edit.
- `default.jpg`, the picture for the left handside of the front page.
- `front.jpg`, the picture for the right handside of the front page, taken from the WUR powerpoint template.
- `logo.png`, WUR's logo.
- `beamerthemewurnew.sty`, the LaTeX style file for WUR's presentation.

You are free to change the pictures, as long as you use the same names.

After working on the Rmd file, you can create the PDF output using

```r
render("example.Rmd")
```
