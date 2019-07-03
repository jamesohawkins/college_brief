********************************************************************************
//	program:			main-brief
//	task:				do file for college attainment issue brief
//	project:			college attainment issue brief
//	author:				joh \ 2019-07-03
********************************************************************************

// Set file/directory macros
global output 						""
global cps_1962_2018 				""
global do_files						""
global acs							""

cd "$do_files"
version 15
clear all
set linesize 80

capture log close
log using "educ-main", replace text

graph set window fontface lato




// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
// Figure 1
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


// Data cleaning
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	// ACS data
	* opening data file
	cd "$acs"
	use raw.dta, clear
	* keeping select variables for analysis
	keep year age educd perwt
	label drop educ_lbl
	* keeping select years for analysis
	tab year
	keep if year == 1950 | year == 1960
	* dropping missing or N/A observations
	drop if educd == 999 | educd == 1											// educd == 1 only include observations less than 5 years old
	tab educd, missing

	// CPS + ACS data
	* appending CPS file to ACS file
	cd "$cps_1962_2018"
	append using raw.dta, generate(source)
	* keeping select variables for analysis
	keep year age educ educd hflag asecwt perwt source
	* dropping missing or NIU observations
	drop if educ == 999 | educ == 1												// educ == 1 is out of sample (less than 15 years old)
	drop if year == 1963														// missing educ data in 1963
	tab educ if source == 1, missing
	* renaming educ variables to correspond with original data set (excluded educ variable from acs)
	rename educ educ_cps
	rename educd educ_acs
	* checking outcome of append
	tab year source
	tab year if educ_cps == .
	tab year if educ_acs == .
	tab educ_cps source, missing
	tab educ_acs source, missing
	* dropping 3/8 file for 2014 (CPS)
	tab hflag
	tab hflag, nol
	drop if hflag == 1
	
	// Combining education variables from ACS and CPS for college completion
	/* based on imputation in: https://www.jstor.org/stable/1392334?seq=1#metadata_info_tab_contents */
	gen college_imput = .
	replace college_imput = 110 if educ_acs == 100								// ACS, 4 years of college
	replace college_imput = 121 if educ_acs == 110								// ACS, 5+ years of college
	replace college_imput = 122 if educ_acs == 111								// ACS, 6 years of college (6+ in 1960-1970)
	replace college_imput = 110 if educ_cps == 110								// CPS, 4 years of college
	replace college_imput = 111 if educ_cps == 111								// CPS, Bachelor's degree
	replace college_imput = 121 if educ_cps == 121								// CPS, 5 years of college
	replace college_imput = 122 if educ_cps == 122								// CPS, 6+ years of college
	replace college_imput = 123 if educ_cps == 123								// CPS, Master's degree
	replace college_imput = 124 if educ_cps == 124								// CPS, Professional school degree
	replace college_imput = 125 if educ_cps == 125									
	tab college_imput, missing
	
	// Dummy variable for college attainment
	gen dcollege = (college_imput == 110 | college_imput == 111 | college_imput == 121 | college_imput == 122 | college_imput == 123 | college_imput == 124 | college_imput == 125)
	tab dcollege educ_acs if source == 0, missing
	tab dcollege educ_cps if source == 1, missing

	// Creating generation bins
	/* generation bins based on Pew Center definition: https://www.pewresearch.org/fact-tank/2019/01/17/where-millennials-end-and-generation-z-begins/ */
	gen generation = .
	* gen z
		local i = 0
		forvalues year = 1997/2018 {
			replace generation = 1 if age <= `i' & year == `year'
			local i = `i' + 1
		}
	* millennials
		local i = 0
		forvalues year = 1981/1996 {
			replace generation = 2 if age <= `i' & year == `year'
			local i = `i' + 1
		}
		local y = 1
		forvalues year = 1997/2018 {
		replace generation = 2 if age >= `y' & age <= `i' & year == `year'
		local i = `i' + 1
		local y = `y' + 1
		}
	* gen x
		local i = 0
		forvalues year = 1965/1980 {
		replace generation = 3 if age <= `i' & year == `year'
		local i = `i' + 1
		}
		local y = 1
		forvalues year = 1981/2018 {
		replace generation = 3 if age >= `y' & age <= `i' & year == `year'
		local i = `i' + 1
		local y = `y' + 1
		}
	* boomers
		local i = 0
		forvalues year = 1946/1964 {
		replace generation = 4 if age <= `i' & year == `year'
		local i = `i' + 1
		}
		local y = 1
		forvalues year = 1965/2018 {
		replace generation = 4 if age >= `y' & age <= `i' & year == `year'
		local i = `i' + 1
		local y = `y' + 1
		}
	* silent
		local i = 0
		forvalues year = 1928/1945 {
		replace generation = 5 if age <= `i' & year == `year'
		local i = `i' + 1
		}
		local y = 1
		forvalues year = 1946/2018 {
		replace generation = 5 if age >= `y' & age <= `i' & year == `year'
		local i = `i' + 1
		local y = `y' + 1
		}
	* retains values for years after the first members of a generation reach 20 years old
	/* note: this is done purely for graphing purposes to avoid having zero
	college attainment rates during the years when none of a generation are of
	college age */
	replace generation = . if generation == 1 & year >= 1997 & year < 2017	
	replace generation = . if generation == 2 & year >= 1981 & year < 2001
	replace generation = . if generation == 3 & year >= 1965 & year < 1985
	replace generation = . if generation == 4 & year >= 1946 & year < 1966
	replace generation = . if generation == 5 & year >= 1928 & year < 1948
	drop if generation == .


// Data analysis
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	drop if asecwt < 0																// negative weights incompatible with pw option

	// College attainment rate by year and generation
	* acs
	preserve
	keep if year <= 1960
	collapse (sum) college_count = dcollege (mean) college = dcollege [pw = perwt], by(year generation)
	save acs_collapsed_educ.dta, replace
	restore
	* cps
	keep if year > 1960
	collapse (sum) college_count = dcollege (mean) college = dcollege [pw = asecwt], by(year generation)
	* combined (cps + acs)
	append using acs_collapsed_educ.dta
	
	// Smoothing trends
	* lowess calculation
	forvalues generation = 1/5 {
		lowess college year if generation == `generation', bwidth(.15) gen(college_smooth`generation') title(Lowess Smoother) nograph
		lowess college_count year if generation == `generation', bwidth(.15) gen(college_count_smooth`generation') title(Lowess Smoother) nograph
	}
	* count of college graduates
	gen college_count_smooth = .
	forvalues i = 1/5 {
		replace college_count_smooth = college_count_smooth`i' if college_count_smooth`i' != .
		drop college_count_smooth`i'
	}
	* college attainment rate
	gen college_smooth = .
	forvalues i = 1/5 {
		replace college_smooth = college_smooth`i' if college_smooth`i' != .
		drop college_smooth`i'
	}

	// Labels for generations
	sort generation year
	label variable generation
	label values generation generation_lbl
	label define generation_lbl ///
		1 "Gen Z" ///
		2 "Millennials" ///
		3 "Gen X" ///
		4 "Baby Boomers" ///
		5 "Silent"

	// Saving results
	cd "$output"
	compress
	save figure1.dta, replace
	export delimited using "figure1", replace


// Graph (combined)
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	use figure1.dta, clear
	keep year generation college_smooth
	drop if generation == 1
	drop if generation == .
	* reshaping data for line graph in Figure 1
	reshape wide college_smooth, i(year) j(generation)
	* y-value of text labels for each business cycle
	forvalues x = 2/5 {
	sum college_smooth`x' if year == 2018, meanonly
	local value`x' = r(mean)
	}
	* adjusting coordinate for text labels
	local value2 = `value2'-.002
	local value3 = `value3'+.002
	* graph for Figure 1
	twoway (line college_smooth5 college_smooth4 college_smooth3 college_smooth2 year, lcolor("0 165 152" "59 126 161" "70 83 94" "253 181 21") lwidth(medium) lpattern(solid solid solid solid)), ///
		ytitle("") yscale(lcolor(gs12) lwidth(thin)) ylabel(0 " " .1 "{bf:10%}" .2 "{bf:20%}" .3 "{bf:30%}" .4 "{bf:40%}", grid glwidth(vthin) glcolor(gs12%25) glpattern(solid) labsize(medsmall) labcolor(gs12) format(%9.0g) tlcolor(gs12)) ///
		xtitle({bf:Year}, size(small) color(gs7)) xtitle(, size(small)) xscale(lcolor(gs12) lwidth(thin)) xlabel(1950 "{bf:1950}" 1960 "{bf:1960}" 1970 "{bf:1970}" 1980 "{bf:1980}" 1990 "{bf:1990}" 2000 "{bf:2000}" 2010 "{bf:2010}" 2018 "{bf:2018}", grid glwidth(vthin) glcolor(gs12%25) glpattern(solid) labsize(small) labcolor(gs12) format(%-9.0g) tlcolor(gs12) ticks) xmtick(1949 " " 1955 "1955" 1965 "1965" 1975 "1975" 1985 "1985" 1995 "1995" 2005 "2005" 2015 "2015" 2018 "2018", tlcolor(gs12) ticks) ///
		title("{bf:Figure 1: Millennials are on track to have the highest college attainment rate}", color("59 126 161") margin(1.8 0 0 0) size(medlarge) position(11) span justification(left)) ///
		subtitle("{bf:Percent with a college degree}", color(gs7) margin(1.8 0 1 .5) size(medsmall) position(11) span justification(left)) ///
		note("{bf:Source}: Author's calculations based on data from IPUMS-CPS and IPUMS-ACS." "{bf:Notes}: Values are imputed for 1951-1959, 1961, and 1963 due to incomplete or unavailable data. Trends for each series are smoothed.", color(gs7) margin(1.9 0 0 -1.2) span size(vsmall) position(7)) ///
		scheme(plotplain) ///
		legend(off) ///
		text(`value2' 2018 " {bf:Millennials}", size(small) color("253 181 21") place(r)) ///
		text(`value3' 2018 " {bf:Gen X}", size(small) color("70 83 94") place(r)) ///
		text(`value4' 2018 " {bf:Baby Boomers}", size(small) color("59 126 161") place(r)) ///
		text(`value5' 2018 " {bf:Silent}", size(small) color("0 165 152") place(r)) ///
		graphregion(margin(0 0 0 1) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium)) ///
		graphregion(margin(l-2 r+20)) ///
		plotregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium)) ///
		plotregion(margin(t+1))
	* exporting graph
	graph export figure1.png, replace
	graph export figure1.svg, replace
	graph export figure1.tif, replace
	graph export figure1.pdf, replace

// Graph (business cycles in separate panels)
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	use figure1.dta, clear
	drop if generation == 1
	* graph for Figure 1 (cycle)
	twoway (line college_smooth year, lcolor(gs3) lwidth(medium) lpattern(solid)) || ///
	(scatter college year, mcolor(%25) msize(tiny) msymbol(circle)), ///
	ytitle("") yscale(lcolor(gs10) lwidth(thin)) ylabel(0 "" .1 "10%" .2 "20%" .3 "30%" .4 "40%", grid glwidth(vthin) glcolor(gs7) glpattern(dot) labcolor(gs7) format(%9.0g)) ///
	xtitle(Age) xtitle(, size(small)) xscale(lcolor(gs10) lwidth(thin)) xlabel(1950 "1959" 1960 "1960" 1980 "1980" 2000 "2000" 2018 "2018", grid glwidth(vthin) glcolor(gs7) glpattern(dot) labsize(vsmall) labcolor(gs7) format(%-9.0g) ticks) xmtick(1955 "1955" 1965 "1965" 1970 "1970" 1975 "1975" 1985 "1985" 1990 "1990" 1995 "1995" 2005 "2005" 2010 "2010" 2015 "2015" 2018 "2018", ticks) ///
	by(, title("Figure 2: College attainment over time", margin(l+.5) size(medlarge) position(11) justification(left)) ///
	subtitle("Percent with a college degree", margin(l+.5) size(small) position(11) span justification(left)) ///
	note("Source: Author's calculations based on data from the IPUMS-CPS." "Notes: 1962-1969 series not based on a full business cycle. Trends for each series are smoothed.", margin(l+.5 ) span size(vsmall) position(7))) ///
	scheme(plotplain) ///
	by(, graphregion(margin(zero) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium)) plotregion(margin(zero) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
	by(generation, imargin(zero) rows(1)) subtitle(, box fcolor(white) lcolor(none) lwidth(medium)) ///
	graphregion(fcolor(gs10) lcolor(gs10) lwidth(medium) ifcolor(gs10) ilcolor(gs10) ilwidth(medium)) plotregion(lcolor(gs10) ilwidth(medium))
	* exporting graph
	graph export figure1_cycle.png, replace

	
	

// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
// Figure 2
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

// Data cleaning
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	// Opening data file
	cd "$cps_1962_2018"
	use raw.dta, clear
	cd "$output"

	// Dropping 3/8 file for 2014
	tab hflag
	tab hflag, nol
	drop if hflag == 1

	// dropping missing or NIU observations for educ
	drop if educ == 999 | educ == 1												// educ == 1 is out of sample (less than 15 years old)
	drop if year == 1963														// missing educ data in 1963
	tab educ, missing
	
	// Dummy variable for educational attainment
	* bachelor's degree
	gen dcollege = (educ == 110 | educ == 111 | educ == 121 | educ == 122 | educ == 123 | educ == 124 | educ == 125)
	* advanced degree
	gen dadvanced = (educ == 123 | educ == 124 | educ == 125)
	* doctoral degree
	gen ddoctorate = (educ == 125)
	
	// Creating two separate age variables for analysis
	* see: https://cps.ipums.org/cps-action/variables/AGE#codes_section
	* binned ages
	gen age_bin = .
	replace age_bin = 1 if age >= 0 & age <= 6
	replace age_bin = 2 if age >= 7 & age <= 13
	replace age_bin = 3 if age >= 14 & age <= 17
	replace age_bin = 4 if age >= 18 & age <= 24
	replace age_bin = 5 if age >= 25 & age <= 29
	replace age_bin = 6 if age >= 30 & age <= 34
	replace age_bin = 7 if age >= 35 & age <= 44
	replace age_bin = 8 if age >= 45 & age <= 54
	replace age_bin = 9 if age >= 55 & age <= 64
	replace age_bin = 10 if age >= 65 & age <= 74
	replace age_bin = 11 if age >= 75
	tab age age_bin
	* recode of single year ages
	gen age_ = age
	replace age_ = 75 if age >= 75													// combining 75+ into single bin
	tab age age_
	* dropping individuals younger than 16 (out of sample universe for education)
	drop if age <= 15

	// Adjusting weight to account for pooled years
	replace asecwt = asecwt / 11 if year >= 2008 & year <= 2018
	replace asecwt = asecwt / 6 if year >= 2002 & year <= 2007
	replace asecwt = asecwt / 11 if year >= 1991 & year <= 2001
	replace asecwt = asecwt / 11 if year >= 1980 & year <= 1990
	replace asecwt = asecwt / 6 if year >= 1974 & year <= 1979
	replace asecwt = asecwt / 4 if year >= 1970 & year <= 1973
	replace asecwt = asecwt / 6 if year >= 1964 & year <= 1969

	// Creating bins for business cycles
	drop if year < 1964
	gen year_bin = 1 if year >= 1964 & year <= 1969
		/* excluding 1961-1963 because 1961 and 1963 are missing for educ */
	replace year_bin = 2 if year >= 1970 & year <= 1973
	replace year_bin = 3 if year >= 1974 & year <= 1979
	replace year_bin = 4 if year >= 1980 & year <= 1990
	replace year_bin = 5 if year >= 1991 & year <= 2001
	replace year_bin = 6 if year >= 2002 & year <= 2007
	replace year_bin = 7 if year >= 2008 & year <= 2018

	// Labels for year bins
	label variable year_bin
	label values year_bin year_bin_lbl
	label define year_bin_lbl ///
		1 "1964-1969" ///
		2 "1970-1973" ///
		3 "1974-1979" ///
		4 "1980-1990" ///
		5 "1991-2001" ///
		6 "2002-2007" ///
		7 "2008-2018"


// Data analysis
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	drop if asecwt < 0															// negative weights incompatible with pw option

	// Calculating attainment rate for each education dummy variable
	collapse (mean) college = dcollege 											///
		(mean) 	advanced = dadvanced 											///
		(mean) doctorate = ddoctorate  											///
		[pw = asecwt], ///
		by(year_bin age_)

	// Smoothing attainment series
	forvalues year = 1/7 {
	lowess college age_ if year_bin == `year', bwidth(.15) gen(college_smooth_`year') title(Lowess Smoother) nograph
	lowess advanced age_ if year_bin == `year', bwidth(.15) gen(advanced_smooth_`year') title(Lowess Smoother) nograph
	}
	* combining smoothed series into single variable
	gen college_smooth = .
	gen advanced_smooth = .
	forvalues year = 1/7 {
	replace college_smooth = college_smooth_`year' if year_bin == `year'
	replace advanced_smooth = advanced_smooth_`year' if year_bin == `year'
	}
	* dropping extraneous variables
	drop college_smooth_* advanced_smooth_*

	// Saving results
	compress
	save figure2.dta, replace
	export delimited using "figure2", replace


// Average increase in college attainment between 21 and 24
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	use figure2.dta, clear
	sort year_bin
	by year_bin: reg college age if age >= 21 & age <= 24


// Graph (combined)
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	use figure2.dta, clear
	keep age_ year_bin college_smooth
	* reshaping data for line graph in figure 2
	reshape wide college_smooth, i(age_) j(year_bin)
	* y-value of text labels for each business cycle
	forvalues x = 1/7 {
	sum college_smooth`x' if age_ == 75, meanonly
	local value`x' = r(mean)
	}
	* adjusting coordinate for text labels
	local value1 = `value1'-.007
	local value2 = `value2'
	* graph for Figure 1
	twoway (line college_smooth* age_, lcolor("188 228 216" "147 205 207" "110 184 197" "69 162 185" "53 137 169" "49 112 151" "44 89 133") lwidth(medium) lpattern(solid solid solid solid solid solid solid)), ///
		ytitle("") yscale(lcolor(gs12) lwidth(thin)) ylabel(0 " " .1 "{bf:10%}" .2 "{bf:20%}" .3 "{bf:30%}" .4 "{bf:40%}", grid glwidth(vthin) glcolor(gs12%25) glpattern(solid) labsize(medsmall) labcolor(gs12) tlcolor(gs12) format(%9.0g)) ///
		xtitle({bf:Age}) xtitle(, color(gs7) size(small)) xscale(lcolor(gs10) lwidth(thin)) xscale(lcolor(gs12)) xlabel(15 "{bf:15}" 30 "{bf:30}" 45 "{bf:45}" 60 "{bf:60}" 75 "{bf:75+}", grid glwidth(vthin) glcolor(gs12%25) glpattern(solid) labsize(small) labcolor(gs12) format(%-9.0g) ticks) xtick(15(15)75, tlcolor(gs12)) xmtick(15(5)75, tlcolor(gs12) ticks) ///
		title("{bf:Figure 2: College attainment has steadily increased over the last six decades}", color("59 126 161") margin(l+0) size(medlarge) position(11) span justification(left)) ///
		subtitle("{bf:Percent with a college degree}", color(gs7) margin(l b+.5 t-.5) size(medsmall) position(11) span justification(left)) ///
		note("{bf:Source}: Author's calculations based on data from IPUMS-CPS." "{bf:Notes}: 1964-1969 series is not based on a full business cycle. The 1980-1981 and 1982-1990 cycles are combined due to sample size limitations. Trends for each" "series are smoothed.", color(gs7) margin(l+.1 t-1.75) span size(vsmall) position(7)) ///
		scheme(plotplain) ///
		legend(off) ///
		text(`value1' 75 " {bf:1964-1969}", size(small) color("188 228 216") place(r)) ///
		text(`value2' 75 " {bf:1970-1973}", size(small) color("147 205 207") place(r)) ///
		text(`value3' 75 " {bf:1974-1979}", size(small) color("110 184 197") place(r)) ///
		text(`value4' 75 " {bf:1980-1990}", size(small) color("69 162 185") place(r)) ///
		text(`value5' 75 " {bf:1991-2001}", size(small) color("53 137 169") place(r)) ///
		text(`value6' 75 " {bf:2002-2007}", size(small) color("49 112 151") place(r)) ///
		text(`value7' 75 " {bf:2008-2018}", size(small) color("44 89 133") place(r)) ///
		graphregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium)) ///
		graphregion(margin(l-.7 r+15)) ///
		plotregion(margin(0 0 0 0) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium)) ///
		plotregion(margin(t+1))
	* exporting graph
	graph export figure2.png, replace
	graph export figure2.svg, replace
	graph export figure2.tif, replace
	graph export figure2.pdf, replace

	
// Graph (business cycles in separate panels)
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	use figure2.dta, clear
	* graph for figure 2 (cycle)
	twoway (line college_smooth age_, lcolor(gs3) lwidth(medium) lpattern(solid)) || ///
	(scatter college age_, mcolor(%25) msize(tiny) msymbol(circle)), ///
	ytitle("") yscale(lcolor(gs10) lwidth(thin)) ylabel(0 "" .1 "10%" .2 "20%" .3 "30%" .4 "40%", grid glwidth(vthin) glcolor(gs7) glpattern(dot) labcolor(gs7) format(%9.0g)) ///
	xtitle(Age) xtitle(, size(small)) xscale(lcolor(gs10) lwidth(thin)) xlabel(15 "15" 30 "30" 45 "45" 60 "60" 75 "75+", grid glwidth(vthin) glcolor(gs7) glpattern(dot) labsize(vsmall) labcolor(gs7) format(%-9.0g) ticks) xmtick(15(5)75, ticks) ///
	by(, title("Figure 2: College attainment over time", margin(l+.5) size(medlarge) position(11) justification(left)) ///
	subtitle("Percent with a college degree", margin(l+.5) size(small) position(11) span justification(left)) ///
	note("Source: Author's calculations based on data from the IPUMS-CPS." "Notes: 1962-1969 series not based on a full business cycle. Trends for each series are smoothed.", margin(l+.5 ) span size(vsmall) position(7))) ///
	scheme(plotplain) ///
	by(, graphregion(margin(zero) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium)) plotregion(margin(zero) fcolor(white) lcolor(white) lwidth(medium) ifcolor(white) ilcolor(white) ilwidth(medium))) ///
	by(year_bin, imargin(zero) rows(1)) subtitle(, box fcolor(white) lcolor(none) lwidth(medium)) ///
	graphregion(fcolor(gs10) lcolor(gs10) lwidth(medium) ifcolor(gs10) ilcolor(gs10) ilwidth(medium)) plotregion(lcolor(gs10) ilwidth(medium))
	* exporting graph
	graph export figure2_cycle.png, replace

