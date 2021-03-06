#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)
library(moments)
library(PerformanceAnalytics)

# Define UI for application that draws a histogram
ui <- fluidPage(
    
    # Application title
    titlePanel("Vasicek loan loss model"),
    
    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            sliderInput("rho",
                        "Correlation:",
                        min = 0,
                        max = 1,
                        value = 0.3),
            sliderInput("pd",
                        "Probability of default:",
                        min = 0,
                        max = 1,
                        value = 0.1),
            sliderInput("bins",
                        "Number of bins:",
                        min = 1,
                        max = 100,
                        value = 20),
            sliderInput("years",
                        "Number of years simulated:",
                        min = 5,
                        max = 1000,
                        value = 500),
            sliderInput("corporates",
                        "Number of corporates:",
                        min = 1000,
                        max = 10000,
                        value = 1000),
            actionButton("do", "New simulation"),
            sliderInput("years_sim",
                        "Number of years simulated in single simulation:",
                        min = 1,
                        max = 100,
                        value = 10),
            sliderInput("corporates_sim",
                        "Number of corporates in single simulation:",
                        min = 100,
                        max = 2000,
                        value = 500)
            
            
        ),
        # Show a plot of the generated distribution
        mainPanel(
            plotOutput("distPlot"),
            textOutput("kurtosis"),
            textOutput("skew"),
            plotOutput('simPlot'),
            textOutput("all_txt")
            
            
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
            output$distPlot <- renderPlot({
                sim_port_loss <- function(n,number_of_years,pd,rho){
                    loss_lim <- qnorm(pd)
                    systematic_factor <-matrix(rep(rnorm(number_of_years),each=n) ,nrow=n)
                    idiosyncratic_factor <- matrix(rnorm(n*number_of_years),nrow=n,ncol=number_of_years)  
                    firm_value <- sqrt(rho)*systematic_factor+sqrt(1-rho)*idiosyncratic_factor
                    sim_port_loss = colSums(firm_value<loss_lim)/n
                }
                pd = min(max(input$pd,1e-6),0.99999999)
                rho = min(max(input$rho,1e-6),0.99999999)
                n=input$corporates
                number_of_years= input$years
                df <-data.frame(loss_rate=sim_port_loss(n,number_of_years,pd,rho))
                kur = round(kurtosis(df$loss_rate,method='sample_excess'),3)
                kur_txt = paste('Kurtosis = ',toString(kur))
                skew_txt = paste('Skewnes = ',toString(round(skewness(df$loss_rate),3)))
                output$kurtosis = renderText(kur_txt)
                output$skew = renderText(skew_txt)
                
                #Plot of whole simulation
                ggplot(df, aes(x=loss_rate)) +geom_histogram(color="darkblue", fill="lightblue",bins=input$bins)+labs(x='Loss rate')+xlim(0,1)
            })
        output$simPlot <- renderPlot({
            sim_port_loss <- function(n,number_of_years,pd,rho){
                loss_lim <- qnorm(pd)
                systematic_factor <-matrix(rep(rnorm(number_of_years),each=n) ,nrow=n)
                idiosyncratic_factor <- matrix(rnorm(n*number_of_years),nrow=n,ncol=number_of_years)  
                firm_value <- sqrt(rho)*systematic_factor+sqrt(1-rho)*idiosyncratic_factor
                sim_port_loss = colSums(firm_value<loss_lim)/n
            }
            pd = min(max(input$pd,1e-6),0.99999999)
            rho = min(max(input$rho,1e-6),0.99999999)
            n=input$corporates_sim
            input$do
            number_of_years= input$years_sim
            df <-data.frame(loss_rate=sim_port_loss(n,number_of_years,pd,rho))
            kur = round(kurtosis(df$loss_rate,method='sample_excess'),3)
            kur_txt = paste('kurtosis = ',toString(kur))
            med <- median(df$loss_rate)
            avg <- mean(df$loss_rate)
            np <- avg *number_of_years*n
            np_sd <- sqrt(avg *number_of_years*n*(1-avg))
            est_lim <- qnorm(0.025,np,np_sd)/number_of_years/n
            
            med_txt <-  paste('median = ',toString(round(med,2)))
            avg_txt <-  paste('Mean = ',toString(round(avg,2)))
            skew_txt = paste('skewnes = ',toString(round(skewness(df$loss_rate),3)))
            lim_pd_txt <- paste('lim pd = ',toString(round(est_lim,3)))
            
            all_txt = paste(avg_txt,med_txt,kur_txt,skew_txt,lim_pd_txt,sep=", ")
            print(all_txt)
            output$all_txt = renderText(all_txt)
            ggplot(df, aes(x=loss_rate)) +geom_histogram(color="darkblue", fill="lightblue",bins=input$bins)+labs(x='Loss rate')+xlim(0,1)
            
            
            
        })
}

# Run the application 
shinyApp(ui = ui, server = server)
