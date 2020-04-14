%Purpose:
    %ECON 525-Spring2020, year of the coronavirus
%Note:
    %This is dependent on:
        %treasuries.xlsx
        %treasuries_copy.csv
     
%Author:
    %Jon Huml-March 18
    %UNC Honor Pledge abided by
    
%I dropped all NAs, so dow chemical got dropped    
returns = readtable("monthly_djia.csv");

benchReturn = mean(returns{:,2});
benchRisk =  std(returns{:,2});
assetm = mean(returns{:,3:end});
assetcov =  cov(returns{:,3:end});

assetNames = (returns(:, 3:end).Properties.VariableNames); 
    
prices = readtable("last_price.xlsx");
%to get the weights, first calc the DOW
%I simply use the last month price for this, 
%since we are investing now. 
%the long decimal is the DOW divisor
dow = (sum(prices{:,2}) / 0.14744568353097); 
dow_weights = prices{:,2} / dow; 
%%
p = Portfolio('AssetList',assetNames);
p = setAssetMoments(p,assetm,assetcov);

%Make the initial starting point the actual weights from the DOW
p = setInitPort(p, dow_weights);
[ersk,eret] = estimatePortMoments(p, p.InitPort);

p = setDefaultConstraints(p);

%return 30 portfolios
pwgt = estimateFrontier(p,30);
%get first two moments
[prsk,pret] = estimatePortMoments(p, pwgt);

%just avg rf rate
rf = 0.02;
%Sharpe Ratio: (E[r] - rf)/(std(portfolio))
max_sharpe = find(max((pret - rf)/prsk)); %gives portfolio 30--last portfolio
%puts ALL weight in MSFT

%%
%Portfolio 2
p_constr = p;
p_constr = setDefaultConstraints(p_constr); 
%have to set the bound constraint or you get an error
%0.05 is minimum weight per asset
p_constr = setBounds(p_constr, .05, 'BoundType', 'conditional');
%minimum 16 assets, max 25
p_constr = setMinMaxNumAssets(p_constr,16,25);

%give 30 portfolios
pwgt2 = estimateFrontier(p_constr,30); 
%get first two moments
[prsk2,pret2]=estimatePortMoments(p_constr,pwgt2);

%%
%Part 2

%portfolio returns: matrix multiplication between initial
%data and weights from optimization process
ret_1 = returns{:,3:end}*pwgt(:,30);
ret_2 = returns{:,3:end}*pwgt2(:,30);

ret = [ret_1 ret_2];

performance = zeros(8,2);
%performance metrics
for i=1:2
    %active returns
    ar = ret(:,i) - returns{:,2}; 
    %Total active: sum up the log returns, Each month is an observation so
    %just take mean to get monthly return. Risk is just standard dev
    %avg monthly/var is Information Ratio. Use maxdrawdown function
    %omega is ratio between positive and negative months in the pdf
    %sortino is like sharpe (subtract rf) but only account for downside
    %risk; upside is first moment (return) accounting for downside risk
    %(second moment)
    performance(:,i) = [sum(ar)*100; mean(ar)*100; std(ar); mean(ar)/std(ar);...
        maxdrawdown(ar, 'arithmetic'); (lpm(-ar, -0, 1) / lpm(ar, 0, 1));...
        (mean(ar) - rf) / sqrt(lpm(ar, 0, 2)); lpm(-ar, -0, 1) / sqrt(lpm(ar, 0, 2))]';
end

performance = array2table(performance,'VariableNames',{'P1', 'P2'},'RowNames',...
        {'TARet', 'MARet', 'ActRisk', 'IRatio', 'MaxDrawdownARet','Omega', 'Sortino', 'Upside'});


%%
%Part 3

figure(1);
%subtract actual weights from calculated weights
bar(categorical(assetNames), pwgt(:,30) - dow_weights)
title('Portfolio 1')

%same thing as P1
figure(2)
bar(categorical(assetNames), pwgt2(:,30) - dow_weights)
title('Portfolio 2')

%%
%Part 4
%{
When we maximize the Sharpe Ratio, each portfolio is essentially the same.
Both put as much weight as possible in Microsoft. Without any constraints,
eventually we put a weight of 1 in MSFT for Portfolio 1. In Portfolio 2, we
add a constraint on the number of assets with a minimum weight of 0.05 in
all assets. The optimization process puts as little weight as possible in
all other minimum 15 assets (0.05) and 0.25 in MSFT. As such the total
active return is lower for portfolio 2. Still, each performs well, with a
130% gain above the DJIA for Portfolio 1, and 71% above the DJIA for Portfolio 2. The all-Microsoft
Portfolio 1 outgains the DJIA by about 2% per month, and the more diversified Portfolio 2
gains about 1% per month above the DJIA. 
Because there are more assets in Portfolio 2, the active risk is also much
less than that of Portfolio 1. The informatio ratio adjusts for additional risk
but measures performance compared to a benchmark index. The smaller risk of
Portfolio 2 is the main source its higher Information Ratio. 

The max drawdown measures the largest trough to peak movement of portfolio
returns. The 16 assets have a less volatile max peak to trough movement in
monthly returns than Microsoft alone. Microsoft has some large outgain of
nearly 30% over the DJIA. 

The Omega ratio is the ratio between the area of a probability distribution
above vs below a specified value. Here, the value is zero, so we are just
finding the ratio of positive return days to negative return days. The 16
asset portfolio seems to have more positive return days than portfolio 1.

The Sortino ratio is a modified Sharpe ratio that only accounts for
downside risk (days with negative returns). This metric tells a different
story than the omega ratio. Portfolio 1 is much better (less negative) than
portfolio 2. Since the Omega ratio is also lower for portfolio 1, and the Sortino is
 overall much higher for portfolio 1, there is
likely a few days where portfolio 1 has large gains (this is also supported
by the max drawdown difference where 1 has a steep dropoff). 
Portfolio 1 is probably heavy-tailed in the positive direction. Still, the
upside ratio for portfolio 2 is higher, likely due to the units of downside
risk where portfolio 1 is 4 times higher. 
%}