# ---------------------------------------------------------------------------
# Import & geocode Comptroller Annual Report MILCON projects
#
# - Reads every .xlsx / .xls in the Comptroller Annual Reports folder
#   (PDFs and FY1998/FY1999 are skipped)
# - Standardizes column names so synonymous headers across years collapse
#   into a single canonical column
# - Row-binds everything into one long file of military construction projects
# - Geocodes each project (lon/lat) from its city/state/country
# - Adds country name + Gleditsch & Ward code via {countrycode}
# - Final output is restricted to <=20 analytic columns
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(purrr)
  library(readxl)
  library(fs)
  library(tidygeocoder)
  library(countrycode)
  library(readr)
})

# ---- 1. Paths -------------------------------------------------------------

src_dir <- "~/Library/CloudStorage/Dropbox/Projects/Troop Data/Data Files/Construction Spending/Comptroller Annual Reports"
src_dir <- path_expand(src_dir)

out_dir <- "~/Library/CloudStorage/Dropbox/R/troopdata/data-raw"
out_dir <- path_expand(out_dir)

stopifnot(dir_exists(src_dir))

files <- dir_ls(src_dir, recurse = TRUE, type = "file",
                regexp = "\\.(xlsx|xls)$", ignore.case = TRUE)

# FY1998 and FY1999 reports do not contain comparable spending information,
# so drop them before reading anything.
skip_re <- "(?i)fy[\\s_-]?(1998|1999|98|99)\\b"
dropped <- files[str_detect(path_file(files), skip_re)]
files   <- files[!str_detect(path_file(files), skip_re)]

if (length(dropped))
  message("Skipping (FY1998/FY1999):\n  ",
          paste(path_file(dropped), collapse = "\n  "))
message(sprintf("Found %d files to import.", length(files)))

# ---- 2. Helpers -----------------------------------------------------------

# Pull a 4-digit fiscal year out of any string (sheet name, filename, etc.).
# Handles "FY2021", "FY 21", "2021", "FY21 MILCON", etc. Two-digit years are
# expanded with a 1950 pivot: 00-49 -> 2000s, 50-99 -> 1900s.
extract_fy <- function(x) {
  x <- as.character(x)

  m1 <- str_match(x, "(?i)FY[\\s_-]?(\\d{2,4})")[, 2]
  m2 <- str_match(x, "\\b(19|20)\\d{2}\\b")[, 1]
  m3 <- str_match(x, "\\b(\\d{2})\\b")[, 2]

  raw <- coalesce(m1, m2, m3)
  fy  <- suppressWarnings(as.integer(raw))
  fy  <- ifelse(!is.na(fy) & fy < 100,
                ifelse(fy < 50, 2000L + fy, 1900L + fy),
                fy)
  fy
}

# Some old .xls files (BIFF5 / Excel 95-97) trip up libxls inside readxl.
# Try a few fallbacks before giving up:
#   1) readxl::read_excel                    -- the fast path
#   2) Convert .xls -> .xlsx via LibreOffice (if installed) and retry
#   3) gdata::read.xls (uses Perl)            -- if {gdata} is installed
have_libreoffice <- function() {
  bin <- Sys.which(c("libreoffice", "soffice"))
  bin <- bin[nzchar(bin)]
  if (length(bin)) return(unname(bin[1]))
  mac <- "/Applications/LibreOffice.app/Contents/MacOS/soffice"
  if (file.exists(mac)) return(mac)
  NA_character_
}

convert_xls_to_xlsx <- function(path) {
  lo <- have_libreoffice()
  if (is.na(lo)) return(NA_character_)
  tmpdir <- tempfile("xls2xlsx_"); dir.create(tmpdir)
  status <- suppressWarnings(system2(
    lo,
    args = c("--headless", "--convert-to", "xlsx", "--outdir", shQuote(tmpdir),
             shQuote(path)),
    stdout = FALSE, stderr = FALSE
  ))
  out <- path(tmpdir, path_ext_set(path_file(path), "xlsx"))
  if (status == 0 && file.exists(out)) out else NA_character_
}

# Find the actual header row in a sheet read with col_names = FALSE.
#
# Comptroller workbooks frequently put a title (and sometimes subtitles)
# above the column headers. The header row is the first row that
#   (a) has at least 3 non-empty cells,
#   (b) is mostly text (not numbers), and
#   (c) covers at least half the populated width of the sheet.
detect_header_row <- function(df, max_check = 20) {
  if (is.null(df) || nrow(df) == 0) return(NA_integer_)
  n_check <- min(max_check, nrow(df))
  width   <- max(rowSums(!is.na(df) & df != ""), na.rm = TRUE)
  if (!is.finite(width) || width < 2) return(NA_integer_)

  for (i in seq_len(n_check)) {
    row <- as.character(unlist(df[i, ]))
    row[is.na(row)] <- ""
    nonempty <- row[row != ""]
    if (length(nonempty) < 3 || length(nonempty) < 0.5 * width) next
    text_share <- mean(suppressWarnings(is.na(as.numeric(nonempty))))
    if (text_share >= 0.7) return(i)
  }
  1L  # give up and use the first row
}

# Apply detected header to a raw sheet, drop empty cols, fill blank names.
# Preserves the ORIGINAL column names from the source workbook -- no
# snake_casing, no janitor mangling. Only collapses runs of whitespace and
# inserts a placeholder when a header cell is genuinely blank.
clean_excel_sheet <- function(raw) {
  if (is.null(raw) || nrow(raw) == 0) return(NULL)

  hdr_i <- detect_header_row(raw)
  if (is.na(hdr_i)) return(NULL)

  nm <- as.character(unlist(raw[hdr_i, ]))
  nm <- str_squish(nm)            # tidy whitespace; keep case & punctuation
  nm[is.na(nm)] <- ""

  df <- raw[-seq_len(hdr_i), , drop = FALSE]

  # Drop columns whose header is blank AND whose body is entirely empty.
  body_empty <- vapply(df, function(x) all(is.na(x) | str_squish(x) == ""),
                       logical(1))
  drop <- nm == "" & body_empty
  df <- df[, !drop, drop = FALSE]
  nm <- nm[!drop]

  # Anything still blank gets a stable placeholder.
  nm[nm == ""] <- paste0("unnamed_col_", which(nm == ""))
  names(df) <- make.unique(nm)

  df[] <- lapply(df, as.character)

  # Drop all-NA rows
  keep_row <- rowSums(!is.na(df) & df != "") > 0
  df <- df[keep_row, , drop = FALSE]
  if (nrow(df) == 0) return(NULL)
  tibble::as_tibble(df, .name_repair = "minimal")
}

read_xls_robust <- function(path, sheet) {
  read_raw <- function(p) {
    tryCatch(
      read_excel(p, sheet = sheet, col_names = FALSE,
                 col_types = "text", .name_repair = "minimal"),
      error = function(e) e
    )
  }

  # 1) readxl directly
  raw <- read_raw(path)
  if (inherits(raw, "data.frame")) return(clean_excel_sheet(raw))

  # 2) LibreOffice conversion -> readxl
  conv <- convert_xls_to_xlsx(path)
  if (!is.na(conv)) {
    raw2 <- read_raw(conv)
    if (inherits(raw2, "data.frame")) return(clean_excel_sheet(raw2))
  }

  # 3) gdata::read.xls (Perl-based)
  if (requireNamespace("gdata", quietly = TRUE)) {
    raw3 <- tryCatch(
      gdata::read.xls(path, sheet = sheet, header = FALSE,
                      stringsAsFactors = FALSE),
      error = function(e) e
    )
    if (inherits(raw3, "data.frame")) {
      raw3[] <- lapply(raw3, as.character)
      return(clean_excel_sheet(tibble::as_tibble(raw3)))
    }
  }

  warning(sprintf("Could not read sheet '%s' of %s", sheet, path_file(path)),
          call. = FALSE)
  NULL
}

# Try to list the sheets; if even excel_sheets() fails, try a LibreOffice
# conversion first so the rest of the function can work off the .xlsx.
list_sheets_robust <- function(path) {
  res <- tryCatch(excel_sheets(path), error = function(e) e)
  if (is.character(res)) return(list(path = path, sheets = res))

  conv <- convert_xls_to_xlsx(path)
  if (!is.na(conv)) {
    res2 <- tryCatch(excel_sheets(conv), error = function(e) e)
    if (is.character(res2)) return(list(path = conv, sheets = res2))
  }
  NULL
}

# Read the FIRST sheet of an Excel workbook. Later sheets in these
# workbooks are archival copies of prior years that would duplicate other
# files in the folder, so we only take the first sheet (which is the
# current year's data). Fiscal year is taken from the sheet name when
# possible, otherwise from the filename.
read_excel_all <- function(path) {
  info <- list_sheets_robust(path)
  if (is.null(info)) {
    warning(sprintf("Skipping %s -- could not open workbook.", path_file(path)),
            call. = FALSE)
    return(NULL)
  }
  fy_from_file <- extract_fy(path_file(path))

  sh <- info$sheets[1]
  if (length(info$sheets) > 1) {
    message(sprintf("  %s: using first sheet '%s' (ignoring %d others)",
                    path_file(path), sh, length(info$sheets) - 1))
  }

  df <- read_xls_robust(info$path, sh)
  if (is.null(df) || nrow(df) == 0) return(NULL)

  fy_sheet <- extract_fy(sh)
  df$source_sheet <- sh
  df$fiscal_year  <- if (!is.na(fy_sheet)) fy_sheet else fy_from_file
  df
}

# NOTE: PDF parsing was removed -- the Comptroller PDFs have inconsistent
# column structure that produced unusable headers when text-extracted.
# Only .xlsx and .xls files are read.

# ---- Column-name standardization ------------------------------------------
#
# Each year's workbook uses slightly different headers ("Project" vs
# "Project Title", "Location" vs "Location Title", "Host Nation" vs
# "Country"). To avoid the bound result having a sea of half-empty
# parallel columns, we normalize known variants to a small set of
# canonical snake_case names BEFORE stacking. Anything not in the table
# keeps its original header text.
#
# Extend COLNAME_CANONICAL whenever a new variant surfaces. Keys must be
# the *normalized* form of the source header (lowercased, non-alphanumeric
# runs collapsed to "_", leading/trailing "_" removed).

COLNAME_CANONICAL <- c(
  # ---- service / branch / component ----
  service                       = "service",
  branch                        = "service",
  component                     = "service",
  dod_component                 = "service",
  military_service              = "service",
  military_department           = "service",
  department                    = "service",
  agency                        = "service",

  # ---- country ----
  country                       = "country",
  country_name                  = "country",
  host_nation                   = "country",
  host_country                  = "country",
  nation                        = "country",
  foreign_country               = "country",
  country_territory             = "country",

  # ---- state ----
  state                         = "state",
  us_state                      = "state",
  u_s_state                     = "state",
  state_name                    = "state",
  state_or_territory            = "state",
  state_territory               = "state",
  state_or_province             = "state",
  province                      = "state",

  # ---- city ----
  city                          = "city",
  town                          = "city",
  locality                      = "city",

  # ---- installation ----
  installation                  = "installation",
  installation_name             = "installation",
  base                          = "installation",
  base_name                     = "installation",
  station                       = "installation",
  site                          = "installation",
  facility                      = "installation",
  facility_name                 = "installation",

  # ---- location_title (a geographic descriptor distinct from city/state/country) ----
  location                      = "location_title",
  location_title                = "location_title",
  location_name                 = "location_title",
  geographic_location           = "location_title",

  # ---- project_title ----
  project                       = "project_title",
  project_title                 = "project_title",
  project_name                  = "project_title",
  title                         = "project_title",

  # ---- project_number ----
  project_number                = "project_number",
  project_no                    = "project_number",
  project_num                   = "project_number",
  pr_number                     = "project_number",
  pr_no                         = "project_number",
  prj_no                        = "project_number",

  # ---- category_code ----
  category_code                 = "category_code",
  cat_code                      = "category_code",
  ccn                           = "category_code",
  fac_code                      = "category_code",
  facility_code                 = "category_code",
  facility_category_code        = "category_code",

  # ---- budget_activity (numeric code) ----
  budget_activity               = "budget_activity",
  ba                            = "budget_activity",
  ba_number                     = "budget_activity",

  # ---- budget_activity_title (text description) ----
  budget_activity_title         = "budget_activity_title",
  ba_title                      = "budget_activity_title",

  # ---- description ----
  description                   = "description",
  project_description           = "description",
  scope                         = "description",
  scope_of_work                 = "description",

  # ---- authorization_amount ($000) ----
  authorization                 = "authorization_amount",
  authorization_amount          = "authorization_amount",
  auth                          = "authorization_amount",
  auth_amount                   = "authorization_amount",
  auth_amt                      = "authorization_amount",
  authorized                    = "authorization_amount",
  authorized_amount             = "authorization_amount",
  auth_000                      = "authorization_amount",
  authorization_000             = "authorization_amount",

  # ---- appropriation_amount ($000) ----
  appropriation                 = "appropriation_amount",
  appropriation_amount          = "appropriation_amount",
  appn                          = "appropriation_amount",
  appn_amount                   = "appropriation_amount",
  appn_amt                      = "appropriation_amount",
  appropriated                  = "appropriation_amount",
  appropriated_amount           = "appropriation_amount",
  appn_000                      = "appropriation_amount",
  appropriation_000             = "appropriation_amount",

  # ---- request_amount ($000) ----
  request                       = "request_amount",
  request_amount                = "request_amount",
  request_amt                   = "request_amount",
  requested                     = "request_amount",
  requested_amount              = "request_amount",
  budget_request                = "request_amount",
  president_s_request           = "request_amount",
  presidents_request            = "request_amount",
  fy_request                    = "request_amount",

  # ---- current_estimate ($000) ----
  current_estimate              = "current_estimate",
  current_working_estimate      = "current_estimate",
  cwe                           = "current_estimate",
  current_est                   = "current_estimate",

  # ---- congressional_action ($000) ----
  congressional_action          = "congressional_action",
  conf                          = "congressional_action",
  conference                    = "congressional_action",
  conference_amount             = "congressional_action",

  # ---- obligation_amount ($000) ----
  obligation                    = "obligation_amount",
  obligations                   = "obligation_amount",
  obligation_amount             = "obligation_amount",
  obligated                     = "obligation_amount",
  obligated_amount              = "obligation_amount"
  # NOTE: deliberately no mapping for "FY" / "Fiscal Year" -- those would
  # collide with the lower-case `fiscal_year` column the loader derives
  # from the workbook itself.
)

normalize_name <- function(x) {
  x <- as.character(x)
  # Strip fiscal-year / year tokens anywhere in the header. These mark
  # which report the column came from rather than the column's meaning,
  # so "FY2025 Authorization Amount" normalizes the same as
  # "Authorization Amount".
  x <- gsub("(?i)\\bFY[\\s_-]?\\d{2,4}\\b", "", x, perl = TRUE)
  x <- gsub("\\b(19|20)\\d{2}\\b",         "", x, perl = TRUE)
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  gsub("^_+|_+$", "", x)
}

standardize_names <- function(df, file_label = NULL) {
  if (is.null(df) || ncol(df) == 0) return(df)
  orig <- names(df)
  norm <- normalize_name(orig)
  prop <- ifelse(norm %in% names(COLNAME_CANONICAL),
                 unname(COLNAME_CANONICAL[norm]),
                 orig)

  # Within-file collision guard.
  #
  # If two source columns in the SAME file would both be renamed to the
  # same canonical name, they almost always represent different things
  # (e.g. "Budget Activity" = numeric code, "Budget Activity Title" = its
  # description; or "Authorization" vs "Appropriation" both mapped to
  # "cost"). To prevent silently collapsing distinct data:
  #
  #   - If exactly one of the colliding columns has a header whose
  #     normalized form IS the canonical name (an exact synonym), give it
  #     the canonical name and revert all others to their originals.
  #   - Otherwise revert ALL colliding columns to their originals so the
  #     distinct data is preserved as-is.
  for (canon in unique(prop[prop != orig])) {
    claimants <- which(prop == canon)
    if (length(claimants) <= 1) next

    exact <- claimants[norm[claimants] == canon]
    if (length(exact) == 1) {
      losers <- setdiff(claimants, exact)
      prop[losers] <- orig[losers]
    } else {
      prop[claimants] <- orig[claimants]
    }
    warning(sprintf(
      "%s: multiple columns map to '%s' (%s); keeping them separate.",
      file_label %||% "file", canon,
      paste0("'", orig[claimants], "'", collapse = ", ")),
      call. = FALSE)
  }

  names(df) <- make.unique(prop)
  df
}

# Tiny null-coalesce helper used above
`%||%` <- function(a, b) if (is.null(a)) b else a

read_one <- function(path) {
  ext <- tolower(path_ext(path))
  df  <- tryCatch(
    switch(ext,
           xlsx = read_excel_all(path),
           xls  = read_excel_all(path),
           NULL),
    error = function(e) {
      warning(sprintf("Failed to read %s: %s",
                      path_file(path), conditionMessage(e)),
              call. = FALSE)
      NULL
    }
  )
  if (is.null(df) || nrow(df) == 0) return(NULL)
  df <- standardize_names(df, file_label = path_file(path))
  df |>
    mutate(
      source_file = path_file(path),
      across(everything(), as.character)
    )
}

# ---- 3. Import & stack ----------------------------------------------------

milcon_raw <- map_dfr(files, read_one)
message(sprintf("Imported %d total rows across %d files.",
                nrow(milcon_raw), length(unique(milcon_raw$source_file))))

# ---- 4. Identify geographic columns --------------------------------------
#
# Use STRICT geographic columns for geocoding + countrycode. We deliberately
# exclude installation / base / facility / site columns -- those contain
# names like "Naval Air Weapons Station China Lake" that fool fuzzy matching
# (countrycode would happily see "China" in the name and assign CHN).

# Headers were standardized to canonical snake_case names before binding,
# so we match the canonical names directly here. The "(\\.\\d+)?$" suffix
# tolerates make.unique() de-duplicated forms (e.g. "country.1") that can
# arise when a single source file used two synonymous headers.
country_pat      <- "^country(\\.\\d+)?$"
state_pat        <- "^state(\\.\\d+)?$"
city_pat         <- "^city(\\.\\d+)?$"
location_pat     <- "^location_title(\\.\\d+)?$"
installation_pat <- "^installation(\\.\\d+)?$"

pick_cols <- function(df, pat) grep(pat, names(df), value = TRUE, perl = TRUE)

# Coalesce across a group of columns: first non-empty value per row.
coalesce_cols <- function(df, cols) {
  if (length(cols) == 0) return(rep(NA_character_, nrow(df)))
  m <- as.matrix(df[, cols, drop = FALSE])
  m[is.na(m) | str_squish(m) == ""] <- NA
  apply(m, 1, function(r) {
    r <- r[!is.na(r)]
    if (length(r) == 0) NA_character_ else str_squish(r[1])
  })
}

milcon <- milcon_raw |>
  mutate(
    country_raw      = coalesce_cols(milcon_raw, pick_cols(milcon_raw, country_pat)),
    state_raw        = coalesce_cols(milcon_raw, pick_cols(milcon_raw, state_pat)),
    city_raw         = coalesce_cols(milcon_raw, pick_cols(milcon_raw, city_pat)),
    location_raw     = coalesce_cols(milcon_raw, pick_cols(milcon_raw, location_pat)),
    installation_raw = coalesce_cols(milcon_raw, pick_cols(milcon_raw, installation_pat))
  )

# Geocoding address: city + state + country (+ generic location text).
# Installation/base names are NOT included -- they introduce false matches.
milcon <- milcon |>
  mutate(
    geo_address = pmap_chr(
      list(city_raw, state_raw, country_raw, location_raw),
      function(city, state, country, location) {
        parts <- c(city, state, country, location)
        parts <- parts[!is.na(parts) & str_squish(parts) != ""]
        if (length(parts) == 0) return(NA_character_)
        str_squish(paste(unique(parts), collapse = ", "))
      }
    )
  )

# ---- 5. Country name + Gleditsch & Ward code -----------------------------
#
# Use the explicit country column only -- never the installation/project text.

milcon <- milcon |>
  mutate(
    iso3c = countrycode(
      sourcevar   = country_raw,
      origin      = "country.name",
      destination = "iso3c",
      warn        = FALSE
    ),
    country_name = countrycode(iso3c, "iso3c", "country.name", warn = FALSE),
    gwcode       = countrycode(iso3c, "iso3c", "gwn",          warn = FALSE)
  )

# ---- 6. Geocode ----------------------------------------------------------
#
# Geocode unique addresses once, then join back. Uses OSM/Nominatim
# (free, ~1 req/sec). Swap method to "arcgis" or "google" for higher volume.

unique_locs <- tibble(geo_address = unique(milcon$geo_address)) |>
  filter(!is.na(geo_address))

geo <- unique_locs |>
  tidygeocoder::geocode(
    address = geo_address,
    method  = "osm",
    lat     = "latitude",
    long    = "longitude",
    quiet   = FALSE
  )

milcon <- milcon |> left_join(geo, by = "geo_address")

# ---- 7. Final column selection (<=20) ------------------------------------
#
# Keep only the canonical analytic columns. `any_of()` silently drops any
# that weren't present in the source data.

final_cols <- c(
  "fiscal_year",            # derived from sheet/filename
  "source_file",
  "service",
  "installation",
  "city",
  "state",
  "country",
  "country_name",           # cleaned via {countrycode}
  "iso3c",
  "gwcode",                 # Gleditsch & Ward
  "latitude",
  "longitude",
  "project_title",
  "category_code",
  "budget_activity",
  "budget_activity_title",
  "authorization_amount",
  "appropriation_amount",
  "request_amount",
  "current_estimate"
)

milcon_final <- milcon |> select(any_of(final_cols))

# ---- 8. Write outputs ----------------------------------------------------

write_csv(milcon_final, path(out_dir, "comptroller_milcon_all.csv"))
write_csv(milcon_raw,   path(out_dir, "comptroller_milcon_raw.csv"))

message("Done. Wrote:")
message("  ", path(out_dir, "comptroller_milcon_all.csv"))
message("  ", path(out_dir, "comptroller_milcon_raw.csv"))
