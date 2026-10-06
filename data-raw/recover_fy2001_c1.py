"""Recover the FY2001 Comptroller C-1 workbook to CSV.

fy2001_c1.xls is not an OLE2 workbook like the other .xls files in the
Comptroller Annual Reports folder, and libxls -- which readxl uses -- cannot
open it, so R silently skipped it. That workbook is the only source for FY2000
(425 rows) alongside FY2001 (309 rows).

Its header spans rows 4-5 with two unlabeled columns and one labeled column that
is empty, so the names below are assigned positionally from inspection of the
sheet. Column 3 carries the service letter (A, F, N, D) that other years call
"Comp", and column 11 is labeled "Organization" but holds nothing.

Run from the repository root:

    python3 data-raw/recover_fy2001_c1.py

Writes data-raw/fy2001_c1_recovered.csv, which build_data_20260603.R binds in.
"""

import csv
import os

import xlrd

SOURCE = os.path.expanduser(
    "~/Dropbox/Projects/Troop Data/Data Files/Construction Spending/"
    "Comptroller Annual Reports/fy2001_c1.xls"
)
DEST = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                    "fy2001_c1_recovered.csv")

NAMES = [
    "fiscal_year",
    "treasury_code",
    "comp",
    "state_country",
    "location_code",
    "location_title",
    "project_number",
    "project_title",
    "ba",
    "facility_category_code",
    "organization_unused",   # labeled "Organization" in the sheet but empty
    "auth_amount",
    "appn_amount",
    "facility_group_title",
]

FIRST_DATA_ROW = 5


def main():
    sheet = xlrd.open_workbook(SOURCE).sheet_by_index(0)
    if sheet.ncols != len(NAMES):
        raise SystemExit(
            f"expected {len(NAMES)} columns, found {sheet.ncols}; "
            "the workbook layout has changed"
        )

    keep = [i for i, name in enumerate(NAMES) if name != "organization_unused"]
    written = 0

    with open(DEST, "w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow([NAMES[i] for i in keep])

        for row in range(FIRST_DATA_ROW, sheet.nrows):
            values = [sheet.cell_value(row, col) for col in range(sheet.ncols)]
            year = str(values[0]).strip()[:4]
            if not year.isdigit():
                continue          # title, subtotal and spacer rows
            writer.writerow([values[i] for i in keep])
            written += 1

    print(f"wrote {DEST}: {written} rows")


if __name__ == "__main__":
    main()
