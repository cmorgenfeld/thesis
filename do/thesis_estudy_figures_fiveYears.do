*******************************************************************
* Name: Creighton Morgenfeld          						            
* Date: 
* Purpose: this program serves as a base shell for all stata do files 
*******************************************************************

*** This next line is the path to this .do file, you can cut and paste this path into stata to run the .do file
* do C:\Users\Creighton.Morgenfeld\Documents\AY23-2\SS489C\do\ss489c-replication2.do

********************************
* Standard Stata Configuration
********************************
clear all
set more off
cap log close

set scheme sj

global dir "C:\Users\Creighton\Documents\Stata\Thesis"  // copy actual file path inside the quotes on this line

global dodir "$dir\do"
global rawdir "$dir\raw"
global savedir "$dir\finaldta"
global logdir "$dir\log"
global graphdir "$dir\graph"
global tabledir "$dir\table"

* Set your directory
cd "${dir}"

* Start a log file, which is the text file that keeps all of the output from a Stata run
// log using "${logdir}\Thesis.log", replace


*** This next line loads the data from your .dta file
use "${savedir}\state_year_fiveYear_15_29", clear


global DEATH_TYPES allDeaths intentionalSelfHarm transportDeaths

collapse (mean) statecode (sum) $DEATH_TYPES (sum) population, by(state year ageGroup)

merge m:1 statecode using ${savedir}\legalization, keepusing(y_e y_l)

drop if y_e == .
drop _merge

gen years_post_effective = year - y_e
gen years_post_licensed = year - y_l

// preserve
//
// keep if allDeaths == 0 | intentionalSelfHarm == 0 | transportDeaths == 0
// keep if abs(years_post_effective) <= 3 | abs(years_post_l) <= 3
//
// restore


drop if statecode == 2 | statecode == 10 | statecode == 11 | statecode == 23 | statecode == 44 | statecode == 50

keep if abs(years_post_effective) <= 3 | abs(years_post_l) <= 3


foreach death in $DEATH_TYPES {
	gen `death'_rate = `death' / (population / 100000)
	
	replace `death'_rate = -1 if `death'_rate == 0
	
	gen log_`death'_rate = log(`death'_rate)
}


	

global OPTIONS effective licensed
global AGE_GROUP 0 1 2 // 0 (15-20); 1 (21-29); 2 (30-39); 3 (40-49)


foreach t in $OPTIONS {
	global LEADS_`t'
	global LAGS_`t'



	forval year = 1/3 {
		gen lead_`year'_`t' = (years_post_`t' == -`year')
		
		global LEADS_`t' ${LEADS_`t'} lead_`year'_`t'
	}

	forval year = 1/3 {
		gen lag_`year'_`t' = (years_post_`t' == `year')
		
		global LAGS_`t' ${LAGS_`t'} lag_`year'_`t'
	}
}


// keep if age == 21




foreach t in $OPTIONS {
	foreach death in $DEATH_TYPES {
		sum years_post_`t'
		reghdfe log_`death'_rate ${LEADS_`t'} ${LAGS_`t'}, absorb(statecode year)
	}
}


local x_axis_name = "Years Relative to Legalization of Recreational Marijuana Use"

foreach t in $OPTIONS {
	foreach group in $AGE_GROUP {
		preserve
		
			keep if ageGroup == `group'
			
			local lower_age = 15 * (`group' == 0) + 20 * (`group' == 1) + 25 * (`group' == 2)
			local upper_age = 19 * (`group' == 0) + 24 * (`group' == 1) + 29 * (`group' == 2)
			
			reghdfe log_allDeaths_rate ${LEADS_`t'} ${LAGS_`t'}, absorb(statecode year)
		

			gen coef_`t' = .
			gen se_`t' = .

			local i = -3
			foreach q in ${LEADS_`t'} {
				replace coef_`t' = _b[`q'] if years_post_`t' == `i'
				replace se_`t' = _se[`q'] if years_post_`t' == `i'
				
				local i = `i' + 1
			}

				replace coef_`t' = 0 if years_post_`t' == 0
				replace se_`t' = 0 if years_post_`t' == 0

			local i = 1
			foreach q in ${LAGS_`t'} {
				replace coef_`t' = _b[`q'] if years_post_`t' == `i'
				replace se_`t' = _se[`q'] if years_post_`t' == `i'
				
				local i = `i' + 1
			}

			gen lb_`t' = coef_`t' - 1.96*se_`t'
			gen ub_`t' = coef_`t' + 1.96*se_`t'
			
			keep if abs(years_post_`t') <= 3	


			twoway rcap lb_`t' ub_`t' years_post_`t', color(gs11) sort || ///
				line coef_`t' years_post_`t', connect(L) lcolor(black) lpattern(solid) ///
				xline(0, lpattern(.)) yline(0, lpattern(.)) ///
				xsc(range(-3 3)) xmtick(-3(1)3) xlabel(-3(1)3) ///
				ytitle("Log(Deaths per 100,000)") ///
				xtitle(`x_axis_name') ///
				title("Death Rate for `lower_age'- to `upper_age'-Year-Olds") ///
				legend(off) name(estudy_`t'_ageGroup_`group', replace)
				
			save "${savedir}\estudy_`t'_ageGroup_`group'", replace
			
			graph save "${graphdir}\estudy_`t'_ageGroup_`group'.gph", replace
			graph export "${graphdir}\estudy_`t'_ageGroup_`group'.png", replace
			
			save "${savedir}\estudy_`t'_ageGroup_`group'", replace

		restore
	}
	local x_axis_name = "Years Relative to Legalization of Licensed Sale of Recreational Marijuana"
}



graph combine "${graphdir}\estudy_effective_ageGroup_0.gph" "${graphdir}\estudy_effective_ageGroup_1.gph" "${graphdir}\estudy_effective_ageGroup_2.gph"




foreach t in $OPTIONS {
	use "${savedir}\estudy_`t'_ageGroup_0", clear
	append using "${savedir}\estudy_`t'_ageGroup_1" "${savedir}\estudy_`t'_ageGroup_2"
	
	replace years_post_`t' = years_post_`t' + 0.1 * ageGroup
	
	save "${savedir}\estudy_`t'", replace
	
}

local x_axis_name = "Years Relative to Legalization of Recreational Marijuana Use"
local title = "Death Rate over Time"

foreach t in $OPTIONS {
	use "${savedir}\estudy_`t'", clear

	twoway rcap lb_`t' ub_`t' years_post_`t' if ageGroup == 0, color(gs11) sort || ///
		line coef_`t' years_post_`t' if ageGroup == 0, connect(L) lcolor(black) lpattern(solid) || ///
		rcap lb_`t' ub_`t' years_post_`t' if ageGroup == 1, color(gs11) sort || ///
		line coef_`t' years_post_`t' if ageGroup == 1, connect(L) lcolor(blue) lpattern(dash) || ///
		rcap lb_`t' ub_`t' years_post_`t' if ageGroup == 2, color(gs11) sort || ///
		line coef_`t' years_post_`t' if ageGroup == 2, connect(L) lcolor(red) lpattern(dot) ///
		xline(0, lpattern(.)) yline(0, lpattern(.)) ///
		xsc(range(-3 3)) xmtick(-3(1)3) xlabel(-3(1)3) ///
		ytitle("Log(Deaths per 100,000)") ///
		xtitle(`x_axis_name') ///
		title(`title') ///
		legend(order(2 "15- to 19-Year-Olds" 4 "20- to 24-Year-Olds" 6 "25- to 29-Year-Olds")) name(estudy_`t', replace)
			
	
	local x_axis_name = "Years Relative to Legalization of Licensed Sale of Recreational Marijuana"
// 	local title = "Death Rate by Years Relative to Legalization of Licensed Sale of Recreational Marijuana"


	graph save "${graphdir}\estudy_`t'.gph", replace
	graph export "${graphdir}\estudy_`t'.png", replace
}

// Dropping states that don't span the entire bandwidth

local x_axis_name = "Years Relative to Legalization of Recreational Marijuana Use"
local title = "Death Rate over Time (Pruned Sample)"

foreach t in $OPTIONS {
	use "${savedir}\estudy_`t'", clear
	
	
	local bad_states 4 9 17 24 26 27 29 30 34 35 36 39 51
	foreach s of local bad_states {
		drop if statecode == `s'
	}
	
	keep if round(abs(years_post_`t' - 0.1 * ageGroup)) <= 3

	twoway rcap lb_`t' ub_`t' years_post_`t' if ageGroup == 0, color(gs11) sort || ///
		line coef_`t' years_post_`t' if ageGroup == 0, connect(L) lcolor(black) lpattern(solid) || ///
		rcap lb_`t' ub_`t' years_post_`t' if ageGroup == 1, color(gs11) sort || ///
		line coef_`t' years_post_`t' if ageGroup == 1, connect(L) lcolor(blue) lpattern(dash) || ///
		rcap lb_`t' ub_`t' years_post_`t' if ageGroup == 2, color(gs11) sort || ///
		line coef_`t' years_post_`t' if ageGroup == 2, connect(L) lcolor(red) lpattern(dot) ///
		xline(0, lpattern(.)) yline(0, lpattern(.)) ///
		xsc(range(-3 3)) xmtick(-3(1)3) xlabel(-3(1)3) ///
		ytitle("Log(Deaths per 100,000)") ///
		xtitle(`x_axis_name') ///
		title(`title') ///
		legend(order(2 "15- to 19-Year-Olds" 4 "20- to 24-Year-Olds" 6 "25- to 29-Year-Olds")) name(estudy_`t'_full, replace)
			
	
	local x_axis_name = "Years Relative to Legalization of Licensed Sale of Recreational Marijuana"
// 	local title = "Death Rate by Years Relative to Legalization of Licensed Sale of Recreational Marijuana"


	graph save "${graphdir}\estudy_`t'_full.gph", replace
	graph export "${graphdir}\estudy_`t'_full.png", replace
}


graph combine "${graphdir}\estudy_effective_full.gph" "${graphdir}\estudy_effective.gph" 
graph combine "${graphdir}\estudy_licensed_full.gph" "${graphdir}\estudy_licensed.gph" 


local t = "effective"
use "${savedir}\estudy_`t'", clear

drop if ageGroup != 0
keep if abs(years_post_`t') <= 2

collapse ageGroup, by(state statecode years_post_`t')
collapse (count) ageGroup, by(state statecode)
drop if ageGroup == 5

//
// local vlist0 foo bar dar
//
// local vlist1
// foreach item of local vlist0 {
// capture confirm variable `item'
// if _rc{
// local vlist1 `vlist1' `item'
// display "`vlist1'"
// }
// }

// Dropping states that don't span the entire bandwidth

local x_axis_name = "Years Relative to Legalization of Recreational Marijuana Use"
local title = "Death Rate over Time (Tighter Bandwidth Sample)"

foreach t in $OPTIONS {
	use "${savedir}\estudy_`t'", clear
	
	
	local bad_states 4 9 17 24 27 29 30 34 35 36 39 51
	foreach s of local bad_states {
		drop if statecode == `s'
	}
	
	keep if round(abs(years_post_`t' - 0.1 * ageGroup)) <= 2

	twoway rcap lb_`t' ub_`t' years_post_`t' if ageGroup == 0, color(gs11) sort || ///
		line coef_`t' years_post_`t' if ageGroup == 0, connect(L) lcolor(black) lpattern(solid) || ///
		rcap lb_`t' ub_`t' years_post_`t' if ageGroup == 1, color(gs11) sort || ///
		line coef_`t' years_post_`t' if ageGroup == 1, connect(L) lcolor(blue) lpattern(dash) || ///
		rcap lb_`t' ub_`t' years_post_`t' if ageGroup == 2, color(gs11) sort || ///
		line coef_`t' years_post_`t' if ageGroup == 2, connect(L) lcolor(red) lpattern(dot) ///
		xline(0, lpattern(.)) yline(0, lpattern(.)) ///
		xsc(range(-2 2)) xmtick(-2(1)2) xlabel(-2(1)2) ///
		ytitle("Log(Deaths per 100,000)") ///
		xtitle(`x_axis_name') ///
		title(`title') ///
		legend(order(2 "15- to 19-Year-Olds" 4 "20- to 24-Year-Olds" 6 "25- to 29-Year-Olds")) name(estudy_`t'_full, replace)
			
	
	local x_axis_name = "Years Relative to Legalization of Licensed Sale of Recreational Marijuana"
// 	local title = "Death Rate by Years Relative to Legalization of Licensed Sale of Recreational Marijuana"


	graph save "${graphdir}\estudy_`t'_2.gph", replace
	graph export "${graphdir}\estudy_`t'_2.png", replace
}





 