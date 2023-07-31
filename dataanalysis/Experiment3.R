library(tidyverse)
library(ggplot2)
library(svglite) 
library(bestNormalize)
library(effectsize)
library(effsize)
library(lsr)

energy_data_csv_path = "datasetExp3.csv"
energy_data = energy_data_csv_path %>%
  lapply(read.csv) %>%
  bind_rows

energy_data = energy_data[,c(
  "Tactic",
  "Value"
)]
energy_data

#set deployment and load size as factors
factor_cols = c(
  "Tactic"
)

energy_data[factor_cols] = lapply(energy_data[factor_cols], factor)

#BY_DEPLOYMENT 
energy_by_tactic = energy_data %>%
  group_by(Tactic)

energy_by_tactic_summary = energy_by_tactic %>%
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

energy_by_tactic_summary

write.csv(
  energy_by_tactic_summary,
  "resultsExp3/energy_by_tactic_summary.csv",
  row.names = FALSE
)

# Create the bar chart
bar_chart <- ggplot(energy_data, aes(x = Tactic, y = Value, fill = Tactic)) +
  geom_bar(stat = "identity") +
  labs(x = "Tactic Application", y = "Average Energy Consumption", title = "Impact of Deallocating Unused Container Resources")

# Display the bar chart
print(bar_chart)

ggsave(
  file="resultsExp3/barchart_avg_energy.png",
  plot=bar_chart,
)

#box_plot_tactic_energy_data
boxplot_tactic_avg_energy = ggplot(energy_data, aes(x=Tactic, y=Value, fill=Tactic)) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 14),
        legend.position = "bottom",
  ) +
  geom_boxplot(outlier.size=.4,) +
  labs(title="Energy Consumption (Watt-Hour) per Tactic Treatment", x="Tactic Application", y="Energy Consumption(Watt-Hour)") +
  stat_summary(fun = mean, color = "grey", position = position_dodge(0.75),
               geom = "point", shape = 18, size = 2,
               show.legend = FALSE, aes(fill=factor(Tactic)))

boxplot_tactic_avg_energy

ggsave(
  file="resultsExp3/boxplot_tactic_avg_energy.png",
  plot=boxplot_tactic_avg_energy,
)

check_normality_data <- function(func_data, saveHistogram = FALSE, saveQQPlot = FALSE, tag='') {
  par(mfrow=c(1,3))
  
  if (saveHistogram) {
    png(paste("resultsExp3/histogram_energy_consumption",tag,".png", sep = ""))
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
    png(paste("resultsExp3/qq_plot_energy_consumption",tag,".png", sep = ""))
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
    dev.off()
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
  } else {
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
  }
  
  shapiro_energy_test = shapiro.test(func_data)  
  print(shapiro_energy_test)
  
  capture.output(shapiro_energy_test, file = paste("resultsExp3/shapiro_energy_consumption",tag,".txt", sep=""))
  par(mfrow=c(1,1))
}

without_tactic <- energy_data$Value[energy_data$Tactic == "without_t3"]
with_tactic <- energy_data$Value[energy_data$Tactic == "with_t3"]

#check_normality_of_each group
check_normality_data(without_tactic, saveHistogram = TRUE, saveQQPlot = TRUE, tag = 'without_t3')
check_normality_data(with_tactic, saveHistogram = TRUE, saveQQPlot = TRUE, tag = 'with_t3')

# Perform Mann-Whitney U test to test hypothesis
result <- wilcox.test(without_tactic, with_tactic)
capture.output(result, file = "resultsExp3/mannwhineytest.txt")

# Perform Cliff's Delta to test effect size
delta <- cliff.delta(without_tactic, with_tactic)
capture.output(delta, file = "resultsExp3/cliffdelta.txt")

# Perform Cohens'd to test effect size
cohen_d <- cohensD(without_tactic, with_tactic)
capture.output(cohen_d, file = "resultsExp3/cohend.txt")

