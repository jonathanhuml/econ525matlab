%price data for commodities index
gsci = readtable("GSCI.xlsx");

%read in weights of actual GSCI Index
weights_table = readtable("GICS_tickwght.xlsx"); 

%get returns from prices
returns = tick2ret(gsci{:,2:end});
%we need avg returns because we think gold and silver will 
%perform close to average
avg_returns = (1+mean(returns)).^252 - 1; 
%Equilibrium weights
weq = (weights_table{:,2})';

%Prior Covariance Matrix    
Sigma = 252*cov(returns);

%IMPORTANT NOTE: the Walters paper uses MONTHLY, not daily samples
%for estimation of tau. I use this here (5 years until Jan. 2020. * 12 months) 
%He also specifies that tauis about on the order of 0.02, and here it is 0.0278. 
%If we use daily,as discussed in the last part, we get extremely small shifts in portfolio 
%weights--hardly perceptible.
T = 60; 
N = size(returns,2); %assets


%% Port 1

%Risk tolerance of the market
delta= 3;
%Coefficient of uncertainty in the prior estimate of the mean
%tau stays constant throughout all portfolios
tau = 1/(T-N);
%Set the views: first view is GOLD = historical so 1 in 2nd to last index, second is 
% SILVER =historical which is last in returns array, last is BRENT outperforms CRUDEOIL, so -1,1 in line 3
P = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0;...
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1;...
0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
Q = [avg_returns(23); avg_returns(24);.01]; %Views (3x3), as elaborated above. Stays constant like P
%Set the uncertainty in the views, just standard way here
Omega = P * tau * Sigma * P' .* eye(1,1);%uncertainty of views set in the "standard way". 

%Portfolio1 into the hlblacklitterman function
[er, ps, w, pw]= hlblacklitterman(delta, weq, Sigma, tau, P, Q, Omega);


%% Port 2

%Risk tolerance of the market
delta= 3;
%Set the uncertainty in the views
Omega = P * tau * Sigma * P' .* eye(1,1);%uncertainty of views set in the "standard way".

%here, we need to double certainty of second view compared to first 
%but the first view has two parts, so technically the second view is 
%represented by the value on the third diagonal. Therefore, we sum the
%first two diagonal values and make it the third diag. value
Omega(3,3) = Omega(1,1)+ Omega(2,2);

%Portfolio2 into the hlblacklitterman function
[er2, ps2, w2, pw2]= hlblacklitterman(delta, weq, Sigma, tau, P, Q, Omega);


%% Port 3

%Risk tolerance of the market, DOUBLED
delta= 6;
%Set the uncertainty in the views
Omega = P * tau * Sigma * P' .* eye(1,1);%uncertainty of views set in the "standard way". 

%Port3 into the hlblacklitterman function
[er3, ps3, w3, pw3]= hlblacklitterman(delta, weq, Sigma, tau, P, Q, Omega);


%% Port 4

%Risk tolerance of the market
delta= 3;
%Set the uncertainty in the views
Omega = P * tau * Sigma * P' .* eye(1,1);%uncertainty of views set in the "standard way". 
for i = 1:3
    %make the diagonals so small that we have virtually no confidence in
    %our predictions (approx 0, or eps > 0)
    Omega(i,i) = 0.000000000001;
end

%Port4 into the hlblacklitterman function
[er4, ps4, w4, pw4]= hlblacklitterman(delta, weq, Sigma, tau, P, Q, Omega);

%% TABLE

posterior = array2table([weq' pw pw2 pw3 pw4],'VariableNames',{'Bench', 'P1', 'P2', 'P3', 'P4'},'RowNames', {'Wheat', 'KansasWheat', 'Corn', 'Soybean', 'Cotton','Sugar',...
    'Coffee', 'Cocoa', 'CrudeOil', 'Brent', 'Unleaded', 'Heating', 'Gas',...
    'NaturalGas', 'Aluminum', 'Copper', 'Lead', 'Nickel', 'Zinc', 'FeederCattle',...
    'LiveCattle','Lean', 'Gold', 'Silver'});

%% Discussion
%{

    All of our portfolios start from the same prior, the equilibrium GSCI
portfolio of the 24 commodities. Black-Litterman models expected
returns with a prior and posterior view (Bayesian). The prior returns are
thus assumed to be normally distributed. For an index with 24 assets, this
probably true on a global scale, though individual assets may not behave
exactly Gaussian. 
This code assumes that the variance of the views, Q, will be proportional
to the variance of the asset returns. This is a notable assumption given
that the two quantities are hypothesized to also be independent. Tau is a
constant of proportionality between these covariances. In the Walters
paper, some authors take tau to be equal to 1. The tau here, about 0.0278, 
significantly shrinks our differences between prior and posterior.
This value is consistent with the 0.025 and 0.05 range given in most
financial literature. It is important to note that with larger tau
approaching one, our confidence intervals for views will widen so as to have less 
practical meaning. Smaller tau thus offers more precision on estimates.
Thus, before we compare portfolios, it is first important to note that the changes across all 
portfolios are slight even when we change our view uncertainty in omega.
 

    We also only have partial views--views on a subset of assets of the GSCI.
When we change our views, which are not "complete" with respect to all
assets of the GSCI, the four assets subtract from the other 20 equally
regardless of how we change our views. Thus, the only weights that change
when we change our views are the four assets that we are specifically
addressing. Everything else is mostly identical. 
If we use the posterior estimate of the variance, the weights of the four assets will
often shift towards lower variance assets. 

    We can observe this in Portfolio 1. Brent and WTI are both fairly
volatile assets, and the holdings of each decrease by about nearly 1% and
5%, respectively. It is important to note that the spread in portfolio 1 between the two
assets increases by about 10%; that is, we have decreased WTI holdings at a
faster rate than brent. In our views, we are saying that brent will
outperform by about 1% more. We see the spread between this pair increase
for all portfolios even though the specific weights change in different
scenarios. 
    In portfolio 2, we double the certainty of the second view. The
spread in the equilibrium portfolio is -0.0781 (Brent ratio minus WTI
ratio). The pairs spread in portfolio 2 stays almost exactly constant at
-0.0786, but the holdings in the WTI decrease to their lowest of all four
of the portfolios. The brent holdings are their highest of the four
calculated portfolios, although it is important to note that this holding
is still about 3% less than the equilibrium weight. Going back to the
theory, this is likely due to the high variance of the oil market. This can
be seen empirically as well. When we double our risk aversion, the result
is roughly the same as portfolio 2. While they may shift for mathematically
different reasons, an interesting observation is that the effects are the
same in this specific instance. 
    When we change our uncertainty to about zero for portfolio 4, 
we see that the calculated portfolios mostly converge to 
equilibrium weights, especially for gold which has a lower variance than
silver. Brent holdings, however, decrease to their lowest levels in
portfolio 4 despite having lower variance (also lower returns) than WTI.
The spread between the two oil assets increases but in an opposite
direction--by increasing WTI holdings. My best guess for this is that WTI
has returns of about 10% compared to 9% for brent, so the risk-return
tradeoff must be enough such that the holdings for WTI increase above GSCI
equilibrium.
    The gold and silver weights change the most sporadically across
portfolios. For portfolios 1,2,and 3, gold decreases by about 17%. The
weight of silver over doubles in each as well (although it is important
to note that 'doubles' or '-17%' is relative since, combined, both gold
and silver are less than 4% of the entire portfolio). In portfolio 4,
when we put little confidence on our views, more weight goes to gold. This also seems
due to gold's higher market return than silver (about +6% vs. +5%). We
saw this phenomenon with WTI as well. 

%}