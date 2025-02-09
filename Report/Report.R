## ----setup, include=FALSE, echo=FALSE-----------------------------------------------------------------------------------
#knitr::opts_chunk$set(echo = FALSE, message = FALSE, warning = FALSE)
require(ggplot2)
require(RColorBrewer)
require(kableExtra)
require(data.table)
library(stringr)
library(ggraph)
library(igraph)
library(tidyverse)
library(rgdal)
library(broom)
library(ggplot2)
library("rjson")
library("readxl")

generateReport <- function(level_name, level_value) {

  ## -----------------------------------------------------------------------------------------------------------------------

  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  ## level_name <- "Order"
  ## level_value <- "ORDER Poputre"


  ## -----------------------------------------------------------------------------------------------------------------------
  ENV_Plot_data_for_level <- read.csv(file = file.path("level", level_name, level_value, "ENV_Plot_data_for_level.csv"))



  ## ----choose site unit, echo=FALSE---------------------------------------------------------------------------------------
  hier_summary <- readRDS(file.path("level", level_name, level_value, paste("heir_summary_",paste(str_replace_all(level_value, " ", "_")), ".RDS", sep="")))
  site_units <- hier_summary$SiteUnits
  print(site_units)


  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  site_unit <- site_units[[2]]

  SUTab <- fread("BEC_ReportR/Classification_tables/ALLBECSU_2021_SU.csv")

  plot_numbers_with_site_unit <- SUTab$PlotNumber[SUTab$SiteUnit == site_unit]


  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  reports_dir <- "veg_reports"
  csv_file_path <- function(layer_name) file.path(reports_dir, paste(layer_name, ".csv", sep = "_"))


  df_herb <- read.csv(file = file.path("level", level_name, level_value, "veg_reports", "Herb_Layer.csv"))
  df_moss <- read.csv(file = file.path("level", level_name, level_value, "veg_reports", "Moss_Layer.csv"))
  df_shrub <- read.csv(file = file.path("level", level_name, level_value, "veg_reports", "Shrub_Layer.csv"))
  df_tree <- read.csv(file = file.path("level", level_name, level_value, "veg_reports", "Tree_Layer.csv"))

  len_herb <- nrow(df_herb)
  len_moss <- nrow(df_moss)
  len_shrub <- nrow(df_shrub)
  len_tree <- nrow(df_tree)



  ## ----Join data, echo=FALSE----------------------------------------------------------------------------------------------
  df <- rbind(df_tree, df_shrub, df_herb, df_moss)

  ## ----Veg report, echo=FALSE---------------------------------------------------------------------------------------------
  df <- df[, c("Layer", "ScientificName", "constantcy", "meanCover", "EnglishName")]

  veg_report <- kbl(df, col.names = c("Layer", "Scientific Name", "Constantcy", "Mean Cover", "English Name"), format = "html", table.attr = "style='width:100%;'", align = "lllll") %>%
    kable_styling() %>%
    row_spec(0, extra_css = "border-bottom: 1px solid") %>%
    row_spec(len_tree, extra_css = "border-bottom: 1px solid") %>%
    row_spec(len_tree + len_shrub, extra_css = "border-bottom: 1px solid") %>%
    row_spec(len_tree + len_shrub + len_herb, extra_css = "border-bottom: 1px solid")
  save_kable(veg_report, file.path("www", level_name, level_value, "veg_report.html"))


  ## ----Get soil moisture regime, echo=FALSE-------------------------------------------------------------------------------
  env_summary <- fromJSON(file = file.path("level", level_name, level_value, "summaries", "env", paste(str_replace_all(level_value, " ", "_"), ".JSON", sep = "")))

  soil_moisture_regime <- env_summary$MoistureRegime
  soil_moisture_regime_values <- as.numeric(names(soil_moisture_regime$summary))

  soil_moisture_regime_values <- soil_moisture_regime_values[!is.na(soil_moisture_regime_values)]

  y_range <- range(soil_moisture_regime_values)

  y_1 <- y_range[1]
  y_2 <- y_range[2]


  ## ----Get aSMR data, echo=FALSE------------------------------------------------------------------------------------------

  aSMR_Plot_data_for_level <- read.csv(file = file.path("level", level_name, level_value, "aSMR_Plot_data_for_level.csv"))
  asmr <- aSMR_Plot_data_for_level$aSMR
  asmr <- asmr[!is.na(asmr)]
  x_range <- range(asmr)

  x_1 <- x_range[1]
  x_2 <- x_range[2]


  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  library("ggplot2")

  df <- data.frame(x1 = c(x_1), x2 = c(x_2), y1 = c(y_1), y2 = c(y_2), colour = c("green"), r = c(1))
  x_lab <- c("v.           \npoor            ", "poor            ", "medium            ", "rich            ", "v.            \nrich            ")
  y_lab <- c("very wet", "wet", "very moist", "moist", "fresh", "slightly dry", "moderely dry", "very dry", "extremely dry", "excessively dry")

  edatopic <- ggplot() +
    scale_x_continuous(name = "Soil Nutrient Regime", labels = x_lab, limits = c(0, 5), breaks = c(1, 2, 3, 4, 5), expand = c(0, 0), position = "top") +
    scale_y_continuous(name = "actual Soil Moisture Regime", labels = y_lab, limits = c(0, 10), breaks = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), expand = c(0, 0)) +
    coord_fixed() +
    geom_rect(data = df, mapping = aes(xmin = x1, xmax = x2, ymin = y1, ymax = y2), fill = df$colour, color = "black", alpha = 0.5) +
    geom_text(data = df, aes(x = x1 + (x2 - x1) / 2, y = y1 + (y2 - y1) / 2, label = r), size = 4) +
    theme(
      panel.grid.major = element_line(linetype = 2, color = "#A7A7A7", size = 0.3),
      panel.grid.minor.x = element_blank(),
      panel.grid.minor.y = element_blank(),
      panel.border = element_rect(colour = "black", size = 1, fill = NA),
      panel.background = element_rect(fill = "#F2F2F2"),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_blank(),
      axis.ticks = element_blank(),
      axis.text.x = element_text(face = "bold", size = 10),
      axis.text.y = element_text(face = "bold", size = 10, vjust = 2.75),
      axis.title = element_text(face = "bold")
    )

  ggsave(file.path("www", level_name, level_value, "edatpic.png"))


  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------

  level_names <- c("Classes", "Orders", "SubOrder", "Alliannces", "Associations")
  level_labels <- unlist(c(hier_summary$Classes, hier_summary$Orders, hier_summary$SubOrder, hier_summary$Alliances, hier_summary$Associations))
  level_labels <- level_labels[!is.na(level_labels)]

  d1 <- data.frame(from = hier_summary$Classes, to = hier_summary$Orders)
  d2 <- data.frame(from = d1$to, to = hier_summary$SubOrder)
  d3 <- data.frame(from = d2$to, to = hier_summary$Alliances)
  d4 <- data.frame(from = d3$to, to = hier_summary$Associations)
  edges <- drop_na(rbind(d1, d2, d3, d4))


  # Create a graph object
  mygraph <- graph_from_data_frame(edges)

  # Basic tree
  heigharchy <- ggraph(mygraph, layout = "dendrogram", circular = FALSE) +
    geom_edge_diagonal() +
    geom_node_point() +
    geom_node_label(aes(label = level_labels), repel = TRUE) +
    theme_void()

  ggsave(file.path("www", level_name, level_value, "hierarchy.png"))


  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  my_spdf <- readOGR(dsn = paste0("BEC_ReportR/Spatial_files"), verbose = FALSE)


  ## -----------------------------------------------------------------------------------------------------------------------
  lat <- ENV_Plot_data_for_level$Latitude
  lon <- ENV_Plot_data_for_level$Longitude * (-1)
  lon_lat <- as.data.frame(cbind(lon, lat)) %>% drop_na()


  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  spdf_fortified <- tidy(my_spdf)

  # Plot it
  # library(ggplot2)
  # ggplot() +
  #   geom_polygon(data = spdf_fortified, aes( x = long, y = lat, group = group), fill="#69b3a2", color="white") +
  #   geom_point(data=lon_lat, aes(lon, lat), alpha = 0.5, size = 1) +
  #   theme_void()


  library("rnaturalearth")
  library("rnaturalearthdata")
  library(ggplot2)


  world <- ne_countries(scale = "medium", returnclass = "sf")
  bc_map <- ggplot() +
    geom_polygon(data = spdf_fortified, aes(x = long, y = lat, group = group), fill = "#69b3a2", color = "white") +
    geom_point(data = lon_lat, aes(x = lon, y = lat), size = 4, shape = 23, fill = "darkred") +
    theme_void()

  ggsave(file.path("www", level_name, level_value, "bc_map.png"))



  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  # strata_cover_tree <- env_summary$StrataCoverTree
  # strata_cover_hurb <- env_summary$StrataCoverTree

  ##strata_cover_tree <- ENV_Plot_data_for_level$StrataCoverTree
  # asmr <- asmr[!is.na(asmr)]



  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  Tree <- ENV_Plot_data_for_level$StrataCoverTree
  Herb <- ENV_Plot_data_for_level$StrataCoverHerb
  Shrub <- ENV_Plot_data_for_level$StrataCoverShrub
  Moss <- ENV_Plot_data_for_level$StrataCoverMoss


  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
 # strata_cover <- melt(data.frame(Tree, Herb, Shrub))

  # Multiple plots same axis
  # p <- ggplot(strata_cover, aes(factor(variable), value)) +
  #   geom_violin() +
  #   geom_boxplot(width = .1)

  tree <- ggplot(ENV_Plot_data_for_level, aes(StrataCoverTree, "Tree")) +
    geom_violin() +
    geom_boxplot(width = .1) +
    coord_flip()
  
  tree
  ggsave(file.path("www", level_name, level_value, "tree.png"))

  herb <- ggplot(ENV_Plot_data_for_level, aes(StrataCoverHerb, "Herb")) +
    geom_violin() +
    geom_boxplot(width = .1) +
    coord_flip()
  
  herb
  ggsave(file.path("www", level_name, level_value, "herb.png"))
  

  shrub <- ggplot(ENV_Plot_data_for_level, aes(StrataCoverShrub, "Shrub")) +
    geom_violin() +
    geom_boxplot(width = .1) +
    coord_flip()
  
  shrub
  ggsave(file.path("www", level_name, level_value, "shrub.png"))

  moss <- ggplot(ENV_Plot_data_for_level, aes(StrataCoverMoss, "Moss")) +
    geom_violin() +
    geom_boxplot(width = .1) +
    coord_flip()
  
  moss
  ggsave(file.path("www", level_name, level_value, "moss.png"))





  

  



  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  MasterSpeciesList <- read_excel("BEC_ReportR/LookUp_tables/MasterSpeciesList.xlsx")
  Veg_Plot_data_for_level <- read.csv(file = file.path("level", level_name, level_value, "Veg_Plot_data_for_level.csv"))
  Veg_Plot_data_for_level$SummedCover <- Veg_Plot_data_for_level$TotalA + Veg_Plot_data_for_level$TotalB + Veg_Plot_data_for_level$Cover6 + Veg_Plot_data_for_level$Cover7



  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  df_lifeforms <- merge(x = Veg_Plot_data_for_level, y = MasterSpeciesList, by.x = "Species", by.y = "Code")



  ## ________________________
  
  for(i in 0:14) {
  
    lifeform_0 <- df_lifeforms %>% filter(Lifeform == i)
    life_form_0 <- data.frame(lifeForm0 = (lifeform_0$TotalA + lifeform_0$TotalB + lifeform_0$Cover6 + lifeform_0$Cover7))
    
    if(nrow(na.omit(life_form_0)) != 0) {
      life_form_0_plot <- ggplot(life_form_0, aes(lifeForm0, paste("lifeForm", i, sep=""))) +
        geom_violin() +
        geom_boxplot(width = .1) +
        coord_flip()
      
      if (count(lifeform_0) != 0) {
        life_form_0_plot
        ggsave(file = file.path("www", level_name, level_value, paste("life_form_", i, "_plot.png", sep="")))
        
        
      }
    }
  }
  
  print("Need Example with life forms, complete data does not exist")

  ## -----------------------------------------------------------------------------------------------------------------------
  # lifeform_0 <- df_lifeforms %>% filter(Lifeform == 0)
  # lifeform_1 <- df_lifeforms %>% filter(Lifeform == 1)
  # lifeform_2 <- df_lifeforms %>% filter(Lifeform == 2)
  # lifeform_3 <- df_lifeforms %>% filter(Lifeform == 3)
  # lifeform_4 <- df_lifeforms %>% filter(Lifeform == 4)
  # lifeform_5 <- df_lifeforms %>% filter(Lifeform == 5)
  # lifeform_6 <- df_lifeforms %>% filter(Lifeform == 6)
  # lifeform_7 <- df_lifeforms %>% filter(Lifeform == 7)
  # lifeform_8 <- df_lifeforms %>% filter(Lifeform == 8)
  # lifeform_9 <- df_lifeforms %>% filter(Lifeform == 9)
  # lifeform_10 <- df_lifeforms %>% filter(Lifeform == 10)
  # lifeform_11 <- df_lifeforms %>% filter(Lifeform == 11)
  # lifeform_12 <- df_lifeforms %>% filter(Lifeform == 12)
  # lifeform_13 <- df_lifeforms %>% filter(Lifeform == 13)
  # lifeform_14 <- df_lifeforms %>% filter(Lifeform == 14)
  # 
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # life_form_0 <- data.frame(lifeForm0 = (lifeform_0$TotalA + lifeform_0$TotalB + lifeform_0$Cover6 + lifeform_0$Cover7))
  # life_form_1 <- data.frame(lifeForm1 = (lifeform_1$TotalA + lifeform_1$TotalB + lifeform_1$Cover6 + lifeform_1$Cover7))
  # life_form_2 <- data.frame(lifeForm2 = (lifeform_2$TotalA + lifeform_2$TotalB + lifeform_2$Cover6 + lifeform_2$Cover7))
  # life_form_3 <- data.frame(lifeForm3 = (lifeform_3$TotalA + lifeform_3$TotalB + lifeform_3$Cover6 + lifeform_3$Cover7))
  # life_form_4 <- data.frame(lifeForm4 = (lifeform_4$TotalA + lifeform_4$TotalB + lifeform_4$Cover6 + lifeform_4$Cover7))
  # life_form_5 <- data.frame(lifeForm5 = (lifeform_5$TotalA + lifeform_5$TotalB + lifeform_5$Cover6 + lifeform_5$Cover7))
  # life_form_6 <- data.frame(lifeForm6 = (lifeform_6$TotalA + lifeform_6$TotalB + lifeform_6$Cover6 + lifeform_6$Cover7))
  # life_form_7 <- data.frame(lifeForm7 = (lifeform_7$TotalA + lifeform_7$TotalB + lifeform_7$Cover6 + lifeform_7$Cover7))
  # life_form_8 <- data.frame(lifeForm8 = (lifeform_8$TotalA + lifeform_8$TotalB + lifeform_8$Cover6 + lifeform_8$Cover7))
  # life_form_9 <- data.frame(lifeForm9 = (lifeform_9$TotalA + lifeform_9$TotalB + lifeform_9$Cover6 + lifeform_9$Cover7))
  # life_form_10 <- data.frame(lifeForm10 = (lifeform_10$TotalA + lifeform_10$TotalB + lifeform_10$Cover6 + lifeform_10$Cover7))
  # life_form_11 <- data.frame(lifeForm11 = (lifeform_11$TotalA + lifeform_11$TotalB + lifeform_11$Cover6 + lifeform_11$Cover7))
  # life_form_12 <- data.frame(lifeForm12 = (lifeform_12$TotalA + lifeform_12$TotalB + lifeform_12$Cover6 + lifeform_12$Cover7))
  # life_form_13 <- data.frame(lifeForm13 = (lifeform_13$TotalA + lifeform_13$TotalB + lifeform_13$Cover6 + lifeform_13$Cover7))
  # life_form_14 <- data.frame(lifeForm14 = (lifeform_14$TotalA + lifeform_14$TotalB + lifeform_14$Cover6 + lifeform_14$Cover7))
  # 
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # 
  # if(nrow(na.omit(life_form_0)) != 0) {
  #   life_form_0_plot <- ggplot(life_form_0, aes(lifeForm0, "lifeForm0")) +
  #     geom_violin() +
  #     geom_boxplot(width = .1) +
  #     coord_flip()
  #   
  #   if (count(lifeform_0) != 0) {
  #     life_form_0_plot
  #     ggsave(file = "www/life_form_0_plot.png")
  #   }
  # }
  # 
  # if(nrow(na.omit(life_form_1)) != 0) {
  #   life_form_1_plot <- ggplot(life_form_1, aes(lifeForm1, "lifeForm1")) +
  #     geom_violin() +
  #     geom_boxplot(width = .1) +
  #     coord_flip()
  #   
  #   if (count(lifeform_1) != 0) {
  #     life_form_1_plot
  #     ggsave(file = "www/life_form_1_plot.png")
  #   }
  #   
  # }
  # 
  # if(nrow(na.omit(life_form_2)) != 0) {
  #   
  # life_form_2_plot <- ggplot(life_form_2, aes(lifeForm2, "lifeForm2")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # if (count(lifeform_2) != 0) {
  #   life_form_2_plot
  #   ggsave(file = "www/life_form_2_plot.png")
  # }
  # 
  # }
  # 
  # life_form_3_plot <- ggplot(life_form_3, aes(lifeForm3, "lifeForm3")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # life_form_4_plot <- ggplot(life_form_4, aes(lifeForm4, "lifeForm4")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # life_form_5_plot <- ggplot(life_form_5, aes(lifeForm5, "lifeForm5")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # life_form_6_plot <- ggplot(life_form_6, aes(lifeForm6, "lifeForm6")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # life_form_7_plot <- ggplot(life_form_7, aes(lifeForm7, "lifeForm7")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # life_form_8_plot <- ggplot(life_form_8, aes(lifeForm8, "lifeForm8")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # 
  # life_form_9_plot <- ggplot(life_form_9, aes(lifeForm9, "lifeForm9")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # life_form_10_plot <- ggplot(life_form_10, aes(lifeForm10, "lifeForm10")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # life_form_11_plot <- ggplot(life_form_11, aes(lifeForm11, "lifeForm11")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # life_form_12_plot <- ggplot(life_form_12, aes(lifeForm12, "lifeForm12")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # life_form_13_plot <- ggplot(life_form_13, aes(lifeForm13, "lifeForm13")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # life_form_14_plot <- ggplot(life_form_14, aes(lifeForm14, "lifeForm14")) +
  #   geom_violin() +
  #   geom_boxplot(width = .1) +
  #   coord_flip()
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # 
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # if (count(lifeform_3) != 0) {
  #   life_form_3_plot
  #   ggsave(file = "www/life_form_3_plot.png")
  # }
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # if (count(lifeform_4) != 0) {
  #   life_form_4_plot
  #   ggsave(file = "www/life_form_4_plot.png")
  # }
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # if (count(lifeform_5) != 0) {
  #   life_form_5_plot
  #   ggsave(file = "www/life_form_5_plot.png")
  # }
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # if (count(lifeform_6) != 0) {
  #   life_form_6_plot
  #   ggsave(file = "www/life_form_6_plot.png")
  # }
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # if (count(lifeform_7) != 0) {
  #   life_form_7_plot
  #   ggsave(file = "www/life_form_7_plot.png")
  # }
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # if (count(lifeform_8) != 0) {
  #   life_form_8_plot
  #   ggsave(file = "www/life_form_8_plot.png")
  # }
  # 
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # if (count(lifeform_9) != 0) {
  #   life_form_9_plot
  #   ggsave(file = "www/life_form_9_plot.png")
  # }
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # if (count(lifeform_10) != 0) {
  #   life_form_10_plot
  #   ggsave(file = "www/life_form_10_plot.png")
  # }
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # if (count(lifeform_11) != 0) {
  #   life_form_11_plot
  #   ggsave(file = "www/life_form_11_plot.png")
  # }
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # if (count(lifeform_12) != 0) {
  #   life_form_12_plot
  #   ggsave(file = "www/life_form_12_plot.png")
  # }
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # if (count(lifeform_13) != 0) {
  #   life_form_13_plot
  #   ggsave(file = "www/life_form_13_plot.png")
  # }
  # 
  # 
  # ## -----------------------------------------------------------------------------------------------------------------------
  # if (count(lifeform_14) != 0) {
  #   life_form_14_plot
  #   ggsave(file = "www/life_form_14_plot.png")
  # }


  ## -----------------------------------------------------------------------------------------------------------------------
  elevation_plot <- ggplot(ENV_Plot_data_for_level, aes(Elevation, "Elevation")) +
    geom_violin() +
    geom_boxplot(width = .1) +
    coord_flip()

  elevation_plot
  ggsave(file.path("www", level_name, level_value, "elevation.png"))
  


  ## -----------------------------------------------------------------------------------------------------------------------

  # Life form = sum of total A, total B, cover6, cover 7
  # Plot number, Species Code, Life form, Summed Cover. Then summarize by lifeform, by plot number


  # Need more information about life forms plots

  # p <- ggplot(df_lifeforms, aes(factor(Lifeform), mpg)) +
  #   geom_violin() +
  #   geom_boxplot(width = .1)
  # p


  ## ----Counts of GIS_BGC for level, echo=FALSE----------------------------------------------------------------------------
  Admin_Plot_data_for_level <- read.csv(file = file.path("level", level_name, level_value, "Admin_Plot_data_for_level.csv"))
  GIS_BGC <- Admin_Plot_data_for_level$GIS_BGC
  counts_GIS_BGC <- table(GIS_BGC)



  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  Climate_Plot_data_for_level <- read.csv(file = file.path("level", level_name, level_value, "Climate_Plot_data_for_level.csv"))

  MAT <- Climate_Plot_data_for_level$MAT
  DD5 <- Climate_Plot_data_for_level$DD5
  EMT <- Climate_Plot_data_for_level$EMT
  MAP <- Climate_Plot_data_for_level$MAP
  MSP <- Climate_Plot_data_for_level$MSP
  PAS <- Climate_Plot_data_for_level$PAS
  CMD <- Climate_Plot_data_for_level$CMD
  FFP <- Climate_Plot_data_for_level$FFP
  TD <- Climate_Plot_data_for_level$TD



  ## -----------------------------------------------------------------------------------------------------------------------
  mat <- ggplot(Climate_Plot_data_for_level, aes(MAT, "MAT")) +
    geom_boxplot(width = .1)
  mat
  ggsave(file.path("www", level_name, level_value, "mat.png"))

  dd5 <- ggplot(Climate_Plot_data_for_level, aes(DD5, "DD5")) +
    geom_boxplot(width = .1)
  dd5
  ggsave(file.path("www", level_name, level_value, "dd5.png"))

  emt <- ggplot(Climate_Plot_data_for_level, aes(EMT, "EMT")) +
    geom_boxplot(width = .1)
  emt
  ggsave(file.path("www", level_name, level_value, "emt.png"))

  map <- ggplot(Climate_Plot_data_for_level, aes(MAP, "MAP")) +
    geom_boxplot(width = .1)
  map
  ggsave(file.path("www", level_name, level_value, "map.png"))

  msp <- ggplot(Climate_Plot_data_for_level, aes(MSP, "MSP")) +
    geom_boxplot(width = .1)
  msp
  ggsave(file.path("www", level_name, level_value, "msp.png"))

  cmd <- ggplot(Climate_Plot_data_for_level, aes(CMD, "CMD")) +
    geom_boxplot(width = .1)
  cmd
  ggsave(file.path("www", level_name, level_value, "cmd.png"))

  pas <- ggplot(Climate_Plot_data_for_level, aes(PAS, "PAS")) +
    geom_boxplot(width = .1)
  pas
  ggsave(file.path("www", level_name, level_value, "pas.png"))

  ffp <- ggplot(Climate_Plot_data_for_level, aes(FFP, "FFP")) +
    geom_boxplot(width = .1)
  ffp
  ggsave(file.path("www", level_name, level_value, "ffp.png"))

  td <- ggplot(Climate_Plot_data_for_level, aes(TD, "TD")) +
    geom_boxplot(width = .1)
  td
  ggsave(file.path("www", level_name, level_value, "td.png"))

  
  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  # df_temperature <- melt(data.frame(MAT, DD5, EMT))
  # df_precipitation <- melt(data.frame(MAP, MSP, PAS))
  # df_derived <- melt(data.frame(CMD, FFP, TD))


  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  # ggplot(df_temperature, aes(x=as.factor(variable), y=value)) +
  #     coord_flip() +
  #     geom_boxplot( alpha=0.2) +    # fill="slateblue"
  #     xlab("Temperature")
  #
  # ggplot(df_precipitation, aes(x=as.factor(variable), y=value)) +
  #     coord_flip() +
  #     geom_boxplot( alpha=0.2) +    # fill="slateblue"
  #     xlab("Precipitation")
  #
  # ggplot(df_derived, aes(x=as.factor(variable), y=value)) +
  #     coord_flip() +
  #     geom_boxplot( alpha=0.2) +    # fill="slateblue"
  #     xlab("Derived")


  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  # WindRose.R
  plot.windrose <- function(data,
                            spd,
                            dir,
                            spdres = round((max(wind_rose_df$SlopeGradient) - min(wind_rose_df$SlopeGradient)) / 10),
                            dirres = 30,
                            spdmin = min(wind_rose_df$SlopeGradient),
                            spdmax = max(wind_rose_df$SlopeGradient),
                            spdseq = c(5, 25, 50, 70, 100),
                            palette = "YlGnBu",
                            countmax = NA,
                            debug = 0) {


    # Look to see what data was passed in to the function
    if (is.numeric(spd) & is.numeric(dir)) {
      # assume that we've been given vectors of the speed and direction vectors
      data <- data.frame(
        spd = spd,
        dir = dir
      )
      spd <- "spd"
      dir <- "dir"
    } else if (exists("data")) {
      # Assume that we've been given a data frame, and the name of the speed
      # and direction columns. This is the format we want for later use.
    }

    # Tidy up input data ----
    n.in <- NROW(data)
    dnu <- (is.na(data[[spd]]) | is.na(data[[dir]]))
    data[[spd]][dnu] <- NA
    data[[dir]][dnu] <- NA

    # figure out the wind speed bins ----
    # if (missing(spdseq)){
    #   spdseq <- seq(spdmin,spdmax,spdres)
    # } else {
    #   if (debug >0){
    #     cat("Using custom speed bins \n")
    #   }
    # }
    # get some information about the number of bins, etc.
    n.spd.seq <- length(spdseq)
    n.colors.in.range <- n.spd.seq - 1

    # create the color map
    spd.colors <- colorRampPalette(brewer.pal(
      min(
        max(
          3,
          n.colors.in.range
        ),
        min(
          9,
          n.colors.in.range
        )
      ),
      palette
    ))(n.colors.in.range)
    #
    #   if (max(data[[spd]],na.rm = TRUE) > spdmax){
    #     spd.breaks <- c(spdseq,
    #                     max(data[[spd]],na.rm = TRUE))
    #     spd.labels <- c(paste(c(spdseq[1:n.spd.seq-1]),
    #                           '-',
    #                           c(spdseq[2:n.spd.seq])),
    #                     paste(spdmax,
    #                           "-",
    #                           max(data[[spd]],na.rm = TRUE)))
    #     spd.colors <- c(spd.colors, "grey50")
    #   } else{
    spd.breaks <- spdseq
    spd.labels <- paste(
      c(spdseq[1:n.spd.seq - 1]),
      "-",
      c(spdseq[2:n.spd.seq])
    )

    spd.labels[4] <- "70 +"
    # }
    data$spd.binned <- cut(
      x = data[[spd]],
      breaks = spd.breaks,
      labels = spd.labels,
      ordered_result = TRUE
    )
    # clean up the data
    data. <- na.omit(data)

    # figure out the wind direction bins
    dir.breaks <- c(
      -dirres / 2,
      seq(dirres / 2, 360 - dirres / 2, by = dirres),
      360 + dirres / 2
    )
    dir.labels <- c(
      paste(360 - dirres / 2, "-", dirres / 2),
      paste(
        seq(dirres / 2, 360 - 3 * dirres / 2, by = dirres),
        "-",
        seq(3 * dirres / 2, 360 - dirres / 2, by = dirres)
      ),
      paste(360 - dirres / 2, "-", dirres / 2)
    )
    # assign each wind direction to a bin
    dir.binned <- cut(data[[dir]],
      breaks = dir.breaks,
      ordered_result = TRUE
    )
    levels(dir.binned) <- dir.labels
    data$dir.binned <- dir.binned

    # Run debug if required ----
    if (debug > 0) {
      cat(dir.breaks, "\n")
      cat(dir.labels, "\n")
      cat(levels(dir.binned), "\n")
    }

    # deal with change in ordering introduced somewhere around version 2.2
    if (packageVersion("ggplot2") > "2.2") {
      # cat("Hadley broke my code\n")
      data$spd.binned <- with(data, factor(spd.binned, levels = rev(levels(spd.binned))))
      spd.colors <- rev(spd.colors)
    }

    # create the plot ----
    p.windrose <- ggplot(
      data = data,
      aes(
        x = dir.binned,
        fill = spd.binned
      )
    ) +
      geom_bar() +
      scale_x_discrete(
        drop = FALSE,
        labels = waiver()
      ) +
      coord_polar(start = -((dirres / 2) / 360) * 2 * pi) +
      scale_fill_manual(
        name = "Slope Gradient %",
        values = spd.colors,
        drop = FALSE
      ) +
      theme(axis.title.x = element_blank())

    # adjust axes if required
    if (!is.na(countmax)) {
      p.windrose <- p.windrose +
        ylim(c(0, countmax))
    }

    # print the plot
    print(p.windrose)

    # return the handle to the wind rose
    return(p.windrose)
  }




  ## ---- echo=FALSE--------------------------------------------------------------------------------------------------------
  data.in <- read.csv(file = "wind_data.csv", col.names = c("date", "hr", "ws.80", "wd.80"))
  wind_rose_df <- ENV_Plot_data_for_level[c("Aspect", "SlopeGradient")] %>%
    drop_na() %>%
    filter(SlopeGradient != 999) %>%
    filter(SlopeGradient > 5)




  ## -----------------------------------------------------------------------------------------------------------------------
  p1 <- plot.windrose(
    spd = wind_rose_df$SlopeGradient,
    dir = wind_rose_df$Aspect
  )

  ggsave(file.path("www", level_name, level_value, "windrose.png"))
  

  sloping_less_than_five <- length(which(ENV_Plot_data_for_level["Aspect"] < 5))
  sloping_999 <- length(which(ENV_Plot_data_for_level["Aspect"] == 999))
  sloping_na <- length(which(is.na(ENV_Plot_data_for_level["Aspect"])))



  ## -----------------------------------------------------------------------------------------------------------------------

  elevation <- ggplot(ENV_Plot_data_for_level, aes(Elevation, "Elevation")) +
    geom_violin() +
    geom_boxplot(width = .1) +
    coord_flip()

  elevation
  ggsave(file.path("www", level_name, level_value, "elevation.png"))
  




  ## -----------------------------------------------------------------------------------------------------------------------
  meso <- env_summary$MesoSlopePosition$summary
  meso


  ## -----------------------------------------------------------------------------------------------------------------------
  humus <- env_summary$HumusForm$summary
  humus



  ## -----------------------------------------------------------------------------------------------------------------------
  mineral_summary <- fromJSON(file = file.path("level", level_name, level_value, "summaries", "mineral", paste(str_replace_all(level_value, " ", "_"), ".JSON", sep = "")))

  texture <- mineral_summary$Texture$summary
  texture


  ## -----------------------------------------------------------------------------------------------------------------------
  depth <- ENV_Plot_data_for_level$RootingDepth
  band_0_30 <- sum(depth >= 0 & depth < 30, na.rm = TRUE)
  band_30_60 <- sum(depth >= 30 & depth < 60, na.rm = TRUE)
  band_60_90 <- sum(depth >= 60 & depth < 90, na.rm = TRUE)
  band_90_plus <- sum(depth >= 90, na.rm = TRUE)
  no_data <- sum(is.na(depth))


  band_0_30
  band_30_60
  band_60_90
  band_90_plus
  no_data


  ## -----------------------------------------------------------------------------------------------------------------------
  rootRestrictingType <- env_summary$RootRestrictingType$summary
  rootRestrictingType
  print("****** END ********")
}

