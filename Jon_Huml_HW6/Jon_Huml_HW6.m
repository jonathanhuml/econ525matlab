%Purpose:
    %ECON 525-Spring2020, year of the coronavirus
%Note:
    %This is dependent on:
        %treasuries.xlsx
        %treasuries_copy.csv
     
%Author:
    %Jon Huml-March 15
    %UNC Honor Pledge abided by
    
treasuries = readtable("treasuries.xlsx");
%same data but matlab doesn't consistently read in NaNs from excel
tr = readtable("treasuries_copy.csv");

dates = datenum(treasuries{:,1});
yield = tr{:,3:end};


MonthYearMat = repmat((1990:2017)',1,12)';
EOMDates = lbusdate(MonthYearMat(:),repmat((1:12)',28,1));
MonthlyIndex = find(ismember(dates,EOMDates));
EstimationData = yield(MonthlyIndex,:);

MonthYearMatTest = repmat((2018)',1,12)';
EOMDatesTest = lbusdate(MonthYearMatTest(:),repmat((1:12)',1,1));
MonthlyIndexTest = find(ismember(dates,EOMDatesTest));
Data = yield(MonthlyIndexTest,:);

% Explicitly set the time factor lambda
lambda_t = .0609;

% Construct a matrix of the factor loadings
% Tenors associated with data
TimeToMat = [3 6 9 12 24 36 60 84 120 240 360]';
X = [ones(size(TimeToMat)) (1 - exp(-lambda_t*TimeToMat))./(lambda_t*TimeToMat) ...
    ((1 - exp(-lambda_t*TimeToMat))./(lambda_t*TimeToMat) - exp(-lambda_t*TimeToMat))];

%%
%1A
% Plot the factor loadings
plot(TimeToMat,X)
title('Diebold Li Model Factor Loadings with time factor of .0609')
xlabel('Maturities (mm)')
ylim([0 1.5])
legend({'Beta1 Factor Loading','Beta2 Factor Loading','Beta3 Factor Loading'},'location','east')

%%
% Preallocate the Betas
Beta = zeros(size(EOMDates,1),3);

% Loop through and fit each end of month yield curve
for jdx = 1:size(EOMDates,1)
    tmpCurveModel = DieboldLi.fitBetasFromYields(EOMDates(jdx),lambda_t*12,daysadd(EOMDates(jdx),30*TimeToMat),EstimationData(jdx,:)');
    Beta(jdx,:) = [tmpCurveModel.Beta1 tmpCurveModel.Beta2 tmpCurveModel.Beta3];
end
    

%%
%1C
forecasts = zeros(12,3); 

for j = 1:3
    for i = 1:12
        tmpBeta = regress(Beta(i+1:end,j),[ones(size(Beta(i+1:end,j))) Beta(1:end-i,j)]);
        forecasts(i,j) = [1 Beta(end,j)]*tmpBeta;
    end    
end

%%
%1D
yield_forecast = zeros(12,11);
    
for k = 1:12 
    yield_forecast(k,:) = sum((X .* repelem(forecasts(k,:),11,1)),2)';
end
        
pfe = (yield_forecast - Data)./ Data;

pfe = array2table(pfe,'RowNames',{'Jan', 'Feb', 'March', 'April', 'May', 'June,'...
        'July', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'},...
      'VariableNames',{'1MO', '3MO', '6MO', '1YR', '2YR', '3YR',...
        '5YR', '7YR', '10YR', '20YR', '30YR'});
