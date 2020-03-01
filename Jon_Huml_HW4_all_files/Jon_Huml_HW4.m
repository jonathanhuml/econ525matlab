%Purpose:
    %ECON 525-Spring2020
%Note:
    %This is dependent on:
        %five_returns.csv
%Author:
    %Jon Huml-Feb 20
    %UNC Honor Pledge abided by
close all; clc; 

tech = readtable("five_returns.csv");

train = table2array(tech(1:1510,3:end));
test = table2array(tech(1511:1515,3:end));

figure(1) 
parcorr(tech.AAPL);
figure(2)
autocorr(tech.AAPL);
figure(3)
parcorr(tech.AMZN);
figure(4)
autocorr(tech.AMZN);
figure(5)
parcorr(tech.FB);
figure(6)
autocorr(tech.FB);
figure(7)
parcorr(tech.GOOGL);
figure(8)
autocorr(tech.GOOGL);
figure(9)
parcorr(tech.MSFT);
figure(10)
autocorr(tech.MSFT);

%{ First we define p as nonseasonal autoregressive polynomial degree, q as the 
%nonseasonal moving average polynomial degree. If the bars reach outside of the confidence interval, then the
%observation is statistically significant. The decay is quite rapid for both plots.
%The PACF, with few to no large spikes, shows that all the higher-order autocorrelations are 
% mostly explained by the lag-1 autocorrelation. While these plots would
% then seem to suggest a (1,1) model, I would prefer a more systematic way
% of doing this. Below is the code I used to find the minimum Bayesian
% Information Criteria, which penalizes overfitted polynomial models p,q.
% We want to generalize our model to new data and abstain from
% overfitting our current data. The code below loops through each asset and
% then each pairwise combo of p,q. This is quite slow so I only ran it once
% and then commented the process out. We want the smallest BIC, which is
% given by p=1,q=1. My best guess of these returns is close to what it was
% yesterday. 
% 
% 
%}


%{
values = zeros(8,8);
pq = zeros(8,8);
for j = 1:5 %number of assets
    for p = 1:8
        for q = 1:8
            mod = arima(p,0,q);
            [fit,~,values] = estimate(mod,train(:,j),'Display','off');
            values(p,q) = values;
            pq(p,q) = p+q;
       end
    end
end

values = reshape(values,64,1);
pq = reshape(pq,64,1);
[~,bic] = aicbic(values,pq+1,100);
reshape(bic,8,8);

min_bic = pq(find(bic==min(bic)),:);
%}
%p=1,q=1

%%
%2a
Mdl = arima(2,0,4);
static_24 = zeros(5,5); %init array
for j = 1:5 %5 assets
    EstMdl = estimate(Mdl,train(:,j));
    [b,mse] = forecast(EstMdl,5,'Y0',train(:,j));
    static_24(:,j)=b;  %fill the array with the 5 values    
end

Mod = arima(1,0,1);
static_11 = zeros(5,5); 
for j = 1:5 %5 assets
    EstMdl = estimate(Mod,train(:,j));
    [b,mse] = forecast(EstMdl,5,'Y0',train(:,j));
    static_11(:,j)=b;       
end

static_24_table = array2table(static_24, "VariableNames",{'AAPL','AMZN','FB','GOOGL','MSFT'});
static_11_table = array2table(static_11, "VariableNames",{'AAPL','AMZN','FB','GOOGL','MSFT'});

%%
%2b
dynamic_24 = zeros(5,5); 
for j = 1:5 %for each asset
    for i = 1:5 %five prediction days
        EstMdl = estimate(Mdl,train(:,j));
        [b,mse] = forecast(EstMdl,1,'Y0',train(:,j));
        train(end+1,j) = b; %add the prediction to the test data for the next prediction
        dynamic_24(i,j)=b; %fill the empty array    
    end
end

%same thing, different model
%probably could've just used one triple loop for these two copy-pastes
dynamic_11 = zeros(5,5); 
for j = 1:5
    for i = 1:5
        EstMdl = estimate(Mod,train(:,j));
        [b,mse] = forecast(EstMdl,1,'Y0',train(:,j));
        train(end+1,j) = b; 
        dynamic_11(i,j)=b;       
    end
end

dynamic_24_table = array2table(dynamic_24, "VariableNames",{'AAPL','AMZN','FB','GOOGL','MSFT'});
dynamic_11_table = array2table(dynamic_11, "VariableNames",{'AAPL','AMZN','FB','GOOGL','MSFT'});

%%
%2c

%{ As stated earlier, the (1,1) specification roughly states that my best
%guess of today's returns is simply what it was yesterday. Thus the (1,1)
%table looks quite uniform across the 5 day testing period. AAPL
%predictions are the most volatile, with GOOGL as a close second. However,
%AMZN and FB rarely deviate from a 0.0012 and 0.0010 median, respectively. MSFT is also quite uniform. 
% The (2,4) specification fits more precise trends. On opening bell that
% Wednesday after New Year's, all the assets (except Amazon) are predicted
% to see a slight increase. The same is roughly true of the following
% Monday. The 2,4 model is more precise because it has higher order
% polynomial terms. Think of f(x)=x^3 vs f(x)=x. The latter is just a straight line, but the
% former is more "wavy". As you add more higher order polynomials, you can
% make abritary fits to data or "overfit." 
% The dynamic and static tables for (1,1) thus are pretty similar. It
% shouldn't matter if I'm making a prediction on a prediction if my best
% guess is simply what yesterday's returns were. The dynamic and static
% tables for (2,4) do seem to differ however. Not only do some of the
% positive or negative signs change, but the return magnitudes all get
% smaller and smaller. There seems to be some attenuation bias in our
% models. This is because we are predicting off of predictions, so there is
% error inside of our independent variable. A standard model specfication
% only accounts for error in the dependent variable. We would expect these
% predictions to get worse and worse as time goes on. 
%}

%%
%2d
tests = [static_24, static_11, dynamic_24,  dynamic_11];

RMSE = zeros(4,5);
for i = 1:4 %do for each model
    RMSE(i,:) = sqrt(mean((test-tests(i)).^2)); %def of root mean squared error
end

RMSE_table = array2table(RMSE', "VariableNames",{'static_24','static_11','dynamic_24','dynamic_11'},"RowNames",{'AAPL','AMZN','FB','GOOGL','MSFT'});

%%
%2e
%Apple is the most unpredictable asset. We see its high RMSE across all
%models. Earlier in our analysis, the predictions were much more volatile
%than any other asset. 
% Amazon is hardly predictable as well, but is much closer to the other three, lower assets. 
%MSFT and GOOGL are among the lowest with similar average RMSEs. 
%As expected, the dynamic performs much worse on average than the static. 
%Making predictions off of predictions should cause attenuation bias, and
%it seems that the empirical evidence supports this suspicion.
%Interestingly enough, the 1,1 static model underpeforms the 2,4 static
%model but 1,1 dynamic outperforms the 2,4 dynamic. The 1,1 dynamic model
%is actually more comparable to static 2,4 model than the static 1,1 model.
%Again, Apple is one outlier (static 1,1 is among the best at predicting
%Apple returns) but it appears that the static 2,4 is the best of these
%four models at least for these days. We might want a larger
%evaluation/test period before we suggest trading off of this model, however. 



