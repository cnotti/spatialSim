% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/setup_om.R
\name{setup_om}
\alias{setup_om}
\title{Specify the settings and parameters of OM}
\usage{
setup_om(
  nb,
  ny,
  np = 12,
  nc,
  nl,
  nfishp,
  fishp1,
  nyAssess = ny,
  fn_growth,
  fn_weight,
  sigmaG_c,
  alpha_c,
  mugI = 0,
  mugH = 0,
  sigmagI,
  taugH,
  kappaH,
  phiIt,
  phiHt,
  phiHl,
  fn_select,
  limit_c,
  areadredge,
  ptarget = 0.9,
  F_intensity = 0.2,
  ffirst_c = rep(0, nc),
  F_settings = 0,
  f_c_fstar,
  f_ct_fsurv,
  probZero = 0,
  catchZero = 0,
  fn_mature,
  R0_c,
  h_c,
  psi_p,
  psi_l,
  psi_cs,
  psi_csb = array(1, c(nc, ns, nb)),
  psi_cst = array(1, c(nc, ns, nt)),
  mugE = 0,
  taugE,
  kappaE,
  phiEt,
  Rho_cc,
  Rrange_c,
  Rthreshold_c = rep(0, nc),
  optionRrange = 0,
  loc_s,
  loc_f,
  mesh,
  lnaniso = rep(0, 2),
  projection = "utm",
  lmin_c = rep(0, nc),
  lmax_c,
  seed = NULL,
  species_names = 1:nc
)
}
\arguments{
\item{nb}{number of time-steps in initialization phase}

\item{ny}{number of years}

\item{np}{number of time-steps within each year}

\item{nc}{number of species}

\item{nl}{number of size intervals}

\item{nfishp}{number of time-steps that make up commercial fishing season}

\item{fishp1}{index (zero-indexed) of first annual period of the fishing season}

\item{nyAssess}{number of years to run model before updating harvest restrictions}

\item{fn_growth}{function specifying the growth of individuals}

\item{fn_weight}{function specifying size-weight relationship}

\item{sigmaG_c}{standard deviations of the expected growth increments on the log scale for each species}

\item{alpha_c}{expected rates of instantaneous natural mortality for each species}

\item{mugI}{expected value of iota}

\item{mugH}{expected value of eta}

\item{sigmagI}{marginal sd of iota}

\item{taugH}{SPDE scale parameter of eta}

\item{kappaH}{SPDE range parameter of eta}

\item{phiIt}{temporal autocorrelation parameter of iota}

\item{phiHt}{temporal autocorrelation parameter of eta}

\item{phiHl}{size autocorrelation parameter of eta}

\item{fn_select}{function specifying fishing selectivity}

\item{limit_c}{harvest limit for each species}

\item{areadredge}{area-swept by fishers}

\item{ptarget}{probability of fishers harvesting from sites with above average densities of individuals}

\item{F_intensity}{parameter controlling intensity of commercial harvesting}

\item{f_c_fstar}{indices (zero-indexed) of \code{loc_f} making up sub-area of domain that commercial fishers will fish}

\item{f_ct_fsurv}{indices (zero-indexed) of \code{loc_f} specifying survey sites}

\item{probZero}{probability of sampling a zero catch given the potential catch at site i is less than \code{cathZero}}

\item{catchZero}{if potential catch at site i is less than \code{catchZero} sample a zero with probability \code{probZero}}

\item{fn_mature}{function specifying sexual maturity}

\item{R0_c}{scale term of stock recruit function for each species}

\item{h_c}{stock-recruit steepness parameters for each species}

\item{psi_p}{probability of recruitment given the annaul period/season}

\item{psi_l}{size distribution of new recruits}

\item{psi_cs}{probability of an individual recruiting conditional on the environmental conditions at locations \code{loc_s}}

\item{psi_csb}{spatial temporal scaling on (0,1) of environmental effect psi_cs for initialization period}

\item{psi_cst}{spatial temporal scaling on (0,1) of environmental effect psi_cs}

\item{mugE}{expected value of epsilon}

\item{taugE}{SPDE scale parameter of epsilon}

\item{kappaE}{SPDE range parameter of epsilon}

\item{phiEt}{temporal autocorrelation parameter of etpsilon}

\item{Rho_cc}{species correlation matrix of epsilon}

\item{Rrange_c}{Spawning range of sexually mature individuals for each species}

\item{Rthreshold_c}{recruitment threshold for each species}

\item{optionRrange}{if \code{optionRrange = 0} recruitment is based on mean SSB in region else if \code{optionRrange = 1} recruitment is based on median SSB in region}

\item{loc_s}{node locations to track population dynamics}

\item{loc_f}{harvest grid locations}

\item{mesh}{INLA mesh object}

\item{lnaniso}{anisotropy parameters}

\item{projection}{"ll" = Longitude-Latitude or "utm"  = Universal Transverse Mercator}

\item{lmin_c}{minimum sizes of individuals for each species}

\item{lmax_c}{maximum sizes of individuals for each species}

\item{seed}{RNG seed}

\item{species_names}{labels representing the simulated species}
}
\value{
an input list specifying the parameters for \code{\link{om}}:
}
\description{
\code{setup_om} creates input list for \code{\link{om}}
}
