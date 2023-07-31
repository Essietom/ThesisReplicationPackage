library(tidyverse)
library(ggplot2)
library(svglite) 
library(bestNormalize)
library(effectsize)

energy_data_csv_path = "scripts/analysis/datasetExp1.csv"
energy_data = energy_data_csv_path %>%
  lapply(read.csv) %>%
  bind_rows

energy_data = energy_data[,c(
  "Deployment",
  "Load",
  "Value"
)]
energy_data

#set deployment and load size as factors
factor_cols = c(
  "Deployment",
  "Load"
)

energy_data[factor_cols] = lapply(energy_data[factor_cols], factor)


# Plot the line graph
mean_energy <- aggregate(Value ~ Deployment + Load, data = energy_data, FUN = mean)

lineplot = ggplot(mean_energy, aes(x = Load, y = Value, group = Deployment)) +
  geom_line(aes(color=Deployment)) +
  geom_point(aes(color=Deployment)) +
  labs(title="Energy Consumption (Watt-Hour) of Container vs Serverless Deployment", x="Load Size", y="Energy Consumption(Watt-Hour)")
ggsave(
  file="scripts/analysis/resultsExp1/linegraph.png",
  plot=lineplot,
)

barchart = ggplot(mean_energy, aes(x = Load, y = Value, fill = Deployment)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title="Energy Consumption (Watt-Hour) of Container vs Serverless Deployment", x="Load Size", y="Energy Consumption(Watt-Hour)")
print(barchart)

ggsave(
  file="scripts/analysis/resultsExp1/barchart.png",
  plot=barchart,
)

#box_plot_load_energy_data
boxplot_load_avg_energy = ggplot(energy_data, aes(x=Load, y=Value, fill=Load)) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 14),
        legend.position = "bottom",
  ) +
  geom_boxplot(outlier.size=.4,) +
  labs(title="Energy Consumption (Watt-Hour) per load size", x="Load Size", y="Energy Consumption(Watt-Hour)") +
  stat_summary(fun = mean, color = "grey", position = position_dodge(0.75),
               geom = "point", shape = 18, size = 2,
               show.legend = FALSE, aes(fill=factor(Load)))

boxplot_load_avg_energy

ggsave(
  file="scripts/analysis/resultsExp1/load/boxplot_load_avg_energy.png",
  plot=boxplot_load_avg_energy,
)


#box_plot_deployment_energy_data
boxplot_deployment_avg_energy = ggplot(energy_data, aes(x=Deployment, y=Value, fill=Deployment)) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 14),
        legend.position = "bottom",
  ) +
  geom_boxplot(outlier.size=.4,) +
  labs(title="Energy Consumption (Watt-Hour) per deployment type", x="Deployment Type", y="Energy Consumption(Watt-Hour)") +
  stat_summary(fun = mean, color = "grey", position = position_dodge(0.75),
               geom = "point", shape = 18, size = 2,
               show.legend = FALSE, aes(fill=factor(Deployment)))

boxplot_deployment_avg_energy

ggsave(
  file="scripts/analysis/resultsExp1/deployment/boxplot_deployment_avg_energy.png",
  plot=boxplot_deployment_avg_energy,
)

#BY_DEPLOYMENT 
energy_by_deployment = energy_data %>%
  group_by(Deployment)

energy_by_deployment_summary = energy_by_deployment %>%
  summarize(
    count = n(),
    Minimum =round( min(Value),3),
    Q1 =round( quantile(Value, 0.25),3),
    Median =round( median(Value),3),
    Mean =round( mean(Value),3),
    SD =round( sd(Value),3),
    Q3 =round( quantile(Value, 0.75),3),
    Maximum =round(max(Value),3)
  )

energy_by_deployment_summary

write.csv(
  energy_by_deployment_summary,
  "scripts/analysis/resultsExp1/deployment/energy_by_deployment_summary.csv",
  row.names = FALSE
)

#BY_LOADSIZE 
energy_by_load = energy_data %>%
  group_by(Load)

energy_by_load_summary = energy_by_load %>%
  summarize(
    count = n(),
    Minimum =round( min(Value),3),
    Q1 =round( quantile(Value, 0.25),3),
    Median =round( median(Value),3),
    Mean =round( mean(Value),3),
    SD =round( sd(Value),3),
    Q3 =round( quantile(Value, 0.75),3),
    Maximum =round(max(Value),3)
  )

energy_by_load_summary

write.csv(
  energy_by_load_summary,
  "scripts/analysis/resultsExp1/load/energy_by_load_summary.csv",
  row.names = FALSE
)


check_normality_data <- function(func_data, saveHistogram = FALSE, saveQQPlot = FALSE, normalized=FALSE) {
  par(mfrow=c(1,3))
  
  normalized_text = if(normalized) '_normalized' else ''
  
  if (saveHistogram) {
    png(paste("scripts/analysis/resultsExp1/histogram_energy_consumption",normalized_text,".png", sep = ""))
    func_data %>%
      hist(breaks=20,main="Energy Consumption Distribution")
    dev.off()
    func_data %>%
      hist(breaks=20,main="Energy Consumption Distribution")
  } else {
    func_data %>%
      hist(breaks=20,main="Energy Consumption Distribution")
  }
  
  if (saveQQPlot) {
    png(paste("scripts/analysis/resultsExp1/qq_plot_energy_consumption",normalized_text,".png", sep = ""))
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
    dev.off()
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
  } else {
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
  }
  
  shapiro_energy_test = shapiro.test(func_data)  
  print(shapiro_energy_test)
  
  capture.output(shapiro_energy_test, file = paste("scripts/analysis/resultsExp1/shapiro_energy_consumption",normalized_text,".txt", sep=""))
  par(mfrow=c(1,1))
}

#check_normality_of_whole_data
check_normality_data(energy_data$Value, saveHistogram = TRUE, saveQQPlot = TRUE)

bestNormAvgEnergy = bestNormalize(energy_data$Value)
bestNormAvgEnergy
energy_data$norm_energy = bestNormAvgEnergy$x.t
check_normality_data(energy_data$norm_energy, saveHistogram = TRUE, saveQQPlot = TRUE, normalized=TRUE)



library(car)
# Using leveneTest()
result = leveneTest(data = energy_data, norm_energy ~ Deployment)

# print the result
print(result)

# #two-way-anova with interaction
res.aov_interaction <- aov(norm_energy ~ Load * Deployment, data = energy_data)
anova_with_interaction_test = summary(res.aov_interaction)
anova_with_interaction_test
capture.output(anova_with_interaction_test, file = "scripts/analysis/resultsExp1/anova_with_interaction.txt")




#aov_residuals <- residuals(object=res.aov_interaction)
#shapiro.test(aov_residuals)



#two-way-anova with no interaction
res.aov_nointeraction <- aov(norm_energy ~ Load + Deployment, data = energy_data)
anova_without_interaction_test = summary(res.aov_nointeraction)
anova_without_interaction_test
capture.output(anova_without_interaction_test, file = "scripts/analysis/resultsExp1/anova_without_interaction.txt")


#finding best fit aniva model with AIC model selection
library(AICcmodavg)

model.set <- list(res.aov_nointeraction, res.aov_interaction)
model.names <- c("no interaction", "interaction")
aictab(model.set, modnames = model.names)

turkeyHSD_test<-TukeyHSD(res.aov_interaction)
capture.output(turkeyHSD_test, file = "scripts/analysis/resultsExp1/turkeyhsd.txt")

print(turkeyHSD_test, digits=15)


#effect size
eta_squared_energy = eta_squared(res.aov_interaction)
eta_squared_energy
capture.output(eta_squared_energy, file = "scripts/analysis/resultsExp1/eta_squared_energy.txt")



energy_data$load_deployment = paste(energy_data$Load, " and ", energy_data$Deployment)

energy_by_load_deployment = energy_data %>%
  group_by(load_deployment)

energy_by_load_deployment_summary = energy_by_load_deployment %>%
  summarize(
    count = n(),
    Minimum =round( min(Value),3),
    Q1 =round( quantile(Value, 0.25),3),
    Median =round( median(Value),3),
    Mean =round( mean(Value),3),
    SD =round( sd(Value),3),
    Q3 =round( quantile(Value, 0.75),3),
    Maximum =round(max(Value),3)
  )

energy_by_load_deployment_summary

write.csv(
  energy_by_load_deployment_summary,
  "scripts/analysis/resultsExp1/energy_by_load_deployment_summary.csv",
  row.names = FALSE
)

