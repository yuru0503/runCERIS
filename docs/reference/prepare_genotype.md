# Prepare genotype matrix for genomic prediction

Ensures genotype matrix is properly oriented (lines as rows) and filters
to lines present in the trait data.

## Usage

``` r
prepare_genotype(genotype, line_codes)
```

## Arguments

- genotype:

  Matrix with line_code as rownames or first column

- line_codes:

  Character vector of line codes from trait data

## Value

Numeric matrix with matching line_codes as rownames

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
SNPs <- prepare_genotype(d$genotype, unique(exp_trait$line_code))
dim(SNPs)
#> [1]  237 1462
```
