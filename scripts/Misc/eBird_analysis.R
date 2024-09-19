library(ggplot2)
library(dplyr)

ebd_coa <- ebd_df1[ebd_df1$LastObs > "1998",]
ebd_hot_spot <- ebd_coa[ebd_coa$]

# get counts of hot spots versus specific locations
hot_spot_count <- as.data.frame(table(ebd_coa$locality_type))
colnames(hot_spot_count) <- c("Locality_Type", "Frequency")

# get percent of hot spots
hot_spot_count <- hot_spot_count %>%
  group_by(Locality_Type) %>%
  mutate(percent = round(Frequency/sum(Frequency)*100,2))

# create pie chart of hot spots
ggplot(hot_spot_count, aes(x = "", y = percent, fill = Locality_Type)) +
  geom_col(color = "black") +
  geom_text(aes(label = paste0(prettyNum(Frequency, big.mark=",",scientific=FALSE)," (",percent,"%)")),
            col = c("white","black"),
            position = position_stack(vjust = 0.5)) +
  guides(fill = guide_legend(title = "Locality Type")) +
  scale_fill_viridis_d(option = "cividis") +
  coord_polar(theta = "y") +
  theme_void()

# get counts of protocol types
protocol_type_count <- as.data.frame(table(ebd_coa$protocol_type))
colnames(protocol_type_count) <- c("Protocol_Type", "Frequency")

# get percent of hot spots
protocol_type_count <- protocol_type_count %>%
  group_by(Protocol_Type) %>%
  mutate(percent = round(Frequency/sum(Frequency)*100,2))

# create bar chart of protocol types
ggplot(protocol_type_count, aes(x=Frequency,y=reorder(Protocol_Type,Frequency))) +
  geom_col(fill="#154c79",width=0.6) + 
  scale_x_continuous(
    position = "top") +
  theme(
    # Set background color to white
    panel.background = element_rect(fill = "white"),
    panel.grid.major.x = element_line(color = "#A8BAC4", size = 0.3),
    # Remove tick marks by setting their length to 0
    axis.ticks.length = unit(0, "mm"),
    # Remove the title for both axes
    axis.title = element_blank(),
    # Remove labels from the vertical axis
    axis.text.y = element_blank(),
    # But customize labels for the horizontal axis
    axis.text.x = element_text(size = 16)) +
  geom_text(data = subset(protocol_type_count, Frequency >= 250000),
    aes(0,y=Protocol_Type,label=paste0(Protocol_Type," (",prettyNum(Frequency, big.mark=",",scientific=FALSE),")")),
    hjust = 0,
    nudge_x = 0.3,
    colour = "white",
    size = 5) + 
  geom_text(data = subset(protocol_type_count, Frequency < 250000),
    aes(Frequency, y = Protocol_Type, label = paste0(Protocol_Type," (",prettyNum(Frequency, big.mark=",",scientific=FALSE),")")),
    hjust = 0,
    nudge_x = 0.3,
    colour = "#154c79",
    size = 5
  )


# subset all traveling records
ebd_traveling <- ebd_coa[ebd_coa$protocol_type == "Traveling",]
ebd_traveling$effort_distance_meters <- ebd_traveling$effort_distance_km*1000
ebd_traveling = ebd_traveling[!duplicated(colnames(ebd_traveling))]

ggplot(data = subset(ebd_traveling, effort_distance_meters <= 1000),aes(x=effort_distance_meters)) +
  geom_histogram(binwidth=50, fill="#154c79", color="#e9ecef", alpha=0.9) +
  ggtitle("Bin size = 50") +
  xlab("Effort Distance in Meters")+
  theme(plot.title = element_text(size=15),
        axis.title.y = element_blank(),
        panel.background = element_rect(fill = "white"),
        panel.grid.major.y = element_line(color = "#A8BAC4", size = 0.3),
        # Remove tick marks by setting their length to 0
        axis.ticks.length = unit(0, "mm"))
          
  )
  

ebird_sf <- st_as_sf(ebd_coa, coords=c("longitude","latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
ebird_sf <- st_transform(ebird_sf, crs=customalbers) # reproject to the custom albers
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_eBird_use"), ebird_sf, overwrite=TRUE) # write a feature class into the geodatabase


# get habitat for planning units
lu_HabTerr <- read.csv("H:/Scripts/COA_Tools/_data/input/lu_HabTerr.csv")
lu_HabName <- read.csv("H:/Scripts/COA_Tools/_data/input/lu_HabitatName.csv")
lu_hab <- left_join(lu_HabTerr,lu_HabName,by="Code")
pu_hab <- lu_hab[lu_hab$unique_id == "071_1146646",]
