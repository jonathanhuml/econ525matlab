%Purpose:
    %ECON 525-Spring2020
%Note:
    %This is dependent on:
        %GDPC1.xls
        %10_Industry_Portfolios.csv
        %market_monthly.csv
     
%Author:
    %Jon Huml-March 1
    %UNC Honor Pledge abided by

gdp = readtable("GDPC1.xls");
gdp{:,2} = gdp{:,2}/100;
Ydate = cellstr(datetime(gdp{:,1},'InputFormat','MM/dd/uuuu','Format','yyyy-MM-dd'));
port = readtable("10_Industry_Portfolios.csv");
port{:,2:end} = port{:,2:end}/100;
ret = readtable("market_monthly.csv");

x =  num2str(ret{:,1});
Xdate = cellstr(datetime(x,'InputFormat','yyyyMMdd','Format','yyyy-MM-dd'));

Xlag = 3;
Ylag = 1;
EstStart = '1947-04-01';
EstEnd = '2017-10-01';
Method = 'rollingwindow';

%%
%2a
forecasts = zeros(4,10,3);
errors = zeros(10,3);
for horizon = 1:3
    for industry = 1:10
        [OutputForecast,OutputEstimate] = MIDAS_ADL(gdp{:,2},Ydate,port{:,industry+1},Xdate,'Xlag',Xlag,'Ylag',Ylag,'Horizon',horizon,'EstStart',EstStart,'EstEnd',EstEnd,'Polynomial','expAlmon','Method',Method,'Display','estimate');
        errors(industry, horizon) = OutputForecast.RMSE;
        forecasts(:,industry,horizon) = OutputForecast.Yf; 
    end
end

e_table = array2table(errors, "VariableNames",...
    {'Hor.1','Hor.2','Hor.3',},...
    "RowNames",{'NoDur','Durbl','Manuf','Enrgy','Tec','Telcm','Shops','Hlth','Utils','Othr'});

%%
%2b
 %I could've used ForcastCombine here but I already saved the forecasts
 %above instead of the models, so I just use equal weighting scheme
comb_errors = zeros(1,3);
for dimension = 1:3
    df = sum(forecasts(:,:,dimension),2) ./ 10; 
    comb_errors(1,dimension) = sqrt(mean((df-gdp{284:end,2}).^2));
end
 
%df = sum(forecasts(:,:,1),2) ./ 10; 

%%
%2c
market_errors = zeros(1,3);
for horizon = 1:3
    [OutputForecast,OutputEstimate] = MIDAS_ADL(gdp{:,2},Ydate,ret{:,2},Xdate,'Xlag',Xlag,'Ylag',Ylag,'Horizon',horizon,'EstStart',EstStart,'EstEnd',EstEnd,'Polynomial','expAlmon','Method',Method,'Display','estimate');
    market_errors(1, horizon) = OutputForecast.RMSE;
  
end
%%
%2d
D = vertcat(errors,comb_errors, market_errors);
all = array2table(D, "VariableNames",...
    {'Hor.1','Hor.2','Hor.3',},...
    "RowNames",{'NoDur','Durbl','Manuf','Enrgy','Tec','Telcm','Shops','Hlth','Utils','Othr', 'Comb', 'Market'});
