SELECT
	Country_name,	
	Time_period,
	round(Est_gdp_in_billions) as Rounded_Est_gdp_in_billions,
    log(Est_gdp_in_billions) as Log_est_gdp_in_billions,
    sqrt(Est_gdp_in_billions) as sqrt_est_in_billions
From
	access_to_basic_services;