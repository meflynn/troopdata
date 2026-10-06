# U.S. Military construction spending data

`build_data_20260918` returns a data frame containing geocoded
location-project-year military construction spending data, for projects
in the United States and overseas.

## Usage

``` r
build_data_20260918
```

## Format

A data frame of location-project-year observations including the
following variables:

- `fiscal_year`:

  Fiscal year of the project.

- `state_country`:

  Two-letter state or country code as reported. Overseas codes mix ISO2C
  with legacy FIPS 10-4 and DoD codes.

- `state_country_name`:

  Readable form of the state or country as reported. The only form
  available for codes such as ZU (Unspecified Worldwide Locations),
  which have no country identifier.

- `iso3c`:

  ISO three character country code. NA for unspecified and worldwide
  locations. The 392 lines of FY2007-FY2016 that are filed under
  "Unspecified Worldwide Locations" but name a U.S. installation in
  their project title (`"USA-224: Fort Hood, TX"`) carry `"USA"`;
  `state_country` and `location_name` are left as the report prints
  them, and the installation and state are in `location_full_name`.

- `gwcode`:

  Gleditsch and Ward country code. The G&W list has no code for a
  dependency, so territories carry the custom codes the troop data use
  for the same places: Puerto Rico 6, Greenland 1002, Diego Garcia 1004,
  Guam 1008, the Northern Mariana Islands 1011, the U.S. Virgin Islands
  1013, Wake Island 1014, American Samoa 1041 and Ascension Island 1042.
  NA for unspecified and worldwide locations.

- `location_name`:

  Installation or location, in title case with initialisms preserved.
  The reports write the same place in block capitals one year and title
  case the next; a derived list of protected tokens keeps forms like
  `"MCAS Iwakuni"`, `"MacDill AFB"` and `"RAF Lakenheath"` intact.

- `location_name_reported`, `project_title_reported`:

  The location and project title as the source sheet wrote them, before
  case harmonization.

- `location_full_name`:

  The address sent to the geocoder: the location followed by the
  country, or by the state and `"United States"`. NA for rows that are
  not geocoded.

- `location_code`:

  Comptroller location code.

- `latitude`, `longitude`:

  Coordinates of the location, kept only where the geocoded point falls
  inside the country or state the row is filed under. NA for rows filed
  under no country (unspecified, worldwide and classified locations),
  for locations that are a label rather than a place
  (`"Various Locations"`), and where no point inside the country or
  state was found. A point inside the right country is not always the
  installation: a geocoder that does not know a place answers with the
  centre of the country, or with another place of the same name. The
  installations found to be placed that way are corrected by hand
  (`geo_source` is `"manual"`); the few that could not be located have
  no coordinates.

- `geo_source`:

  Where the coordinates came from: the geocoding service that resolved
  the location (`"arcgis"` for every geocoded row in the current data),
  or `"manual"` for a point entered by hand from
  `data-raw/geocode_overrides.csv`, which records what each point is and
  the page it was read from.

- `organization`:

  Service or agency, harmonized across years to full names: `"Army"`,
  `"Navy"`, `"Air Force"`, `"Defense-Wide"`,
  `"Special Operations Command"` and other defense agencies. Marine
  Corps construction is carried in the Navy accounts and has no value of
  its own; guard and reserve components appear in `appn_title`.

- `organization_reported`:

  The organization string as the source sheet wrote it, before
  harmonization.

- `project_number`, `project_title`:

  Project identifier and description. The title is in title case with
  initialisms preserved.

- `appn_amount`, `auth_amount`, `auth_appn_amount`, `toa_amount`:

  Appropriation, authorization, authorization of appropriation, and
  total obligational authority, in thousands of current US dollars.
  Negative values occur for rescissions and reprogramming.

- `appn_title`:

  Appropriation account title.

- `budget_activity`:

  Budget activity number. Meaningful only within an appropriation
  account: activity 1 is major construction in the MILCON accounts but
  FY 2005 BRAC, new construction or direct loan subsidy in others.

- `budget_activity_title`:

  Budget activity, harmonized to one label per activity across years.
  The source workbooks write these inconsistently, with case variants,
  abbreviations, truncations and typos.

- `budget_activity_title_reported`:

  The budget activity label as the source sheet wrote it, before
  harmonization.

- `facility_category_title_reported`:

  The facility title as the source sheet wrote it, before case and
  abbreviation harmonization.

- `facility_category_code`, `facility_category_title`:

  The three-digit DoD facility category code and its title, in sentence
  case with initialisms preserved. One code maps to exactly one title.

- `facility_group_title`:

  The coarse level of the DoD facility taxonomy, in sentence case. The
  reports carry it under three different headers – "Facility Group
  Title", "Fiscal Category Title", and, in the most recent years, the
  facility category column – and all three are collected here. Kept
  separate from `facility_category_title`, the finer three-digit level
  of the same taxonomy, though the split is a reconstruction rather than
  something the reports maintain;
  [`get_builddata()`](https://meflynn.github.io/troopdata/reference/get_builddata.md)
  therefore searches both columns from its single `facility_category`
  argument.

- `transaction_type`:

  Type of budget action, where reported (`"BUDGET"`, `"REPROGRAM"`,
  rescissions). NA for most rows.

- `sheet_type`:

  Which kind of sheet the row came from: `"base"` for regular
  fiscal-year sheets, or `"oco"` for an overseas contingency operations
  exhibit. The other supplemental exhibits restate lines of the regular
  sheets and are not in the data.

- `source_file`, `source_sheet`, `source_row`:

  Workbook and sheet the row was read from, and its position in that
  sheet counting from 1 below the header. Together they identify one
  line of one report. A report can list two projects that agree in every
  other column, and this is what tells them apart.

- `report_year`:

  Latest fiscal year covered by the source workbook, i.e. the report
  vintage. Consecutive reports restate the same fiscal years, and every
  fiscal year here comes from the most recent report that covers it.

- `is_request`:

  TRUE where the row is a budget request rather than an enacted figure:
  the fiscal year is the terminal year of its source report, or the row
  comes from a request sheet. That is all of FY2016, whose later reports
  are not among the source files, and 26 lines of FY2010 from the
  overseas contingency operations request sheet (`"C1_2010_OCO_Req"`)
  that are on no enacted sheet.

- `classification`:

  Security classification marking carried on the row, `"U"` for
  unclassified. FY2011 onward.

- `dollar_type`:

  Kind of dollar figure the row reports (`"Budget"` or
  `"Congressional Rescission"`). FY2003-FY2005.

- `existing_mission`:

  Whether the project supports an existing mission, as reported.
  FY2003-FY2005.

- `pe`:

  Program element. FY2003-FY2004.

- `percent_recapitalization`:

  Share of the project classed as recapitalization. No values: only the
  FY2008 report printed it, and the years it covers are taken from later
  reports.

- `state_country_sort`:

  Sort key the source sheet used for the state or country column.
  FY2006.

## Value

Returns the full data frame containing location-project-year
observations of U.S. military construction spending, compiled from the
DoD Comptroller Annual Report C-1 exhibits. All amounts are in thousands
of current US dollars. Each fiscal year is taken from the most recent
report that covers it, so a project-year appears once, and each row is
one line of that report.

## Year coverage

The C-1 exhibit layout changed over time, and a later report does not
always print what an earlier one did, so several fields are reported
only for a subset of years: `transaction_type` and `appn_title`
FY2001-FY2002; `pe` FY2003-FY2004; `dollar_type` and `existing_mission`
FY2003-FY2005; `location_code` FY2000-FY2006; `facility_category_code`
FY2000 and FY2003-FY2006; `project_number` FY2000-FY2006 and FY2013
onward; `state_country_sort` FY2006; `classification` FY2011 onward;
`facility_category_title` FY2003-FY2005, FY2007-FY2021 and FY2026;
`facility_group_title` FY2000 and FY2007 onward; `state_country_name`
FY2006 and FY2009 onward. FY2006 reports appropriations only, so
`toa_amount`, `auth_amount`, `auth_appn_amount` and
`budget_activity_title` are missing for that year; `toa_amount` and
`auth_appn_amount` are also missing for FY2000, and
`budget_activity_title` for FY2000 and FY2008. The workbooks that supply
FY2004-FY2007 give the service of an Army, Navy or Air Force line in
their "Treasury Agency" column rather than under "Organization";
`organization` is filled from it, and `organization_reported` holds the
letter printed there (`"A"`, `"N"` or `"F"`). The series runs FY2000
through FY2026.
