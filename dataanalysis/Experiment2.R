library(tidyverse)
library(ggplot2)
library(svglite) 
library(bestNormalize)
library(effectsize)

energy_data_csv_path = "datasetExp2.csv"
energy_data = energy_data_csv_path %>%
  lapply(read.csv) %>%
  bind_rows

energy_data = energy_data[,c(
  "Tactic",
  "Load",
  "Value"
)]
energy_data

#set tactic and load size as factors
factor_cols = c(
  "Tactic",
  "Load"
)

energy_data[factor_cols] = lapply(energy_data[factor_cols], factor)


# Plot the line graph
mean_energy <- aggregate(Value ~ Tactic + Load, data = energy_data, FUN = mean)

lineplot = ggplot(mean_energy, aes(x = Load, y = Value, group = Tactic)) +
  geom_line(aes(color=Tactic)) +
  geom_point(aes(color=Tactic)) +
  labs(title="Energy Consumption (Watt-Hour): Granular Scaling", x="Load Size", y="Energy Consumption(Watt-Hour)")
ggsave(
  file="resultsExp2/linegraph.png",
  plot=lineplot,
)

barchart2 = ggplot(mean_energy, aes(x = Load, y = Value, fill = Tactic)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title="Energy Consumption (Watt-Hour) : Granular Scaling", x="Load Size", y="Energy Consumption(Watt-Hour)")
print(barchart2)

ggsave(
  file="resultsExp2/barchart.png",
  plot=barchart2,
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
  file="resultsExp2/load/boxplot_load_avg_energy.png",
  plot=boxplot_load_avg_energy,
)


#box_plot_tactic_energy_data
boxplot_tactic_avg_energy = ggplot(energy_data, aes(x=Tactic, y=Value, fill=Tactic)) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 14),
        legend.position = "bottom",
  ) +
  geom_boxplot(outlier.size=.4,) +
  labs(title="Energy Consumption (Watt-Hour) per tactic", x="Tactic Application", y="Energy Consumption(Watt-Hour)") +
  stat_summary(fun = mean, color = "grey", position = position_dodge(0.75),
               geom = "point", shape = 18, size = 2,
               show.legend = FALSE, aes(fill=factor(Tactic)))

boxplot_tactic_avg_energy

ggsave(
  file="resultsExp2/tactic/boxplot_tactic_avg_energy.png",
  plot=boxplot_tactic_avg_energy,
)

#BY_TACTIC
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
  "resultsExp2/tactic/energy_by_tactic_summary.csv",
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
  "resultsExp2/load/energy_by_load_summary.csv",
  row.names = FALSE
)


check_normality_data <- function(func_data, saveHistogram = FALSE, saveQQPlot = FALSE, normalized=FALSE) {
  par(mfrow=c(1,3))
  
  normalized_text = if(normalized) '_normalized' else ''
  
  if (saveHistogram) {
    png(paste("resultsExp2/histogram_energy_consumption",normalized_text,".png", sep = ""))
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
    png(paste("resultsExp2/qq_plot_energy_consumption",normalized_text,".png", sep = ""))
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
    dev.off()
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
  } else {
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
  }
  
  shapiro_energy_test = shapiro.test(func_data)  
  print(shapiro_energy_test)
  
  capture.output(shapiro_energy_test, file = paste("resultsExp2/shapiro_energy_consumption",normalized_text,".txt", sep=""))
  par(mfrow=c(1,1))
}

#check_normality_of_whole_data
check_normality_data(energy_data$Value, saveHistogram = TRUE, saveQQPlot = TRUE)


bestNormAvgEnergy = bestNormalize(energy_data$Value)
bestNormAvgEnergy
energy_data$norm_energy = bestNormAvgEnergy$x.t
check_normality_data(energy_data$norm_energy, saveHistogram = TRUE, saveQQPlot = TRUE, normalized=TRUE)



# #two-way-anova with interaction
res.aov_interaction <- aov(norm_energy ~ Load * Tactic, data = energy_data)
anova_with_interaction_test = summary(res.aov_interaction)
anova_with_interaction_test
capture.output(anova_with_interaction_test, file = "resultsExp2/anova_with_interaction.txt")


#two-way-anova with no interaction
res.aov_nointeraction <- aov(norm_energy ~ Load + Tactic, data = energy_data)
anova_without_interaction_test = summary(res.aov_nointeraction)
anova_without_interaction_test
capture.output(anova_without_interaction_test, file = "resultsExp2/anova_without_interaction.txt")


#finding best fit aniva model with AIC model selection
library(AICcmodavg)
library(multcompView)

model.set <- list(res.aov_nointeraction, res.aov_interaction)
model.names <- c("no interaction", "interaction")
aictab(model.set, modnames = model.names)

tt<-TukeyHSD(res.aov_interaction)
capture.output(tt, file = "resultsExp2/turkeyhsd2.txt")
print(tt, digits=15)

interaction.plot(x.factor = energy_data$Load, trace.factor = energy_data$Tactic, response = energy_data$norm_energy,
                 type = "b", legend = TRUE, pch = 19, col = c("blue", "red"),
                 xlab = "Diet", ylab = "Weight Loss",
                 main = "Interaction Plot: Gender x Diet on Weight Loss")

#print(tt, digits=15)


#simple main effect analysis to under stand difference between tactic treatment at each load level
#Load 0 subset
load0 <- subset(energy_data, Load == "0")
#Load 20 subset
load20 <- subset(energy_data, Load == "20")
#Load 50 subset
load50 <- subset(energy_data, Load == "50")
#Load 100 subset
load100 <- subset(energy_data, Load == "100")

#We control for type 1 error by dividing 0.05/4 => significance level = 0.0125
#then we run an anova on the load subset

load0.aov <- aov(norm_energy ~ Tactic, data = load0)
anova_load0 = summary(load0.aov)
anova_load0
capture.output(anova_load0, file = "resultsExp2/anova_load0.txt")


load20.aov <- aov(norm_energy ~ Tactic, data = load20)
anova_load20 = summary(load20.aov)
anova_load20
capture.output(anova_load20, file = "resultsExp2/anova_load20.txt")


load50.aov <- aov(norm_energy ~ Tactic, data = load50)
anova_load50 = summary(load50.aov)
anova_load50
capture.output(anova_load50, file = "resultsExp2/anova_load50.txt")


load100.aov <- aov(norm_energy ~ Tactic, data = load100)
anova_load100 = summary(load100.aov)
anova_load100
capture.output(anova_load100, file = "resultsExp2/anova_load100.txt")



#effect size
eta_squared_energy = eta_squared(res.aov_interaction)
eta_squared_energy
capture.output(eta_squared_energy, file = "resultsExp2/eta_squared_energy.txt")


#effect size
load0.eta = eta_squared(load0.aov)
load0.eta


#effect size
load20.eta = eta_squared(load20.aov)
load0.eta

#effect size
load50.eta = eta_squared(load50.aov)
load50.eta

#effect size
load100.eta = eta_squared(load100.aov)
load100.eta


energy_data$load_tactic = paste(energy_data$Load, " and ", energy_data$Tactic)

energy_by_load_tactic = energy_data %>%
  group_by(load_tactic)

energy_by_load_tactic_summary = energy_by_load_tactic %>%
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

energy_by_load_tactic_summary

write.csv(
  energy_by_load_tactic_summary,
  "resultsExp2/energy_by_load_tactic_summary.csv",
  row.names = FALSE
)

