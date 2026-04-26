# .Rprofile for metabo2026
#
# Forces the cairo graphics backend so that grid::stringMetric and friends
# never reach for the legacy X11 bitmap-font path. This is what fixes the
# "X11 font -adobe-helvetica-... could not be loaded" error from
# MetaProViz::viz_heatmap on bare Ubuntu LTS VMs.
#
# Requires libcairo2 + a TTF font set (fonts-dejavu / fonts-liberation).
# Both are present on a default Ubuntu 22.04 install.

local({
    options(
        bitmapType = "cairo",
        device = function(...) grDevices::png(..., type = "cairo")
    )
    try(grDevices::X11.options(type = "cairo"), silent = TRUE)
})
