#' Helper function to verify package availability
#'
#' @importFrom purrr map_df
#' @importFrom tibble tibble
#' @param packages Packages to verify are available.
#' @param func Calling function.
#'
#' @return Invisible
#' @noRd
#' @examples
#' \dontrun{
#' check_availability(packages = c("ggplot2", "dplyr"), func = "my_function")
#' }
check_availability <- function(packages, func) {
  res <- purrr::map_df(packages,
                       ~ tibble::tibble(package = .x,
                                        available = requireNamespace(.x, quietly=TRUE)))
  if (sum(res$available) != length(packages)) {
    stop(func, " requires the following packages which are not available: ",
         paste0(res[, ]$package, collapse = ", "), "\n",
         "Please install and try again.", call. = FALSE)
  }

  invisible()

}

#' Format dollar amounts in terms of millions of USD
#'
#' Given a number, return a string formatted in terms of millions of dollars.
#'
#' @importFrom dplyr %>%
#' @param x A number.
#' @return String in the format of $xM.
#' @export
#' @examples
#' dollar_millions(1.523 * 10^6)
dollar_millions <- function(x) {
  # paste0('$', x / 10 ^ 6, 'M')
  x <- (x/10^6) %>% round(digits = 2)
  paste0("$", x, "M")
}

#' Calculate maximum losses
#'
#' Calculate the biggest single annual loss for each scenario, as well as
#'   the minimum and maximum ALE across all simulations. Calculations both
#'   with and without outliers (if passed) are returned.
#'
#' @importFrom dplyr filter group_by summarize ungroup union
#' @importFrom rlang .data
#' @param simulation_results Simulation results dataframe.
#' @param scenario_outliers Optional vector of IDs of outlier scenarios.
#' @return A dataframe with the following columns:
#'   - `scenario_id` - index of the simulation
#'   - `biggest_single_scenario_loss` - the biggest annual loss in that simulation,
#'   - `min_loss` - the smallest annual loss in that simulation,
#'   - `max_loss` - the total annual losses in that simulation
#'   - `outliers` - logical of whether or not outliers are included
#' @export
#' @examples
#' data(simulation_results)
#' calculate_max_losses(simulation_results)
calculate_max_losses <- function(simulation_results, scenario_outliers = NULL) {
  max_loss <- simulation_results %>%
    dplyr::filter(!.data$scenario_id %in% scenario_outliers) %>%
    dplyr::group_by(.data$simulation) %>%
    dplyr::summarize(biggest_single_scenario_loss = max(.data$ale),
                      min_loss = min(.data$ale), max_loss = sum(.data$ale),
                      outliers = FALSE) %>%
    dplyr::ungroup()
  # if we're not passed any outliers, don't bother calculating outliers
  if (is.null(scenario_outliers)) return(max_loss)

  max_loss_w_outliers <- simulation_results %>%
    dplyr::group_by(.data$simulation) %>%
    dplyr::summarize(biggest_single_scenario_loss = max(.data$ale),
                      min_loss = min(.data$ale),
                      max_loss = sum(.data$ale), outliers = TRUE) %>%
    dplyr::ungroup()
  dplyr::union(max_loss, max_loss_w_outliers)
}
