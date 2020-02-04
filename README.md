# econ525matlab
Matlab files for econ 525 


hw1: Standard two pass and Fama MacBeth regression factor models. Step one estimates exposure. Step two estimates premia based on estimated exposure. Notice the errors in variables problem. This file does not group portfolio betas or use instrumental variables to combat this. 
Constituent tickers web scraped from wikipedia, then use this file to get data (cleaned, monthly log return data) in R from yahoo finance. 

hw2: actually creating the Fama French factors "small minus big" (SMB) and "high minus low" (HML). We sort the S&P 500 constituents into 6 bins using percentiles for market cap (share price * # shares outstanding) and book to market value. You could use a bunch of loops for this, but boolean selection is way faster and more elegant--basically five lines of code. The rest is just cleaning up the tables and graphing the time series of expected returns. 
