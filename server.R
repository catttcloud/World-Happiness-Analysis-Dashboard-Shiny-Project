source("global.R")

# Define server logic
server <- function(input, output) {
#----------------------------- Home --------------------------------------
  #### Home - Global Happiness Map
  output$worldMap <- renderLeaflet({
    # Create a leaflet map
    leaflet(data = world_data) %>%
      addTiles() %>%
      addPolygons(
        fillColor = ~colorQuantile("YlOrRd", Ladder.score)(Ladder.score),
        weight = 2,
        opacity = 1,
        color = 'white',
        dashArray = '3',
        fillOpacity = 0.7,
        # create popup info
        popup = ~paste(
          "<strong>Country:</strong>", name, "<br>",
          "<strong>Happiness Ladder Score:</strong>", Ladder.score
        )
      ) %>%
      addLegend( # add details
        pal = colorQuantile("YlOrRd", world_data$Ladder.score),
        values = ~Ladder.score,
        title = "Happiness Ladder Score",
        position = "bottomright"
      )
  })
  
  #### Home - 2023 Stats Summary
  # Render the value box for global average score
  output$valuebox_global_avg_score <- renderValueBox({
    valueBox(
      formatC(global_avg_score, format = "f", digits = 2),
      "Global Average Ladder Score",
      icon = icon("globe"),
      color = "green"  # or any other color
    )
  })
  # Render the value box for global max score
  output$valuebox_global_max_score <- renderValueBox({
    valueBox(
      formatC(global_max_score, format = "f", digits = 2),
      "Global Maximal Ladder Score",
      icon = icon("maximize"),
      color = "red"  # or any other color
    )
  })
  # Render the value box for global min score
  output$valuebox_global_min_score <- renderValueBox({
    valueBox(
      formatC(global_min_score, format = "f", digits = 2),
      "Global Minimal Ladder Score",
      icon = icon("minimize"),
      color = "blue"  
    )
  })
  output$valuebox_median_happy_country <- renderValueBox({
    valueBox(
      # Use HTML tags to apply inline CSS for font size
      HTML(paste0('<span style="font-size: 24px; text-shadow: 2px 2px 5px rgba(0,0,0,0.5);">', median_happy_country, '</span>')),
      "Countries with Median Happiness Score",
      icon = icon("face-smile"),
      color = "yellow"
    )
  })
  output$valuebox_happinest_country <- renderValueBox({
    valueBox(
      # Use HTML tags to apply inline CSS for font size
      HTML(paste0('<span style="font-size: 24px; text-shadow: 2px 2px 5px rgba(0,0,0,0.5);">', most_happy_country$name, '</span>')),
      "Happiest country in the world",
      icon = icon("face-laugh-squint"),
      color = "orange"
    )
  })
  output$valuebox_least_happinest_country <- renderValueBox({
    valueBox(
      # Use HTML tags to apply inline CSS for font size
      HTML(paste0('<span style="font-size: 24px; text-shadow: 2px 2px 5px rgba(0,0,0,0.5);">', least_happy_country$name, '</span>')),
      "Least happiest country in the world",
      icon = icon("face-frown"),
      color = "aqua"
    )
  })
  
  #### Home - 2023 Top 10 Bar chart
  # Reactive expression to filter dataset for the top 10 countries in 2023
  filtered_data_2023_top10 <- reactive({
    req(dataset_by_country)  
    dataset_by_country %>%
      select(Country.name, Ladder.score, upperwhisker, lowerwhisker) %>%  
      arrange(desc(Ladder.score)) %>% 
      head(10) 
  })
  
  output$bar_chart_2023 <- renderPlotly({
    data <- filtered_data_2023_top10()
    
    # Create bar chart using ggplot with color differentiation
    p <- ggplot(data, aes(x = reorder(Country.name, Ladder.score), y = Ladder.score, fill = Country.name)) +
      geom_bar(stat = "identity") + 
      geom_text(aes(label = round(Ladder.score, 1)), vjust = -0.5, size = 3.5, color = "black") +  
      scale_fill_brewer(palette = "Set3") +  
      coord_flip() +  
      labs(x = "Country", y = "Score") +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, size = 16, face = "bold"), 
        axis.title = element_text(size = 12, face = "bold"),  
        axis.text = element_text(size = 10), 
        panel.grid.major.y = element_line(color = "#d3d3d3"),  
        panel.grid.minor.y = element_blank(),  
        plot.margin = margin(20, 20, 20, 20),  
        legend.position = "none" 
      )
    
    # Convert ggplot to plotly for interactivity
    ggplotly(p, tooltip = NULL) %>%
      layout(
        hoverlabel = list(bgcolor = "white", font = list(size = 12, color = "black")),
        xaxis = list(title = "Country"),
        yaxis = list(title = "Score"),
        margin = list(l = 100, r = 10, b = 100, t = 50),  
        title = "Top 10 Countries by Total Scores in 2023"
      ) %>%
      style(
        hovertemplate = paste0(
          '<b>Country:</b> %{x}<br>',  
          '<b>Score:</b> %{y}<br>',   
          '<b>Upper Whisker:</b> %{customdata[0]}<br>',  
          '<b>Lower Whisker:</b> %{customdata[1]}<br>' 
        ),
        customdata = t(data[c("upperwhisker", "lowerwhisker")]) 
      ) %>%
      highlight(on = "plotly_hover", off = "plotly_deselect") %>%
      config(
        modeBarButtonsToRemove = c(
          "zoom2d", "pan2d", "select2d", "lasso2d", 
          "zoomIn2d", "zoomOut2d", "autoScale2d", 
          "resetScale2d", "hoverClosestCartesian", "hoverCompareCartesian"  
        ),
        displaylogo = FALSE  # Remove the Plotly logo
      )
    
  })

#----------------------------- Searching --------------------------------------  
  #### Searching - Select your country
  output$selector_country <- renderUI({
  # Ensure choices are non-empty and unique
  country_choices <- unique(dataset_by_country$Country.name)
  
  # Print to check if choices are correct
  print(country_choices)
  
  pickerInput(
    inputId = "country",  
    label = "Pick a country:",  
    choices = country_choices,  
    selected = NULL,  # Default to no selection
    options = list(
      `live-search` = TRUE,  
      style = "btn-info",  
      maxOptions = 7  
    )
  )
})
  
  # Render the date of the last data update as HTML
  output$text_date_update <- renderUI({
    # Create HTML content to display the formatted date
    tags$p(
      tags$b("Data last updated on: 2023")  
    )
  })
  
  # Searching - Show the 2023 newest stats for that country
  # Reactive expression to get the data based on the selected country
  country_data <- reactive({
    req(input$country)  
    dataset <- dataset_by_country
    subset(dataset, Country.name == input$country)  
  })
  output$valuebox_overall_score <- renderValueBox({
    data <- country_data()
    valueBox(
      formatC(data$Ladder.score, format = "f", digits = 2),
      paste("Overall score for", input$country),
      icon = icon("globe"),
      color = "green"  # or any other color
    )
  })
  # Render the value box for global max score
  output$valuebox_max_score <- renderValueBox({
    data <- country_data()
    valueBox(
      formatC(data$upperwhisker, format = "f", digits = 2),
      paste("Maximal score for", input$country),
      icon = icon("maximize"),
      color = "red"  # or any other color
    )
  })
  # Render the value box for global min score
  output$valuebox_min_score <- renderValueBox({
    data <- country_data()
    valueBox(
      formatC(data$lowerwhisker, format = "f", digits = 2),
      paste("Minimal score for", input$country),
      icon = icon("minimize"),
      color = "blue"  # or any other color
    )
  })
  
  #### Searching - Pie chart about 6 factors distribution
  # Create the pie chart
  output$pieChart <- renderPlotly({
    
    # Filter data for the selected country
    selected_country_data <- dataset_by_country %>%
      filter(Country.name == input$country)
    
    # Calculate the percentage of each factor based on Ladder.score
    factors <- c("Log GDP per person", "Healthy life expectancy", "Social support", 
                 "Perceived freedom to make life choice", "Generosity", "Perception of corruption", 
                 "Dystopia (1.58) + residual")
    
    values <- c(
      selected_country_data$Log.GDP.per.capita.value,
      selected_country_data$Healthy.life.expectancy.value,
      selected_country_data$Social.support.value,
      selected_country_data$Freedom.to.make.life.choices.value,
      selected_country_data$Generosity.value,
      selected_country_data$Perceptions.of.corruption.value,
      selected_country_data$Dystopia...residual.value
    )
    
    percentages <- as.numeric(values / selected_country_data$Ladder.score * 100)
    
    # Convert the data to a named list instead of a named vector
    pie_data <- list(
      factors = factors,
      percentages = percentages
    )
    
    # Generate the pie chart using plotly with enhanced colors and layout
    plot_ly(
      labels = ~pie_data$factors, 
      values = ~pie_data$percentages, 
      type = "pie",
      textinfo = 'label+percent',  
      hoverinfo = 'label+percent+value',  
      marker = list(
        colors = c('#636EFA', '#EF553B', '#00CC96', '#AB63FA', '#FFA15A', '#19D3F3', '#FF6692'),  
        line = list(color = '#FFFFFF', width = 2)  
      )
    ) %>%
      layout(
        title = list(
          text = paste("Happiness Factor Breakdown for", input$country), 
          font = list(size = 18, color = "#4A4A4A") 
        ),
        showlegend = TRUE,  
        legend = list(
          orientation = 'v',  
          x = 1,  
          y = 0.5,
          xanchor = 'left',  
          font = list(size = 12)  
        ),
        margin = list(l = 50, r = 150, t = 50, b = 50) 
      ) %>%
      config(
        modeBarButtonsToRemove = c(
          "zoom2d", "pan2d", "select2d", "lasso2d", 
          "zoomIn2d", "zoomOut2d", "autoScale2d", 
          "resetScale2d", "hoverClosestCartesian"  
        ),
        displaylogo = FALSE  
      )
  })
  
  #### Searching - Line chart
  # Render the line chart
  output$LadderScore_lineChart <- renderPlotly({
    # Filter data for the selected country
    selected_country_data <- dataset_by_year %>%
      filter(Country.name == input$country)
    
    # Create the line chart with text labels
    plot_ly(
      data = selected_country_data,
      x = ~year,
      y = ~Ladder.score,
      type = 'scatter',
      mode = 'lines+markers+text',
      marker = list(color = 'blue'),
      line = list(width = 2),
      text = ~Ladder.score,  
      textposition = 'top center', 
      hoverinfo = 'x+y', 
      textfont = list(size = 12) 
    ) %>%
      layout(
        title = paste("Ladder Score Trend for", input$country),
        xaxis = list(title = "Year"),
        yaxis = list(title = "Ladder Score")
      ) %>%
      config(
        modeBarButtonsToRemove = c(
          "zoom2d", "pan2d", "select2d", "lasso2d", 
          "zoomIn2d", "zoomOut2d", "autoScale2d", 
          "resetScale2d", "hoverClosestCartesian", "hoverCompareCartesian"  # Remove "Toggle Show Closest Data"
        ),
        displaylogo = FALSE  
      )
  })
  
  output$Ladder_def <- renderText({
    "<div style='padding: 15px; border: 1px solid #dcdcdc; border-radius: 8px; background-color: #fafafa; 
              box-shadow: 0 4px 8px rgba(0,0,0,0.1); margin-top: 10px;'>
    <strong style='font-size: 16px; color: #333;'>Ladder Score:</strong> 
    <p style='font-size: 14px; color: #666;'>
      The Ladder Score, also known as the Cantril life ladder, measures subjective well-being based on survey responses from the Gallup World Poll (GWP) from 2005/06 to 2023. 
      It reflects the national average response to the question: 
      <ul>
        <li>“Imagine a ladder, with steps numbered from 0 at the bottom to 10 at the top. The top of the ladder represents the best possible life, 
        and the bottom represents the worst. On which step of the ladder do you feel you stand at this time?”</li>
      </ul>
    </p>
  </div>"
  })

  # Render the line chart for Log.GDP.per.capita over time
  output$GDP_lineChart <- renderPlotly({
    # Filter data for the selected country
    selected_country_data <- dataset_by_year %>%
      filter(Country.name == input$country)
    
    # Create the line chart with text labels
    plot_ly(
      data = selected_country_data,
      x = ~year,
      y = ~Log.GDP.per.capita,
      type = 'scatter',
      mode = 'lines+markers+text',
      marker = list(color = 'green'),
      line = list(width = 2),
      text = ~Log.GDP.per.capita, 
      textposition = 'top center', 
      hoverinfo = 'x+y',  
      textfont = list(size = 12)  
    ) %>%
      layout(
        title = paste("Log GDP per Capita Trend for", input$country),
        xaxis = list(title = "Year"),
        yaxis = list(title = "Log GDP per Capita")
      ) %>%
      config(
        modeBarButtonsToRemove = c(
          "zoom2d", "pan2d", "select2d", "lasso2d", 
          "zoomIn2d", "zoomOut2d", "autoScale2d", 
          "resetScale2d", "hoverClosestCartesian", "hoverCompareCartesian"  # Remove "Toggle Show Closest Data"
        ),
        displaylogo = FALSE  
      )
  })
  
  output$GDP_def <- renderText({
    "<div style='padding: 15px; border: 1px solid #dcdcdc; border-radius: 8px; background-color: #fafafa; 
              box-shadow: 0 4px 8px rgba(0,0,0,0.1); margin-top: 10px;'>
    <strong style='font-size: 16px; color: #333;'>GDP per Capita:</strong> 
    <p style='font-size: 14px; color: #666;'>
      GDP per capita in purchasing power parity (PPP) at constant 2017 international dollar prices 
      is sourced from the World Development Indicators (WDI, version 23, Metadata last updated on - Sep 27, 2023).
      For Taiwan, Syria, Palestinian Territories, Venezuela, Djibouti, and Yemen, data is from the Penn World Table 10.01.
    </p>
  </div>"
  })
  
  # Render the line chart for Social Support over time
  output$SocialSupport_lineChart <- renderPlotly({
    selected_country_data <- dataset_by_year %>%
      filter(Country.name == input$country)
    
    # Create the line chart with text labels
    plot_ly(
      data = selected_country_data,
      x = ~year,
      y = ~Social.support,
      type = 'scatter',
      mode = 'lines+markers+text',
      marker = list(color = 'green'),
      line = list(width = 2),
      text = ~Social.support, 
      textposition = 'top center',  
      hoverinfo = 'x+y', 
      textfont = list(size = 12)  
    ) %>%
      layout(
        title = paste("Social Support Trend for", input$country),
        xaxis = list(title = "Year"),
        yaxis = list(title = "Social Support")
      ) %>%
      config(
        modeBarButtonsToRemove = c(
          "zoom2d", "pan2d", "select2d", "lasso2d", 
          "zoomIn2d", "zoomOut2d", "autoScale2d", 
          "resetScale2d", "hoverClosestCartesian", "hoverCompareCartesian"  
        ),
        displaylogo = FALSE  # Remove the Plotly logo
      )
  })
  
  output$Social_def <- renderText({
    "<div style='padding: 15px; border: 1px solid #dcdcdc; border-radius: 8px; background-color: #fafafa; 
              box-shadow: 0 4px 8px rgba(0,0,0,0.1); margin-top: 10px;'>
    <strong style='font-size: 16px; color: #333;'>Social Support:</strong> 
    <p style='font-size: 14px; color: #666;'>
      Social support is the national average of responses to the GWP question:
      <ul>
        <li>“If you were in trouble, do you have relatives or friends you can count on to help you?”</li>
      </ul>
    </p>
  </div>"
  })
  
  
  # Render the line chart for Healthy Life Expectancy over time
  output$HealthyLifeExpectancy_lineChart <- renderPlotly({
    selected_country_data <- dataset_by_year %>%
      filter(Country.name == input$country)
    
    plot_ly(
      data = selected_country_data,
      x = ~year,
      y = ~Healthy.life.expectancy.at.birth,
      type = 'scatter',
      mode = 'lines+markers+text',
      marker = list(color = 'green'),
      line = list(width = 2),
      text = ~Healthy.life.expectancy.at.birth, 
      textposition = 'top center',  
      hoverinfo = 'x+y',  
      textfont = list(size = 12) 
    ) %>%
      layout(
        title = paste("Healthy Life Expectancy Trend for", input$country),
        xaxis = list(title = "Year"),
        yaxis = list(title = "Healthy Life Expectancy")
      ) %>%
      config(
        modeBarButtonsToRemove = c(
          "zoom2d", "pan2d", "select2d", "lasso2d", 
          "zoomIn2d", "zoomOut2d", "autoScale2d", 
          "resetScale2d", "hoverClosestCartesian", "hoverCompareCartesian"  
        ),
        displaylogo = FALSE  # Remove the Plotly logo
      )
  })
  
  output$Life_def <- renderText({
    "<div style='padding: 15px; border: 1px solid #dcdcdc; border-radius: 8px; background-color: #fafafa; 
              box-shadow: 0 4px 8px rgba(0,0,0,0.1); margin-top: 10px;'>
    <strong style='font-size: 16px; color: #333;'>Life Expectancy:</strong> 
    <p style='font-size: 14px; color: #666;'>
      Life expectancy at birth is based on WHO data and reflects the average number of years a newborn is expected 
      to live under current mortality rates. Data is available for selected years and is adjusted for the report's 
      sample period.
    </p>
  </div>"
  })
  
  # Render the line chart for Freedom over time
  output$Freedom_lineChart <- renderPlotly({
    selected_country_data <- dataset_by_year %>%
      filter(Country.name == input$country)
    
    plot_ly(
      data = selected_country_data,
      x = ~year,
      y = ~Freedom.to.make.life.choices,
      type = 'scatter',
      mode = 'lines+markers+text',
      marker = list(color = 'green'),
      line = list(width = 2),
      text = ~Freedom.to.make.life.choices,  
      textposition = 'top center', 
      hoverinfo = 'x+y',  
      textfont = list(size = 12)  
    ) %>%
      layout(
        title = paste("Freedom to make life choices Trend for", input$country),
        xaxis = list(title = "Year"),
        yaxis = list(title = "Freedom to make life choices")
      ) %>%
      config(
        modeBarButtonsToRemove = c(
          "zoom2d", "pan2d", "select2d", "lasso2d", 
          "zoomIn2d", "zoomOut2d", "autoScale2d", 
          "resetScale2d", "hoverClosestCartesian", "hoverCompareCartesian"  # Remove "Toggle Show Closest Data"
        ),
        displaylogo = FALSE  
      )
  })
  
  output$Freedom_def <- renderText({
    "<div style='padding: 15px; border: 1px solid #dcdcdc; border-radius: 8px; background-color: #fafafa; 
              box-shadow: 0 4px 8px rgba(0,0,0,0.1); margin-top: 10px;'>
    <strong style='font-size: 16px; color: #333;'>Freedom:</strong> 
    <p style='font-size: 14px; color: #666;'>
      Freedom to make life choices is the national average of responses to the GWP
question:
      <ul>
        <li>“Are you satisfied or dissatisfied with your freedom to choose what
you do with your life?”</li>
      </ul>
    </p>
  </div>"
  })
  
  # Render the line chart for Generosity over time
  output$Generosity_lineChart <- renderPlotly({
    selected_country_data <- dataset_by_year %>%
      filter(Country.name == input$country)
    
    plot_ly(
      data = selected_country_data,
      x = ~year,
      y = ~Generosity,
      type = 'scatter',
      mode = 'lines+markers+text',
      marker = list(color = 'green'),
      line = list(width = 2),
      text = ~Generosity,  
      textposition = 'top center',  
      hoverinfo = 'x+y',  
      textfont = list(size = 12) 
    ) %>%
      layout(
        title = paste("Generosity Trend for", input$country),
        xaxis = list(
          title = "Year",
          showgrid = TRUE,  
          zeroline = FALSE,  
          showline = FALSE,   
          showticklabels = TRUE  
        ),
        yaxis = list(
          title = "Generosity",
          showgrid = TRUE,  
          zeroline = FALSE  
        ),
        shapes = list() 
      ) %>%
      config(
        modeBarButtonsToRemove = c(
          "zoom2d", "pan2d", "select2d", "lasso2d", 
          "zoomIn2d", "zoomOut2d", "autoScale2d", 
          "resetScale2d", "hoverClosestCartesian", "hoverCompareCartesian"  
        ),
        displaylogo = FALSE  
      )
  })
  
  output$Generosity_def <- renderText({
    "<div style='padding: 15px; border: 1px solid #dcdcdc; border-radius: 8px; background-color: #fafafa; 
              box-shadow: 0 4px 8px rgba(0,0,0,0.1); margin-top: 10px;'>
    <strong style='font-size: 16px; color: #333;'>Generosity:</strong> 
    <p style='font-size: 14px; color: #666;'>
      Generosity is the residual from regressing the national average response to the GWP question:
      <ul>
        <li>“Have you donated money to a charity in the past month?”</li>
      </ul>
    </p>
  </div>"
  })
  
  # Render the line chart for Perception of Corruption over time
  output$Perception_lineChart <- renderPlotly({
    selected_country_data <- dataset_by_year %>%
      filter(Country.name == input$country)
    
    plot_ly(
      data = selected_country_data,
      x = ~year,
      y = ~Perceptions.of.corruption,
      type = 'scatter',
      mode = 'lines+markers+text',
      marker = list(color = 'green'),
      line = list(width = 2),
      text = ~Perceptions.of.corruption,  
      textposition = 'top center',  
      hoverinfo = 'x+y',  
      textfont = list(size = 12)  
    ) %>%
      layout(
        title = paste("Perception of Corruption Trend for", input$country),
        xaxis = list(
          title = "Year",
          showgrid = TRUE,  
          zeroline = FALSE,  
          showline = FALSE,  
          showticklabels = TRUE  
        ),
        yaxis = list(
          title = "Perception of Corruption",
          showgrid = TRUE,  
          zeroline = FALSE  
        )
      ) %>%
      config(
        modeBarButtonsToRemove = c(
          "zoom2d", "pan2d", "select2d", "lasso2d", 
          "zoomIn2d", "zoomOut2d", "autoScale2d", 
          "resetScale2d", "hoverClosestCartesian", "hoverCompareCartesian"  # Remove "Toggle Show Closest Data"
        ),
        displaylogo = FALSE  
      )
  })
  
  output$Perceptions_def <- renderText({
    "<div style='padding: 15px; border: 1px solid #dcdcdc; border-radius: 8px; background-color: #fafafa; 
              box-shadow: 0 4px 8px rgba(0,0,0,0.1); margin-top: 10px;'>
    <strong style='font-size: 16px; color: #333;'>Corruption Perception:</strong> 
    <p style='font-size: 14px; color: #666;'>
      Corruption Perception is the average of two survey responses in GWP: 
      <ul>
        <li>“Is corruption widespread throughout the government?”</li>
        <li>“Is corruption widespread within businesses?”</li>
      </ul>
      ⚠️ If government corruption data is missing, business corruption data is used.</strong>
    </p>
  </div>"
  })
  
  # Render the line chart for Positive Affect over time
  output$PositiveAffect_lineChart <- renderPlotly({
    selected_country_data <- dataset_by_year %>%
      filter(Country.name == input$country)
    
    plot_ly(
      data = selected_country_data,
      x = ~year,
      y = ~Positive.affect,
      type = 'scatter',
      mode = 'lines+markers+text',
      marker = list(color = 'green'),
      line = list(width = 2),
      text = ~Positive.affect, 
      textposition = 'top center',  
      hoverinfo = 'x+y', 
      textfont = list(size = 12)  
    ) %>%
      layout(
        title = paste("Positive Affect Trend for", input$country),
        xaxis = list(title = "Year"),
        yaxis = list(title = "Positive Affect")
      ) %>%
      config(
        modeBarButtonsToRemove = c(
          "zoom2d", "pan2d", "select2d", "lasso2d", 
          "zoomIn2d", "zoomOut2d", "autoScale2d", 
          "resetScale2d", "hoverClosestCartesian", "hoverCompareCartesian" 
        ),
        displaylogo = FALSE  # Remove the Plotly logo
      )
  })
  
  output$PositiveAffect_def <- renderText({
  "<div style='padding: 15px; border: 1px solid #dcdcdc; border-radius: 8px; background-color: #fafafa; 
              box-shadow: 0 4px 8px rgba(0,0,0,0.1); margin-top: 10px;'>
    <strong style='font-size: 16px; color: #333;'>Positive Affect:</strong> 
    <p style='font-size: 14px; color: #666;'>
      Positive affect is the average of three measures in GWP: laugh, enjoyment, and doing interesting 
      things. These are responses to:
      <ul>
        <li>“Did you smile or laugh a lot yesterday?”</li>
        <li>“Did you experience enjoyment a lot yesterday?”</li>
        <li>“Did you do something interesting yesterday?”</li>
      </ul>
    </p>
  </div>"
})

  # Render the line chart for Negative Affect over time
  output$NegativeAffect_lineChart <- renderPlotly({
    selected_country_data <- dataset_by_year %>%
      filter(Country.name == input$country)
    
    plot_ly(
      data = selected_country_data,
      x = ~year,
      y = ~Negative.affect,
      type = 'scatter',
      mode = 'lines+markers+text',
      marker = list(color = 'green'),
      line = list(width = 2),
      text = ~Negative.affect,  
      textposition = 'top center',  
      hoverinfo = 'x+y',  
      textfont = list(size = 12)  
    ) %>%
      layout(
        title = paste("Negative Affect Trend for", input$country),
        xaxis = list(title = "Year"),
        yaxis = list(title = "Negative Affect")
      ) %>%
      config(
        modeBarButtonsToRemove = c(
          "zoom2d", "pan2d", "select2d", "lasso2d", 
          "zoomIn2d", "zoomOut2d", "autoScale2d", 
          "resetScale2d", "hoverClosestCartesian", "hoverCompareCartesian"  
        ),
        displaylogo = FALSE  # Remove the Plotly logo
      )
  })
  
  output$NegativeAffect_def <- renderText({
    "<div style='padding: 15px; border: 1px solid #dcdcdc; border-radius: 8px; background-color: #fafafa; 
               box-shadow: 0 4px 8px rgba(0,0,0,0.1); margin-top: 10px;'>
     <strong style='font-size: 16px; color: #333;'>Negative Affect:</strong> 
     <p style='font-size: 14px; color: #666;'>Negative affect is defined as the average of three negative affect measures in
     GWP. These measures are worry, sadness, and anger, which are responses to the questions:
     <ul>
       <li>“Did you experience the following feelings during A LOT OF THE DAY yesterday? How about Worry?”</li>
       <li>“Did you experience the following feelings during A LOT OF THE DAY yesterday? How about Sadness?”</li>
       <li>“Did you experience the following feelings during A LOT OF THE DAY yesterday? How about Anger?”</li>
     </ul>
     </p>
   </div>"
  })
  
# --------------------------- Comparison Page --------------------------------------
  #### Comparison - selector
  # Render the country selector UI
  output$selector_multiple_country <- renderUI({
    pickerInput(
      inputId = "selected_countries",
      label = "Select multiple countries you want compare:",
      choices = unique(dataset_by_country$Country.name),
      selected = "Finland", 
      multiple = TRUE,
      options = list(
        `live-search` = TRUE,
        `actions-box` = TRUE
      )
    )
  })
  
  # Output for displaying selected countries with enhanced UI
  output$selected_countries_info <- renderUI({
    selected_countries <- input$selected_countries
    
    if (length(selected_countries) == 0) {
      HTML("<div style='color: red; font-weight: bold; white-space: nowrap;'>No country is selected.</div>")
    } else {
      # Create a space-separated list of countries
      selected_list <- paste(selected_countries, collapse = ", ")
      
      # HTML with styling to ensure wrapping and fitting within the box
      HTML(paste(
        "<div style='font-size: 16px; max-width: 100%; overflow-wrap: break-word;'>",
        "<b>You have selected the following countries:</b><br>",
        selected_list,
        "</div>"
      ))
    }
  })
  
  # Reactive expression to filter dataset based on selected countries
  filtered_data <- reactive({
    req(input$selected_countries)  

    dataset_by_country %>%
      filter(Country.name %in% input$selected_countries)
    
  })
  
  #### Comparison - bar chart
  # Render the stacked bar chart with enhanced aesthetics
  output$bar_chart <- renderPlot({
    data <- filtered_data()
    
    if (nrow(data) > 0) {
        
      melted_data <- melt(data, id.vars = c("Country.name", "Ladder.score"), 
                          measure.vars = c("Log.GDP.per.capita.value", 
                                           "Social.support.value", 
                                           "Healthy.life.expectancy.value", 
                                           "Freedom.to.make.life.choices.value", 
                                           "Generosity.value", 
                                           "Perceptions.of.corruption.value", 
                                           "Dystopia...residual.value"), 
                          variable.name = "Factor", 
                          value.name = "Score")
      
      # Rename Factor levels for better legend names
      melted_data <- melted_data %>%
        mutate(Factor = recode(Factor,
                               "Log.GDP.per.capita.value" = "GDP per Capita",
                               "Social.support.value" = "Social Support",
                               "Healthy.life.expectancy.value" = "Healthy Life Expectancy",
                               "Freedom.to.make.life.choices.value" = "Freedom to Make Life Choices",
                               "Generosity.value" = "Generosity",
                               "Perceptions.of.corruption.value" = "Perceptions of Corruption",
                               "Dystopia...residual.value" = "Dystopia Residual"))
      
      ggplot(melted_data, aes(x = reorder(Country.name, Ladder.score), y = Ladder.score, fill = Factor)) +
        geom_bar(stat = "identity") +  # Create stacked bars
        geom_text(aes(label = round(Score, 1)), position = position_stack(vjust = 0.5), size = 3.5, color = "black") + 
        coord_flip() +
        labs(x = "Country", y = "Score", title = "2023 Factors Breakdown by Country") +
        scale_fill_brewer(palette = "Set3", name = "Factors") +  
        theme_minimal() +
        theme(
          plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),  
          axis.title = element_text(size = 12, face = "bold"), 
          axis.text = element_text(size = 10), 
          panel.grid.major.y = element_line(color = "#d3d3d3"),  
          panel.grid.minor.y = element_blank(), 
          plot.margin = margin(20, 20, 20, 20) 
        )
    }
  })
  
# --------------------------- About Page --------------------------------------
  
  # Render the data table
  output$data_table <- renderDT({
    datatable(
      dataset_by_country,  
      options = list(
        pageLength = 10, 
        autoWidth = TRUE,  
        scrollX = TRUE  
      )
    )
  })
  
  # Render the data source information
  output$data_source_info <- renderUI({
    HTML("<div style='font-size: 16px; color: #333; padding: 10px; background-color: #f9f9f9; border-radius: 5px;'>
            <b style='font-size: 18px;'>Data Source:</b><br>
            The data for this table is sourced from the <a href='https://worldhappiness.report/data/' style='color: #007bff;'>World Happiness Report 2024</a>.
            <br><br>
            For more details, visit the official website at <a href='https://worldhappiness.report/data/' style='color: #007bff;'>https://worldhappiness.report/data/</a>.
          </div>")
  })
  
  # Download handler for data table
  output$download_data <- downloadHandler(
    filename = function() {
      paste("world_happiness_data_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(dataset_by_country, file, row.names = FALSE)
    }
  )
}
