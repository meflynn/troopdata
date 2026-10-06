# The package's public API.
#
# A missing @export fails no other test in this suite. testthat runs test files
# with the package namespace as their parent environment, so an unexported
# function is still callable from a test and the whole suite passes while
# troopdata::get_troopdata() does not exist for users. Only an explicit check of
# the NAMESPACE catches it.
#
# This file exists because get_troopdata() lost its export exactly that way: a
# helper was defined between its roxygen block and the function, so roxygen2
# attached the block -- @export, title, every @param -- to the helper instead.
# R CMD check reported it only indirectly, as undocumented and mismatched
# arguments in the helper's Rd file.

test_that("the package exports exactly its public API", {
  expect_setequal(
    getNamespaceExports("troopdata"),
    c("%>%", "get_basedata", "get_builddata", "get_exercises", "get_troopdata")
  )
})

test_that("every exported function resolves and is a function", {
  for (f in c("get_basedata", "get_builddata", "get_exercises", "get_troopdata")) {
    expect_true(is.function(getExportedValue("troopdata", f)),
                info = paste(f, "is not an exported function"))
  }
})

test_that("internal helpers stay internal", {
  # max_reported() is a one-line guard around max(na.rm = TRUE); it is not part
  # of the public interface. If it is ever exported deliberately, add it to the
  # expected set above rather than deleting this test.
  expect_false("max_reported" %in% getNamespaceExports("troopdata"))
  expect_true(is.function(get("max_reported", envir = asNamespace("troopdata"))))
})
