# ---- Load functions ----

#' Convert 2005 Julian Day to Date Time
#'
#' Conversion from julian day to date time checked against sources/data_reduction/surveys_reduced_6_05.xls. These are believed to be in local time (ADT, UTC-8): The times of large calving events (sources/coord_trans/big_calves_lines.txt, sources/coord_trans/biggest_events.txt) – plotted unaltered in sources/coord_trans/marker_tracklines.m – match those in the original calving observations (CG05_calving_obs.xls), which are in local time.
#'
#' @param julian_day Julian day of 2005 in local time (ADT, UTC-8).
#' @return ISO 8601 date time in UTC.
#' @examples
#' julian_day_to_datetime(153.9652778) # 2005-06-03 07:10:00
julian_day_to_datetime <- function(julian_day) {
  utc_offset <- -8 * (60 * 60)
  origin <- strptime("2004-12-31 00:00:00", "%Y-%m-%d %H:%M:%S", tz = "UTC")
  as.POSIXct(julian_day * (60 * 60 * 24) - utc_offset, tz = "UTC", origin = origin)
}

#' Convert WGS84 Lng, Lat to UTM (Alaska, Zone 6N)
#'
#' @param lnglat WGS84 geographic coordinates.
#' @return WGS84 Zone 6N UTM coordinates.
lnglat_to_utm <- function(lnglat) {
  lnglat <- as.data.frame(if (is.vector(lnglat)) t(lnglat) else lnglat)[, 1:2]
  sp::coordinates(lnglat) <- names(lnglat)
  sp::proj4string(lnglat) <- sp::CRS("+proj=longlat +datum=WGS84")
  return(sp::spTransform(lnglat, sp::CRS("+proj=utm +zone=6"))@coords)
}

# ---- Markers 1, 3, 4 (June 2005) ----

# Load files
filenames <- c(
  "sources/coord_trans/mk111.txt",
  "sources/coord_trans/mk333.txt",
  "sources/coord_trans/mk444.txt"
)

results <- lapply(filenames, function(filename) {
  read.table(filename) %>%
    # Assign columns (sources/coord_trans/survey_coord_trans.m)
    set_names(c("marker", "t", "x", "y", "z"))
})

# ---- Marker 2 (June 2005) ----

filename <- "sources/data_reduction/surveys_reduced_6_05.xls"
temp <- readxl::read_excel(filename, sheet = "Sheet1", skip = 7)
names(temp) <- make.names(names(temp), unique = TRUE)
df <- temp[!is.na(temp$Marker) & temp$Marker == 222, c("Marker", "Tavg__1", "Ereduced", "Nreduced", "Z")]
names(df) <- c("marker", "t", "x", "y", "z")
results <- c(results, list(df))

# ---- Marker 5 (September 2005) ----

filename <- "sources/CG_2005SurveyData_Shad/SeptSurveyMatlabIn.xls"
temp <- readxl::read_excel(filename, sheet = "ExportMatlab")
df <- temp[, c("Tavg", "Ereduced", "Nreduced", "Z")]
df <- cbind(555, df)
names(df) <- c("marker", "t", "x", "y", "z")
results <- c(results, list(df))

# ---- Merge results ----

df <- do.call("rbind", results)

# ---- Simplify marker identifers ----

# Use single digit integer
df$marker <- floor(df$marker / 100)

# ---- Convert decimal day to datetime ----

# Convert local julian day to UTC datetime
df$t <- julian_day_to_datetime(df$t)

# ---- Convert local to world coordinates (xy) ----

# Gun local coordinates (sources/data_reduction/surveys_reduced_6_05.xls)
gun_local <- c(5000, 5000, 1000)
# Gun and reference coordinates (GPS/2005/2005_GPS_coords.xls and GPS/2005/coords.CSV as WGS84 Lng, Lat, HAE)
# NOTE: These match sources/coord_trans/survey_coord_trans.m (as NAD27 UTM)
gun <- c(-(147 + 3 / 60 + 19.69752 / 3600), 61 + 7 / 60 + 6.95838 / 3600, 154.432)
gun[1:2] <- lnglat_to_utm(gun[1:2])
ref <- c(-(147 + 3 / 60 + 19.73640 / 3600), 61 + 7 / 60 + 11.21458 / 3600, 162.526)
ref[1:2] <- lnglat_to_utm(ref[1:2])
# Local coordinates relative to gun
# NOTE: Results differ from original (sources/coord_trans/survey_coord_trans.m), where coordinates were rotated without first substracting origin (5000, 5000) as done here.
dxy <- sweep(as.matrix(df[c("x", "y")]), 2, gun_local[1:2], FUN = "-")
# Align with UTM axes
# NOTE: Need rotation counterclockwise relative to +y. Adjustment (pi/2) needed since atan2 relative to +x.
theta <- atan2(ref[2] - gun[2], ref[1] - gun[1]) - pi / 2
R <- matrix(c(cos(theta), sin(theta), -sin(theta), cos(theta)), nrow = 2, byrow = TRUE)
xy <- sweep(dxy %*% R, 2, gun[1:2], FUN = "+")
# Save result
df[c("x", "y")] <- xy

# ---- Plot results ----

plot(df[df$marker == 1, c("x", "y")], xlim = range(c(df$x, gun[1])), ylim = range(c(df$y, gun[2])), asp = 1)
points(df[df$marker == 2, c("x", "y")], col = "red")
points(df[df$marker == 3, c("x", "y")], col = "green")
points(df[df$marker == 4, c("x", "y")], col = "yellow")
points(df[df$marker == 5, c("x", "y")], col = "blue")
points(gun[1], gun[2], col = "red")
term <- read.table("sources/coord_trans/terminus_178_04.txt")
sp::coordinates(term) <- names(term)
sp::proj4string(term) <- sp::CRS("+proj=utm +zone=6 +datum=NAD27")
sp::plot(sp::spTransform(term, sp::CRS("+proj=utm +zone=6 +datum=WGS84")), add = TRUE)

# ---- Convert local to world coordinates (z) ----

df$z <- gun[3] - (gun_local[3] - df$z)

# ---- Save results ----

resource <- df %>%
  dplyr::transmute(
    track = marker %>%
      as.integer() %>%
      dpkg::set_field(description = "Track identifier (marker #)"),
    t = t %>%
      dpkg::set_field(description = "Date and time (UTC)"),
    x = x %>%
      units::set_units("m") %>%
      dpkg::set_field(description = "Easting (WGS84 UTM Zone 6N, EPSG:32606)"),
    y = y %>%
      units::set_units("m") %>%
      dpkg::set_field(description = "Northing (WGS84 UTM Zone 6N, EPSG:32606)"),
    z = z %>%
      units::set_units("m") %>%
      dpkg::set_field(description = "Elevation (height above the WGS84 ellipsoid)")
  ) %>%
  dpkg::set_resource(
    name = "positions",
    path = "data/positions.csv"
  )

dp <- list(resource) %>%
  dpkg::set_package(
    name = "optical-surveys-2005",
    title = "Optical Surveys (2005)",
    description = "Four survey targets (1, 2, 3, 4) were deployed in June 2005 and one (5) in September 2005, within one km of the calving face using a helicopter. The maximum lifetime of the markers was limited to 15 days, before each succumbed to calving. Positions of the targets were obtained using a Leica total station robotic survey theodolite at nominal time separation of 20-30 minutes.",
    version = "0.1.0",
    contributors = list(
      dpkg::contributor("Ethan Welty", email = "ethan.welty@gmail.com", role = "author"),
      dpkg::contributor("Shad O'Neel", role = "Performed the research and processed the data")
    ),
    sources = list(
      dpkg::source("Original data, scripts, and documentation", path = "sources/")
    )
  )

dpkg::write_package(dp)
