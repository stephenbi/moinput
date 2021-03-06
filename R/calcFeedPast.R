#' @title calcFeedPast
#' @description Combines feed baskets of the past with livestock production to get total feed demand
#'
#' @param balanceflow if TRUE, non-eaten food is included in feed baskets, if not it is excluded.
#' @param products products in feed baskets that shall be reported
#' @param cellular if TRUE value is calculate on cellular level with returned datajust in dry matter
#' @param nutrients nutrients like dry matter (DM), reactive nitrogen (Nr), Phosphorus (P), Generalizable Energy (GE) and wet
#' matter (WM). 
#' @return List of magpie objects with results on country or cellular level, unit and description.
#' @author Isabelle Weindl, Benjamin Leon Bodirsky, Kristine Karstems
#' @examples
#' 
#' \dontrun{ 
#' calcOutput("FeedPast")
#' }
#' @importFrom magpiesets findset 
#' @importFrom magclass getNames

calcFeedPast<-function(balanceflow=TRUE, cellular=FALSE, products="kall",nutrients="all"){
  
  if(cellular&(length(nutrients)>1)){stop("out of memory reasons, cellular datasets can only be used with one nutrient")}
  if(cellular&(products=="kall")){cat("out of memory reasons, cellular datasets can often not be run with kall yet; try kfeed")}
  
  kap                 <- findset("kap")
  kli                 <- findset("kli")
  kcr                 <- findset("kcr")
  
  products2           <- findset(products,noset = "original")
  
  LivestockProduction <- collapseNames(calcOutput("Production", products="kli", cellular=cellular ,aggregate=FALSE)[,,"dm"])
  AnimalProduction    <- add_columns(LivestockProduction, addnm="fish", dim=3.1)
  AnimalProduction[,,"fish"]        <- 0
  getNames(AnimalProduction, dim=1) <- paste0("alias_",getNames(AnimalProduction,dim=1))
  
  FeedBaskets         <- calcOutput("FeedBasketsPast", non_eaten_food=FALSE, aggregate = FALSE)
  FeedBaskets         <- FeedBaskets[,,products2]
  if(cellular){FeedBaskets <- toolIso2CellCountries(FeedBaskets)}
  
  FeedConsumption  <- AnimalProduction * FeedBaskets
  min                 <- 0
  
  if (balanceflow==TRUE) {
    
    Balanceflow                 <- calcOutput("FeedBalanceflow", cellular=cellular, products=products,aggregate = FALSE)
    getNames(Balanceflow,dim=1) <- paste0("alias_",getNames(Balanceflow,dim=1))
    FeedConsumption             <- FeedConsumption + Balanceflow[getCells(FeedConsumption),getYears(FeedConsumption),getNames(FeedConsumption)]
    min                         <- -Inf
    
  } else if (balanceflow!=FALSE){stop("balanceflow has to be boolean")}

  FeedConsumption     <- round(FeedConsumption, 8)
  
  ProdAttributes      <- calcOutput("Attributes", aggregate = FALSE)
  if (all(nutrients!="all")) {ProdAttributes=ProdAttributes[,,nutrients]}
  FeedConsumption     <- FeedConsumption * ProdAttributes[,,products2]
  unit                <- "Mt DM/Nr/P/K/WM or PJ energy"
  description         <- "Feed: dry matter: Mt (dm), gross energy: PJ (ge), reactive nitrogen: Mt (nr), phosphor: Mt (p), potash: Mt (k), wet matter: Mt (wm)."
    
  
  return(list(x=FeedConsumption,
          weight=NULL,
          unit=unit,
          min=min,
          description=description,
          isocountries=!cellular)
  )                   
}

