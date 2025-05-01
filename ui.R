source("global.R")

# Define the sidebar
sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Global Stats", tabName = "home", icon = icon("home")),
    menuItem("Search", tabName = "search", icon = icon("magnifying-glass-location")),
    menuItem("Comparison", tabName = "comparison", icon = icon("globe")),
    menuItem("About", tabName = "about", icon = icon("info"))  ## download & share
  )
)

# Define the header
header <- dashboardHeader(title = span(icon("smile"), "World Happiness"))

# Define the body content
body <- dashboardBody(
  useShinyjs(),  # Use the Shinyjs library for dynamic JavaScript functionality

  # Add custom CSS styles to the HTML head section
  tags$head(
    tags$style(
      HTML(
        "
        .checkboxgroup-inline {
          margin-left: 0px;
          margin-right: 10px;
        }
        .checkboxgroup-inline + .checkboxgroup-inline {
          margin-left: 0px;
          margin-right: 10px;
        }
        .happy-theme {
          font-family: Arial, sans-serif;  
          background-color: #f9f9f9;  
          color: #333;  
        }
        .slider .ui-slider-range {
          background: Goldenrod !important;  
        }
        .slider .ui-slider-handle {
          background: Goldenrod !important;  
          border: 1px solid #fff !important; 
        }
        .btn-toggle {
          border: 2px solid #ced4da; 
          border-radius: 25px;  
          font-size: 16px;  
          font-weight: 600;  
          text-align: center;
          padding: 12px 24px; 
          margin: 5px;  
          transition: all 0.3s ease; 
          cursor: pointer;
          background-color: #f8f9fa;  
          color: #6c757d;  
          box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);  
        }
        
        .btn-toggle.active {
          background-color: #007bff; 
          border-color: #007bff; 
          color: #ffffff; 
          box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);  
        }
        
        .btn-toggle:hover {
          background-color: #e2e6ea;  
          border-color: #5a6268;  
          color: #5a6268; 
        
        .btn-toggle:focus {
          outline: none;  
          box-shadow: 0 0 0 3px rgba(38, 123, 255, 0.5);  
        }
        "
      )
    )
  ),
  
  # Add JavaScript code to the HTML head section using `tags$script`
  tags$script(
    HTML(
      "
      var openTab = function(tabName){
        $('a', $('.sidebar')).each(function() {
          if(this.getAttribute('data-value') == tabName) {
            this.click()
          };
        });
      }
      "
    )
  ),
  
  shinyEffects::setShadow(class = "box"),  
  shinyEffects::setShadow(class = "valueBoxOutput"),  
  
  # Use SweetAlert for custom alert dialogs
  shinyWidgets::useSweetAlert(),
  
  # Choose a slider skin with `chooseSliderSkin`
  chooseSliderSkin(skin = "Modern", color = "Goldenrod"),
  
  # Add custom CSS styles to the HTML head section using `tags$style`
  tags$style(type = "text/css", ".happy-slider { border-radius: 10px; }"),
  
  tabItems(
    tabItem(tabName = "home",
            h2("World Happiness Home"),
            
            # Home - Global Happiness Map
            fluidRow(
              box(title = span(icon("map"), "2023 Global Happiness Map"), 
                  status = "warning",  # primary, success, info, warning, danger.
                  solidHeader = FALSE,  
                  width = 12,  
                  collapsible = TRUE,
                  leafletOutput("worldMap", height = 400)
              )
            ),
            
            # Home - 2023 Stats Summary
            fluidRow(
              box(title = span(icon("table"), "2023 Stats Summary"),
                  solidHeader = FALSE,  # Disable solid header
                  status = "info",  # primary, success, info, warning, danger.
                  collapsible = TRUE,  
                  width = 12, 

                  valueBoxOutput("valuebox_global_avg_score") %>% withSpinner(color = "#5bc0de"),
                  valueBoxOutput("valuebox_global_max_score") %>% withSpinner(color = "#5bc0de"),
                  valueBoxOutput("valuebox_global_min_score") %>% withSpinner(color = "#5bc0de"),
                  valueBoxOutput("valuebox_median_happy_country"),
                  valueBoxOutput("valuebox_happinest_country"),
                  valueBoxOutput("valuebox_least_happinest_country")
              )
            ),
            
            # Box for 2023 Bar Chart
            fluidRow(
              box(title = span(icon("chart-bar"), "Top 10 Countries by Total Scores in 2023"),
                  status = "info",
                  solidHeader = FALSE,
                  collapsible = TRUE,
                  width = 12,
                  height = "auto",
                  plotlyOutput("bar_chart_2023")  
              )
            )
    ),
    
    tabItem(tabName = "search",
            h2("World Happiness Search"),
            fluidRow(
              # Searching - Box for country selection
              box(title = span(icon("hand-pointer"), "Choose Your Preference"), 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 3, 
                  height = "180px",
                  uiOutput("selector_country"),
                  htmlOutput("text_date_update")  # Date Update
              ),
              box(title = span(icon("chart-simple"), "2023 Stats Summary"), 
                  solidHeader = FALSE,  
                  status = "success",  
                  collapsible = TRUE,  
                  collapsed = FALSE,  
                  width = 9,  
                  
                  # ValueBoxes with spinners for loading animation
                  valueBoxOutput("valuebox_overall_score") %>% withSpinner(color = "#5bc0de"),
                  valueBoxOutput("valuebox_max_score") %>% withSpinner(color = "#5bc0de"),
                  valueBoxOutput("valuebox_min_score") %>% withSpinner(color = "#5bc0de"),
              )
            ),

            # Pie chart for factors distribution
            fluidRow(
              box(title = span(icon("chart-pie"), "2023 Majority Factors Distribution"),
                  status = "warning",
                  solidHeader = FALSE,  
                  collapsible = TRUE,  
                  collapsed = FALSE,   
                  width = 12,
                  
                  plotlyOutput("pieChart") 
              )
            ),
            
            # Line chart for Ladder and factors in every year
            fluidRow(
              box(
                title = span(icon("chart-line"), "Time Trend for Ladder Score and Multiple Factors"),
                status = "info",
                solidHeader = FALSE,
                collapsible = TRUE,  
                collapsed = FALSE,  
                width = 12,

                # Time trend for Ladder score
                tabBox(
                  id = "tabset2",  # ID for tabBox (if you need to refer to it in server)
                  width = 12,
                  # Time trend for Ladder Score line chart
                  tabPanel(
                    title = "Ladder Score",
                    plotlyOutput("LadderScore_lineChart"),  # Line chart output
                    htmlOutput("Ladder_def")
                  ),
                  # Time trend for GDP per Capita
                  tabPanel("Log GDP per Capita",
                           plotlyOutput("GDP_lineChart"),
                           htmlOutput("GDP_def")
                  ),
                  # Time trend for Social Support
                  tabPanel("Social Support",
                           plotlyOutput("SocialSupport_lineChart"),
                           htmlOutput("Social_def")
                  ),
                  # Time trend for Healthy Life Expectancy
                  tabPanel("Healthy Life Expectancy",
                           plotlyOutput("HealthyLifeExpectancy_lineChart"),
                           htmlOutput("Life_def")
                  ),
                  # Time trend for Freedom to make life choices
                  tabPanel("Freedom to make life choices",
                           plotlyOutput("Freedom_lineChart"),
                           htmlOutput("Freedom_def")
                  ),
                  # Time trend for generosity
                  tabPanel("Generosity",
                           plotlyOutput("Generosity_lineChart"),
                           htmlOutput("Generosity_def")
                  ),
                  # Time trend for perceptions of corruption
                  tabPanel("Perceptions of Corruption",
                           plotlyOutput("Perception_lineChart"),
                           htmlOutput("Perceptions_def")
                  ),
                  # Time trend for Positive Affect
                  tabPanel("Positive Affect",
                           plotlyOutput("PositiveAffect_lineChart"),
                           htmlOutput("PositiveAffect_def")  
                  ),
                  # Time trend for Negative Affect
                  tabPanel("Negative Affect",
                           plotlyOutput("NegativeAffect_lineChart"),
                           htmlOutput("NegativeAffect_def") 
                  )
                )
        )),
      ),
    
    tabItem(tabName = "comparison",
            h2("World Happiness Comparison"),
            
            fluidRow(
                # Box for country and year selection in a single box
                box(title = span(icon("hand-pointer"), "Choose Your Selection"), 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4, 
                    height = "200px",
                    uiOutput("selector_multiple_country")  
                ),
                box(
                  title = span(icon("flag"), "Selected Result"), 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 8, 
                  height = "200px",
                  uiOutput("selected_countries_info")  
                  )
            ),
          
          # Box for the horizontal bar chart of total scores for 2023
          fluidRow(
            box(title = span(icon("chart-bar"), "2023 Ladder Score Explained by Factors"),
                status = "warning",
                solidHeader = FALSE,  
                collapsible = TRUE, 
                collapsed = FALSE,  
                width = 12,
                height = "auto",
                plotOutput("bar_chart", height = "450px") 
            )
          )
    ),
    
    tabItem(tabName = "about",
            h2("World Happiness About Page"),
            
            fluidRow(
              # Data Table
              box(title = span(icon("table"), " Data Table"),
                  status = "info", 
                  solidHeader = FALSE,  
                  collapsible = TRUE,  
                  width = 12, 
                  collapsed = FALSE,  
                  fluidRow(
                    column(width = 12,  
                           DTOutput("data_table")  
                    ),
                    column(width = 3,  
                           downloadButton("download_data", "Download Data")  
                    )
                )
              )),
            
            fluidRow(
              # Data Source Box
              box(
                title = span(icon("info-circle"), "Data Source"),
                status = "info",  
                solidHeader = FALSE, 
                width = 12,  
                collapsed = FALSE, 
                htmlOutput("data_source_info") 
              )
            )
            
    )
  )
)

ui <- function(req) {
  dashboardPage(
    title = "World Happiness",   
    sidebar = sidebar,           
    header = header,              
    body = body,                  
    skin = 'blue'
  )
}