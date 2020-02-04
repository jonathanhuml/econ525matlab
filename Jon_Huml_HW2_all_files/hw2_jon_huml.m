%Purpose:
    %ECON 525-Spring2020
%Note:
    %This is dependent on:
        %EC525_HW2_SimData.xlsx
        %NumShares.xlsx
        %bookvaluepershare.xlsx
%Author:
    %Jon Huml-Feb 3
    %UNC Honor Pledge abided by
clear all; close all; clc; 
price_table = readtable("EC525_HW2_SimData.xlsx");
years = table2array(price_table(2:size(price_table,1),1));
prices = table2array(price_table(:,2:size(price_table,2)));
%get returns
returns = tick2ret(prices);

shares_table = readtable("NumShares.xlsx"); 
shares = table2array(shares_table(:,2:size(shares_table,2)));
btm_table = readtable("bookvaluepershare.xlsx");
btm = table2array(btm_table(2:size(btm_table,1),2:size(btm_table,2)));

%market cap is the share price * number of shares outstanding
market_cap = prices .* shares; 
%drop the first year because returns drops the first year
market_cap = market_cap(2:size(market_cap,1),:);


%get the small, big stocks
small = prctile(market_cap,50,2) > market_cap;
big = ~small;

value = prctile(btm,30,2) > btm;
growth = prctile(btm,70,2) < btm;
%if it's neither value nor growth it's neutral
neutral = ~(value | growth); 

%sorry for the ugliness of this part
%computes average portfolio returns per year (21 years) per portfolio type.
%Note that (small & value) is a boolean array, so we do element wise
%multiplication, then average across the rows (dim=2) and omit zero entries
%since zero entries represent other portfolio types
sv = sum(returns .* (small & value),2) ./ sum(returns .* (small & value)~=0,2);
sg = sum(returns .* (small & growth),2) ./ sum(returns .* (small & growth)~=0,2); 
sn = sum(returns .* (small & neutral),2) ./ sum(returns .* (small & neutral)~=0,2); 
bv = sum(returns .* (big & value),2) ./ sum(returns .* (small & value)~=0,2);
bg = sum(returns .* (big & growth),2) ./ sum(returns .* (small & value)~=0,2);
bn = sum(returns .* (big & neutral),2) ./ sum(returns .* (big & neutral)~=0,2);

%by Fama definitions
smb = (1/3)*(sv+sn+sg)-(1/3)*(bv+bg+bn);
hml = (1/2)*(sv+bv)-(1/2)*(sg+bg); 

small = [sv sg sn];
%PART A
figure
plot(years, small);
title('Small Value, Small Growth, Small Neutral');

%PART B
small_descript=table();
small_descript.Median=median(small)';
small_descript.Mean=mean(small)';
small_descript.Max=max(small)';
small_descript.Std_dev=std(small)';
%{
Small value stocks have the only positive median (about 2% growth). They are also 
highly skewed as evidenced by the high mean and large standard deviation.
There is some portfolio return of nearly 450% for small value. Small growth
stocks actually seem to do the poorest out of all the yearly portfolios,
although they paradoxically seem to have the smallest standard deviation
(against my intuition). 
The volatility across each has a large spread: small value has a standard
deviation of 0.99, while small growth has a std of 0.09. The deviation of
outcomes for small companies is quite unrestricted as expected. 

%}



big = [bv bg bn];
%PART C
figure
plot(years, big);
title('Big Value, Big Growth, Big Neutral');

%PART D
big_descript=table();
big_descript.Median=median(big)';
big_descript.Mean=mean(big)';
big_descript.Max=max(big)';
big_descript.Std_dev=std(big)';
%{
The big companies are much more uniform in their descriptive statistics as 
one would expect for many reasons. Smaller companies are more exposed to market
swings. In the event of a macroeconomic downturn, liquidity dries up, cash
flows get squeezed, and workers get laid off. For companies with fewer resources, this 
can mean shutting down. They are also inherently prone to dying in good times as well
due to the difficult nature of business in general. There seems to be some
size threshold--if you become big, you become stable and more predictable. 
Big companies all have median returns of about 13-18%. The volatility
across big value, big growth, and big neutral is quite tight as well,
ranging from 0.08-0.12. 
%}

%PART E
figure
plot(years, [smb hml]);
title('SMB and HML');

%PART F
fact_descript=table();
fact_descript.Median=median([smb hml])';
fact_descript.Mean=mean([smb hml])';
fact_descript.Max=max([smb hml])';
fact_descript.Std_dev=std([smb hml])';
%{
The negative SMB seems to indicate that bigger companies had better returns
during this period. The positive HML indicates that high value stocks also
had better returns during this period. 
We seem to have vindicated Warren Buffett. These results suggest investing
in large "undervalued" companies instead of smaller, perhaps more
"overvalued" companies like a new Initial Public Offering (IPO). 
%}