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
  library(tictoc)
})


# First read in a list of relevant files --------------------------------------

file.list <- list.files(
  "~/Dropbox/Projects/Troop Data/Data Files/Construction Spending/Comptroller Annual Reports/",
  full.names = TRUE
)


# Read EVERY sheet in EVERY workbook ------------------------------------------
#
# Each C-1 workbook holds one sheet per fiscal year, plus supplemental sheets
# (OCO, Emergency, Enactment, Mandatory Reconciliation). The previous version
# called read_xls(f) / read_xlsx(f, skip = 1) with no `sheet` argument, so it
# read sheet 1 only and discarded 54 sheets and 9,340 rows -- including all of
# FY2015 and FY2016 (sheets 2 and 3 of c1(8).xlsx and c1a(2).xlsx) and every
# supplemental OCO / Emergency sheet.
#
# It also called discard_at(c(1, 2)) on each list to drop FY1998 and FY1999.
# That is correct for the .xls list, where those two sort first, but on the
# .xlsx list it dropped two arbitrary workbooks by position. Files are now
# excluded by NAME instead.

excel.files <- file.list[grepl("\\.xlsx?$", file.list, ignore.case = TRUE)]

# FY1998 and FY1999 contain no usable spending data.
excel.files <- excel.files[
  !grepl("fy1998|fy1999", basename(excel.files), ignore.case = TRUE)
]

# fy2001_c1.xls is not an OLE2 workbook like its siblings and libxls cannot open
# it at all, so readxl::excel_sheets() aborts on it. The previous version hid
# this inside possibly(read_xls), which is why FY2000 -- a year that exists only
# in that workbook -- never reached the data. It is recovered from CSV below.
list_sheets_safely <- function(f) {
  sheets <- possibly(\() readxl::excel_sheets(f))()
  if (is.null(sheets)) {
    warning("Could not open workbook, skipping: ", basename(f), call. = FALSE)
    return(tibble::tibble(path = character(), sheet = character()))
  }
  tibble::tibble(path = f, sheet = sheets)
}

sheet.index <- purrr::map_dfr(excel.files, list_sheets_safely) %>%
  dplyr::filter(!grepl("user|guide|cover|notes", sheet, ignore.case = TRUE))

# Column names for the FY2002 and FY2003 workbooks, which carry a blank or
# partial first row instead of a usable header. Keyed by file name rather than by
# list position: the original indexed files.xls[c(1:2)], which landed on these
# two only because the FY2001 workbook silently failed to read.
names.2002.2003 <- c(
  "fiscal_year",
  "location_code",
  "location_title",
  "project_number",
  "project_title",
  "state_country",
  "appn",
  "comp",
  "appn_title",
  "ba",
  "ba_title",
  "transaction_type",
  "auth_amount",
  "auth_for_appn",
  "appn_amount",
  "toa_amount"
)

# Every sheet is read and then coerced to character so that heterogeneous sheets
# can be bound together. as.character() is the wrong tool for that: R renders some
# round doubles in scientific notation, so as.character(100000) is "1e+05", and the
# numeric clean-up further down strips everything that is not a digit, a dot or a
# minus -- turning "1e+05" into "105". That quietly cut 24 project amounts by three
# orders of magnitude: $100M read as $105K, $200M as $205K, $800M as $805K, about
# $3.4 billion in total. formatC() with a fixed format never uses an exponent.
as_character_fixed <- function(x) {

  if (!is.numeric(x)) {
    return(as.character(x))
  }

  out <- trimws(formatC(x, format = "f", drop0trailing = TRUE))
  out[is.na(x)] <- NA_character_
  out

}

read_c1_sheet <- function(path, sheet) {
  is.xlsx <- grepl("\\.xlsx$", path, ignore.case = TRUE)

  reader <- if (is.xlsx) {
    possibly(\() readxl::read_xlsx(path, sheet = sheet, skip = 1))
  } else {
    possibly(\() readxl::read_xls(path, sheet = sheet))
  }

  d <- reader()

  if (is.null(d) || nrow(d) == 0 || ncol(d) == 0) {
    return(NULL)
  }

  # The FY2002/FY2003 header fix, applied by file name.
  if (grepl("fy2002_c1|fy2003_c1", basename(path)) &&
      ncol(d) == length(names.2002.2003)) {
    d <- set_names(d, names.2002.2003)
  }

  d <- janitor::clean_names(d)

  # The FY2024-FY2026 workbooks prefix their amount headers with the fiscal year
  # ("FY2026 Authorization Amount"), which clean_names() turns into
  # fy2026_authorization_amount. That matches nothing in the merge vocabulary
  # below, so every amount for FY2024-FY2026 was dropped: all 440 FY2026 rows had
  # no money values at all, and FY2024 and FY2025 kept only the handful of rows
  # that came from an older report.
  names(d) <- sub("^fy[0-9]{4}_", "", names(d))

  # The supplemental exhibits prefix their amount headers with the exhibit name
  # instead ("Overseas Operations Costs (OOC) Appn Amount", "Reconciliation Appn
  # Amount"), which left 62 rows on three sheets with no amounts at all. Only
  # these two prefixes are stripped, by name: a general rule that collapsed any
  # column ending in "appropriation_amount" would merge
  # authorized_for_appropriation_amount into appropriation_amount on ten sheets.
  names(d) <- sub("^(overseas_operations_costs_ooc|reconciliation)_", "", names(d))

  d %>%
    dplyr::mutate(dplyr::across(tidyselect::everything(), as_character_fixed)) %>%
    # Cells arrive with newlines, tabs, double spaces and stray leading or
    # trailing blanks from the spreadsheets. Left alone they split otherwise
    # identical labels: 232 project titles carried an internal double space, 31
    # held a newline, and one sheet name was " FY 2019 OCO" with a leading space.
    dplyr::mutate(dplyr::across(tidyselect::where(is.character), stringr::str_squish)) %>%
    dplyr::mutate(
      source_file = basename(path),
      # NOT squished: one workbook names a sheet " FY 2019 OCO" with a leading
      # space, and source_sheet has to stay byte-identical to the sheet name or a
      # row can no longer be traced back to the cell it came from.
      source_sheet = sheet,
      # Position of the row in the sheet as read, counting from 1 below the header.
      # A report can list two projects that agree in every column -- two $148
      # million "Barracks & Dining" complexes at Fort Bliss in FY2009 -- and this
      # is what keeps them two rows and lets either be found again in the workbook.
      source_row = dplyr::row_number()
    )
}

files.combined.df <- purrr::map2(
  sheet.index$path,
  sheet.index$sheet,
  read_c1_sheet
) %>%
  purrr::compact() %>%
  dplyr::bind_rows() %>%
  dplyr::select(sort(names(.)))

# The FY2001 workbook, recovered to CSV because R cannot open the .xls. It holds
# FY2000 (425 rows) and FY2001 (309 rows); FY2000 appears in no other report.
# Regenerate with data-raw/recover_fy2001_c1.py if the workbook is ever replaced.
fy2001.path <- here::here("data-raw/fy2001_c1_recovered.csv")

if (file.exists(fy2001.path)) {
  fy2001.df <- readr::read_csv(fy2001.path, col_types = readr::cols(.default = "c")) %>%
    janitor::clean_names() %>%
    dplyr::mutate(
      source_file = "fy2001_c1.xls",
      source_sheet = "Sheet 1",
      source_row = dplyr::row_number()
    )

  files.combined.df <- dplyr::bind_rows(files.combined.df, fy2001.df) %>%
    dplyr::select(sort(names(.)))
} else {
  warning("fy2001_c1_recovered.csv is missing; FY2000 will be absent.",
          call. = FALSE)
}

message("Read ", nrow(sheet.index), " sheets from ", length(excel.files),
        " workbooks: ", nrow(files.combined.df), " rows.")



# Coalesce columns with different names but same values into a single column
#
merge_cols <- function(df, into, from) {
  df[[into]] <- do.call(coalesce, df[, from, drop = FALSE])
  df[, !(names(df) %in% setdiff(from, into))]
}

files.combined.df <- files.combined.df |>
  merge_cols("account_name", c("account", "account_title")) |>
  merge_cols("appn_amount", c("appropriation_amount", "appn_amount", "appn")) |>

  # ---- authorization ----
  merge_cols(
    "auth_appn_amount",
    c(
      "auth_for_appn",
      "auth_for_appn_amount",
      "authorized_for_appn",
      "authorization_of_approp_amount",
      "authorization_of_appropriation_amount",
      "authorized_for_appropriation_amount"
    )
  ) |>
  # auth_amount must be in its own `from` list. Without it, merge_cols overwrote
  # the column with a coalesce of the two alternative spellings only, discarding
  # every value from the workbooks that already call it auth_amount -- which is
  # why authorizations were missing for FY2012-FY2021.
  merge_cols("auth_amount", c("auth_amount", "authorization", "authorization_amount")) |>

  # ---- budget activity (code vs title) ----
  merge_cols("budget_activity", c("budget_activity", "ba")) |>
  # budget_activity_short_title is not a second, shorter label: it is the same
  # field under a different header in the FY2014-FY2021 workbooks. No row has
  # both (3,460 rows carry only the short form, the rest only the long one), so
  # leaving it out of this merge put the budget activity of those 3,460 rows in a
  # column get_builddata() never filters on.
  merge_cols(
    "budget_activity_title",
    c("budget_activity_title", "ba_title", "budget_activity_short_title")
  ) |>

  # ---- project (number vs title) ----
  # construction_project is the project identifier in the FY2012-FY2026 workbooks,
  # the same field project_number holds in the earlier ones. No row has both
  # (6,890 rows carry only project_number, 5,820 only construction_project), so
  # leaving them apart meant the project ID was missing for either half of the
  # series depending on which column you looked at.
  merge_cols("project_number", c("project_number", "construction_project")) |>
  merge_cols(
    "project_title",
    c("project_title", "construction_project_title")
  ) |>

  # ---- facility category (code vs title) ----
  merge_cols(
    "facility_category_code",
    c("facility_category_code", "facility_category", "category_code")
  ) |>
  # facility_group_title is deliberately NOT merged into facility_category_title.
  # They are different levels of the DoD facility taxonomy: the 3-digit facility
  # category code pairs with facility_category_title, while facility_group_title
  # is the coarse grouping (the code's hundreds series). Coalescing them made a
  # single code appear under several titles -- 211 as both "AIRCRAFT MAINTENANCE
  # FACILITIES" (its category) and "MAINTENANCE & PRODUCTION FACILITIES" (its
  # group). Every one of those collisions came from workbooks that report the
  # group rather than the category. Excluding them, all 143 codes in the data map
  # to exactly one category title.

  # ---- location ----
  # ---- facility group ----
  # "Fiscal Category Title" (c1(2).xlsx, FY2022-FY2024) and "Facility Group Title"
  # (fy2001, fy2009) are the same variable: 21 of their 24 values are identical
  # once case is set aside, and no row carries both. Merged.
  merge_cols("facility_group_title",
             c("facility_group_title", "fiscal_category_title")) |>
  merge_cols("location_name", c("location_title")) |>

  merge_cols("location_code", c("location", "location_code")) |>

  # ---- state / country ----
  # state_country_title is copied out first. Coalescing it into the two-letter
  # code discarded the only readable form of codes like ZU (Unspecified
  # Worldwide Locations), which have no ISO3C or gwcode to fall back on.
  (\(d) {
    if ("state_country_title" %in% names(d)) d$state_country_name <- d$state_country_title
    d
  })() |>
  merge_cols("state_country", c("state_country", "state_country_title")) |>

  # ---- organization ----
  # Sheets encode the services differently across years (ARMY vs A, NAVY vs N,
  # AF vs F, DEFW vs D), and these columns are merged without reconciling their
  # values, so organization = "A" matched only a quarter of Army rows. The
  # merged raw string is kept as organization_reported and harmonized below.
  #
  # "Treasury Agency" is the last column tried. The FY2005, FY2006, FY2007 and
  # FY2009 workbooks, which supply fiscal years 2004 to 2007, print the agency of
  # a Defense-wide line in "Organization" and leave that column empty on every
  # Army, Navy and Air Force line; the service is in "Treasury Agency" (A, N, F,
  # with D for Defense-wide). Without it organization was missing on all 2,136
  # service lines of those four years, $47.2 billion of appropriations, and
  # organization = "Army" returned 3, 2, 0 and 3 rows for FY2004 to FY2007. Where
  # a workbook prints both columns they agree on every service line (A beside
  # ARMY, N beside NAVY, F beside AF).
  merge_cols("organization", c("organization", "org", "mil_dept_dw", "comp", "treasury_agency")) |>

  # ---- total obligation authority ----
  merge_cols(
    "toa_amount",
    c("toa_amount", "toa", "total_obligation_authority",
      # FY2024 sheet of the FY2025 report: "PB Req w/ CR Adj Total Obligation
      # Authority". It is that sheet's TOA column.
      "pb_req_w_cr_adj_total_obligation_authority")
  ) %>%

  merge_cols("project_number", c("project", "project_number"))


# List of names to preserve for the final compilation.
names.preserve <- c(
  "fiscal_year",
  "appn_amount",
  "appn_title",
  "auth_amount",
  "auth_appn_amount",
  "budget_activity",
  "budget_activity_title",
  "budget_activity_title_reported",
  "classification",
  "comp",
  "dollar_type",
  "existing_mission",
  "facility_category_code",
  "facility_category_title",
  "facility_category_title_reported",
  "location_name_reported",
  "project_title_reported",
  "facility_group_title",
  "location_code",
  "location_name",
  "organization",
  "pe",
  "percent_recapitalization",
  "project",
  "project_number",
  "project_title",
  "state_country",
  "state_country_name",
  "state_country_sort",
  "toa_amount",
  "transaction_type",
  # provenance and derived flags
  "source_file",
  "source_sheet",
  "source_row",
  "report_year",
  "sheet_type",
  "organization_reported",
  "is_request"
)

# ----- Provenance, sheet type, structural cleanup, vintages ------------------

files.combined.df <- files.combined.df %>%
  dplyr::mutate(fiscal_year = suppressWarnings(as.numeric(
    gsub("[^0-9.\\-]", "", fiscal_year)
  ))) %>%
  # Report section headers and grand totals ("Total", "Total Obligational
  # Authority", "Military Construction, Navy") carry no fiscal year and no
  # location. Left in, they added roughly $69 billion of TOA that belongs to no
  # project, and two column-header remnants that the geocoder resolved to a
  # point off the coast of Nicaragua.
  dplyr::filter(!is.na(fiscal_year)) %>%
  # A second guard for a total line that does carry a fiscal year. It has to
  # look at the location as well as the title: a title that begins "Total" is
  # not enough, because "Total Army School System Facility" is a project. Testing
  # the title alone removed four of them from the data (Augusta MI in FY2002,
  # Springfield IL in FY2005, Fort Belvoir in FY2006, Camp Williams UT in
  # FY2007; $59.9 million of appropriations). A total line has no location.
  dplyr::filter(!(is.na(location_name) &
                    grepl("^\\s*total|obligational authority", project_title,
                          ignore.case = TRUE))) %>%
  # Which sheet a row came from. OCO, Emergency, Enactment and Mandatory
  # Reconciliation sheets are supplemental rather than base-budget construction;
  # they are kept, and labelled, so they can be included or excluded on purpose.
  # ("OOC" is a typo for OCO in the FY2023 workbook.)
  dplyr::mutate(sheet_type = dplyr::case_when(
    grepl("reconcil", source_sheet, ignore.case = TRUE) ~ "reconciliation",
    grepl("emergency", source_sheet, ignore.case = TRUE) ~ "emergency",
    grepl("enact", source_sheet, ignore.case = TRUE) ~ "enactment",
    grepl("OCO|OOC", source_sheet, ignore.case = TRUE) ~ "oco",
    TRUE ~ "base"
  )) %>%
  # A workbook's vintage is the latest fiscal year it covers, and within a
  # workbook the latest fiscal year is the budget request rather than an enacted
  # figure.
  dplyr::group_by(source_file) %>%
  dplyr::mutate(
    report_year = suppressWarnings(max(fiscal_year, na.rm = TRUE)),
    # A sheet that is itself a request is one too, whatever the year: "C1_2010_OCO_Req"
    # in the FY2011 workbook is headed "FY 2010 OCO Request". Its lines that are also
    # on the enacted sheets are dropped further down as restatements, and the 26 that
    # are on no other sheet stay in the data, so they have to carry the flag.
    is_request = fiscal_year == report_year | grepl("req", source_sheet, ignore.case = TRUE)
  ) %>%
  dplyr::ungroup()

# Budget activity labels are written differently in every era: case variants,
# truncations ("MAINTENANCE OF REAL PROPE"), abbreviations ("MAJOR CONST"),
# double spaces, and outright typos ("PLANING & DESIGN", "PRIVITIZATION",
# "Nato Sec Inv Ogm", "Intrest"). That left 103 distinct strings for about 40
# activities, so get_builddata(budget_activity = "MAJOR CONSTRUCTION") matched
# 8,740 rows and missed 3,712 more spelled another way. The reported string is
# kept in budget_activity_title_reported.
#
# Note that budget_activity (the number) is only meaningful within an
# appropriation account: BA 1 is Major Construction in the MILCON accounts but
# FY 2005 BRAC, New Construction or Direct Loan Subsidy in others. It is not a
# standalone key.
ba.canonical <- c(
  "major construction" = "MAJOR CONSTRUCTION",
  "major const" = "MAJOR CONSTRUCTION",
  "maj const" = "MAJOR CONSTRUCTION",
  "minor construction" = "MINOR CONSTRUCTION",
  "minor const" = "MINOR CONSTRUCTION",
  "new construction" = "NEW CONSTRUCTION",
  "fh newconstruct" = "NEW CONSTRUCTION",
  "fh new const" = "NEW CONSTRUCTION",
  "fh new constr" = "NEW CONSTRUCTION",
  "planning & design" = "PLANNING AND DESIGN",
  "planing & design" = "PLANNING AND DESIGN",
  "planning and design" = "PLANNING AND DESIGN",
  "planning" = "PLANNING",
  "design" = "DESIGN",
  "construction improvements" = "CONSTRUCTION IMPROVEMENTS",
  "operating expenses" = "OPERATING EXPENSES",
  "operating exp" = "OPERATING EXPENSES",
  "operation" = "OPERATIONS",
  "operations" = "OPERATIONS",
  "fho&m operations" = "OPERATIONS",
  "maintenance of real property" = "MAINTENANCE OF REAL PROPERTY",
  "maintenance of real prope" = "MAINTENANCE OF REAL PROPERTY",
  "maintenance" = "MAINTENANCE OF REAL PROPERTY",
  "fh maintenance" = "MAINTENANCE OF REAL PROPERTY",
  "leasing" = "LEASING",
  "utilities" = "UTILITIES",
  "supporting activities" = "SUPPORTING ACTIVITIES",
  "other operating costs" = "OTHER OPERATING COSTS",
  "other operating cost" = "OTHER OPERATING COSTS",
  "housing pvt support" = "HOUSING PRIVATIZATION SUPPORT",
  "housing privitization support" = "HOUSING PRIVATIZATION SUPPORT",
  "housing privatization support" = "HOUSING PRIVATIZATION SUPPORT",
  "family housing improvement fund" = "FAMILY HOUSING IMPROVEMENT FUND",
  "fam hsg imp fund" = "FAMILY HOUSING IMPROVEMENT FUND",
  "ford isl improvement fund" = "FORD ISLAND IMPROVEMENT FUND",
  "unaccompanied housing imp" = "UNACCOMPANIED HOUSING IMPROVEMENT",
  "fh post-acq const" = "POST-ACQUISITION CONSTRUCTION",
  "fh post-acq constr" = "POST-ACQUISITION CONSTRUCTION",
  "nato security investment program" = "NATO SECURITY INVESTMENT PROGRAM",
  "nato sec inv pgm" = "NATO SECURITY INVESTMENT PROGRAM",
  "nato sec inv ogm" = "NATO SECURITY INVESTMENT PROGRAM",
  "nato infrastructure" = "NATO SECURITY INVESTMENT PROGRAM",
  "fy 2005 brac" = "FY 2005 BRAC",
  "fy2005 brac" = "FY 2005 BRAC",
  "brac 2005" = "FY 2005 BRAC",
  "dod brac" = "DOD BRAC",
  "base closure i" = "BASE CLOSURE I",
  "base closure ii" = "BASE CLOSURE II",
  "base closure (ii)" = "BASE CLOSURE II",
  "base closure iii" = "BASE CLOSURE III",
  "base closure (iii)" = "BASE CLOSURE III",
  "base closure iv" = "BASE CLOSURE IV",
  "base closure (iv)" = "BASE CLOSURE IV",
  "base closure round iv" = "BASE CLOSURE IV",
  "global posture moves" = "GLOBAL POSTURE MOVES",
  "global posture" = "GLOBAL POSTURE MOVES",
  "mortgage insurance premiums" = "MORTGAGE INSURANCE PREMIUMS",
  "mortgage insurance premiu" = "MORTGAGE INSURANCE PREMIUMS",
  "payments to homeowner's" = "PAYMENTS TO HOMEOWNERS",
  "pay to homeownr" = "PAYMENTS TO HOMEOWNERS",
  "payment to homeowners (private sale and foreclosure assistan" = "PAYMENTS TO HOMEOWNERS",
  "payment to homeowners (private sale and foreclosure assistance)" = "PAYMENTS TO HOMEOWNERS",
  "interest payments, c&w housing" = "INTEREST PAYMENTS, C&W HOUSING",
  "interest payments, c&w ho" = "INTEREST PAYMENTS, C&W HOUSING",
  "direct loan subsidy" = "DIRECT LOAN SUBSIDY",
  "re-est dir loan subsidy" = "RE-ESTIMATE OF DIRECT LOAN SUBSIDY",
  "reestimate of direct loan subsidy" = "RE-ESTIMATE OF DIRECT LOAN SUBSIDY",
  "re-est loan guar subsidy" = "RE-ESTIMATE OF LOAN GUARANTEE SUBSIDY",
  "mods of dir loan subsidy" = "MODIFICATION OF DIRECT LOAN SUBSIDY",
  "modification of direct loan subsidy" = "MODIFICATION OF DIRECT LOAN SUBSIDY",
  "mods of loan guar subsidy" = "MODIFICATION OF LOAN GUARANTEE SUBSIDY",
  "int on re-est dir loan" = "INTEREST ON RE-ESTIMATE OF DIRECT LOAN SUBSIDY",
  "intrest on re-estimate of direct loan subsidy" = "INTEREST ON RE-ESTIMATE OF DIRECT LOAN SUBSIDY",
  "administrative expenses" = "ADMINISTRATIVE EXPENSES",
  "admin expns" = "ADMINISTRATIVE EXPENSES",
  "equity investments" = "EQUITY INVESTMENTS",
  "equity investment" = "EQUITY INVESTMENTS",
  "undistributed" = "UNDISTRIBUTED",
  "chem/demil const" = "CHEMICAL DEMILITARIZATION CONSTRUCTION",
  "maj rep const" = "MAJOR REPLACEMENT CONSTRUCTION",
  "foreign currency fluctuation" = "FOREIGN CURRENCY FLUCTUATION",
  "differential lease payments" = "DIFFERENTIAL LEASE PAYMENTS",
  "acquisition of real property" = "ACQUISITION OF REAL PROPERTY",
  "varlocs-historic" = "VARIOUS LOCATIONS - HISTORIC"
)

files.combined.df <- files.combined.df %>%
  dplyr::mutate(
    budget_activity_title_reported = budget_activity_title,
    ba_key_tmp = tolower(stringr::str_squish(budget_activity_title)),
    budget_activity_title = dplyr::coalesce(
      unname(ba.canonical[ba_key_tmp]),
      budget_activity_title
    )
  )

unmapped.ba <- files.combined.df %>%
  dplyr::filter(!is.na(ba_key_tmp), !ba_key_tmp %in% names(ba.canonical)) %>%
  dplyr::distinct(budget_activity_title_reported) %>%
  dplyr::pull(budget_activity_title_reported)

if (length(unmapped.ba) > 0) {
  warning("Budget activity titles with no canonical mapping: ",
          paste(sort(unmapped.ba), collapse = " | "), call. = FALSE)
}

files.combined.df <- files.combined.df %>%
  dplyr::select(-ba_key_tmp)


# Tokens are interpolated into regular expressions below, so any character that
# is special to a regex has to be escaped first. Without this, the token "p.l."
# (Public Law) matched "Polk" -- the dots matching any character -- and turned
# Fort Polk into "Fort P.L." in 22 rows.
escape_regex <- function(x) {
  gsub("([.\\\\|()\\[\\]{}^$*+?])", "\\\\\\1", x, perl = TRUE)
}

# ----- Casing for names: locations, states and project titles -----------------
#
# The reports write the same name in block capitals one year and title case the
# next, so 532 location names, 80 state names and 1,049 project titles differed
# only by case -- which splits a place in two as soon as anything is grouped or
# counted by it. These columns are put in title case.
#
# Plain title casing would wreck the initialisms these fields are full of
# ("MCAS Iwakuni" -> "Mcas Iwakuni", "KC-46A" -> "Kc-46a", "MacDill" ->
# "Macdill"), so tokens that must keep their own rendering are protected. The
# list below is DERIVED FROM THE DATA rather than guessed: in values the reports
# wrote in mixed case -- where the intended rendering is visible -- it collects
# every token the authors did not render as ordinary title case, keeping the
# majority rendering where a token appears both ways. Tokens whose majority
# rendering is already plain title case are left to the general rule.
#
# Two classes are deliberately excluded. Ordinary English words that a sheet
# merely shouted ("IN", "OR", "OF") would otherwise be forced to capitals in the
# middle of a sentence, and US state postal codes are ambiguous against real
# words ("DE" in "Havre De Grace", "LA" in "La Plata"), so those are restored
# only where a state code can appear: after a comma, or at the end of the value.
location.initialisms <- c(
  "aafes" = "AAFES",
  "aap" = "AAP",
  "aasf" = "AASF",
  "ab" = "AB",
  "ac" = "AC",
  "adal" = "ADAL",
  "aetc" = "AETC",
  "af" = "AF",
  "afb" = "AFB",
  "afcec" = "AFCEC",
  "afrpa" = "AFRPA",
  "afs" = "AFS",
  "age" = "AGE",
  "ags" = "AGS",
  "ait" = "AIT",
  "ame" = "AME",
  "amsa" = "AMSA",
  "amu" = "AMU",
  "ang" = "ANG",
  "angb" = "ANGB",
  "angs" = "ANGS",
  "ap" = "AP",
  "apr" = "APR",
  "aps" = "APS",
  "apt" = "APT",
  "ar" = "AR",
  "arb" = "ARB",
  "ars" = "ARS",
  "ase" = "ASE",
  "asoc" = "ASOC",
  "atc" = "ATC",
  "atfp" = "ATFP",
  "avfid" = "AVFID",
  "bams" = "BAMS",
  "bct" = "BCT",
  "beq" = "BEQ",
  "bmt" = "BMT",
  "catm" = "CATM",
  "ch" = "CH",
  "cirf" = "CIRF",
  "cis" = "CIS",
  "cma" = "CMA",
  "cmv" = "CMV",
  "cnaf" = "cNAF",
  "cnatt" = "CNATT",
  "cnci" = "CNCI",
  "cpos" = "CPOs",
  "crh" = "CRH",
  "csl" = "CSL",
  "css" = "CSS",
  "cst" = "CST",
  "ctc" = "CTC",
  "cv" = "CV",
  "cvn" = "CVN",
  "cybercom" = "CYBERCOM",
  "d&a" = "D&A",
  "dabs" = "DABS",
  "dar" = "DAR",
  "deca" = "DECA",
  "dfas" = "DFAS",
  "disa" = "DISA",
  "dla" = "DLA",
  "dlr" = "DLR",
  "dod" = "DoD",
  "dodea" = "DoDEA",
  "don" = "DoN",
  "dpw" = "DPW",
  "dss" = "DSS",
  "e&t" = "E&T",
  "ea" = "EA",
  "ecaos" = "ECAOS",
  "ecip" = "ECIP",
  "ecp" = "ECP",
  "ecs" = "ECS",
  "edi" = "EDI",
  "eiamd" = "EIAMD",
  "eic" = "EIC",
  "eod" = "EOD",
  "ercip" = "ERCIP",
  "eri" = "ERI",
  "es" = "ES",
  "esb" = "ESB",
  "f.e." = "F.E.",
  "fev" = "FEV",
  "fhif" = "FHIF",
  "fms" = "FMS",
  "foa" = "FOA",
  "foas" = "FOAs",
  "fol" = "FOL",
  "fp" = "FP",
  "fsh" = "FSH",
  "ftc" = "FTC",
  "ftu" = "FTU",
  "fy" = "FY",
  "gbsd" = "GBSD",
  "gds" = "GDS",
  "h&sa" = "H&SA",
  "hc" = "HC",
  "hq" = "HQ",
  "hqs" = "HQs",
  "hrd" = "HRD",
  "hs" = "HS",
  "iap" = "IAP",
  "ic" = "IC",
  "idt" = "IDT",
  "ied" = "IED",
  "igpbs" = "IGPBS",
  "ii" = "II",
  "iii" = "III",
  "ind" = "IND",
  "indo" = "INDO",
  "indopacom" = "INDOPACOM",
  "isr" = "ISR",
  "iv" = "IV",
  "ix" = "IX",
  "jfhq" = "JFHQ",
  "jiac" = "JIAC",
  "jitc" = "JITC",
  "jrb" = "JRB",
  "jsf" = "JSF",
  "jsou" = "JSOU",
  "kc" = "KC",
  "kmc" = "KMC",
  "lak" = "LAK",
  "lcs" = "LCS",
  "lgbds" = "LGBDS",
  "lhd" = "LHD",
  "lo" = "LO",
  "lrso" = "LRSO",
  "macdill" = "MacDill",
  "mackall" = "MacKall",
  "mals" = "MALS",
  "mardiv" = "MARDIV",
  "mc" = "MC",
  "mcalester" = "McAlester",
  "mcas" = "MCAS",
  "mcbride" = "McBride",
  "mcchord" = "McChord",
  "mccoy" = "McCoy",
  "mccrady" = "McCrady",
  "mccsss" = "MCCSSS",
  "mcguire" = "McGuire",
  "mclb" = "MCLB",
  "mcleansville" = "McLeansville",
  "mcminnville" = "McMinnville",
  "mcnair" = "McNair",
  "mcnr" = "MCNR",
  "mcon" = "MCON",
  "mcpherson" = "McPherson",
  "mcsa" = "MCSA",
  "med" = "MED",
  "medcen" = "MEDCEN",
  "mef" = "MEF",
  "mh" = "MH",
  "mhpi" = "MHPI",
  "mhs" = "MHS",
  "mif" = "MIF",
  "mildep" = "MilDep",
  "mit" = "MIT",
  "mlg" = "MLG",
  "mob" = "MOB",
  "mout" = "MOUT",
  "mpmg" = "MPMG",
  "mpt" = "MPT",
  "mq" = "MQ",
  "mrsp" = "MRSP",
  "ms" = "MS",
  "msa" = "MSA",
  "msic" = "MSIC",
  "muns" = "MUNS",
  "mv" = "MV",
  "mwr" = "MWR",
  "mxg" = "MXG",
  "nas" = "NAS",
  "nasic" = "NASIC",
  "nc" = "NC",
  "ncis" = "NCIS",
  "nco" = "NCO",
  "ne" = "NE",
  "ng" = "NG",
  "nga" = "NGA",
  "nmc" = "NMC",
  "nmcrc" = "NMCRC",
  "nmmc" = "NMMC",
  "northcom" = "NORTHCOM",
  "nosc" = "NOSC",
  "nrc" = "NRC",
  "nrf" = "NRF",
  "ns" = "NS",
  "nsa" = "NSA",
  "nsaw" = "NSAW",
  "nscs" = "NSCS",
  "nswg" = "NSWG",
  "nw" = "NW",
  "nws" = "NWS",
  "oco" = "OCO",
  "og" = "OG",
  "oir" = "OIR",
  "ortc" = "ORTC",
  "osd" = "OSD",
  "oss" = "OSS",
  "p&d" = "P&D",
  "paip" = "PAIP",
  "par" = "PAR",
  "pdi" = "PDI",
  "pfpa" = "PFPA",
  "pmo" = "PMO",
  "pn" = "PN",
  "pol" = "POL",
  "prtc" = "PRTC",
  "psc" = "PSC",
  "r&da" = "R&DA",
  "radr" = "RADR",
  "rafmh" = "RAFMH",
  "rapcon" = "RAPCON",
  "rc" = "RC",
  "rdat&e" = "RDAT&E",
  "rdt&e" = "RDT&E",
  "recce" = "RECCE",
  "rm" = "RM",
  "rpa" = "RPA",
  "rpma" = "RPMA",
  "rpmc" = "RPMC",
  "s&s" = "S&S",
  "satcom" = "SATCOM",
  "scif" = "SCIF",
  "sdvt" = "SDVT",
  "se" = "SE",
  "seawolf" = "SEAWOLF",
  "sere" = "SERE",
  "sf" = "SF",
  "sfg" = "SFG",
  "sfs" = "SFS",
  "sgt" = "SGT",
  "sima" = "SIMA",
  "sof" = "SOF",
  "stratcom" = "STRATCOM",
  "sts" = "STS",
  "sw" = "SW",
  "t&e" = "T&E",
  "tacamo" = "TACAMO",
  "tacmor" = "TACMOR",
  "tass" = "TASS",
  "tbs" = "TBS",
  "tech" = "TECH",
  "temf" = "TEMF",
  "tfi" = "TFI",
  "thaad" = "THAAD",
  "trf" = "TRF",
  "ts" = "TS",
  "u.s." = "U.S.",
  "uas" = "UAS",
  "uav" = "UAV",
  "uhif" = "UHIF",
  "uhs" = "UHS",
  "uph" = "UPH",
  "us" = "US",
  "usa" = "USA",
  "usaf" = "USAF",
  "usamricd" = "USAMRICD",
  "usamriid" = "USAMRIID",
  "usar" = "USAR",
  "usmc" = "USMC",
  "usmcr" = "USMCR",
  "usstratcom" = "USSTRATCOM",
  "vi" = "VI",
  "vii" = "VII",
  "viii" = "VIII",
  "vms" = "VMS",
  "w&a" = "W&A",
  "weg" = "WEG",
  "whs" = "WHS",
  "wmd" = "WMD",
  "wra" = "WRA",
  "wsa" = "WSA",
  "wt" = "WT",
  "xi" = "XI",
  "xii" = "XII",
  "xiii" = "XIII",
  "xiv" = "XIV",

  # Curated supplement: initialisms that appear only inside all-caps values, so the
  # derivation above cannot see their intended rendering. Checked against the data --
  # every one of these is present -- and none is an English word.
  "aaf" = "AAF",
  "acc" = "ACC",
  "acft" = "ACFT",
  "addn" = "ADDN",
  "aetc" = "AETC",
  "afrc" = "AFRC",
  "afsoc" = "AFSOC",
  "ang" = "ANG",
  "angb" = "ANGB",
  "at/fp" = "AT/FP",
  "atfp" = "ATFP",
  "avn" = "AVN",
  "beq" = "BEQ",
  "boq" = "BOQ",
  "c4i" = "C4I",
  "conus" = "CONUS",
  "derf" = "DERF",
  "ecip" = "ECIP",
  "hazmat" = "HAZMAT",
  "impvs" = "IMPVS",
  "isr" = "ISR",
  "jrb" = "JRB",
  "milcon" = "MILCON",
  "mnt" = "MNT",
  "mout" = "MOUT",
  "nolf" = "NOLF",
  "nsy" = "NSY",
  "nws" = "NWS",
  "org" = "ORG",
  "p.l." = "P.L.",
  "pmrf" = "PMRF",
  "pov" = "POV",
  "qtrs" = "QTRS",
  "raf" = "RAF",
  "satcom" = "SATCOM",
  "sbct" = "SBCT",
  "sere" = "SERE",
  "temf" = "TEMF",
  "uav" = "UAV",
  "unh" = "UNH",
  "uph" = "UPH",
  "usar" = "USAR"
)

# Words that stay lowercase unless they begin the value.
location.particles <- c("and", "for", "in", "of", "on", "to", "with")

# US state and territory postal codes, restored only in state position.
location.state.codes <- c("AL", "AK", "AZ", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MO", "MT", "NV", "NH", "NJ", "NM", "NY", "ND", "OH", "OK", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WI", "WV", "WY", "DC", "PR", "GU", "MP")

title_case_label <- function(x) {

  out <- stringr::str_squish(tolower(x))

  # First letter of every word. Any non-letter is a word break, so hyphenated and
  # slashed compounds are handled ("add/alt" -> "Add/Alt", "two-bay" -> "Two-Bay").
  out <- gsub("(^|[^a-z'])([a-z])", "\\1\\U\\2", out, perl = TRUE)

  # Protected tokens. The lookarounds rather than \\b keep "&" and "." inside a
  # token from ending it (R&D, U.S.).
  for (i in seq_along(location.initialisms)) {
    out <- gsub(paste0("(?<![A-Za-z0-9&.])", escape_regex(names(location.initialisms)[i]), "(?![A-Za-z0-9&.])"),
                location.initialisms[[i]], out, perl = TRUE, ignore.case = TRUE)
  }

  # Letters immediately before a digit are a designator: KC-46A, F-35, CH-53K, MQ-9.
  out <- gsub("(?<![A-Za-z0-9])([A-Za-z]{1,4})(?=-?[0-9])", "\\U\\1", out, perl = TRUE)

  # State codes, only where a state code can occur.
  for (s in location.state.codes) {
    out <- gsub(paste0("(?<=, )", s, "(?![A-Za-z0-9])"), s, out, perl = TRUE, ignore.case = TRUE)
    out <- gsub(paste0("(?<![A-Za-z0-9])", s, "$"), s, out, perl = TRUE, ignore.case = TRUE)
  }

  # Particles, except as the first word.
  for (p in location.particles) {
    out <- gsub(paste0("(?<=[A-Za-z0-9] )", p, "(?=[ ,/)-])"), p, out, perl = TRUE, ignore.case = TRUE)
  }

  # Ordinal suffixes.
  out <- gsub("(?<=[0-9])(St|Nd|Rd|Th)(?![A-Za-z])", "\\L\\1", out, perl = TRUE)

  out

}

files.combined.df <- files.combined.df %>%
  dplyr::mutate(
    location_name_reported = location_name,
    project_title_reported = project_title,
    location_name = title_case_label(location_name),
    state_country_name = title_case_label(state_country_name),
    project_title = title_case_label(project_title)
  )



# Facility titles are written inconsistently across reports: the same category
# appears in block capitals in one year and title case in another, with
# abbreviations ("Unaccompanied Housing Impr Fund" against "Unaccompanied Housing
# Improvement Fund"), stray commas ("Land Purchase, Condemnation, Donation or
# Transfer") and typos ("GARGAGE", "LABORARTORIES", "DEWELLINGS",
# "Adminstrative", "REFREGERATION"). That left 328 distinct strings for 190
# categories, so grouping or filtering on the title split the same category in
# two. Everything is put in sentence case, with initialisms preserved.

facility.initialisms <- c("rdt&e" = "RDT&E", "r&d" = "R&D", "p&d" = "P&D",
                          "fh" = "FH", "dod" = "DoD", "nato" = "NATO",
                          "pol" = "POL", "hap" = "HAP", "ac" = "AC",
                          "milcon" = "MILCON", "pl" = "PL",
                          "ii" = "II", "iii" = "III", "iv" = "IV", "v" = "V")

facility.typos <- c("gargage" = "garbage", "laborartories" = "laboratories",
                    "refregeration" = "refrigeration", "dewellings" = "dwellings",
                    "adminstrative" = "administrative", "paymets" = "payments")

sentence_case_label <- function(x) {

  out <- stringr::str_squish(tolower(x))

  for (i in seq_along(facility.typos)) {
    out <- gsub(paste0("\\b", escape_regex(names(facility.typos)[i]), "\\b"),
                facility.typos[[i]], out, perl = TRUE)
  }

  out <- sub("^(.)", "\\U\\1", out, perl = TRUE)

  # Initialisms are restored after lower-casing. The lookaround rather than \\b
  # keeps "&" inside RDT&E and P&D from ending the token.
  for (i in seq_along(facility.initialisms)) {
    out <- gsub(paste0("(?<![A-Za-z0-9&])", escape_regex(names(facility.initialisms)[i]),
                       "(?![A-Za-z0-9&])"),
                facility.initialisms[[i]], out, perl = TRUE, ignore.case = TRUE)
  }

  out

}

# Explicit map for the facility categories, because collapsing abbreviations and
# punctuation variants onto one label is a judgment call rather than a rule. Any
# title not listed here still gets sentence-cased by the function above, and is
# reported so it can be added.
facility.category.titles <- c(
  "ADMIN BLDGS" = "Admin bldgs",
  "Admin Bldgs" = "Admin bldgs",
  "ADMIN STRUCTURES OTHER THAN BLDGS" = "Admin structures other than bldgs",
  "Administrative Facilities" = "Administrative facilities",
  "Adminstrative Facilities" = "Administrative facilities",
  "AIRCRAFT FUEL DISPENSING FACILITIES" = "Aircraft fuel dispensing facilities",
  "Aircraft Fuel Dispensing Facilities" = "Aircraft fuel dispensing facilities",
  "AIRCRAFT MAINTENANCE FACILITIES" = "Aircraft maintenance facilities",
  "Aircraft Maintenance Facilities" = "Aircraft maintenance facilities",
  "AIRCRAFT RDT&E BUILDINGS" = "Aircraft RDT&E buildings",
  "Aircraft Rdt&E Buildings" = "Aircraft RDT&E buildings",
  "AIRFIELD APRONS" = "Airfield aprons",
  "Airfield Aprons" = "Airfield aprons",
  "AIRFIELD OPERATIONAL BUILDINGS" = "Airfield operational buildings",
  "Airfield Operational Buildings" = "Airfield operational buildings",
  "AIRFIELD OPERATIONAL FACILITIES OTHER THAN BUILDINGS" = "Airfield operational facilities other than buildings",
  "Airfield Operational Facilities Other Than Buildings" = "Airfield operational facilities other than buildings",
  "AIRFIELD PAVEMENT LIGHTING" = "Airfield pavement lighting",
  "Airfield Pavement Lighting" = "Airfield pavement lighting",
  "AIRFIELD RUNWAYS" = "Airfield runways",
  "Airfield Runways" = "Airfield runways",
  "AIRFIELD TAXIWAYS" = "Airfield taxiways",
  "Airfield Taxiways" = "Airfield taxiways",
  "Ammunition, Explosives & Toxic Prod Fac." = "Ammunition, explosives, & toxic prod fac.",
  "AMMUNITION, EXPLOSIVES, & TOXIC PROD FAC." = "Ammunition, explosives, & toxic prod fac.",
  "Ammunition, Explosives, & Toxics RDT&E Buildings" = "Ammunition, explosives, & toxics RDT&E buildings",
  "AMMUNITION, EXPLOSIVES, & TOXICS RDT&E BUILDINGS" = "Ammunition, explosives, & toxics RDT&E buildings",
  "AMMUNITION, EXPLOSIVES, AND TOXIC MAINTENANCE FACILITIES" = "Ammunition, explosives, and toxic maintenance facilities",
  "Ammunition, Explosives, and Toxic Maintenance Facilities" = "Ammunition, explosives, and toxic maintenance facilities",
  "AVIATION NAVIGATION & TRAFFIC AIDS BUILDING" = "Aviation navigation & traffic aids building",
  "Aviation Navigation & Traffic Aids Building" = "Aviation navigation & traffic aids building",
  "AVIATION NAVIGATION & TRAFFIC AIDS FAC OTHER THAN BLD." = "Aviation navigation & traffic aids fac other than bld.",
  "Aviation Navigation & Traffic Aids Fac Other Than Bld." = "Aviation navigation & traffic aids fac other than bld.",
  "Base Realignment & Closure Account" = "Base realignment & closure account",
  "BASE REALIGNMENT & CLOSURE ACCOUNT IV" = "Base realignment & closure account IV",
  "Base Realignment & Closure Account IV" = "Base realignment & closure account IV",
  "BASE REALIGNMENT & CLOSURE ACCOUNT V" = "Base realignment & closure account V",
  "Base Realignment & Closure Account V" = "Base realignment & closure account V",
  "BUILDING IMPROVEMENTS" = "Building improvements",
  "BULK LIQUID FUEL STORAGE" = "Bulk liquid fuel storage",
  "Bulk Liquid Fuel Storage" = "Bulk liquid fuel storage",
  "CARGO HANDLING AND STAGING AREAS" = "Cargo handling and staging areas",
  "Chilled Water (AC) Transmission & Dist Lines" = "Chilled water (AC) transmission & dist lines",
  "CHILLED WATER (AC) TRANSMISSION & DIST LINES" = "Chilled water (AC) transmission & dist lines",
  "CLEARING, GRADING, & LANDSCAPING" = "Clearing, grading, & landscaping",
  "Clearing, Grading, & Landscaping" = "Clearing, grading, & landscaping",
  "COMMUNICATION BUILDINGS" = "Communication buildings",
  "Communication Buildings" = "Communication buildings",
  "Communication Lines" = "Communication lines",
  "COMMUNICATION LINES" = "Communication lines",
  "Communications Facilities Other Than Buildings" = "Communications facilities other than buildings",
  "Community Facilities" = "Community facilities",
  "CONGRESSIONAL RESCISSION (PL 101-148)" = "Congressional rescission (PL 101-148)",
  "CONTINGENCY CONSTRUCTION" = "Contingency construction",
  "Contingency Construction" = "Contingency construction",
  "DENTAL CLINICS" = "Dental clinics",
  "Dental Clinics" = "Dental clinics",
  "DEPOT & ARSENAL AMMUNITION STORAGE" = "Depot & arsenal ammunition storage",
  "Depot & Arsenal Ammunition Storage" = "Depot & arsenal ammunition storage",
  "Depot & Arsenal Covered Storage" = "Depot & arsenal covered storage",
  "DEPOT & ARSENAL COVERED STORAGE" = "Depot & arsenal covered storage",
  "Depot Open Storage" = "Depot open storage",
  "DEPOT OPEN STORAGE" = "Depot open storage",
  "DETACHED UNACCOM PERSONNEL HOUSING FAC" = "Detached unaccom personnel housing fac",
  "Detached Unaccom Personnel Housing Fac" = "Detached unaccom personnel housing fac",
  "DISPENSARIES & CLINICS" = "Dispensaries & clinics",
  "Dispensaries & Clinics" = "Dispensaries & clinics",
  "DoD Family Housing Improvement Fund" = "DoD family housing improvement fund",
  "DOD FAMILY HOUSING IMPROVEMENT FUND" = "DoD family housing improvement fund",
  "DREDGING" = "Dredging",
  "EASEMENTS" = "Easements",
  "Easements" = "Easements",
  "Education Facilities" = "Education facilities",
  "EDUCATION FACILITIES" = "Education facilities",
  "ELECTRIC POWER SOURCE" = "Electric power source",
  "Electric Power Source" = "Electric power source",
  "Electric Power Substations & Switching Stations" = "Electric power substations & switching stations",
  "ELECTRIC POWER SUBSTATIONS & SWITCHING STATIONS" = "Electric power substations & switching stations",
  "ELECTRIC POWER TRANSMISSION & DIST LINES" = "Electric power transmission & dist lines",
  "Electric Power Transmission & Dist Lines" = "Electric power transmission & dist lines",
  "ELECTRONIC & COMMUNICATIONS EQUIPMENT MAINTENANCE FACILITIES" = "Electronic & communications equipment maintenance facilities",
  "Electronic & Communications Equipment Maintenance Facilities" = "Electronic & communications equipment maintenance facilities",
  "ELECTRONIC AND COMMUNICATIONS EQUIP RDT&E BUILDINGS" = "Electronic and communications equip RDT&E buildings",
  "Electronic and Communications Equip RDT&E Buildings" = "Electronic and communications equip RDT&E buildings",
  "EMERGENCY UNACCOM PERSONNEL HOUSING" = "Emergency unaccom personnel housing",
  "Emergency Unaccom Personnel Housing" = "Emergency unaccom personnel housing",
  "Energy Conservation" = "Energy conservation",
  "ENERGY CONSERVATION" = "Energy conservation",
  "ENLISTED PERSONNEL UNACCOMPANIED PERSONNEL HOUSING" = "Enlisted personnel unaccompanied personnel housing",
  "Enlisted Personnel Unaccompanied Personnel Housing" = "Enlisted personnel unaccompanied personnel housing",
  "FAM HSG DEWELLINGS" = "Fam hsg dwellings",
  "Fam Hsg Dewellings" = "Fam hsg dwellings",
  "FAM HSG TRAILERS SITES" = "Fam hsg trailers sites",
  "FAMILY & CHILD SUPPORT FACILITIES" = "Family & child support facilities",
  "Family & Child Support Facilities" = "Family & child support facilities",
  "Family Housing Construction" = "Family housing construction",
  "Family Housing Improvement Fund" = "Family housing improvement fund",
  "Family Housing Operations" = "Family housing operations",
  "Family Housing P&D" = "Family housing P&D",
  "FAMILY HOUSING P&D" = "Family housing P&D",
  "FH Furnishings Account" = "FH furnishings account",
  "FH FURNISHINGS ACCOUNT" = "FH furnishings account",
  "FH INTEREST PAYMETS" = "FH interest payments",
  "FH LEASING ACCOUNT" = "FH leasing account",
  "FH Leasing Account" = "FH leasing account",
  "FH MAINTENANCE OF REAL PROPERTY" = "FH maintenance of real property",
  "FH Maintenance Of Real Property" = "FH maintenance of real property",
  "FH MANAGEMENT ACCOUNT" = "FH management account",
  "FH Management Account" = "FH management account",
  "FH MISCELLANEOUS ACCOUNT" = "FH miscellaneous account",
  "FH Miscellaneous Account" = "FH miscellaneous account",
  "FH MORTGAGE INSURANCE PREMIUMS" = "FH mortgage insurance premiums",
  "FH POST ACQUISITION CONSTRUCTION IMPROVEMENTS" = "FH post acquisition construction improvements",
  "FH Post Acquisition Construction Improvements" = "FH post acquisition construction improvements",
  "FH PRIVATIZATION SUPPORT" = "FH privatization support",
  "FH Privatization Support" = "FH privatization support",
  "FH SERVICES ACCOUNT" = "FH services account",
  "FH Services Account" = "FH services account",
  "FH UTILITIES ACCOUNT" = "FH utilities account",
  "FH Utilities Account" = "FH utilities account",
  "FIRE & OTHER ALARM SYSTEMS" = "Fire & other alarm systems",
  "FIRE EXTINGUISHING SYSTEMS" = "Fire extinguishing systems",
  "FIRE PROTECTION WATER FAC" = "Fire protection water fac",
  "FOOD SERVICE FAC" = "Food service fac",
  "GENERAL" = "General",
  "General" = "General",
  "GROUND OPERATIONAL BUILDINGS" = "Ground operational buildings",
  "Ground Operational Buildings" = "Ground operational buildings",
  "Ground Operational Facilities Other Than Buildings" = "Ground operational facilities other than buildings",
  "GROUND OPERATIONAL FACILITIES OTHER THAN BUILDINGS" = "Ground operational facilities other than buildings",
  "Ground/Fencing" = "Ground/fencing",
  "GROUND/FENCING" = "Ground/fencing",
  "Grounding Drainage" = "Grounding drainage",
  "GROUNDING DRAINAGE" = "Grounding drainage",
  "GROUNDS FENCING, GATES, & GUARD TOWERS" = "Grounds fencing, gates, & guard towers",
  "Grounds Fencing, Gates, & Guard Towers" = "Grounds fencing, gates, & guard towers",
  "Guided Missile Maintenance Facilities" = "Guided missile maintenance facilities",
  "GUIDED MISSILE MAINTENANCE FACILITIES" = "Guided missile maintenance facilities",
  "HAP - OTHER OPERATING COSTS" = "HAP - other operating costs",
  "HAP - Other Operating Costs" = "HAP - other operating costs",
  "HARBOR PROTECTION FACILITIES" = "Harbor protection facilities",
  "Harbor Protection Facilities" = "Harbor protection facilities",
  "Heat Source" = "Heat source",
  "HEAT SOURCE" = "Heat source",
  "HEAT TRANSMISSION & DIST LINES" = "Heat transmission & dist lines",
  "Heat Transmission & Dist Lines" = "Heat transmission & dist lines",
  "HEATING GAS SOURCE" = "Heating gas source",
  "HEATING GAS TRANSMISSION" = "Heating gas transmission",
  "Homeowners Assistance" = "Homeowners assistance",
  "Hospital And Medical Facilities" = "Hospital and medical facilities",
  "HOST NATION SUPPORT (P&D)" = "Host nation support (P&D)",
  "Host Nation Support (P&D)" = "Host nation support (P&D)",
  "Impact, Maneuver, and Training Areas" = "Impact, maneuver, and training areas",
  "IMPACT, MANEUVER, AND TRAINING AREAS" = "Impact, maneuver, and training areas",
  "INDOOR ATHLETIC FAC" = "Indoor athletic fac",
  "Indoor Athletic Fac" = "Indoor athletic fac",
  "INDOOR ENTERTAINMENT FAC" = "Indoor entertainment fac",
  "Indoor Entertainment Fac" = "Indoor entertainment fac",
  "INDOOR RECREATION FAC" = "Indoor recreation fac",
  "INSTALL & ORG COVERED STORAGE" = "Install & org covered storage",
  "Install & Org Covered Storage" = "Install & org covered storage",
  "INSTALL & ORG OPEN STORAGE" = "Install & org open storage",
  "Install & Org Open Storage" = "Install & org open storage",
  "INSTALL & READY-ISSUE AMMUNITION STORAGE" = "Install & ready-issue ammunition storage",
  "Install & Ready-Issue Ammunition Storage" = "Install & ready-issue ammunition storage",
  "INSTALLATION SUPPORT FAC" = "Installation support fac",
  "Installation Support Fac" = "Installation support fac",
  "Installation, Repair & Operation Maint Fac." = "Installation, repair, & operation maint fac.",
  "INSTALLATION, REPAIR, & OPERATION MAINT FAC." = "Installation, repair, & operation maint fac.",
  "Land Purchase, Condemnation, Donation or Transfer" = "Land purchase, condemnation, donation, or transfer",
  "LAND PURCHASE, CONDEMNATION, DONATION, OR TRANSFER" = "Land purchase, condemnation, donation, or transfer",
  "Land Vehicle Fuel Dispensing Facilities" = "Land vehicle fuel dispensing facilities",
  "LAND VEHICLE FUEL DISPENSING FACILITIES" = "Land vehicle fuel dispensing facilities",
  "Maintenance & Production Facilities" = "Maintenance & production facilities",
  "Marine Fuel Dispensing Facilities" = "Marine fuel dispensing facilities",
  "MARINE IMPROVEMENTS" = "Marine improvements",
  "Marine Improvements" = "Marine improvements",
  "MED & MED SUPPORT FAC" = "Med & med support fac",
  "Med & Med Support Fac" = "Med & med support fac",
  "MEDICAL CENTERS & HOSPITALS" = "Medical centers & hospitals",
  "Medical Centers & Hospitals" = "Medical centers & hospitals",
  "Milcon Planning & Design" = "MILCON planning & design",
  "MILCON PLANNING & DESIGN" = "MILCON planning & design",
  "Milcon Unspecified Minor Construction" = "MILCON unspecified minor construction",
  "MILCON UNSPECIFIED MINOR CONSTRUCTION" = "MILCON unspecified minor construction",
  "MISC COMPONENTS OF OTHER FACILITIES" = "Misc components of other facilities",
  "MISC INDOOR MORALE, WELFARE, & REC FAC" = "Misc indoor morale, welfare, & rec fac",
  "MISC ITEMS & EQUIP MAINT FACILITIES" = "Misc items & equip maint facilities",
  "Misc Items & Equip Maint Facilities" = "Misc items & equip maint facilities",
  "Misc Items & Equip RDT&E Buildings" = "Misc items & equip RDT&E buildings",
  "MISC ITEMS & EQUIP RDT&E BUILDINGS" = "Misc items & equip RDT&E buildings",
  "MISC PERSONNEL SUPPORT & SERVICE FAC" = "Misc personnel support & service fac",
  "MISC UTILITIES-EACH" = "Misc utilities-each",
  "Misc Utilities-Each" = "Misc utilities-each",
  "Misc Utilities-Gallons" = "Misc utilities-gallons",
  "MISC UTILITIES-GALLONS" = "Misc utilities-gallons",
  "Misc Utilities-Linear Feet" = "Misc utilities-linear feet",
  "MISC UTILITIES-SQUARE FEET" = "Misc utilities-square feet",
  "Misc Utilities-Square Feet" = "Misc utilities-square feet",
  "MISSILE & SPACE RDT&E BUILDINGS" = "Missile & space RDT&E buildings",
  "Missile & Space RDT&E Buildings" = "Missile & space RDT&E buildings",
  "MOORINGS" = "Moorings",
  "Moorings" = "Moorings",
  "MUSEUMS & MEMORIALS" = "Museums & memorials",
  "Museums & Memorials" = "Museums & memorials",
  "Nato Security Investment Program" = "NATO security investment program",
  "NATO SECURITY INVESTMENT PROGRAM" = "NATO security investment program",
  "NONPOTABLE WATER DISTRIBUTION SYSTEM" = "Nonpotable water distribution system",
  "Nonpotable Water Distribution System" = "Nonpotable water distribution system",
  "NONPOTABLE WATER SUPPLY & STORAGE" = "Nonpotable water supply & storage",
  "NOT REAL PROPERTY" = "Not real property",
  "OFFICERS UNACCOM PERSONNEL HOUSING" = "Officers unaccom personnel housing",
  "Officers Unaccom Personnel Housing" = "Officers unaccom personnel housing",
  "OPEN AMMUNITION STORAGE PAD" = "Open ammunition storage pad",
  "Open Ammunition Storage Pad" = "Open ammunition storage pad",
  "Operating Fuel Storage Facilities" = "Operating fuel storage facilities",
  "OPERATING FUEL STORAGE FACILITIES" = "Operating fuel storage facilities",
  "Operational Facilities" = "Operational facilities",
  "OPERATIONAL SUPPORT BUILDINGS" = "Operational support buildings",
  "Operational Support Buildings" = "Operational support buildings",
  "OPERATIONAL SUPPORT FACILITIES OTHER THAN BUILDINGS" = "Operational support facilities other than buildings",
  "Operational Support Facilities Other Than Buildings" = "Operational support facilities other than buildings",
  "Other" = "Other",
  "OTHER AIRFIELD PAVEMENTS" = "Other airfield pavements",
  "Other Airfield Pavements" = "Other airfield pavements",
  "OTHER IMPROVEMENTS" = "Other improvements",
  "Other Improvements" = "Other improvements",
  "Other Liquid Fuel & Dispensing Facilities" = "Other liquid fuel & dispensing facilities",
  "OTHER LIQUID FUEL & DISPENSING FACILITIES" = "Other liquid fuel & dispensing facilities",
  "OTHER OPERATIONAL" = "Other operational",
  "Other Operational" = "Other operational",
  "Other Waterfront Operational Facilities" = "Other waterfront operational facilities",
  "OTHER WATERFRONT OPERATIONAL FACILITIES" = "Other waterfront operational facilities",
  "OUTDOOR RECREATION FAC" = "Outdoor recreation fac",
  "Personnel Support Facilities" = "Personnel support facilities",
  "PERSONNEL SUPPORT FACILITIES" = "Personnel support facilities",
  "PIERS AND WHARFS" = "Piers and wharfs",
  "Piers and Wharfs" = "Piers and wharfs",
  "Planning & Design" = "Planning & design",
  "POL Pipelines" = "POL pipelines",
  "POL PIPELINES" = "POL pipelines",
  "POTABLE WATER DISTRIBUTION SYSTEM" = "Potable water distribution system",
  "Potable Water Distribution System" = "Potable water distribution system",
  "POTABLE WATER SUPPLY, TREATMENT & STORAGE" = "Potable water supply, treatment & storage",
  "Potable Water Supply, Treatment & Storage" = "Potable water supply, treatment & storage",
  "PROPULSION RDT&E BUILDINGS" = "Propulsion RDT&E buildings",
  "Propulsion RDT&E Buildings" = "Propulsion RDT&E buildings",
  "Public Domain Withdraw" = "Public domain withdraw",
  "PUBLIC DOMAIN WITHDRAW" = "Public domain withdraw",
  "R&D Facilities" = "R&D facilities",
  "RAILROAD FAC OTHER THAN TRACKS" = "Railroad fac other than tracks",
  "Railroad Fac Other Than Tracks" = "Railroad fac other than tracks",
  "RAILROAD TRACKS" = "Railroad tracks",
  "Railroad Tracks" = "Railroad tracks",
  "RDT&E FACILITIES OTHER THAN BUILDINGS" = "RDT&E facilities other than buildings",
  "RDT&E Facilities Other Than Buildings" = "RDT&E facilities other than buildings",
  "RDT&E RANGE FACILITIES" = "RDT&E range facilities",
  "RDT&E Range Facilities" = "RDT&E range facilities",
  "RDT&E SCIENCE LABORARTORIES" = "RDT&E science laboratories",
  "Rdt&E Science Laborartories" = "RDT&E science laboratories",
  "Real Estate" = "Real estate",
  "Refregeration (AC) Source" = "Refrigeration (AC) source",
  "REFREGERATION (AC) SOURCE" = "Refrigeration (AC) source",
  "REFUSE & GARBAGE FAC" = "Refuse & garbage fac",
  "Refuse & Garbage Fac" = "Refuse & garbage fac",
  "REFUSE & GARGAGE FAC" = "Refuse & garbage fac",
  "RELIGIOUS FACILITIES" = "Religious facilities",
  "Religious Facilities" = "Religious facilities",
  "REPLACE FIRECRASH/RESCUE STATION" = "Replace fire crash/rescue station",
  "Replace Firecrash/Rescue Station" = "Replace fire crash/rescue station",
  "Replace Tele. and Security Forces Facility" = "Replace tele. and security forces facility",
  "REPLACE TELE. AND SECURITY FORCES FACILITY" = "Replace tele. and security forces facility",
  "RETAIL SALE & SERVICES FAC" = "Retail sale & services fac",
  "ROADS" = "Roads",
  "Roads" = "Roads",
  "SAFETY, DISP, & REHAB FAC" = "Safety, disp, & rehab fac",
  "Safety, Disp, & Rehab Fac" = "Safety, disp, & rehab fac",
  "SEA WALLS, BULKHEADS, AND QUAY WALLS" = "Sea walls, bulkheads, and quay walls",
  "Sea Walls, Bulkheads, and Quay Walls" = "Sea walls, bulkheads, and quay walls",
  "SEWAGE & INDUSTRIAL WASTE COLLECTION LINES" = "Sewage & industrial waste collection lines",
  "Sewage & Industrial Waste Collection Lines" = "Sewage & industrial waste collection lines",
  "SEWAGE & INDUSTRIAL WASTE TREATMENT & DISPOSAL" = "Sewage & industrial waste treatment & disposal",
  "Sewage & Industrial Waste Treatment & Disposal" = "Sewage & industrial waste treatment & disposal",
  "SHIP & MARINE EQUIPMENT RDT&E BUILDINGS" = "Ship & marine equipment RDT&E buildings",
  "SHIP NAVIGATION & TRAFFIC AIDS BUILDING" = "Ship navigation & traffic aids building",
  "SHIP OPERATIONAL BUILDINGS" = "Ship operational buildings",
  "Ship Operational Buildings" = "Ship operational buildings",
  "Ships and Spares Maintenance Facilities" = "Ships and spares maintenance facilities",
  "SHIPS AND SPARES MAINTENANCE FACILITIES" = "Ships and spares maintenance facilities",
  "SHIPS AND SPARES PRODUCTION FACILITIES" = "Ships and spares production facilities",
  "SIDEWALKS & OTHER PAVEMENTS" = "Sidewalks & other pavements",
  "Sidewalks & Other Pavements" = "Sidewalks & other pavements",
  "SIMULATION FACILITIES" = "Simulation facilities",
  "Simulation Facilities" = "Simulation facilities",
  "Small Craft Building" = "Small craft building",
  "SMALL CRAFT BUILDING" = "Small craft building",
  "Supply Facilities" = "Supply facilities",
  "Supporting Activities" = "Supporting activities",
  "TANK & AUTOMOTIVE RDT&E BUILDINGS" = "Tank & automotive RDT&E buildings",
  "TANK AND AUTOMOTIVE MAINTENANCE FACILITIES" = "Tank and automotive maintenance facilities",
  "Tank and Automotive Maintenance Facilities" = "Tank and automotive maintenance facilities",
  "TECHNICAL SERVICES RDT&E BUILDINGS" = "Technical services RDT&E buildings",
  "TRAINING BUILDINGS" = "Training buildings",
  "Training Buildings" = "Training buildings",
  "Training Facilities" = "Training facilities",
  "TRAINING FACILITIES OTHER THAN BUILDINGS" = "Training facilities other than buildings",
  "Training Facilities Other Than Buildings" = "Training facilities other than buildings",
  "TRAINING RANGES" = "Training ranges",
  "Training Ranges" = "Training ranges",
  "TRAINING SUPPORT FACILITIES" = "Training support facilities",
  "Training Support Facilities" = "Training support facilities",
  "Troop Housing Facilities" = "Troop housing facilities",
  "UNACCOM PERSONNEL HOUSING MESS FAC" = "Unaccom personnel housing mess fac",
  "Unaccom Personnel Housing Mess Fac" = "Unaccom personnel housing mess fac",
  "Unaccompanied Housing Impr Fund" = "Unaccompanied housing improvement fund",
  "Unaccompanied Housing Improvement Fund" = "Unaccompanied housing improvement fund",
  "UNDERGROUND ADMIN STRUCTURES" = "Underground admin structures",
  "UNDERWATER EQUIPMENT RDT&E BUILDINGS" = "Underwater equipment RDT&E buildings",
  "Unspecified Minor Construction" = "Unspecified minor construction",
  "Util/Misc" = "Util/misc",
  "Utility Facilities" = "Utility facilities",
  "Vehicle Facilities" = "Vehicle facilities",
  "VEHICLE FACILITIES" = "Vehicle facilities",
  "Water Pollution Abatement" = "Water pollution abatement",
  "WEAPONS & WEAPON SYSTEMS RDT&E BUILDINGS" = "Weapons & weapon systems RDT&E buildings",
  "Weapons & Weapon Systems RDT&E Buildings" = "Weapons & weapon systems RDT&E buildings",
  "WEAPONS AND SPARES MAINTENANCE FACILITIES" = "Weapons and spares maintenance facilities",
  "Weapons and Spares Maintenance Facilities" = "Weapons and spares maintenance facilities"
)

# facility_group_title arrives mostly as block capitals, which the sentence-case
# rule handles on its own. It is not entirely free of abbreviation clashes,
# though: the FY2022 workbook writes one group label in short form
# ("Unaccompanied Housing Impr Fund"), and the rule turns that into a second,
# distinct label sitting beside the full one. Fold the known short forms in
# explicitly before applying the rule to everything else. Keys are lower case
# and squished so that any capitalization in the source matches.
facility.group.aliases <- c(
  "unaccompanied housing impr fund" = "Unaccompanied housing improvement fund",
  "unaccom housing impr fund" = "Unaccompanied housing improvement fund",
  "unaccomp housing impr fund" = "Unaccompanied housing improvement fund",
  "fam housing improvement fund" = "Family housing improvement fund",
  "fam hsg improvement fund" = "Family housing improvement fund",
  "fam housing construction" = "Family housing construction",
  "fam hsg construction" = "Family housing construction",
  "fam housing operations" = "Family housing operations",
  "fam hsg operations" = "Family housing operations",
  "fam housing p&d" = "Family housing P&D",
  "fam hsg p&d" = "Family housing P&D"
)

files.combined.df <- files.combined.df %>%
  dplyr::mutate(
    facility_category_title_reported = facility_category_title,
    facility_key_tmp = stringr::str_squish(facility_category_title),
    facility_category_title = dplyr::coalesce(
      unname(facility.category.titles[facility_key_tmp]),
      sentence_case_label(facility_category_title)
    ),
    facility_group_title = dplyr::coalesce(
      unname(facility.group.aliases[tolower(stringr::str_squish(facility_group_title))]),
      sentence_case_label(facility_group_title)
    )
  )

# The coarse grouping reaches the data under a third header as well: the FY2022
# forward workbooks write "Facility Category Title" but fill it, for some rows,
# with group-level labels rather than a facility category. Those rows carry no
# facility_category_code, so the value itself is the discriminator -- the coarse
# vocabulary is a closed list. Such values are moved to facility_group_title so
# that each column holds one level of the taxonomy. facility_category_title_reported
# keeps whatever the sheet said.
facility.group.vocabulary <- c(
  "Administrative facilities",
  "Base realignment & closure account",
  "Community facilities",
  "Energy conservation",
  "Family housing construction",
  "Family housing improvement fund",
  "Family housing operations",
  "Family housing P&D",
  "General reduction various",
  "Homeowners assistance",
  "Hospital and medical facilities",
  "Maintenance & production facilities",
  "NATO security investment program",
  "Operational facilities",
  "Other",
  "Planning & design",
  "R&D facilities",
  "Real estate",
  "Supply facilities",
  "Supporting activities",
  "Training facilities",
  "Troop housing facilities",
  "Unaccompanied housing improvement fund",
  "Unspecified minor construction",
  "Utility facilities"
)

files.combined.df <- files.combined.df %>%
  dplyr::mutate(
    group_level_tmp = is.na(facility_category_code) &
      facility_category_title %in% facility.group.vocabulary,
    facility_group_title = dplyr::if_else(group_level_tmp,
                                          facility_category_title,
                                          facility_group_title),
    facility_category_title = dplyr::if_else(group_level_tmp,
                                             NA_character_,
                                             facility_category_title)
  ) %>%
  dplyr::select(-group_level_tmp)

unmapped.facility <- files.combined.df %>%
  dplyr::filter(!is.na(facility_key_tmp),
                !facility_key_tmp %in% names(facility.category.titles)) %>%
  dplyr::distinct(facility_category_title_reported) %>%
  dplyr::pull(facility_category_title_reported)

if (length(unmapped.facility) > 0) {
  warning("Facility category titles not in facility.category.titles (sentence-cased by rule only): ",
          paste(sort(unmapped.facility), collapse = " | "), call. = FALSE)
}

files.combined.df <- files.combined.df %>%
  dplyr::select(-facility_key_tmp)


# Harmonize the organization field to full names, keeping what each sheet
# actually said in organization_reported. The workbooks use several encodings for
# the same component across years (ARMY and A, NAVY and N, AF and F, D and DEFW),
# so organization = "A" matched only a quarter of Army rows.
#
# There is no Marine Corps value: in the C-1 exhibits Marine Corps construction
# is carried in the Navy accounts, visible only in appn_title ("Fam Housing
# Construction, Navy & Marine Corps"). Guard and reserve components are likewise
# in appn_title rather than here. UNDD appears on Defense-Wide program items
# (Contingency Construction, Energy Conservation, Foreign Currency, NATO
# Headquarters) and is treated as Defense-Wide.
organization.names <- c(
  "A" = "Army",
  "ARMY" = "Army",
  "N" = "Navy",
  "NAVY" = "Navy",
  "F" = "Air Force",
  "AF" = "Air Force",
  "AIR FORCE" = "Air Force",
  "D" = "Defense-Wide",
  "DEFW" = "Defense-Wide",
  "UNDD" = "Defense-Wide",
  "SOCOM" = "Special Operations Command",
  "DLA" = "Defense Logistics Agency",
  "TMA" = "TRICARE Management Activity",
  "DHA" = "Defense Health Agency",
  "DHP" = "Defense Health Program",
  "NSA" = "National Security Agency",
  "DODEA" = "Department of Defense Education Activity",
  "DIA" = "Defense Intelligence Agency",
  "WHS" = "Washington Headquarters Services",
  "MDA" = "Missile Defense Agency",
  "TJS" = "The Joint Staff",
  "NGA" = "National Geospatial-Intelligence Agency",
  "DISA" = "Defense Information Systems Agency",
  "DFAS" = "Defense Finance and Accounting Service",
  "DSS" = "Defense Security Service",
  "DCSA" = "Defense Counterintelligence and Security Agency",
  "DCMA" = "Defense Contract Management Agency",
  "DECA" = "Defense Commissary Agency",
  "OSD" = "Office of the Secretary of Defense",
  "DTRA" = "Defense Threat Reduction Agency",
  "DTSA" = "Defense Technology Security Administration",
  "DMACT" = "Defense Media Activity",
  "CIFA" = "Counterintelligence Field Activity",
  "AFIS" = "American Forces Information Service",
  "DLSA" = "Defense Legal Services Agency",
  "DHRA" = "Defense Human Resources Activity",
  "CBDP" = "Chemical and Biological Defense Program",
  "DPAA" = "Defense POW/MIA Accounting Agency",
  "CYBER" = "United States Cyber Command",
  "IG" = "Inspector General"
)

files.combined.df <- files.combined.df %>%
  dplyr::mutate(
    organization_reported = organization,
    organization_key_tmp = toupper(stringr::str_squish(organization)),
    organization = dplyr::coalesce(
      unname(organization.names[organization_key_tmp]),
      organization
    )
  )

unmapped.org <- files.combined.df %>%
  dplyr::filter(!is.na(organization_key_tmp),
                !organization_key_tmp %in% names(organization.names)) %>%
  dplyr::distinct(organization_reported) %>%
  dplyr::pull(organization_reported)

if (length(unmapped.org) > 0) {
  warning("Organization codes with no full-name mapping: ",
          paste(sort(unmapped.org), collapse = ", "), call. = FALSE)
}

files.combined.df <- files.combined.df %>%
  dplyr::select(-organization_key_tmp)


# One report per fiscal year: the most recent one that covers it.
#
# Every C-1 workbook covers two or three fiscal years, so a year is printed in up
# to three reports -- first as the budget request, then as enacted, then as the
# actual -- and each project-year arrived here two or three times. An earlier
# version tried to match the restatements project by project, on fiscal year,
# location, project number, title, organization, transaction type and sheet type.
# That could not work, in either direction:
#
#   - The reports do not print the same fields for the same year. The FY2009
#     report has no project numbers for FY2007, FY2004-FY2009 print no
#     organization, and transaction type exists only in FY2001-FY2003. A project
#     and its restatement therefore differed on the key and both were kept: 6,300
#     of 20,344 rows came from a superseded report, and the appropriations in the
#     file summed to $599.7 billion against about $402 billion in the latest
#     report for each year.
#   - Different projects do share the key. Three "Barracks Complex" projects at
#     Vicenza in FY2007 ($46.0, $29.0 and $41.0 million) were one row; 211 rows
#     and $8.0 billion of appropriations were dropped that way.
#
# Taking each fiscal year whole from its most recent report needs no matching.
# FY2016 is the one year whose latest report is the one that requests it (the
# FY2017 and FY2018 reports are not among the source files), so it is the only
# whole year still flagged is_request. The other flagged rows are the 26 lines of
# the FY2010 overseas contingency operations request sheet that are on no other
# sheet.
n.rows.all.reports <- nrow(files.combined.df)

files.combined.df <- files.combined.df %>%
  dplyr::group_by(fiscal_year) %>%
  dplyr::filter(report_year == max(report_year)) %>%
  dplyr::ungroup()

# Each fiscal year must now come from exactly one workbook.
reports.per.year <- files.combined.df %>%
  dplyr::distinct(fiscal_year, source_file) %>%
  dplyr::count(fiscal_year) %>%
  dplyr::filter(n > 1)

if (nrow(reports.per.year) > 0) {
  warning("Fiscal years drawn from more than one workbook: ",
          paste(reports.per.year$fiscal_year, collapse = ", "), call. = FALSE)
}

# A supplemental sheet (OCO, enactment, emergency, reconciliation) can restate
# projects that are already on the same workbook's main sheet for that year: all
# 56 rows of "FY 2011 OCO", all 93 of "C1_2010_OCO_Enacted", all 8 of "FY 2012
# OCO" and all 40 of "FY2026 Mandatory Reconciliation" are on the main sheet too,
# usually at the same amount. Those are dropped. A supplemental row with no
# counterpart on the main sheet is a project in its own right and is kept (the 13
# European Reassurance Initiative projects on "FY 2015 OCO", for example).
restated.key <- c("source_file", "fiscal_year", "key_state", "key_location", "key_title")

with_restated_key <- function(d) {
  d %>%
    dplyr::mutate(key_state = tolower(state_country),
                  key_location = tolower(location_name),
                  key_title = tolower(project_title))
}

main.sheet.projects <- files.combined.df %>%
  dplyr::filter(sheet_type == "base", !is.na(project_title)) %>%
  with_restated_key() %>%
  dplyr::distinct(dplyr::across(tidyselect::all_of(restated.key))) %>%
  dplyr::mutate(on_main_sheet = TRUE)

n.rows.latest.report <- nrow(files.combined.df)

files.combined.df <- files.combined.df %>%
  with_restated_key() %>%
  dplyr::left_join(main.sheet.projects, by = restated.key) %>%
  dplyr::filter(!(sheet_type != "base" & !is.na(on_main_sheet))) %>%
  dplyr::select(-key_state, -key_location, -key_title, -on_main_sheet)

message("One report per fiscal year: ", n.rows.all.reports, " rows in all reports, ",
        n.rows.latest.report, " in the latest report for each year, ",
        nrow(files.combined.df), " after dropping ",
        n.rows.latest.report - nrow(files.combined.df),
        " supplemental rows that restate the main sheet.")

# No spreadsheet row may be in the data twice.
stopifnot(!any(duplicated(files.combined.df[, c("source_file", "source_sheet", "source_row")])))

# Cap the series at the last enacted fiscal year. A year that appears only as
# the terminal year of the newest report is a budget request, not spending.
last.enacted <- suppressWarnings(max(
  files.combined.df$fiscal_year[!files.combined.df$is_request],
  na.rm = TRUE
))

message("Last enacted fiscal year: ", last.enacted,
        ". Dropping ",
        sum(files.combined.df$fiscal_year > last.enacted, na.rm = TRUE),
        " request-only rows.")

files.combined.df <- files.combined.df %>%
  dplyr::filter(fiscal_year <= last.enacted)

# A facility category code must identify exactly one category title.
category.conflicts <- files.combined.df %>%
  dplyr::filter(!is.na(facility_category_code), !is.na(facility_category_title)) %>%
  dplyr::distinct(facility_category_code, facility_category_title) %>%
  dplyr::count(facility_category_code) %>%
  dplyr::filter(n > 1)

if (nrow(category.conflicts) > 0) {
  warning(
    "facility_category_code values carrying more than one facility_category_title: ",
    paste(category.conflicts$facility_category_code, collapse = ", "),
    call. = FALSE
  )
}

files.combined.df <- files.combined.df %>%
  dplyr::select(any_of(sort(names.preserve)))


write_csv(files.combined.df, here::here("data-raw/build_data_20260604.csv"))

# ----- Add standardized country identifiers ---------------------------------
# (Ahead of the geocoding, which needs to know which country a row is in.)
# state_country mixes US state postal abbreviations (domestic construction) with
# overseas country codes. The overseas codes are themselves a mix of ISO2C
# (e.g. "KW", "PL", "IT") and legacy FIPS 10-4 / DoD codes (e.g. "JA" Japan,
# "UK" United Kingdom, "SP" Spain, "IC" Iceland, "HO" Honduras, "PO" Portugal),
# plus a custom "GY" for Germany. Derive clean Gleditsch and Ward (gwcode) and
# ISO3C identifiers so downstream functions can filter on standard country codes
# rather than the raw two-letter field. US state abbreviations map to the United
# States (gwcode 2, iso3c "USA").

# Custom/ambiguous codes that must be pinned before automatic conversion.
# ("GY" is Guyana in both ISO2C and FIPS, but denotes Germany in this data.)
custom_iso2c <- c(GY = "DE")
state_country_fixed <- dplyr::recode(
  files.combined.df$state_country,
  !!!custom_iso2c
)

# Resolve each code by trying ISO2C first, then falling back to FIPS 10-4 for
# the legacy DoD codes. coalesce() keeps the ISO2C hit where both resolve.
to_iso3c <- function(x) {
  dplyr::coalesce(
    suppressWarnings(countrycode::countrycode(x, "iso2c", "iso3c")),
    suppressWarnings(countrycode::countrycode(x, "fips", "iso3c"))
  )
}
to_gwn <- function(x) {
  dplyr::coalesce(
    suppressWarnings(countrycode::countrycode(x, "iso2c", "gwn")),
    suppressWarnings(countrycode::countrycode(x, "fips", "gwn"))
  )
}

# US state (and territory) postal abbreviations resolve to a state name via
# usdata::abbr2state(); those rows are domestic and map to the United States.
is_us_state <- !is.na(usdata::abbr2state(files.combined.df$state_country))

# The C-1 exhibits do not use ISO or FIPS codes consistently: a good many of their two-letter
# codes are the reports' own, and several of those happen to be valid ISO2C codes for a different
# country. Trying ISO2C first therefore assigned the wrong country outright. Checked against the
# name each report prints beside the code (`state_country_name`) and, for the early years that
# print no name, against the locations filed under it:
#
#   IR is Iraq (70 projects coded as Iran)       BI is Bahrain (44, as Burundi)
#   ML is the Marianas (121, as Mali)            GB is Guantanamo Bay, Cuba (40, as the UK)
#   KW is Kwajalein (22, as Kuwait)              TK is Turkey (19, as Tokelau)
#   ET is Estonia (10, as Ethiopia)              SV is Slovakia (8, as El Salvador)
#   ES is El Salvador (3, as Spain)              ER is Ecuador -- Manta (6, as Eritrea)
#   KN is Kyrgyzstan (3, as St Kitts and Nevis)  BA is the Bahamas (2, as Bosnia)
#   CM is Colombia (as Cameroon)                 NI is Niger (as Nicaragua)
#   CR is the Czech Republic (as Costa Rica)     SM is American Samoa (as San Marino)
#   AI is Ascension Island (as Anguilla)         CU is Aruba and Curacao (7, as Cuba)
#
# and six codes resolved to nothing at all: DG Diego Garcia, JD Jordan, NW Norway, LX Luxembourg,
# PI the Philippines, WK Wake Island. 424 rows in all. Pinned here by code; anything not listed
# still goes through the ISO2C-then-FIPS lookup, which is right for the rest.
c1.country.iso3c <- c(AI = "SHN", BA = "BHS", BI = "BHR", CM = "COL", CR = "CZE", DG = "IOT",
                      ER = "ECU", ES = "SLV", ET = "EST", GB = "CUB", IR = "IRQ", JD = "JOR",
                      KN = "KGZ", KW = "MHL", LX = "LUX", NI = "NER", NW = "NOR", PI = "PHL",
                      SM = "ASM", SV = "SVK", TK = "TUR", WK = "UMI")

# G&W member states that countrycode has no gwn entry for.
c1.gw.microstates <- c(MHL = 983, FSM = 987, PLW = 986)

# Territories and dependencies. The Gleditsch and Ward list has no code for
# them, so `gwcode` used to be NA and a numeric `host` could not reach Guam or
# Puerto Rico at all. They carry the custom codes the troop data use for the
# same places (custom.gwn in data-raw/troopdata-rebuild.R), so one code selects a
# place in both data sets. Two of these ISO codes cover more than one place in
# the troop data; here each stands for the only one the C-1 reports list:
# UMI is Wake Island (1014, not Midway or Johnston Island) and SHN is Ascension
# Island (1042). tests/testthat/test-get_builddata.R checks the two tables agree.
c1.territory.codes <- c(PRI = 6, GRL = 1002, IOT = 1004, GUM = 1008, MNP = 1011,
                        VIR = 1013, UMI = 1014, ABW = 1019, CUW = 1025, ASM = 1041,
                        SHN = 1042)

c1.pinned <- files.combined.df$state_country %in% c("ML", "CU", names(c1.country.iso3c))

files.combined.df <- files.combined.df %>%
  dplyr::mutate(
    iso3c = dplyr::case_when(
      is_us_state ~ "USA",
      # "Mariana Islands" covers both Guam and the Northern Marianas (Saipan, Tinian).
      state_country == "ML" & grepl("guam", location_name, ignore.case = TRUE) ~ "GUM",
      state_country == "ML" ~ "MNP",
      state_country == "CU" & grepl("aruba", location_name, ignore.case = TRUE) ~ "ABW",
      state_country == "CU" ~ "CUW",
      state_country %in% names(c1.country.iso3c) ~ unname(c1.country.iso3c[state_country]),
      TRUE ~ to_iso3c(state_country_fixed)
    ),
    gwcode = dplyr::case_when(
      is_us_state ~ 2,
      c1.pinned ~ as.numeric(suppressWarnings(countrycode::countrycode(iso3c, "iso3c", "gwn"))),
      TRUE ~ as.numeric(to_gwn(state_country_fixed))
    ),
    gwcode = dplyr::coalesce(gwcode, unname(c1.gw.microstates[iso3c])),
    # The territory codes take precedence over anything the lookup returned.
    gwcode = dplyr::coalesce(unname(c1.territory.codes[iso3c]), gwcode)
  )

# Every row that is in a country must now have a code.
uncoded <- sort(unique(files.combined.df$iso3c[!is.na(files.combined.df$iso3c) &
                                                 is.na(files.combined.df$gwcode)]))
if (length(uncoded) > 0) {
  warning("ISO codes with no gwcode: ", paste(uncoded, collapse = ", "),
          ". Add them to c1.territory.codes with the code the troop data use.",
          call. = FALSE)
}

# Surface any overseas codes that still failed to resolve so they can be added
# to custom_iso2c above rather than silently dropped from country filtering.
unresolved <- files.combined.df %>%
  dplyr::filter(!is_us_state & is.na(iso3c)) %>%
  dplyr::distinct(state_country) %>%
  dplyr::pull(state_country)
if (length(unresolved) > 0) {
  warning(
    "Unresolved state_country codes (no ISO3C/gwcode): ",
    paste(sort(unresolved), collapse = ", ")
  )
}


# ----- Geocode locations ----------------------------------------------------

# New function to extract location names
extract_location <- function(x) {
  # 1. Strip "USA-###:" / "DoN-32:" / "USAREUR-12:" prefix (mixed case)
  x <- sub("^[A-Za-z]{2,8}-\\d+:\\s*", "", x)

  # 2. Patterns in priority order. Each pattern is reasonably specific to
  #    a real installation type, so a non-match means "no location info".
  patterns <- c(
    "\\b(?:Fort|Ft\\.?)\\s+[A-Z][A-Za-z'-]+(?:[- ][A-Z][A-Za-z'-]+)?(?:\\s*,\\s*[A-Z]{2}\\b)?",
    "\\bCamp\\s+[A-Z][A-Za-z'-]+(?:\\s*,\\s*[A-Z]{2}\\b)?",
    paste0(
      "\\b(?:NAS|NS|NSB|NWS|NAVSTA|NSA|NSWC|NCBC|NMCRC|NSWCDD)",
      "\\s+[A-Z][A-Za-z'-]+(?:\\s+[A-Z][A-Za-z'-]+){0,2}",
      "(?:\\s*,\\s*[A-Z]{2}\\b)?"
    ),
    paste0(
      "\\b(?:MCAS|MCB|MCRD|MCLB|MCSA)",
      "\\s+[A-Z][A-Za-z'-]+(?:\\s+[A-Z][A-Za-z'-]+){0,2}",
      "(?:\\s*,\\s*[A-Z]{2}\\b)?"
    ),
    paste0(
      "\\b[A-Z][A-Za-z'-]+(?:[- ][A-Z][A-Za-z'-]+)?",
      "\\s+(?:AFB|ANGB|ARB|AAF|ANG)",
      "(?:\\s*,\\s*[A-Z]{2}\\b)?"
    ),
    "\\b[A-Z][A-Za-z'-]+(?:\\s+[A-Z][A-Za-z'-]+)?\\s+Arsenal(?:\\s*,\\s*[A-Z]{2}\\b)?",
    paste0(
      "\\b[A-Z][A-Za-z'-]+",
      "(?:\\s+(?:Army|Naval|Marine|Air|Chemical|Logistics))?",
      "\\s+Depot(?:\\s*,\\s*[A-Z]{2}\\b)?"
    ),
    "\\b[A-Z][A-Za-z'-]+\\s+(?:Naval\\s+)?Shipyard(?:\\s*,\\s*[A-Z]{2}\\b)?",
    "\\b(?:Pentagon|Quantico)\\b",
    "\\b[A-Z][A-Za-z .'-]+?,\\s*[A-Z]{2}\\b"
  )

  out <- rep(NA_character_, length(x))
  for (pat in patterns) {
    todo <- is.na(out)
    if (!any(todo)) {
      break
    }
    matches <- stringr::str_extract_all(x[todo], pat)
    joined <- vapply(
      matches,
      function(m) {
        if (length(m)) {
          paste(stringr::str_squish(m), collapse = ", ")
        } else {
          NA_character_
        }
      },
      character(1)
    )
    out[todo] <- joined
  }

  stringr::str_squish(out) # NA stays NA
}


# What is sent to the geocoder, and what comes back, are both checked against
# where the row is.
#
# The address used to be "<location>, <two-letter code>": "Rota, SP", "Misawa AB,
# JA", "Heidelberg, GY". The code is the report's own, not a postal or ISO code,
# and a geocoder reads it as whatever it resembles, so Rota landed in Sao Paulo,
# Misawa on Sumatra and Heidelberg in Guyana. 644 of the 2,808 overseas rows with
# coordinates were outside their country (66 of 68 in Spain, all 44 in Bahrain),
# 41 domestic rows were outside the United States and about 300 more were in the
# wrong state. Rows with no country at all were geocoded on their label:
# "Classified Location, XC" is a point in West Virginia.
#
# Now the address spells the place out -- "Rota, Spain", "Fort Stewart, Georgia,
# United States" -- and a result is kept only if it falls inside the bounds of
# that country or state. A row gets no coordinates when:
#
#   - it is filed under no country (unspecified, worldwide, classified), unless
#     its project title names an installation and a state ("USA-224: Fort Hood,
#     TX", as the base closure rows do);
#   - its location is not a place ("Various Locations", "Unspecified Estonia");
#   - neither geocoder returns a point inside the country or state, and
#     data-raw/geocode_overrides.csv does not supply one;
#   - geocode_overrides.csv blanks it, because the place could not be located
#     or the report's location and state contradict each other.
#
# Inside the right country is not the same as at the installation. The
# corrections for that are applied after the lookups, further down.

# Where a point is, from the outlines in the `maps` package. Two tests, because
# neither is enough alone:
#
#   - which country's outline contains the point. This is what catches a result
#     just across a border -- "Ramstein, Germany" answered with a point in
#     Switzerland -- but the outlines are coarse, and a base on a coast, in a
#     harbour or on an atoll (Guantanamo Bay, Kwajalein, Bahrain) is often
#     inside none of them;
#   - whether the point is inside the smallest box that holds the country or
#     state, widened by half a degree. This is the fallback for a point that no
#     outline contains.
#
# A result is rejected when it is inside another country's outline, or inside
# none and outside the box. For a state only the box is used, along with the
# rule that the point must not be in another country: a post can sit across a
# state line from the state the report files it under (Fort Campbell).
geo.outline <- local({

  margin <- 0.5

  outline_points <- function(database) {
    m <- maps::map(database, plot = FALSE, fill = TRUE)
    piece <- cumsum(is.na(m$x)) + 1
    keep <- !is.na(m$x)
    stopifnot(max(piece) == length(m$names))
    tibble::tibble(name = m$names[piece[keep]],
                   longitude = m$x[keep],
                   latitude = m$y[keep])
  }

  # Island groups the map lists under a name of their own, with the code this
  # data files them under.
  island.groups <- c("Chagos Archipelago" = "IOT", "Ascension Island" = "SHN",
                     "Azores" = "PRT", "Madeira Islands" = "PRT",
                     "Canary Islands" = "ESP", "Micronesia" = "FSM",
                     "Barbuda" = "ATG", "Grenadines" = "VCT", "Kosovo" = "XKX",
                     "Bonaire" = "BES", "Sint Eustatius" = "BES", "Saba" = "BES",
                     "Saint Martin" = "MAF")

  world <- outline_points("world") %>%
    dplyr::mutate(region = sub(":.*$", "", name))

  regions <- tibble::tibble(region = unique(world$region)) %>%
    dplyr::mutate(geo_key = dplyr::coalesce(
      unname(island.groups[region]),
      suppressWarnings(countrycode::countrycode(region, "country.name", "iso3c"))
    ))

  countries <- world %>%
    dplyr::left_join(regions, by = "region") %>%
    dplyr::filter(!is.na(geo_key)) %>%
    dplyr::select(geo_key, longitude, latitude)

  # States: the "state" map has the lower 48 and DC. Alaska, Hawaii and the
  # offshore pieces of the others (the Florida Keys, for one) are in "world",
  # named "USA:<state>:<piece>".
  state.pieces <- world %>%
    dplyr::filter(grepl("^USA:", name)) %>%
    dplyr::transmute(geo_key = paste0("US-", usdata::state2abbr(sub("^USA:([^:]+).*$", "\\1", name))),
                     longitude, latitude)

  states <- outline_points("state") %>%
    dplyr::transmute(geo_key = paste0("US-", usdata::state2abbr(sub(":.*$", "", name))),
                     longitude, latitude)

  bounds <- dplyr::bind_rows(countries, state.pieces, states) %>%
    dplyr::filter(geo_key != "US-NA") %>%
    dplyr::group_by(geo_key) %>%
    dplyr::summarise(lon_min = min(longitude) - margin, lon_max = max(longitude) + margin,
                     lat_min = min(latitude) - margin, lat_max = max(latitude) + margin,
                     .groups = "drop") %>%
    # Wake Island is not on the map at all. UMI is used in this data for Wake only.
    dplyr::bind_rows(tibble::tibble(geo_key = "UMI", lon_min = 166.1, lon_max = 167.1,
                                    lat_min = 18.8, lat_max = 19.8))

  list(regions = regions, bounds = bounds)
})

# The country whose outline contains each point: its key, "USA" anywhere in the
# United States, or NA for a point that no outline contains.
point_country <- function(longitude, latitude) {
  out <- rep(NA_character_, length(longitude))
  ok <- !is.na(longitude) & !is.na(latitude)
  if (any(ok)) {
    region <- sub(":.*$", "", maps::map.where("world", longitude[ok], latitude[ok]))
    out[ok] <- geo.outline$regions$geo_key[match(region, geo.outline$regions$region)]
  }
  out
}

# TRUE inside the box, FALSE outside, NA where there is no box to test against.
# The world outline runs from -180 to 190 degrees, so a country that crosses the
# date line has an upper bound past 180; a longitude is tried as given and with
# 360 added.
inside_bounds <- function(longitude, latitude, lon_min, lon_max, lat_min, lat_max) {
  lon.ok <- (longitude >= lon_min & longitude <= lon_max) |
    (longitude + 360 >= lon_min & longitude + 360 <= lon_max)
  lon.ok & latitude >= lat_min & latitude <= lat_max
}

# TRUE where a point is acceptable for the place it is meant to be in, FALSE
# where it is not, NA where it cannot be judged (no outline and no box).
point_in_place <- function(longitude, latitude, geo_key, lon_min, lon_max, lat_min, lat_max) {
  found <- point_country(longitude, latitude)
  in.box <- inside_bounds(longitude, latitude, lon_min, lon_max, lat_min, lat_max)
  wants.state <- startsWith(geo_key, "US-")
  dplyr::case_when(
    is.na(longitude) | is.na(latitude) ~ NA,
    wants.state & !is.na(found) & found != "USA" ~ FALSE, # in another country
    wants.state ~ in.box,
    !is.na(found) ~ found == geo_key,                     # inside a country's outline
    TRUE ~ in.box                                         # inside none: the box decides
  )
}

# Names for the address. US states are spelled out and followed by the country.
# UMI is left blank: for Wake Island the location name is the whole address.
geo.country.name <- function(iso3c) {
  out <- suppressWarnings(countrycode::countrycode(iso3c, "iso3c", "country.name"))
  out[iso3c %in% "UMI"] <- ""
  out
}

# "<location>, <place>", without repeating a place the location already ends in
# ("Bagram Air Base, Afghanistan"; "Fort Stewart, Georgia").
geo_address <- function(location, place, place.suffix = "") {
  # One location in the FY2020 workbook holds a character that was already
  # unreadable in the source ("Fort Belvoir, VA <?> Rivanna Station").
  location <- stringr::str_squish(stringr::str_replace_all(location, "[\\p{C}\\x{FFFD}]+", " "))
  repeated <- !is.na(place) & place != "" &
    stringr::str_ends(tolower(location), stringr::fixed(paste0(", ", tolower(place))))
  location[repeated] <- stringr::str_sub(location[repeated], 1,
                                         nchar(location[repeated]) - nchar(place[repeated]) - 2)
  dplyr::case_when(
    is.na(location) | is.na(place) ~ NA_character_,
    place == "" ~ location,
    TRUE ~ paste0(location, ", ", place, place.suffix)
  )
}

# Locations that are a label rather than a place.
not.a.place <- "various|unspecified|classified|worldwide|undistributed|reduction"

files.combined.df <- files.combined.df %>%
  dplyr::mutate(
    title_location = extract_location(project_title),
    # A state named at the end of a location taken from the project title, used
    # only for rows that are filed under no country.
    title_state = stringr::str_extract(title_location, "(?<=,\\s)[A-Z]{2}$"),
    title_state = dplyr::if_else(is.na(iso3c) & !is.na(usdata::abbr2state(title_state)),
                                 title_state, NA_character_),
    # Which bounds a result has to fall inside.
    geo_key = dplyr::case_when(
      iso3c == "USA" ~ paste0("US-", state_country),
      !is.na(iso3c) ~ iso3c,
      !is.na(title_state) ~ paste0("US-", title_state),
      TRUE ~ NA_character_
    ),
    location_full_name = dplyr::case_when(
      is.na(geo_key) ~ NA_character_,
      iso3c == "USA" ~ geo_address(location_name, usdata::abbr2state(state_country),
                                   ", United States"),
      !is.na(iso3c) ~ geo_address(location_name, geo.country.name(iso3c)),
      TRUE ~ geo_address(sub(",\\s*[A-Z]{2}$", "", title_location),
                         usdata::abbr2state(title_state), ", United States")
    ),
    location_full_name = dplyr::if_else(
      !is.na(iso3c) & grepl(not.a.place, location_name, ignore.case = TRUE),
      NA_character_, location_full_name
    ),
    geo_key = dplyr::if_else(is.na(location_full_name), NA_character_, geo_key),
    # A row filed under no country whose title names a U.S. installation is in the
    # United States. These are the base realignment and closure lines of FY2007 to
    # FY2016, filed under "Unspecified Worldwide Locations" with titles such as
    # "USA-224: Fort Hood, TX": 392 rows and $11.3 billion of appropriations. They
    # were given the installation's address and coordinates but no country code, so
    # host = "USA" left them out while a map drew them inside the country. The
    # report's own columns (state_country "ZU", the location name) are left as
    # printed; the state is in location_full_name.
    placed_by_title = is.na(iso3c) & !is.na(title_state) & !is.na(location_full_name),
    iso3c = dplyr::if_else(placed_by_title, "USA", iso3c),
    gwcode = dplyr::if_else(placed_by_title, 2, as.numeric(gwcode))
  ) %>%
  dplyr::select(-title_location, -title_state, -placed_by_title)

# One set of bounds per address: the place is part of the address, so an address
# that mapped to two would be a bug in the lines above.
geo.targets <- files.combined.df %>%
  dplyr::filter(!is.na(location_full_name)) %>%
  dplyr::distinct(location_full_name, geo_key)

stopifnot(!any(duplicated(geo.targets$location_full_name)))

# Blank the coordinates of any result that is not where its row is.
check_bounds <- function(results, label) {

  if (nrow(results) == 0) {
    return(results)
  }

  checked <- results %>%
    dplyr::left_join(geo.targets, by = "location_full_name") %>%
    dplyr::left_join(geo.outline$bounds, by = "geo_key") %>%
    dplyr::mutate(
      in_place = point_in_place(longitude, latitude, geo_key,
                                lon_min, lon_max, lat_min, lat_max),
      outside = !is.na(latitude) & !is.na(in_place) & !in_place
    )

  message(label, ": ", sum(!is.na(checked$latitude)), " of ", nrow(checked),
          " addresses located, ", sum(checked$outside),
          " of them outside their country or state and discarded, ",
          sum(!is.na(checked$latitude) & is.na(checked$in_place)),
          " that could not be checked.")

  checked %>%
    dplyr::mutate(latitude = dplyr::if_else(outside, NA_real_, latitude),
                  longitude = dplyr::if_else(outside, NA_real_, longitude),
                  geo_source = dplyr::if_else(outside, NA_character_, geo_source)) %>%
    dplyr::select(location_full_name, latitude, longitude, geo_source)
}

# Geocode unique addresses once, then join back -- avoids hammering the API
# with duplicates.

# Wrapper: geocode ONE address with a given method; return NA on any error
# so a single timeout or rate-limit doesn't kill the whole loop.
safe_geocode <- function(address, method) {
  fn <- possibly(
    \(a) {
      tibble(location_full_name = a) |>
        geocode(
          address = location_full_name,
          method = method,
          lat = "latitude",
          long = "longitude",
          quiet = TRUE
        )
    },
    otherwise = tibble(
      location_full_name = address,
      latitude = NA_real_,
      longitude = NA_real_
    )
  )
  fn(address)
}

tic()

# Geocodes are cached on disk. Every address is one API call, so without a cache
# each rebuild re-looks-up several thousand locations that have not changed.
# The cache is keyed by the address, and the address format above is new, so the
# first build after this change looks every address up again; entries under the
# old format are never matched and are dropped from the file.
geocode.cache.path <- here::here("data-raw/geocode_cache.csv")

# Shape of a geocode result, used both to seed an empty cache and to stand in for
# a lookup pass with nothing to look up. map_dfr() over an empty vector returns a
# data frame with no columns at all, so the mutates below need this.
empty.geo <- tibble(
  location_full_name = character(),
  latitude = numeric(),
  longitude = numeric(),
  geo_source = character()
)

geo_cache <- if (file.exists(geocode.cache.path)) {
  readr::read_csv(geocode.cache.path, show_col_types = FALSE,
                  col_types = readr::cols(location_full_name = "c", latitude = "d",
                                          longitude = "d", geo_source = "c")) |>
    dplyr::filter(location_full_name %in% geo.targets$location_full_name)
} else {
  empty.geo
}

# Unique addresses to look up (anything already cached is skipped)
addrs <- setdiff(geo.targets$location_full_name, geo_cache$location_full_name)

message(length(addrs), " new addresses to geocode; ",
        nrow(geo_cache), " served from cache.")

# Pass 1: ArcGIS for everything not already cached
arcgis_results <- if (length(addrs) > 0) {
  map_dfr(addrs, safe_geocode, method = "arcgis") |>
    mutate(geo_source = if_else(!is.na(latitude), "arcgis", NA_character_)) |>
    check_bounds("ArcGIS")
} else {
  empty.geo
}

# Pass 2: OSM as backstop for addresses ArcGIS couldn't resolve, or resolved to
# a point outside the country or state
holdouts <- arcgis_results |>
  filter(is.na(latitude)) |>
  pull(location_full_name)

osm_results <- if (length(holdouts) > 0) {
  map_dfr(holdouts, safe_geocode, method = "osm") |>
    mutate(geo_source = if_else(!is.na(latitude), "osm", NA_character_)) |>
    check_bounds("OSM")
} else {
  empty.geo
}

# Combine: keep ArcGIS hits, fill misses with OSM hits. The cache is checked
# again as it is read back, so nothing reaches the data unchecked.
geo_lookup <- arcgis_results |>
  filter(!is.na(latitude)) |>
  bind_rows(osm_results) |>
  bind_rows(check_bounds(geo_cache, "Cache")) |>
  distinct(location_full_name, .keep_all = TRUE)

# A lookup pass that finds almost nothing means the geocoding service was not
# reachable, not that the addresses are bad. Say so rather than ship a file with
# no coordinates, and do not write the misses to the cache.
if (length(addrs) > 50 && mean(is.na(geo_lookup$latitude[geo_lookup$location_full_name %in% addrs])) > 0.5) {
  warning("More than half of the ", length(addrs), " new addresses came back with no coordinates. ",
          "Check the connection to the geocoding services and run the build again; ",
          "the cache has not been updated.", call. = FALSE)
} else {
  # Refresh the cache with everything resolved so far.
  readr::write_csv(geo_lookup, geocode.cache.path)
}

# Corrections to the geocoder, kept in data-raw/geocode_overrides.csv.
#
# A point inside the right country or state is not necessarily the installation.
# Checked against where each installation is, the first full run put 92 of the
# 1,406 located addresses 37 to 2,454 km away, in two ways the bounds test
# cannot see:
#
#   - when a geocoder does not know the place it answers with the centre of the
#     country or state. Eleven Korean camps, Camp Humphreys among them, shared
#     one point in the middle of South Korea; nine bases in Afghanistan and six
#     in Iraq did the same.
#   - a name that exists twice resolves to the other one: "Yorktown, Virginia"
#     to a neighbourhood of Arlington, "Langley AFB" to Langley in McLean,
#     "Camp Butler, Japan" to Honshu rather than Okinawa, "Incirlik AB, Turkey"
#     to a village 550 km east of Adana.
#
# The file gives the address exactly as it appears in location_full_name, the
# coordinates, what the installation is, what the coordinates are of (the base,
# its airfield, or the nearest town where the base itself could not be found)
# and the page they were read from. A row with no coordinates blanks the
# geocoder's answer: it is used where the place could not be located, or where
# the report's location and state contradict each other. Rows are applied after
# the cache is written, so the cache stays what the geocoders returned, and
# they go through the same country and state test as everything else.
geocode.overrides.path <- here::here("data-raw/geocode_overrides.csv")

geo.overrides <- readr::read_csv(
  geocode.overrides.path, show_col_types = FALSE,
  col_types = readr::cols(location_full_name = "c", latitude = "d", longitude = "d",
                          .default = "c")
) %>%
  dplyr::select(location_full_name, latitude, longitude)

stopifnot(!any(duplicated(geo.overrides$location_full_name)),
          !any(xor(is.na(geo.overrides$latitude), is.na(geo.overrides$longitude))))

# An override for an address that is no longer in the data is a spelling that
# has drifted, or a location a newer report dropped. Say so, and leave it out.
overrides.unused <- setdiff(geo.overrides$location_full_name, geo.targets$location_full_name)

if (length(overrides.unused) > 0) {
  warning("geocode_overrides.csv has ", length(overrides.unused),
          " address(es) that are not in the data: ",
          paste(overrides.unused, collapse = "; "), call. = FALSE)
}

geo.overrides <- geo.overrides %>%
  dplyr::filter(location_full_name %in% geo.targets$location_full_name) %>%
  dplyr::mutate(geo_source = dplyr::if_else(!is.na(latitude), "manual", NA_character_))

geo.overrides.checked <- check_bounds(geo.overrides, "Overrides")

# A correction that fails the test is a mistake in the file, not a geocoder miss.
overrides.rejected <- geo.overrides$location_full_name[
  !is.na(geo.overrides$latitude) &
    is.na(geo.overrides.checked$latitude[match(geo.overrides$location_full_name,
                                               geo.overrides.checked$location_full_name)])
]

if (length(overrides.rejected) > 0) {
  warning("geocode_overrides.csv places ", length(overrides.rejected),
          " address(es) outside their country or state; they have no coordinates: ",
          paste(overrides.rejected, collapse = "; "), call. = FALSE)
}

geo_lookup <- geo_lookup %>%
  dplyr::filter(!location_full_name %in% geo.overrides.checked$location_full_name) %>%
  dplyr::bind_rows(geo.overrides.checked)

message("Coordinate overrides: ", sum(!is.na(geo.overrides.checked$latitude)),
        " addresses placed by hand, ", sum(is.na(geo.overrides.checked$latitude)),
        " left without coordinates.")

# Join back to the original df
files.combined.df <- files.combined.df |>
  left_join(geo_lookup, by = "location_full_name") |>
  dplyr::select(-geo_key)

toc()


# Convert variables to numeric where appropriate

numeric_cols <- c(
  "appn_amount",
  "auth_amount",
  "auth_appn_amount",
  "toa_amount",
  "existing_footprint",
  "percent_recapitalization",
  "budget_activity",
  "fiscal_year",
  "latitude",
  "longitude"
)

# Convert numeric columns to numeric. The rest are all character columns.
files.combined.df <- files.combined.df |>
  mutate(across(
    any_of(numeric_cols),
    # Columns that are already numeric (latitude and longitude, from the geocoder)
    # are left alone: round-tripping them through gsub() would expose them to the
    # same scientific-notation problem described above.
    \(x) if (is.numeric(x)) x else suppressWarnings(as.numeric(gsub("[^0-9.\\-]", "", x)))
  )) %>%
  # Rows with no location, no state or country and no project: blank lines that
  # carried a fiscal year. (This used to test the address for "NA, NA", which
  # only worked while every row had an address.)
  dplyr::filter(!(is.na(location_name) & is.na(state_country) & is.na(project_title)))


# ----- Column and row order -------------------------------------------------

# Up to here the columns sit in whatever order the sheets, the merges and the
# derived fields produced -- alphabetical, from the `sort(names.preserve)`
# select further up -- which puts amounts next to provenance and scatters the
# geography across the frame. Order them instead by what a reader looks for
# first: country, year, location, who built it, what was built, then the money,
# then the fields only some report years carry, then provenance last.
#
# Within each block the identifier comes before its companions, and a
# harmonized label is immediately followed by the *_reported string it was
# derived from, so a value and the source wording sit side by side.
column.order <- c(

  # Country
  "gwcode", "iso3c", "state_country", "state_country_name",
  "state_country_sort",

  # Year
  "fiscal_year",

  # Location
  "location_name", "location_name_reported", "location_full_name",
  "location_code", "latitude", "longitude", "geo_source",

  # Organization
  "organization", "organization_reported",

  # Project
  "project_number", "project_title", "project_title_reported",

  # Appropriation account and facility taxonomy, coarse level before fine
  "appn_title", "budget_activity", "budget_activity_title",
  "budget_activity_title_reported", "facility_group_title",
  "facility_category_code", "facility_category_title",
  "facility_category_title_reported",

  # Amounts, in thousands of current US dollars
  "toa_amount", "appn_amount", "auth_amount", "auth_appn_amount",
  "transaction_type", "dollar_type",

  # Project attributes carried by only a few report years
  "existing_mission", "percent_recapitalization", "pe", "classification",

  # Provenance
  "source_file", "source_sheet", "source_row", "report_year", "sheet_type",
  "is_request"
)

# Warn rather than stop on schema drift. any_of() keeps every column, so one
# that is not listed is appended at the end instead of being silently dropped,
# and a listed column that no longer exists is reported rather than failing the
# last step of a long build.
order.not.in.data <- setdiff(column.order, names(files.combined.df))
data.not.in.order <- setdiff(names(files.combined.df), column.order)

if (length(order.not.in.data) > 0) {
  warning("column.order lists columns that are not in the data: ",
          paste(sort(order.not.in.data), collapse = ", "),
          call. = FALSE)
}
if (length(data.not.in.order) > 0) {
  warning("Columns missing from column.order, appended at the end: ",
          paste(sort(data.not.in.order), collapse = ", "),
          call. = FALSE)
}

files.combined.df <- files.combined.df %>%
  dplyr::relocate(tidyselect::any_of(column.order)) %>%
  # Rows follow the same logic. iso3c sorts NA last, so the unspecified and
  # worldwide rows -- which carry an amount but no usable location -- collect at
  # the end rather than leading the file. Largest project first within a
  # location-year.
  dplyr::arrange(iso3c, fiscal_year, location_name,
                 dplyr::desc(toa_amount), project_title)

message("Final frame: ", nrow(files.combined.df), " rows, ",
        ncol(files.combined.df), " columns, fiscal years ",
        min(files.combined.df$fiscal_year, na.rm = TRUE), "-",
        max(files.combined.df$fiscal_year, na.rm = TRUE), ".")


write_csv(files.combined.df, here::here("data-raw/build_data_20260604.csv"))


# Save data for rda file.
build_data_20260918 <- files.combined.df

usethis::use_data(build_data_20260918,
                  overwrite = TRUE,
                  internal = FALSE)


