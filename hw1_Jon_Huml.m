%Purpose:
    %ECON 525-Spring2020
%Note:
    %This is dependent on:
        %hw1_returns_constituents.csv
        %div_yield.csv
        %T10Y2Y.csv
        %GS10.csv
        %INDPROD.csv
%Author:
    %Jon Huml-Jan 27
    %UNC Honor Pledge abided by

clear all; close all; clc; 

returns = readtable('hw1_returns_constituents.csv');

%drop the null values
%the return data is already adjusted for splits, etc.
returns=returns(:,~any(ismissing(returns)));
%get the names for table_1
stock_tickers = returns.Properties.VariableNames(:,3:size(returns.Properties.VariableNames, 2))
%get a numerical array of returns for regress function below
returns_array = table2array(returns(:,3:size(returns,2)))


%s&p500 dividends
div = rmmissing(readtable("div_yield.csv"));
div = table2array(div(:,2));

%10-2 factor
ten_two = readtable("T10Y2Y.csv");
ten_two = table2array(ten_two(:,2));

%10 yr
ten = readtable("GS10.csv");
ten = table2array(ten(:,2));

indus_prod = readtable("INDPROD.csv");
indus_array = table2array(indus_prod(:,2));
%need percent change, so this is still raw
indus_change = price2ret(indus_array); 

factors = [ten ten_two div indus_change];
%loop through each ticker 
%subtract risk free rate from each ticker return 
    
%NUMBER ONE: Standard two pass
%First Pass: Estimate the betas
%create zero matrix
beta = zeros(size(returns_array,2),5); 
for i = 1:size(returns_array,2) %loop over each asset
    y = returns_array(:,i); %Set the "y"
    X = [ones(size(factors,1),1) factors]; %set the "X"; Add ones vector for intercept. 
    [b,bint,r,rint,stats] = regress(y,X); %Conduct regression.
    beta(i,1:5) = b'; %grab the betas and stack
end


%Second Pass: Regress avg returns on estimated betas
AvgRet = mean(returns_array); %Compute avg ret
clear b y X
y = AvgRet'; %Set the y 
X = [beta(:,2:5)]; % Set the X. Note that the fitlm function includes intercept by default. 
mdl = fitlm(X,y); %second pass regression. 

%calc min/max values for betas
[argminvalue, argmin] = min(beta);
lowest_betas = stock_tickers(argmin);
[argmaxvalue, argmax] = max(beta);
highest_betas = stock_tickers(argmax);

table_1 = [stock_tickers' num2cell(y) num2cell(beta)];
%PART B
%{
The mean average return is about 0.0096. The returns are mostly
positive for this time period as expected since we've been in a bull
market for a while now. For each beta, I look at the
argmin and argminvalues. The companies most negatively affected by these
factors were semiconductor companies like NVDA and a couple pharma
companies. This agrees with my intuition since these types are typically
thought to be more affected by regulation or commodity price
swings--otherwise wide-reaching price movers that are implicitly tied into 
the macro factors in our regression. The same is true for the most positive betas:
they also contain pharma companies, realty, and a retail company. 
%}

table_2 = mdl.Coefficients;


%{
There is a positive premium, 0.04, for ten year (x1). This is significant 
at about the 95% confidence level. The ten-two is the most negative premium, 
and is significant at the 90% level. The dividends premia is slightly
negative, and is significant at the 95% confidence level. The change in
industrial production coefficient is almost zero, and is significant at the 90%
confidence level. 
Because of the errors in variables problem, slightly positive or negative
values may be misleading. Regardless, it seems that the effect of
industrial production on equity premia is almost zero. The only positive
premia is the effect of the ten year yield. If the ten year yield increases, 
then the compensation for holding those equities increases according to our model. 
%}


%NUMBER TWO: Fama-MacBeth

%The first step of any of these factor models is the same
%So table_3 = table_1
table_3 = table_1;

dev = std(beta,1);
%{ 
The interpretation is the same as table 1 since they're the same table. 
I will add that the variation in the betas is highest for the change in
industrial production. There are likely a few companies that are heavily 
affected by this, like semiconductor companies. Software companies like Facebook
have almost zero (0.02) effect from industrial production, which aligns with 
intuition, but Nvidia is quite high since they rely on industrial production 
for their chips. The variation for ten and ten-and-two is close to
zero. Dividends is a bit higher in variation, but is still close to zero.
%}

T = size(returns_array,1); %# of months
for t = 1:T %Loop over each month
    y = returns_array(t,:); %Set the y 
    X = [ones(size(beta,1),1) beta(:,2:size(beta,2))]; % Set the X; add ones for intercept
    [lambda,bint,r,rint,stats] = regress(y',X); %Regress returns on estimated beta
    %Grab the Lambda
    Lambda1(t,:) = lambda'; 
end

%Summarize by avg the lambdas over time
AvgL = mean(Lambda1); 

%Create a t-statistic for this avg lambda 
%def. t stat: (sample mean - hypothesized mean)/(std / sqrt(n))
%hypothesized mean is zero b/c random walk
t_values = zeros(size(AvgL,2),1)';
for j = 1:size(AvgL, 2);
    t_values(:,j) = (AvgL(1,j)/(std(Lambda1(:,j))/size(Lambda1,j)));
end
    
factor_names = {'Intercept'; 'Ten'; '10 and 2';'Dividends';'Industrial Production'};
%concat the vectors, coerce numeric to cell values 
out = [factor_names' ; num2cell(AvgL); num2cell(t_values)]; %Group for the table
table_4 = out';
%{
All of the factors have significant premia except for the ten year
yield. These are significant at the 90% confidence level. Once again,
agreeing with our standard two pass, ten is also the only positive 
coefficient. Since this is not statistically significant, though, we
cannot infer anything about this ten year yield relationship from this 
test. 

%}