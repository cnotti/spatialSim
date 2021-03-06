#' Specify the settings and parameters of OM
#'
#' \code{setup_om} creates input list for \code{\link{om}}
#'
#' @param nb number of time-steps in initialization phase
#' @param ny number of years
#' @param np number of time-steps within each year
#' @param nc number of species
#' @param nl number of size intervals
#' @param nfishp number of time-steps that make up commercial fishing season
#' @param fishp1 index (zero-indexed) of first annual period of the fishing season 
#' @param nyAssess number of years to run model before updating harvest restrictions
#' @param fn_growth function specifying the growth of individuals
#' @param fn_weight function specifying size-weight relationship
#' @param sigmaG_c standard deviations of the expected growth increments on the log scale for each species
#' @param alpha_c expected rates of instantaneous natural mortality for each species
#' @param mugI expected value of iota
#' @param mugH expected value of eta
#' @param sigmagI marginal sd of iota
#' @param taugH SPDE scale parameter of eta
#' @param kappaH SPDE range parameter of eta
#' @param phiIt temporal autocorrelation parameter of iota
#' @param phiHt temporal autocorrelation parameter of eta
#' @param phiHl size autocorrelation parameter of eta
#' @param fn_select function specifying fishing selectivity
#' @param limit_c harvest limit for each species
#' @param areadredge area-swept by fishers
#' @param ptarget probability of fishers harvesting from sites with above average densities of individuals
#' @param F_intensity parameter controlling intensity of commercial harvesting
#' @param f_c_fstar indices (zero-indexed) of \code{loc_f} making up sub-area of domain that commercial fishers will fish
#' @param f_ct_fsurv indices (zero-indexed) of \code{loc_f} specifying survey sites
#' @param probZero probability of sampling a zero catch given the potential catch at site i is less than \code{cathZero}
#' @param catchZero if potential catch at site i is less than \code{catchZero} sample a zero with probability \code{probZero}
#' @param fn_mature function specifying sexual maturity
#' @param R0_c scale term of stock recruit function for each species
#' @param h_c stock-recruit steepness parameters for each species
#' @param upsilon_l size distribution of new recruits
#' @param xi_csb probability of an individual recruiting conditional on the environmental conditions at locations \code{loc_s} at initialization time period \code{b}
#' @param xi_cst probability of an individual recruiting conditional on the environmental conditions at locations \code{loc_s} at time period \code{t}
#' @param mugE expected value of epsilon
#' @param taugE SPDE scale parameter of epsilon
#' @param kappaE SPDE range parameter of epsilon
#' @param phiEt temporal autocorrelation parameter of etpsilon
#' @param Rho_cc species correlation matrix of epsilon
#' @param Rrange_c Spawning range of sexually mature individuals for each species
#' @param Rthreshold_c recruitment threshold for each species
#' @param optionRrange if \code{optionRrange = 0} recruitment is based on mean SSB in region else if \code{optionRrange = 1} recruitment is based on median SSB in region
#' @param loc_s node locations to track population dynamics
#' @param loc_f harvest grid locations
#' @param mesh INLA mesh object
#' @param lnaniso anisotropy parameters
#' @param projection "ll" = Longitude-Latitude or "utm"  = Universal Transverse Mercator
#' @param lmin_c minimum sizes of individuals for each species
#' @param lmax_c maximum sizes of individuals for each species
#' @param seed RNG seed
#' @param species_names labels representing the simulated species
#' 
#' @return an input list specifying the parameters for \code{\link{om}}:
#'
#' @export
setup_om = function(
  
  # indexing/population structure
  nb, 
  ny, 
  np = 12, 
  nc,
  nl, 
  nfishp, 
  fishp1,
  nyAssess = ny,
  
  # growth 
  fn_growth,
  fn_weight,
  sigmaG_c,
      
  # natural mortality
  alpha_c,
  mugI = 0,
  mugH = 0,
  sigmagI,
  taugH,
  kappaH,
  phiIt,
  phiHt,
  phiHl,
  
  # fishing mortality
  fn_select,
  limit_c,
  areadredge,
  ptarget = 0.9,
	ploc_f = -1,
  F_intensity = 0.2,
  ffirst_c = rep(0, nc),
  F_settings = 0,
  f_c_fstar,
  f_ct_fsurv,
  probZero = 0,
  catchZero = 0,
  
  # recruitment
  fn_mature,
  R0_c,
  h_c,
  upsilon_l, 
	xi_csb = array(1, c(nc,ns,nb)),
	xi_cst = array(1, c(nc,ns,nt)),
  mugE = 0,
  taugE,
  kappaE,
  phiEt,
  Rho_cc,
  Rrange_c,
  Rthreshold_c = rep(0,nc),
  optionRrange = 0,
  
  # spatial objects
  loc_s,
  loc_f,
  mesh,
  lnaniso = rep(0, 2),
  projection = "utm",
  areaOmega,
	
  # population size structure
  lmin_c = rep(0, nc), 
  lmax_c,
  
  # extra
  seed = NULL,
  species_names = 1:nc
  
  ) {
    set.seed(seed)

    # functions
	# Growth transition matrix (in future release users may specify fn_G)
    fn_G = function(delta_cl, omega_c, sigmaG_c) {
      pow = function(x, p) {
        x^p
      }
      plnu = function(y, nu, tau, omega){
        H = function(y, nu, tau, omega){
          (y*plnorm(y, nu, tau) -
             exp(nu + 0.5*tau^2) *
             pnorm(log(y), nu + tau^2, tau))/omega
        }
        H(y, nu, tau, omega) - H(pmax(y - omega, 0), nu, tau, omega)
      }
      
      nl = ncol(delta_cl)
      nc = nrow(delta_cl)
      G_c_ll = as.vector(rep(list(matrix(0, nrow = nl, ncol = nl)), nc), "list")
      for (c in 1:nc) {
        for (k in 1:nl) {
          # prob growing from size class k to j
          for (j in 1:nl) {
            if (k <= j) {
              if((j-k)*omega_c[c] == 0) {
                G_c_ll[[c]][j,k] = plnu(omega_c[c],
                                      log(delta_cl[c,k]) - pow(sigmaG_c[c],2)/2,
                                      sigmaG_c[c],
                                      omega_c[c]);
              } else{
                pr_b = plnu(omega_c[c] + (j-k)*omega_c[c],
                            log(delta_cl[c,k]) - pow(sigmaG_c[c],2)/2,
                            sigmaG_c[c],
                            omega_c[c])
                pr_a = plnu((j - k) * omega_c[c],
                            log(delta_cl[c,k]) - pow(sigmaG_c[c],2)/2,
                            sigmaG_c[c],
                            omega_c[c]);
                G_c_ll[[c]][j,k] = ifelse(isTRUE(all.equal(pr_b, pr_a)), 0, pr_b - pr_a)
              }
            }
            # fill neg growth probs with 0
            if (k > j) {
              G_c_ll[[c]][j,k] = 0;
            }
            if (G_c_ll[[c]][j,k] < 0) {
              warning("elemant(s) of G < 0: check growth parameters");
            }
          }
          G_c_ll[[c]][,k] = G_c_ll[[c]][,k]/sum(G_c_ll[[c]][,k]);
        }
      }
      G_c_ll
    }
      
  
    # options (at this stage these are fixed)
    g_I = "logit"
    g_E = "logit"
    g_H = "log"
    
    # debug checks

    # total time-steps
    nt = ny*np
    
    # start stop variables used in OM loop
    ntAssess = nyAssess * np
    tstop_a = cumsum(rep(ntAssess, nt/ntAssess)) - 1
    if (tail(tstop_a, 1) != nt - 1) tstop_a = c(tstop_a, nt - 1)
    tstart_a = c(0, tstop_a[-length(tstop_a)] + 1)
    
    # annual period at each time point t
    p_t = rep(1:np - 1, ny)
    
    # setup harvesting book-keeping vars
    t_catch = rep(1, ny*np)
    q_y = 0:(ny - 1)
    nq = length(q_y)
    fishp = seq(fishp1 + 1, by = 1, length.out = nfishp)
    t_catch[fishp + rep(q_y*np, each = nfishp)] = 0
  
    
    # population size structure
    omega_c = NULL
    lmid_cl = matrix(0, nrow = nc, ncol = nl)
    for (c in 1:nc) {
      l1 = seq(lmin_c[c], lmax_c[c], len = nl + 1)
      omega_c[c] = l1[2] - l1[1]
      lmid_cl[c,] = l1[-length(l1)] + omega_c[c]/2
    }
    
    # growth, weight-at-size, selectivity, maturity
    delta_cl = fn_growth(lmid_cl)
    weight_cl = fn_weight(lmid_cl)
    selectivityF_cl = fn_select(lmid_cl)
    pmat_cl = fn_mature(lmid_cl)
    G_c_ll = fn_G(delta_cl, omega_c, sigmaG_c)
    
    # recruitment
    npsi = 1
    upsilon_l = matrix(c(rep(1/npsi, npsi), rep(0, nl - npsi)), ncol = 1)
    if (missing(Rho_cc)) {
      Rho_cc = diag(nc)
    }
    
    # inla object
    ns = nrow(loc_s)
    splus_s = which(mesh[["loc"]][,1] %in% loc_s[,1] &
                      mesh[["loc"]][,2] %in% loc_s[,2]) - 1
    inla_spde = INLA::inla.spde2.matern(mesh)

    # ---------- Begin code that prepare objects for anisotropy.
    Dset = 1:2
    # Triangle info
    TV = mesh$graph$tv           # Triangle to vertex indexing
    V0 = mesh$loc[TV[,1],Dset]   # V = vertices for each triangle
    V1 = mesh$loc[TV[,2],Dset]
    V2 = mesh$loc[TV[,3],Dset]
    E0 = V2 - V1                      # E = edge for each triangle
    E1 = V0 - V2
    E2 = V1 - V0
    # Calculate Areas
    TmpFn = function(Vec1, Vec2) abs(det( rbind(Vec1, Vec2) ))
    Tri_Area = rep(NA, nrow(E0))
    for (i in 1:length(Tri_Area)) Tri_Area[i] = TmpFn( E0[i,],E1[i,] )/2   # T = area of each triangle
    # ---------- End code that prepare objects for anisotropy.

    spde = list(
      "n_s"      = inla_spde$n.spde,
      "n_tri"    = nrow(TV),
      "Tri_Area" = Tri_Area,
      "E0"       = E0,
      "E1"       = E1,
      "E2"       = E2,
      "TV"       = TV - 1,
      "G0"       = inla_spde$param.inla$M0,
      "G0_inv"   = as(diag(1/Matrix::diag(inla_spde$param.inla$M0)), "dgTMatrix"))

    nf = nrow(loc_f)
    A_fs = INLA::inla.spde.make.A(mesh, loc_f)[,splus_s+1]
    if(isFALSE(all.equal(Matrix::rowSums(A_fs), 1))) {
      warning("Check A_fs. One ore more grid locations may be outside domain")
    }

    # calculate nodes within spawning range of each s
    s_cs_sstar = vector("list", nc*ns)
    cs = 1
    # distance between s and s' in km
    if (projection == "utm") {
      dist_utm = function(xy.from, xy.to) {
        sqrt( (xy.from[1] - xy.to[,1])^2 + (xy.from[2] - xy.to[,2])^2)
      }
      xy.from = lapply(seq_len(nrow(loc_s)), function(i) loc_s[i,])
      distmat = sapply(xy.from, function(xy.from) dist_utm(xy.from, loc_s))/1000
    } else if (projection == "ll") {
      distmat = geosphere::distm(loc_s, loc_s)/1000
    }
    
    for (c in 1:nc) {
      for (s in 1:ns) {
        s_cs_sstar[[cs]] = which(distmat[,s] < Rrange_c[c]) - 1
        cs = cs + 1
      }
    }
    
    
    
    
    # return list
    list(
      # options
      g_I = g_I, 
      g_H = g_H, 
      g_E = g_E, 
      
      # indexing
      tstart = 0,
      tstop = nt-1,
      nb = nb, 
      ny = ny, 
      np = np, 
      nt = nt, 
      nc = nc, 
      ns = ns,
      nl = nl, 
      nq = nq, 
      nf = nf,
      p_t = p_t,
      splus_s = splus_s,
      t_catch = t_catch, 
      nfishp = nfishp, 
      fishp1 = fishp1,
      s_cs_sstar = s_cs_sstar,
      ct_ct = matrix(0:(nc*nt-1), nrow = nc, ncol = nt, byrow = TRUE),
      
      # growth 
      delta_cl = delta_cl,
      sigmaG_c = sigmaG_c,
      G_c_ll = G_c_ll,
      
      # natural mortality
      alpha_c = alpha_c, 
      I_b = array(0, dim = nb),
      H_sbl = array(0, dim = c(ns, nb, nl)),
      gI_t = array(0, dim = nt),
      gH_stl = array(0, dim = c(ns, nt, nl)),
      mugI = mugI,
      mugH = mugH,
      sigmagI = sigmagI,
      taugH = taugH,
      kappaH = kappaH,
      phiIt = phiIt,
      phiHt = phiHt,
      phiHl = phiHl,
      
      # fishing mortality
      selectivityF_cl = selectivityF_cl,
      ncatch_cstl = array(0, dim = c(nc, ns, nt, nl)),
      limit_c = limit_c,
      areaOmega = areaOmega, 
      areadredge = areadredge,
      ptarget = ptarget,
			ploc_f = ploc_f,
      F_intensity = F_intensity,
      ffirst_c = ffirst_c,
      F_settings = F_settings,
      f_c_fstar = f_c_fstar,
      f_ct_fsurv = f_ct_fsurv,
      probZero = probZero,
      catchZero = catchZero,
      
      # recruitment
      R0_c = R0_c,
      h_c = h_c,
      pmat_cl = pmat_cl,
      upsilon_l = upsilon_l,
			xi_csb = xi_csb,
			xi_cst = xi_cst,
      E_csb = array(0, dim = c(nc, ns, nb)),
      gE_cst = array(0, dim = c(nc, ns, nt)),
      mugE = mugE,
      taugE = taugE,
      kappaE = kappaE,
      phiEt = phiEt,
      Rho_cc = Rho_cc,
      Rthreshold_c = Rthreshold_c,
      optionRrange = optionRrange,
      
      # spde objects
      spde = spde,
      A_fs = A_fs,
      lnaniso = lnaniso,
          
      # population size structure
      lmin_c = lmin_c, 
      lmax_c = lmax_c,
      omega_c = omega_c,
      lmid_cl = lmid_cl,
      weight_cl = weight_cl,

      N_csl = array(0, dim = c(nc, ns, nl)),
      SSB0_c = array(0, dim = c(nc)),
      SSB_sc = array(0, dim = c(ns, nc)),
      dummyParameter = 0,
      
      # --------------------------------------- #
      # additional items for use outside of cpp #
      # --------------------------------------- #
      extra = list(
        species_names = species_names,
        loc_f = loc_f,
        mesh = mesh,
        tstart_a = tstart_a,
        tstop_a = tstop_a
      )
    )
}
